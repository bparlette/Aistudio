--!strict
-- Server ModuleScript: Feedback + Remotes.Juice VFX/SFX cues for clients
-- Payload shape: { kind = string, message = string?, ... }

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JuiceService = {}

local function getJuiceRemote(): RemoteEvent?
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		return nil
	end
	local ev = remotes:FindFirstChild("Juice")
	if ev and ev:IsA("RemoteEvent") then
		return ev
	end
	return nil
end

local function getFeedback(): any?
	local mod = script.Parent:FindFirstChild("FeedbackService")
	if not mod then
		return nil
	end
	local ok, fb = pcall(require, mod)
	return if ok then fb else nil
end

local function toast(player: Player, message: string, tone: string)
	local fb = getFeedback()
	if not fb then
		return
	end
	if fb.Notify then
		fb.Notify(player, tone, message)
	elseif fb.Tell then
		fb.Tell(player, message, tone)
	end
end

function JuiceService.Play(player: Player, kind: string, meta: { [string]: any }?)
	local ev = getJuiceRemote()
	if not ev then
		return
	end
	local payload = meta and table.clone(meta) or {}
	payload.kind = kind
	ev:FireClient(player, payload)
end

function JuiceService.Fire(player: Player, kind: string, meta: { [string]: any }?)
	JuiceService.Play(player, kind, meta)
end

function JuiceService.Broadcast(kind: string, meta: { [string]: any }?)
	local ev = getJuiceRemote()
	if not ev then
		return
	end
	local payload = meta and table.clone(meta) or {}
	payload.kind = kind
	for _, player in Players:GetPlayers() do
		ev:FireClient(player, payload)
	end
end

function JuiceService.Steal(player: Player, petName: string?)
	local name = petName or "a pet"
	toast(player, "Yoinked " .. name .. " — run!", "steal")
	-- subjectUserId lets client StealCreamFlash attach trail/highlight (DemoRival + PvP)
	JuiceService.Play(player, "steal", {
		message = name,
		petName = name,
		subjectUserId = player.UserId,
	})
end

function JuiceService.Deposit(player: Player)
	toast(player, "Pet secured on your ranch!", "steal")
	-- JUICE-2 STING FIX: ONE pad-pop sting (`place`). Do not also fire deposit/place_burst
	-- (was lock+buy double same frame). VFX PlaceBurst listens to kind place|place_burst.
	JuiceService.Play(player, "place", {
		message = "Pet placed!",
		subjectUserId = player.UserId,
	})
end

function JuiceService.Buy(player: Player, petName: string?)
	local msg = if petName then ("Bought " .. petName) else "Carpet purchase!"
	toast(player, msg, "buy")
	JuiceService.Play(player, "buy", { message = msg, petName = petName })
end

function JuiceService.Rebirth(player: Player, level: number?)
	local msg = if typeof(level) == "number" then ("Rebirth ×" .. tostring(level)) else "Rebirth!"
	toast(player, msg, "rebirth")
	JuiceService.Play(player, "rebirth", { message = msg, level = level })
end

function JuiceService.Daily(player: Player, msg: string?)
	local text = msg or "Daily reward claimed!"
	toast(player, text, "daily")
	JuiceService.Play(player, "daily", { message = text })
end

function JuiceService.Lock(player: Player, vip: boolean?)
	local text = if vip then "LOCKED — VIP timer" else "🔒 Ranch locked!"
	toast(player, text, "info")
	JuiceService.Play(player, "lock", { message = text, vip = vip == true })
end

--- Creator clip cue (Secret steal / Aura podium) — Feedback tone + Juice kind "clip"
function JuiceService.Clip(player: Player, message: string?, meta: { [string]: any }?)
	local text = message or "CLIP MOMENT"
	toast(player, text, "clip")
	local payload = meta and table.clone(meta) or {}
	payload.message = text
	JuiceService.Play(player, "clip", payload)
end



--- Carpet hatch / buy drip — maps to client Vfx hatch_burst / hatch_drip
function JuiceService.Hatch(player: Player, rarity: string?, petId: string?)
	local r = rarity or "Common"
	local kind = if r == "Common" then "hatch_drip" else "hatch_burst"
	local msg = if petId then ("Hatched " .. tostring(petId)) else ("Hatch — " .. r)
	if r == "Secret" or r == "Mythic" then
		toast(player, msg, "mythic")
		JuiceService.Play(player, "mythic", { message = msg, rarity = r, petId = petId })
		local fomoMod = script.Parent:FindFirstChild("FomoBroadcastService")
		if fomoMod then
			pcall(function()
				local Fomo = require(fomoMod)
				if Fomo and Fomo.OnMythicHatch then
					Fomo.OnMythicHatch(player, if petId then tostring(petId) else r)
				end
			end)
		end
	elseif r == "Rare" or r == "Epic" or r == "Legendary" then
		-- Align Legendary toast/tone with rare path (SoundHooks already plays rare bus)
		toast(player, msg, "rare")
		JuiceService.Play(player, kind, { message = msg, rarity = r, petId = petId })
	else
		toast(player, msg, "buy")
		JuiceService.Play(player, kind, { message = msg, rarity = r, petId = petId })
	end
	-- Always fire a place_burst so ranch pad pop is obvious post-buy
	JuiceService.Play(player, "place_burst", { message = "Pet placed!", rarity = r, petId = petId })
end

--- Rival / player Aura vote confirm — FOV/shake only (no economy)
function JuiceService.VotePunch(player: Player, targetUserId: number?, isRival: boolean?)
	local rival = isRival == true
	local msg = if rival then "Voted Rival Dummy!" else "Vote locked in!"
	toast(player, msg, "aura")
	JuiceService.Play(player, "vote_punch", {
		message = msg,
		subjectUserId = player.UserId,
		targetUserId = targetUserId,
		rival = rival,
	})
end

--- Aura flex start — broadcast flex_shock (client VfxService / SoundHooks alias flex)
function JuiceService.FlexShock(_meta: any?)
	JuiceService.Broadcast("flex_shock", if typeof(_meta) == "table" then _meta else {})
end

--- Aura podium beams — broadcast aura_beams with optional winners list
function JuiceService.AuraBeams(winners: any?)
	local meta: { [string]: any } = {}
	if typeof(winners) == "table" then
		meta.winners = winners
	end
	JuiceService.Broadcast("aura_beams", meta)
end

--- Compat aliases (Feedback toast + Juice remote)
function JuiceService.Pop(player: Player, kind: string, message: string?, tone: string?)
	if message then
		toast(player, message, tone or kind)
	end
	JuiceService.Play(player, kind, { message = message })
end

function JuiceService.Shake(player: Player, kind: string)
	JuiceService.Play(player, kind, {})
end

return JuiceService
