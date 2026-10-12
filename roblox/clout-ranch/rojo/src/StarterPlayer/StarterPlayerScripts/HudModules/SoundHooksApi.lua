--!strict
-- Shared SoundHooks API — PlayKind + remotes. Debounced; PRIMARY Juice/Feedback SFX.
-- SoundHooks.client.lua boots Start(); HUD may call PlayKind for optimistic click juice.
-- SoundService.Start is a no-op — this module is the sole Remotes.Juice SFX owner.
-- docs/AUDIO_MIX_BIBLE.md · docs/SoundHooks.md

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

export type Bus = {
	id: number,
	volume: number,
	speed: number,
	backupId: number?,
}

local BUSES: { [string]: Bus } = {
	steal = { id = 9120708094, volume = 0.70, speed = 1.05 },
	stealSparkle = { id = 9126090298, volume = 0.45, speed = 1.0 },
	lock = { id = 9114881879, volume = 0.60, speed = 1.0 },
	lockClick = { id = 140910211, volume = 0.40, speed = 1.0 },
	buy = { id = 7112275565, volume = 0.65, speed = 1.0 },
	rare = { id = 9116384757, volume = 0.78, speed = 1.0 }, -- Magic Burst
	aura = { id = 9114323612, volume = 0.82, speed = 0.98 },
	podium = { id = 9117241719, volume = 0.75, speed = 1.0 },
	rebirth = { id = 9125402735, volume = 0.85, speed = 0.95 },
	rebirthTail = { id = 9126090298, volume = 0.70, speed = 1.0 },
	daily = { id = 7128958209, volume = 0.62, speed = 1.0 },
	mythic = { id = 9114323612, volume = 0.90, speed = 0.92 },
	mythicBoom = { id = 9125402735, volume = 0.85, speed = 0.92 },
	mythicBurst = { id = 9116384757, volume = 0.78, speed = 1.0 },
	-- JUICE-2 STING FIX: slap impact (NOT lock). Backup if primary Get Audio fails.
	slap = { id = 9120907213, backupId = 9114111252, volume = 0.70, speed = 1.05 }, -- Wood Impact 2
	-- Pad-pop thud (deposit / place) — same wood impact family, quieter; NOT cash win
	place = { id = 9120907213, volume = 0.68, speed = 1.0 },
	bedRanch = { id = 9118752742, volume = 0.22, speed = 1.0 },
}

-- Juice/Feedback kind → bus alias. Hatch rarity branched in PlayKind (not buy above Common).
local ALIAS: { [string]: string } = {
	steal = "steal",
	steal_trail = "steal",
	lock = "lock",
	buy = "buy",
	rare = "rare",
	aura = "aura",
	podium = "podium",
	rebirth = "rebirth",
	rebirth_flash = "rebirth",
	daily = "daily",
	mythic = "mythic",
	mythic_entrance = "mythic",
	clip = "rare",
	success = "buy",
	clout = "rebirth",
	flex_shock = "aura",
	flex = "aura",
	aura_beams = "podium",
	-- JUICE-2: slap → slap bus (was lock). deposit/place → place pad-pop (was lock/buy).
	slap = "slap",
	place = "place",
	place_burst = "place",
	deposit = "place",
	pop = "buy",
	vote_punch = "aura",
	-- hatch_burst / hatch_drip intentionally NOT aliased — rarity branch in PlayKind
}

-- Debounce moment keys (AUDIO_MIX_BIBLE). slap+place share impact family.
local MOMENT_CD: { [string]: number } = {
	steal = 0.15,
	lock = 0.15,
	buy = 0.15,
	impact = 0.15, -- slap / place / deposit pad-pop
	rare = 0.35,
	aura = 0.35, -- AuraFlex
	podium = 0.35,
	daily = 0.35,
	rebirth = 0.80,
	mythic = 0.80,
}

-- Alias/bus key → debounce moment
local TO_MOMENT: { [string]: string } = {
	steal = "steal",
	lock = "lock",
	buy = "buy",
	slap = "impact",
	place = "impact",
	rare = "rare",
	aura = "aura",
	podium = "podium",
	daily = "daily",
	rebirth = "rebirth",
	mythic = "mythic",
}

local BIG_JUICE: { [string]: boolean } = {
	mythic = true,
	rebirth = true,
	aura = true, -- AuraFlex
}

local lastPlayed: { [string]: number } = {}
local activeByMoment: { [string]: { Sound } } = {}
local bedSound: Sound? = nil
local bedBaseVol = 0.22
local started = false

local SoundHooksApi = {}

local function makeSound(bus: Bus): Sound
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(bus.id)
	s.Volume = bus.volume
	s.PlaybackSpeed = bus.speed
	s.Parent = SoundService
	return s
end

local function stopMoment(moment: string)
	local list = activeByMoment[moment]
	if not list then
		return
	end
	for _, s in list do
		if s.Parent then
			pcall(function()
				s:Stop()
			end)
			s:Destroy()
		end
	end
	activeByMoment[moment] = nil
end

--- BigJuice mutex: Mythic / Rebirth / AuraFlex — starting one stops the others
local function stopOtherBigJuice(keepMoment: string)
	for moment in pairs(BIG_JUICE) do
		if moment ~= keepMoment then
			stopMoment(moment)
		end
	end
end

local function trackSound(moment: string, s: Sound)
	local list = activeByMoment[moment]
	if not list then
		list = {}
		activeByMoment[moment] = list
	end
	table.insert(list, s)
	s.Ended:Once(function()
		if s.Parent then
			s:Destroy()
		end
		local cur = activeByMoment[moment]
		if cur then
			for i = #cur, 1, -1 do
				if cur[i] == s or not cur[i].Parent then
					table.remove(cur, i)
				end
			end
			if #cur == 0 then
				activeByMoment[moment] = nil
			end
		end
	end)
	task.delay(5, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

local function playBus(moment: string, busKey: string)
	local bus = BUSES[busKey]
	if not bus or bus.id == 0 then
		return
	end
	local s = makeSound(bus)
	s:Play()
	trackSound(moment, s)
	-- backupId: swap if primary fails to load (Get Audio / Toolbox). Used by slap.
	local backupId = bus.backupId
	if backupId and backupId ~= 0 then
		task.delay(0.15, function()
			if not s.Parent then
				return
			end
			if s.IsLoaded and s.TimeLength > 0 then
				return
			end
			pcall(function()
				s:Stop()
			end)
			s.SoundId = "rbxassetid://" .. tostring(backupId)
			s:Play()
		end)
	end
end

local function duckBed(seconds: number)
	if not bedSound then
		return
	end
	local target = bedBaseVol * 0.45
	TweenService:Create(bedSound, TweenInfo.new(0.08), { Volume = target }):Play()
	task.delay(seconds, function()
		if bedSound then
			TweenService:Create(bedSound, TweenInfo.new(0.25), { Volume = bedBaseVol }):Play()
		end
	end)
end

local function tryDebounce(moment: string): boolean
	local cd = MOMENT_CD[moment] or 0.15
	local now = os.clock()
	local last = lastPlayed[moment] or 0
	if now - last < cd then
		return false
	end
	lastPlayed[moment] = now
	stopMoment(moment)
	if BIG_JUICE[moment] then
		stopOtherBigJuice(moment)
	end
	return true
end

local function playRareDrop(moment: string)
	duckBed(0.30)
	playBus(moment, "rare")
	-- Optional sparkle layer @ +40ms (same id as stealSparkle)
	task.delay(0.04, function()
		playBus(moment, "stealSparkle")
	end)
end

local function playMomentStack(moment: string, alias: string)
	if moment == "steal" then
		playBus(moment, "steal")
		task.delay(0.04, function()
			playBus(moment, "stealSparkle")
		end)
	elseif moment == "lock" then
		playBus(moment, "lock")
		playBus(moment, "lockClick")
	elseif moment == "rebirth" then
		duckBed(0.35)
		playBus(moment, "rebirth")
		task.delay(0.12, function()
			playBus(moment, "rebirthTail")
		end)
	elseif moment == "mythic" then
		duckBed(0.40)
		playBus(moment, "mythic")
		task.delay(0.08, function()
			playBus(moment, "mythicBoom")
		end)
		task.delay(0.16, function()
			playBus(moment, "mythicBurst")
		end)
	elseif moment == "rare" then
		playRareDrop(moment)
	elseif moment == "aura" then
		duckBed(0.30)
		playBus(moment, "aura")
	elseif moment == "podium" then
		playBus(moment, "podium")
	elseif moment == "daily" then
		playBus(moment, "daily")
	elseif moment == "buy" then
		playBus(moment, "buy")
	elseif moment == "impact" then
		-- slap vs place pad-pop (shared debounce family)
		playBus(moment, alias)
	else
		playBus(moment, alias)
	end
end

--- Resolve hatch_* kinds by payload.rarity before Play. Never buy alias above Common.
local function resolveHatchKind(kind: string, meta: { [string]: any }?): string
	if kind ~= "hatch_burst" and kind ~= "hatch_drip" then
		return kind
	end
	local rarity = "Common"
	if meta and typeof(meta.rarity) == "string" and meta.rarity ~= "" then
		rarity = meta.rarity
	end
	if rarity == "Mythic" or rarity == "Secret" then
		return "mythic" -- leave mythic stack (server usually fires mythic already)
	elseif rarity == "Rare" or rarity == "Epic" or rarity == "Legendary" then
		return "rare"
	else
		-- Common (and Uncommon / nil) → buy bus
		return "buy"
	end
end

function SoundHooksApi.PlayKind(kind: string, meta: { [string]: any }?)
	local resolved = resolveHatchKind(kind, meta)
	local alias = ALIAS[resolved] or resolved
	-- hatch resolved to rare/buy/mythic already; ALIAS may still map
	if resolved == "rare" and (kind == "hatch_burst" or kind == "hatch_drip") then
		alias = "rare"
	elseif resolved == "buy" and (kind == "hatch_burst" or kind == "hatch_drip") then
		alias = "buy"
	elseif resolved == "mythic" and (kind == "hatch_burst" or kind == "hatch_drip") then
		alias = "mythic"
	end

	local moment = TO_MOMENT[alias] or TO_MOMENT[resolved] or TO_MOMENT[kind]
	if not moment then
		if BUSES[alias] then
			moment = "buy"
		else
			return
		end
	end

	if not tryDebounce(moment) then
		return
	end

	playMomentStack(moment, alias)
end

-- Alias for callers that prefer playKind casing
SoundHooksApi.playKind = SoundHooksApi.PlayKind

local function startBed()
	local bus = BUSES.bedRanch
	if bedSound then
		bedSound:Destroy()
	end
	bedSound = makeSound(bus)
	assert(bedSound, "bedSound missing after makeSound")
	bedSound.Looped = true
	bedBaseVol = bus.volume
	bedSound.Volume = bedBaseVol
	bedSound:Play()
end

--- Juice-owned moments: Feedback listener must NOT also sting these (dual-path anti-double).
--- Soft UI tones (buy/lock/success/pop/info/warn/error) may still play via Feedback.
local JUICE_OWNED_TONES: { [string]: boolean } = {
	steal = true,
	steal_trail = true,
	rare = true,
	mythic = true,
	mythic_entrance = true,
	rebirth = true,
	rebirth_flash = true,
	aura = true,
	flex = true,
	flex_shock = true,
	vote_punch = true,
	podium = true,
	aura_beams = true,
	clip = true,
	daily = true,
	slap = true,
	place = true,
	place_burst = true,
	deposit = true,
	clout = true,
	hatch_drip = true,
	hatch_burst = true,
}

--- Soft Feedback allowlist (dry UI). Everything else juice-owned or no-bus → skip SFX.
local FEEDBACK_SOFT_TONES: { [string]: boolean } = {
	buy = true,
	lock = true,
	success = true,
	pop = true,
	info = true,
	warn = true,
	error = true,
}

--- Wire Juice + Feedback remotes once (LocalScript boot). Idempotent.
function SoundHooksApi.Start()
	if started then
		return
	end
	started = true

	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
		if not remotes then
			return
		end
		startBed()

		local juice = remotes:FindFirstChild("Juice") or remotes:WaitForChild("Juice", 5)
		if juice and juice:IsA("RemoteEvent") then
			juice.OnClientEvent:Connect(function(payload: any)
				if typeof(payload) == "table" and typeof(payload.kind) == "string" then
					-- Pass full payload so hatch rarity can branch before Play
					SoundHooksApi.PlayKind(payload.kind, payload)
				elseif typeof(payload) == "string" then
					SoundHooksApi.PlayKind(payload)
				end
			end)
		end

		local fb = remotes:FindFirstChild("Feedback")
		if fb and fb:IsA("RemoteEvent") then
			fb.OnClientEvent:Connect(function(a: any, b: any)
				local tone: string? = nil
				if typeof(a) == "table" then
					tone = a.tone or a.kind
				elseif typeof(a) == "string" and typeof(b) == "string" then
					tone = b
				elseif typeof(a) == "string" then
					tone = a
				end
				if typeof(tone) ~= "string" then
					return
				end
				-- Soften dual-path: Juice owns juice moments; Feedback only soft UI tones.
				-- Toast visuals still render via FeedbackToast; this gate is SFX-only.
				if JUICE_OWNED_TONES[tone] then
					return
				end
				if not FEEDBACK_SOFT_TONES[tone] then
					return
				end
				-- Soft UI (buy/lock/…) — error/warn have no bus → PlayKind no-ops
				SoundHooksApi.PlayKind(tone)
			end)
		end

		print("[CloutRanch] SoundHooks online (primary Juice SFX; debounce + BigJuice mutex)")
	end)
end

return SoundHooksApi
