--!strict
-- ProfileStore-backed persistence (optional backend for DataService).
-- Session: StartSessionAsync on join → mutate Profile.Data in memory → EndSession on leave.
-- Autosave ~300s (ProfileStore AUTO_SAVE_PERIOD) + EndSession flush.
-- Studio: uses ProfileStore.Mock when available / when live DataStore is not Access.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local STORE_NAME = "CloutRanch_ProfileStore_v1"
local SCHEMA_VERSION = 1

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
	pets: { [string]: string },
	maxSlots: number?,
	rebirths: number,
	aura: number,
	daily: DailyPersist,
	luckBoosts: { LuckBoostPersist },
	battlePass: BattlePassPersist?,
	gamePasses: { [string]: boolean }?,
	lastSeen: number?,
}

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

local function starterCash(): number
	local cfgFolder = ReplicatedStorage:FindFirstChild("Config")
	local mod = cfgFolder and cfgFolder:FindFirstChild("EconomyConfig")
	if mod and mod:IsA("ModuleScript") then
		local ok, cfg = pcall(require, mod)
		if ok and cfg and typeof(cfg.StarterCash) == "number" then
			return cfg.StarterCash
		end
	end
	return 50
end

local function defaultProfile(): ProfileV1
	local cash = starterCash()
	return {
		schemaVersion = SCHEMA_VERSION,
		sessionVersion = 0,
		cash = cash,
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
	}
end

local ProfileStoreModule: any = nil
do
	local packages = ReplicatedStorage:FindFirstChild("Packages")
	local mod = packages and packages:FindFirstChild("ProfileStore")
	if mod and mod:IsA("ModuleScript") then
		local ok, result = pcall(require, mod)
		if ok then
			ProfileStoreModule = result
		else
			warn("[DataServiceProfile] ProfileStore require failed", result)
		end
	end
end

if not ProfileStoreModule then
	error("[DataServiceProfile] Packages.ProfileStore missing — use legacy DataService")
end

local playerStore = ProfileStoreModule.New(STORE_NAME, defaultProfile())

local function resolveStore(): any
	-- Studio Mock when DataStore has no access (ProfileStore.Mock). Live path WaitForStoreReady otherwise.
	if RunService:IsStudio() and playerStore.Mock then
		local state = ProfileStoreModule.DataStoreState
		if state == "NoAccess" or state == "NoInternet" then
			return playerStore.Mock
		end
	end
	return playerStore
end

type SessionRecord = {
	profile: any, -- ProfileStore Profile
	loaded: boolean,
	released: boolean,
}

local sessions: { [number]: SessionRecord } = {}

local DataServiceProfile = {}

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

--- Snapshot live services into Profile.Data (in-memory; ProfileStore autosaves / EndSession flushes).
function DataServiceProfile.Capture(player: Player): ProfileV1?
	local rec = sessions[player.UserId]
	if not rec or not rec.profile or not rec.loaded then
		return nil
	end
	local p = rec.profile.Data :: ProfileV1

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
	if Ranch then
		local ranch = Ranch.GetByUser(player.UserId)
		if not ranch and Ranch.AssignPlot then
			ranch = Ranch.AssignPlot(player)
		end
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
	if Daily and Daily.ApplyState and profile.daily then
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

	local folder = player:FindFirstChild("CloutStats")
	if folder then
		local streak = folder:FindFirstChild("DailyStreak")
		if not streak then
			streak = Instance.new("NumberValue")
			streak.Name = "DailyStreak"
			streak.Parent = folder
		end
		if streak:IsA("NumberValue") and profile.daily then
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

function DataServiceProfile.MarkDirty(player: Player)
	-- Keep Profile.Data hot so ProfileStore autosave (~300s) persists progress.
	local rec = sessions[player.UserId]
	if rec and rec.loaded and not rec.released and rec.profile and rec.profile:IsActive() then
		pcall(DataServiceProfile.Capture, player)
	end
end

function DataServiceProfile.IsLoaded(player: Player): boolean
	local rec = sessions[player.UserId]
	return rec ~= nil and rec.loaded == true
end

function DataServiceProfile.GetProfile(player: Player): ProfileV1?
	local rec = sessions[player.UserId]
	if not rec or not rec.profile then
		return nil
	end
	return rec.profile.Data :: ProfileV1
end

function DataServiceProfile.LoadPlayer(player: Player): boolean
	if sessions[player.UserId] and sessions[player.UserId].loaded then
		return true
	end

	local store = resolveStore()
	local key = "u_" .. tostring(player.UserId)
	local profile = store:StartSessionAsync(key, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		warn("[DataServiceProfile] StartSessionAsync failed for", player.Name)
		player:Kick("Data is loading on another server. Please rejoin in a moment.")
		return false
	end

	if profile.AddUserId then
		profile:AddUserId(player.UserId)
	end
	if profile.Reconcile then
		profile:Reconcile()
	end

	profile.OnSessionEnd:Connect(function()
		local rec = sessions[player.UserId]
		if rec then
			rec.released = true
			rec.loaded = false
			sessions[player.UserId] = nil
		end
		if player.Parent == Players then
			player:Kick("Profile session ended — please rejoin.")
		end
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return false
	end

	sessions[player.UserId] = {
		profile = profile,
		loaded = true,
		released = false,
	}

	local data = profile.Data :: ProfileV1
	local applyOk, applyErr = pcall(applyToServices, player, data)
	if not applyOk then
		warn("[DataServiceProfile] Apply failed", player.Name, applyErr)
	end

	return true
end

function DataServiceProfile.SavePlayer(player: Player, _releaseLock: boolean?): boolean
	local rec = sessions[player.UserId]
	if not rec or not rec.loaded or not rec.profile then
		return false
	end
	if rec.released then
		return true
	end
	pcall(DataServiceProfile.Capture, player)
	-- Prefer ProfileStore autosave; no forced mid-session write API required.
	return true
end

function DataServiceProfile.ReleasePlayer(player: Player)
	local rec = sessions[player.UserId]
	if not rec or not rec.profile then
		return
	end
	if not rec.released then
		pcall(DataServiceProfile.Capture, player)
		local data = rec.profile.Data :: ProfileV1
		data.sessionVersion = (data.sessionVersion or 0) + 1
		data.lastSeen = os.time()
		pcall(function()
			rec.profile:EndSession()
		end)
		rec.released = true
	end
	sessions[player.UserId] = nil
end

function DataServiceProfile.Bootstrap()
	Players.PlayerRemoving:Connect(function(player)
		DataServiceProfile.ReleasePlayer(player)
	end)

	-- ProfileStore registers its own BindToClose; we still Capture before leave.
	-- Extra BindToClose Capture so shutdown flushes latest Economy/Ranch into Profile.Data.
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			local rec = sessions[player.UserId]
			if rec and rec.loaded and not rec.released then
				pcall(DataServiceProfile.Capture, player)
				pcall(function()
					rec.profile:EndSession()
				end)
				rec.released = true
			end
		end
	end)

	local usingMock = RunService:IsStudio() and ProfileStoreModule.DataStoreState ~= "Access"
	print(
		"[DataServiceProfile] Bootstrap OK — store=",
		STORE_NAME,
		"mockPreferred=",
		usingMock,
		"autosave~300s"
	)
end

DataServiceProfile.Backend = "ProfileStore"
DataServiceProfile.StoreName = STORE_NAME

return DataServiceProfile
