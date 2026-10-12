--!strict
-- Server ModuleScript: production DataStore persistence with session locking
-- When Packages.ProfileStore + DataServiceProfile present and USE_PROFILE_STORE=true, delegates to ProfileStore.
-- (Miner's Haven / Roblox best practice). Server-authoritative only.
-- Studio without API access falls back to in-memory mock so the game still runs.
-- pre-alpha-datastore-tighten-1: UpdateAsync re-checks lock ownership; BindToClose ~8s parallel saves.

-- Optional ProfileStore backend (Packages.ProfileStore). Legacy session-lock path is fallback.
local USE_PROFILE_STORE = true

local function tryProfileStoreBackend(): any?
	if not USE_PROFILE_STORE then
		return nil
	end
	local RS = game:GetService("ReplicatedStorage")
	local packages = RS:FindFirstChild("Packages")
	local ps = packages and packages:FindFirstChild("ProfileStore")
	if not ps or not ps:IsA("ModuleScript") then
		return nil
	end
	local profileMod = script.Parent:FindFirstChild("DataServiceProfile")
	if not profileMod or not profileMod:IsA("ModuleScript") then
		return nil
	end
	local okPs = pcall(require, ps)
	if not okPs then
		warn("[DataService] ProfileStore package failed to load — using legacy DataService")
		return nil
	end
	local ok, svc = pcall(require, profileMod)
	if ok and svc then
		print("[DataService] USE_PROFILE_STORE=true — delegating to DataServiceProfile")
		return svc
	end
	warn("[DataService] DataServiceProfile failed — using legacy DataService", svc)
	return nil
end

do
	local backend = tryProfileStoreBackend()
	if backend then
		return backend
	end
end

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local SCHEMA_VERSION = 1
local STORE_NAME = "CloutRanch_Player_v1"
local AUTOSAVE_INTERVAL = 60
local LOCK_TTL_SEC = 30 * 60 -- 30 minutes
local LOCK_RETRY_COUNT = 8
local LOCK_RETRY_WAIT = 2.5
local BIND_CLOSE_BUDGET = 8

export type SessionLock = {
	jobId: string,
	timestamp: number, -- unix
}

export type LuckBoostPersist = {
	mult: number,
	expiresUnix: number,
}

export type DailyPersist = {
	streak: number,
	lastClaimDay: number?,
	graceUsed: boolean,
}

export type BattlePassPersist = {
	seasonId: number,
	xp: number,
	tier: number,
	premium: boolean,
	claimedFree: { [string]: boolean },
	claimedPremium: { [string]: boolean },
}

export type ProfileV1 = {
	schemaVersion: number,
	sessionVersion: number,
	cash: number,
	incomeMult: number,
	pets: { [string]: string }, -- slotIndex string → petId
	maxSlots: number?,
	rebirths: number,
	aura: number,
	daily: DailyPersist,
	luckBoosts: { LuckBoostPersist },
	battlePass: BattlePassPersist?,
	gamePasses: { [string]: boolean }?,
	lastSeen: number?,
	lock: SessionLock?,
}

type SessionRecord = {
	profile: ProfileV1,
	dirty: boolean,
	loaded: boolean,
	saving: boolean,
	saveDepth: number,
	released: boolean,
}

local DataService = {}

local store: DataStore? = nil
local useMock = false
local mockPrinted = false
local mockStore: { [string]: ProfileV1 } = {}
local sessions: { [number]: SessionRecord } = {}
local jobId = if game.JobId ~= "" then game.JobId else ("studio-" .. tostring(os.time()))

local function softRequire(name: string): any?
	local mod = script.Parent:FindFirstChild(name)
	if not mod or not mod:IsA("ModuleScript") then
		return nil
	end
	local ok, result = pcall(require, mod)
	if ok then
		return result
	end
	return nil
end

local function defaultProfile(): ProfileV1
	return {
		schemaVersion = SCHEMA_VERSION,
		sessionVersion = 0,
		cash = 50,
		incomeMult = 1,
		pets = {},
		maxSlots = 3,
		rebirths = 0,
		aura = 0,
		daily = {
			streak = 0,
			lastClaimDay = nil,
			graceUsed = false,
		},
		luckBoosts = {},
		battlePass = {
			seasonId = 1,
			xp = 0,
			tier = 0,
			premium = false,
			claimedFree = {},
			claimedPremium = {},
		},
		gamePasses = {},
		lastSeen = nil,
		lock = nil,
	}
end

local function deepCopyProfile(src: ProfileV1): ProfileV1
	local pets: { [string]: string } = {}
	for k, v in src.pets do
		pets[k] = v
	end
	local luck: { LuckBoostPersist } = {}
	for _, b in src.luckBoosts do
		table.insert(luck, { mult = b.mult, expiresUnix = b.expiresUnix })
	end
	local gp: { [string]: boolean } = {}
	if src.gamePasses then
		for k, v in src.gamePasses do
			gp[k] = v
		end
	end
	local claimedFree: { [string]: boolean } = {}
	local claimedPremium: { [string]: boolean } = {}
	local bp = src.battlePass
	if bp then
		for k, v in bp.claimedFree do
			claimedFree[k] = v
		end
		for k, v in bp.claimedPremium do
			claimedPremium[k] = v
		end
	end
	return {
		schemaVersion = src.schemaVersion or SCHEMA_VERSION,
		sessionVersion = src.sessionVersion or 0,
		cash = src.cash or 50,
		incomeMult = src.incomeMult or 1,
		pets = pets,
		maxSlots = src.maxSlots or 3,
		rebirths = src.rebirths or 0,
		aura = src.aura or 0,
		daily = {
			streak = if src.daily then src.daily.streak else 0,
			lastClaimDay = if src.daily then src.daily.lastClaimDay else nil,
			graceUsed = if src.daily then src.daily.graceUsed else false,
		},
		luckBoosts = luck,
		battlePass = {
			seasonId = if bp then bp.seasonId else 1,
			xp = if bp then bp.xp else 0,
			tier = if bp then bp.tier else 0,
			premium = if bp then bp.premium else false,
			claimedFree = claimedFree,
			claimedPremium = claimedPremium,
		},
		gamePasses = gp,
		lastSeen = src.lastSeen,
		lock = if src.lock
			then { jobId = src.lock.jobId, timestamp = src.lock.timestamp }
			else nil,
	}
end

local function keyFor(userId: number): string
	return "u_" .. tostring(userId)
end

local function ensureStore(): boolean
	if useMock then
		return true
	end
	if store then
		return true
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok and result then
		store = result
		-- Probe once in Studio — API may still be off
		if RunService:IsStudio() then
			local pokeOk = pcall(function()
				(store :: DataStore):GetAsync("__clout_ranch_probe__")
			end)
			if not pokeOk then
				useMock = true
				store = nil
				if not mockPrinted then
					mockPrinted = true
					print("[DataService] Studio DataStore unavailable — using in-memory mock (game still runs)")
				end
			end
		end
		return true
	end
	useMock = true
	if not mockPrinted then
		mockPrinted = true
		print("[DataService] DataStore not available — using in-memory mock (game still runs)")
	end
	return true
end

local function _dsGet(userId: number): ProfileV1?
	ensureStore()
	local key = keyFor(userId)
	if useMock then
		local m = mockStore[key]
		return if m then deepCopyProfile(m) else nil
	end
	local ok, data = pcall(function()
		return (store :: DataStore):GetAsync(key)
	end)
	if not ok then
		warn("[DataService] GetAsync failed", userId, data)
		return nil
	end
	if typeof(data) ~= "table" then
		return nil
	end
	return deepCopyProfile(data :: ProfileV1)
end

local function dsUpdate(userId: number, transform: (ProfileV1?) -> ProfileV1): (boolean, ProfileV1?)
	ensureStore()
	local key = keyFor(userId)
	if useMock then
		local prev = mockStore[key]
		local nextProfile = transform(if prev then deepCopyProfile(prev) else nil)
		mockStore[key] = deepCopyProfile(nextProfile)
		return true, deepCopyProfile(nextProfile)
	end
	local out: ProfileV1? = nil
	local ok, err = pcall(function()
		(store :: DataStore):UpdateAsync(key, function(old)
			local prev: ProfileV1? = nil
			if typeof(old) == "table" then
				prev = deepCopyProfile(old :: ProfileV1)
			end
			local nextProfile = transform(prev)
			out = nextProfile
			return nextProfile
		end)
	end)
	if not ok then
		warn("[DataService] UpdateAsync failed", userId, err)
		return false, nil
	end
	return true, out
end

local function lockHeldByOther(lock: SessionLock?): boolean
	if not lock then
		return false
	end
	if lock.jobId == jobId then
		return false
	end
	local age = os.time() - (lock.timestamp or 0)
	return age < LOCK_TTL_SEC
end

--- True only if stored lock is absent or owned by this server (jobId match).
--- Used on every UpdateAsync save so a post-TTL steal by another server is never overwritten.
local function ownsStoredLock(lock: SessionLock?): boolean
	if not lock then
		return true
	end
	return lock.jobId == jobId
end

local function acquireLock(userId: number): (boolean, ProfileV1?)
	local lastProfile: ProfileV1? = nil
	for attempt = 1, LOCK_RETRY_COUNT do
		local ok, profile = dsUpdate(userId, function(old)
			local p = if old then deepCopyProfile(old) else defaultProfile()
			lastProfile = p
			if lockHeldByOther(p.lock) then
				-- Refuse overwrite while foreign lock is fresh
				return p
			end
			p.lock = {
				jobId = jobId,
				timestamp = os.time(),
			}
			return p
		end)
		if not ok or not profile then
			task.wait(LOCK_RETRY_WAIT)
			continue
		end
		lastProfile = profile
		if profile.lock and profile.lock.jobId == jobId then
			return true, profile
		end
		-- Soft "data loading" wait while another server holds the lock
		if attempt < LOCK_RETRY_COUNT then
			task.wait(LOCK_RETRY_WAIT)
		end
	end
	return false, lastProfile
end

local function _releaseLockAndSave(userId: number, profile: ProfileV1): boolean
	profile.lock = nil
	profile.lastSeen = os.time()
	profile.sessionVersion = (profile.sessionVersion or 0) + 1
	local aborted = false
	local ok = dsUpdate(userId, function(old)
		local prev: ProfileV1? = if old then deepCopyProfile(old) else nil
		-- Never blind-write after TTL if another server already holds the lock
		if prev and not ownsStoredLock(prev.lock) then
			aborted = true
			return prev
		end
		return profile
	end)
	if aborted then
		warn("[DataService] _releaseLockAndSave aborted — foreign session lock", userId)
		return false
	end
	return ok
end

local function boolMapFromNumberKeys(src: { [number]: boolean }?): { [string]: boolean }
	local out: { [string]: boolean } = {}
	if not src then
		return out
	end
	for k, v in src do
		if v then
			out[tostring(k)] = true
		end
	end
	return out
end

local function numberBoolMapFromStringKeys(src: { [string]: boolean }?): { [number]: boolean }
	local out: { [number]: boolean } = {}
	if not src then
		return out
	end
	for k, v in src do
		local n = tonumber(k)
		if n and v then
			out[n] = true
		end
	end
	return out
end

--- Snapshot live services into the session profile (does not write DataStore).
function DataService.Capture(player: Player): ProfileV1?
	local rec = sessions[player.UserId]
	if not rec then
		return nil
	end
	local p = rec.profile

	local Economy = softRequire("EconomyService")
	if Economy and Economy.Get then
		local w = Economy.Get(player)
		p.cash = w.cash
		p.incomeMult = w.incomeMult
	end

	local Ranch = softRequire("RanchService")
	if Ranch and Ranch.GetByUser then
		local ranch = Ranch.GetByUser(player.UserId)
		if ranch then
			local pets: { [string]: string } = {}
			for i, petId in ranch.slots do
				if typeof(petId) == "string" and petId ~= "" then
					pets[tostring(i)] = petId
				end
			end
			p.pets = pets
			p.maxSlots = ranch.maxSlots
		end
	end

	local Rebirth = softRequire("RebirthService")
	if Rebirth and Rebirth.GetLevel then
		p.rebirths = Rebirth.GetLevel(player)
	end

	local Aura = softRequire("AuraService")
	if Aura and Aura.GetAura then
		p.aura = Aura.GetAura(player)
	end

	local Daily = softRequire("DailyService")
	if Daily and Daily.GetState then
		local d = Daily.GetState(player)
		p.daily = {
			streak = d.streak or 0,
			lastClaimDay = d.lastClaimDay,
			graceUsed = d.graceUsed == true,
		}
	end

	local Luck = softRequire("LuckService")
	if Luck and Luck.GetPersistedBoosts then
		p.luckBoosts = Luck.GetPersistedBoosts(player)
	elseif Luck and Luck.GetLongestRemaining then
		-- Fallback: no structured export — leave existing list
	end

	local BP = softRequire("BattlePassService")
	if BP and BP.GetProgress then
		local prog = BP.GetProgress(player)
		p.battlePass = {
			seasonId = prog.seasonId or 1,
			xp = prog.xp or 0,
			tier = prog.tier or 0,
			premium = prog.premium == true,
			claimedFree = boolMapFromNumberKeys(prog.claimedFree),
			claimedPremium = boolMapFromNumberKeys(prog.claimedPremium),
		}
	end

	local Mon = softRequire("Monetization")
	if Mon and Mon.GetOwnedFlags then
		p.gamePasses = Mon.GetOwnedFlags(player)
	elseif Mon and Mon.Has then
		local flags: { [string]: boolean } = {}
		for _, key in { "VIP", "DoubleCash", "AutoCollect", "ExtraPet", "FastTravel", "FlexQueue", "BattlePass" } do
			if Mon.Has(player, key) then
				flags[key] = true
			end
		end
		p.gamePasses = flags
	end

	p.schemaVersion = SCHEMA_VERSION
	p.lastSeen = os.time()
	return p
end

local function applyToServices(player: Player, profile: ProfileV1)
	local Economy = softRequire("EconomyService")
	if Economy and Economy.ApplyLoaded then
		Economy.ApplyLoaded(player, profile.cash, profile.incomeMult)
	elseif Economy and Economy.InitPlayer then
		Economy.InitPlayer(player)
		if Economy.Get then
			local w = Economy.Get(player)
			w.cash = profile.cash
			w.incomeMult = profile.incomeMult or 1
		end
	end

	local Rebirth = softRequire("RebirthService")
	if Rebirth and Rebirth.SetLevel then
		Rebirth.SetLevel(player, profile.rebirths or 0)
	end

	local Mon = softRequire("Monetization")
	if Mon and profile.gamePasses and Mon.ApplyCachedFlags then
		Mon.ApplyCachedFlags(player, profile.gamePasses)
	elseif Mon and profile.gamePasses and Mon.GrantFlag then
		for key, on in profile.gamePasses do
			if on then
				Mon.GrantFlag(player, key)
			end
		end
	end

	local Ranch = softRequire("RanchService")
	local ranch = nil
	if Ranch then
		ranch = Ranch.GetByUser(player.UserId)
		if not ranch and Ranch.AssignPlot then
			ranch = Ranch.AssignPlot(player)
		end
		-- Expand for rebirth / ExtraPet before placing pets
		local slots = 3 + math.floor((profile.rebirths or 0) / 2)
		if profile.maxSlots and profile.maxSlots > slots then
			slots = profile.maxSlots
		end
		if Mon and Mon.Has and Mon.Has(player, "ExtraPet") then
			slots = math.max(slots, 4)
		end
		if Ranch.ExpandSlots then
			Ranch.ExpandSlots(player, slots)
		end
		if Ranch.ApplyPets then
			local byIndex: { [number]: string } = {}
			for k, petId in profile.pets do
				local idx = tonumber(k)
				if idx and typeof(petId) == "string" then
					byIndex[idx] = petId
				end
			end
			Ranch.ApplyPets(player, byIndex)
		end
	end

	if Mon and Mon.ApplyOwned then
		Mon.ApplyOwned(player)
	end

	local Daily = softRequire("DailyService")
	if Daily and Daily.ApplyState then
		Daily.ApplyState(player, {
			streak = profile.daily.streak,
			lastClaimDay = profile.daily.lastClaimDay,
			graceUsed = profile.daily.graceUsed,
		})
	end

	local Aura = softRequire("AuraService")
	if Aura and Aura.SetAura then
		Aura.SetAura(player, profile.aura or 0)
	end

	local Luck = softRequire("LuckService")
	if Luck and Luck.ApplyPersistedBoosts then
		Luck.ApplyPersistedBoosts(player, profile.luckBoosts or {})
	end

	local BP = softRequire("BattlePassService")
	if BP and BP.ApplyProgress and profile.battlePass then
		local bp = profile.battlePass
		BP.ApplyProgress(player, {
			seasonId = bp.seasonId,
			xp = bp.xp,
			tier = bp.tier,
			premium = bp.premium,
			claimedFree = numberBoolMapFromStringKeys(bp.claimedFree),
			claimedPremium = numberBoolMapFromStringKeys(bp.claimedPremium),
		})
	end

	-- Sync streak NumberValue for HUD
	local folder = player:FindFirstChild("CloutStats")
	if folder then
		local streak = folder:FindFirstChild("DailyStreak")
		if not streak then
			streak = Instance.new("NumberValue")
			streak.Name = "DailyStreak"
			streak.Parent = folder
		end
		if streak:IsA("NumberValue") then
			streak.Value = profile.daily.streak or 0
		end
		local rebirthVal = folder:FindFirstChild("Rebirths")
		if not rebirthVal then
			rebirthVal = Instance.new("NumberValue")
			rebirthVal.Name = "Rebirths"
			rebirthVal.Parent = folder
		end
		if rebirthVal:IsA("NumberValue") then
			rebirthVal.Value = profile.rebirths or 0
		end
	end
end

function DataService.MarkDirty(player: Player)
	local rec = sessions[player.UserId]
	if rec and rec.loaded and not rec.released then
		rec.dirty = true
	end
end

function DataService.IsLoaded(player: Player): boolean
	local rec = sessions[player.UserId]
	return rec ~= nil and rec.loaded == true
end

function DataService.GetProfile(player: Player): ProfileV1?
	local rec = sessions[player.UserId]
	return if rec then rec.profile else nil
end

--- Acquire session lock, load profile, push into live services. Soft-kick if locked elsewhere.
function DataService.LoadPlayer(player: Player): boolean
	ensureStore()
	if sessions[player.UserId] and sessions[player.UserId].loaded then
		return true
	end

	local acquired, profile = acquireLock(player.UserId)
	if not acquired or not profile then
		warn("[DataService] Could not acquire session lock for", player.Name)
		player:Kick("Data is loading on another server. Please rejoin in a moment.")
		return false
	end

	local rec: SessionRecord = {
		profile = profile,
		dirty = false,
		loaded = true,
		saving = false,
		saveDepth = 0,
		released = false,
	}
	sessions[player.UserId] = rec

	local applyOk, applyErr = pcall(applyToServices, player, profile)
	if not applyOk then
		warn("[DataService] Apply failed", player.Name, applyErr)
	end

	return true
end

function DataService.SavePlayer(player: Player, releaseLock: boolean?): boolean
	local rec = sessions[player.UserId]
	if not rec or not rec.loaded then
		return false
	end
	if rec.released then
		return true
	end
	-- Leave / BindToClose: wait briefly for in-flight autosave so we can release cleanly
	if rec.saving and releaseLock then
		local waitUntil = os.clock() + 2.5
		while rec.saving and os.clock() < waitUntil do
			task.wait(0.05)
		end
		if rec.released then
			return true
		end
	elseif rec.saving then
		return false
	end

	rec.saveDepth += 1
	rec.saving = true

	local okCapture, captureErr = pcall(function()
		DataService.Capture(player)
	end)
	if not okCapture then
		warn("[DataService] Capture failed", player.Name, captureErr)
	end

	local profile = deepCopyProfile(rec.profile)
	profile.sessionVersion = (profile.sessionVersion or 0) + 1
	profile.lastSeen = os.time()
	profile.schemaVersion = SCHEMA_VERSION

	if releaseLock then
		profile.lock = nil
	else
		profile.lock = {
			jobId = jobId,
			timestamp = os.time(),
		}
	end

	local abortedForeign = false
	local ok = false
	local saved: ProfileV1? = nil
	ok, saved = dsUpdate(player.UserId, function(old)
		local prev: ProfileV1? = if old then deepCopyProfile(old) else nil
		-- Re-check ownership inside UpdateAsync (post-TTL another server may own the lock)
		if prev and not ownsStoredLock(prev.lock) then
			abortedForeign = true
			return prev
		end
		return profile
	end)

	rec.saveDepth = math.max(0, rec.saveDepth - 1)
	rec.saving = rec.saveDepth > 0

	if abortedForeign then
		warn("[DataService] Save aborted — foreign session lock (will not overwrite)", player.Name)
		return false
	end

	if ok and saved then
		rec.profile = saved
		rec.dirty = false
		if releaseLock then
			rec.released = true
		end
	else
		warn("[DataService] Save failed", player.Name)
	end

	return ok
end

function DataService.ReleasePlayer(player: Player)
	local rec = sessions[player.UserId]
	if not rec then
		return
	end
	if not rec.released then
		DataService.SavePlayer(player, true)
	end
	-- Keep unreleased sessions so BindToClose orphan path can still flush
	if rec.released then
		sessions[player.UserId] = nil
	end
end

function DataService.Bootstrap()
	ensureStore()

	Players.PlayerRemoving:Connect(function(player)
		DataService.ReleasePlayer(player)
	end)

	-- Prioritize persistence on shutdown: parallel release-saves, aim to finish under ~8s
	game:BindToClose(function()
		local deadline = os.clock() + BIND_CLOSE_BUDGET
		local pending = 0
		local finished = 0

		local function kickSave(player: Player?)
			pending += 1
			task.spawn(function()
				local ok, err = pcall(function()
					if player then
						DataService.ReleasePlayer(player)
					end
				end)
				if not ok then
					warn("[DataService] BindToClose save error", err)
				end
				finished += 1
			end)
		end

		for _, player in Players:GetPlayers() do
			kickSave(player)
		end

		-- Orphan sessions (player already gone) — save/release by userId if still held
		for userId, rec in sessions do
			if rec.loaded and not rec.released then
				local plr = Players:GetPlayerByUserId(userId)
				if not plr then
					pending += 1
					task.spawn(function()
						local ok, err = pcall(function()
							if rec.saving then
								local waitUntil = os.clock() + 1.5
								while rec.saving and os.clock() < waitUntil do
									task.wait(0.05)
								end
							end
							if not rec.released then
								local profile = deepCopyProfile(rec.profile)
								profile.lock = nil
								profile.lastSeen = os.time()
								profile.sessionVersion = (profile.sessionVersion or 0) + 1
								profile.schemaVersion = SCHEMA_VERSION
								local abortedForeign = false
								local saveOk = dsUpdate(userId, function(old)
									local prev: ProfileV1? = if old then deepCopyProfile(old) else nil
									if prev and not ownsStoredLock(prev.lock) then
										abortedForeign = true
										return prev
									end
									return profile
								end)
								if abortedForeign then
									warn("[DataService] BindToClose orphan save aborted — foreign lock", userId)
								elseif saveOk then
									rec.released = true
									rec.dirty = false
								end
							end
							sessions[userId] = nil
						end)
						if not ok then
							warn("[DataService] BindToClose orphan error", userId, err)
						end
						finished += 1
					end)
				end
			end
		end

		while finished < pending and os.clock() < deadline do
			task.wait(0.1)
		end
		if finished < pending then
			warn("[DataService] BindToClose budget exhausted", finished, "/", pending, "saves finished")
		end
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for _, player in Players:GetPlayers() do
				local rec = sessions[player.UserId]
				if rec and rec.dirty and not rec.released then
					task.spawn(function()
						DataService.SavePlayer(player, false)
					end)
				end
			end
		end
	end)

	print("[DataService] Bootstrap OK — store=", STORE_NAME, "mock=", useMock, "jobId=", jobId)
end

return DataService
