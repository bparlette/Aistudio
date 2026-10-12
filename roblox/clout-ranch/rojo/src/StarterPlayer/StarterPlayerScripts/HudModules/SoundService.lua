--!strict
-- Thin Juice SFX helper — PRIMARY listener is SoundHooks.client.lua (auto LocalScript).
-- ClientHud must NOT call Start() or Juice events double-fire (double Med SFX from RanchPlay).
-- Keep Play/Handle for optional one-shot calls from HUD code; Start is intentionally a no-op.

local SoundServiceEngine = game:GetService("SoundService")

local SoundService = {}

-- Primaries aligned to SoundHooks.client.lua BUSES (for optional Play() only)
local PLACEHOLDERS: { [string]: string } = {
	steal_trail = "rbxassetid://9120708094",
	hatch_burst = "rbxassetid://9116384757",
	hatch_drip = "rbxassetid://7112275565",
	rebirth_flash = "rbxassetid://9125402735",
	aura_beams = "rbxassetid://9114323612",
	flex_shock = "rbxassetid://9117241719",
	slap = "rbxassetid://9120907213",
	deposit = "rbxassetid://9120907213",
	place = "rbxassetid://9120907213",
	place_burst = "rbxassetid://9120907213",
	buy = "rbxassetid://7112275565",
	mythic = "rbxassetid://9114323612",
	lock = "rbxassetid://9114881879",
	pop = "rbxassetid://7112275565",
	shake = "rbxassetid://9120708094",
	clip = "rbxassetid://9116384757",
}

local VOL: { [string]: number } = {
	steal_trail = 0.45,
	hatch_burst = 0.5,
	hatch_drip = 0.45,
	rebirth_flash = 0.55,
	aura_beams = 0.5,
	flex_shock = 0.5,
	slap = 0.5,
	deposit = 0.4,
	buy = 0.35,
	mythic = 0.7,
	lock = 0.4,
	pop = 0.35,
	shake = 0.4,
	clip = 0.45,
}

local warned: { [string]: boolean } = {}

local function ensureGroup(): Instance
	local existing = SoundServiceEngine:FindFirstChild("CloutRanchSounds")
	if existing then
		return existing
	end
	local f = Instance.new("Folder")
	f.Name = "CloutRanchSounds"
	f.Parent = SoundServiceEngine
	return f
end

local function playId(kind: string, soundId: string, volume: number, pitch: number?)
	if soundId == "" or soundId == "rbxassetid://0" then
		if not warned[kind] then
			warned[kind] = true
		end
		return
	end
	local parent = ensureGroup()
	local s = Instance.new("Sound")
	s.Name = "Juice_" .. kind
	s.SoundId = soundId
	s.Volume = volume
	s.PlaybackSpeed = pitch or 1
	s.Parent = parent
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
	end)
	task.delay(6, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

local function pitchForRarity(rarity: string?): number
	if rarity == "Mythic" or rarity == "Secret" then
		return 1.15
	elseif rarity == "Legendary" then
		return 1.1
	elseif rarity == "Epic" then
		return 1.05
	elseif rarity == "Rare" then
		return 1.0
	elseif rarity == "Uncommon" then
		return 0.95
	end
	return 0.9
end

function SoundService.Play(kind: string, meta: { [string]: any }?)
	local id = PLACEHOLDERS[kind]
	local playKind = kind
	if not id then
		if kind == "steal" then
			id = PLACEHOLDERS.steal_trail
			playKind = "steal_trail"
		elseif kind == "rebirth" then
			id = PLACEHOLDERS.rebirth_flash
			playKind = "rebirth_flash"
		elseif kind == "flex" then
			id = PLACEHOLDERS.flex_shock
			playKind = "flex_shock"
		elseif kind == "mythic_entrance" then
			id = PLACEHOLDERS.mythic
			playKind = "mythic"
		else
			return
		end
	end
	local vol = VOL[playKind] or 0.4
	local pitch = 1
	if meta and typeof(meta.rarity) == "string" then
		pitch = pitchForRarity(meta.rarity)
		if meta.rarity == "Common" and (playKind == "hatch_burst" or playKind == "hatch_drip") then
			vol = 0.28
		end
	end
	playId(playKind, id, vol, pitch)
end

function SoundService.Handle(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	local kind = payload.kind
	if typeof(kind) ~= "string" then
		return
	end
	SoundService.Play(kind, payload)
end

--- Disabled: SoundHooks.client.lua already listens to Remotes.Juice (+ Feedback).
--- Calling this would double-SFX every RanchPlay juice event.
function SoundService.Start(_parentMaid: any?)
	-- no-op — primary path is HudModules/SoundHooks.client.lua
	print("[CloutRanch] SoundService.Start skipped (SoundHooks.client.lua is primary)")
end

return SoundService
