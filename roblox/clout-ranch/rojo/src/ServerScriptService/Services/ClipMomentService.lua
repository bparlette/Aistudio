--!strict
-- Server ModuleScript: clip-bait moments for creators (Secret steal + Aura podium)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetCatalog"))

local ClipMomentService = {}

local feedbackService: any = nil
local juiceService: any = nil
local wired = false

local function getFeedback()
	if feedbackService then
		return feedbackService
	end
	local mod = script.Parent:FindFirstChild("FeedbackService")
	if mod then
		local ok, result = pcall(require, mod)
		if ok then
			feedbackService = result
		end
	end
	return feedbackService
end

local function getJuice()
	if juiceService then
		return juiceService
	end
	local mod = script.Parent:FindFirstChild("JuiceService")
	if mod then
		local ok, result = pcall(require, mod)
		if ok then
			juiceService = result
		end
	end
	return juiceService
end

local function fireClip(player: Player, message: string, meta: { [string]: any }?)
	local juice = getJuice()
	if juice and juice.Clip then
		juice.Clip(player, message, meta)
		return
	end
	local fb = getFeedback()
	if fb then
		if fb.Notify then
			fb.Notify(player, "clip", message)
		elseif fb.Tell then
			fb.Tell(player, message, "clip")
		end
	end
	if juice and juice.Play then
		juice.Play(player, "clip", meta or { message = message })
	elseif juice and juice.Fire then
		juice.Fire(player, "clip", meta)
	end
end

local function broadcastClip(message: string, meta: { [string]: any }?)
	local fb = getFeedback()
	if fb and fb.Broadcast then
		fb.Broadcast(message, "clip")
	else
		for _, player in Players:GetPlayers() do
			fireClip(player, message, meta)
		end
		return
	end
	local juice = getJuice()
	if juice and juice.Broadcast then
		juice.Broadcast("clip", meta or { message = message })
	end
end

--- Secret pet yanked off a ranch — perfect clip beat.
function ClipMomentService.OnSecretStolen(thief: Player, petId: string, victimUserId: number?)
	local def = PetCatalog.Get(petId)
	if not def or def.rarity ~= "Secret" then
		return
	end
	local name = def.name
	local victim = if victimUserId then Players:GetPlayerByUserId(victimUserId) else nil
	local victimName = if victim then victim.DisplayName else "a ranch"
	local msg = string.format("🎬 CLIP — %s stole Secret %s from %s!", thief.DisplayName, name, victimName)
	fireClip(thief, string.format("🎬 CLIP ME — Secret %s!", name), {
		moment = "secret_steal",
		petId = petId,
		role = "thief",
	})
	if victim then
		fireClip(victim, string.format("🎬 CLIP — your Secret %s got yoinked!", name), {
			moment = "secret_steal",
			petId = petId,
			role = "victim",
		})
	end
	-- Soft lobby ping so nearby creators look up
	for _, player in Players:GetPlayers() do
		if player ~= thief and player ~= victim then
			fireClip(player, msg, {
				moment = "secret_steal",
				petId = petId,
				role = "spectator",
			})
		end
	end
end

--- Aura Flex podium — top placements are clip bait.
function ClipMomentService.OnAuraPodium(winners: { number })
	if not winners or #winners == 0 then
		return
	end
	local names = {}
	for i, userId in winners do
		local plr = Players:GetPlayerByUserId(userId)
		if plr then
			table.insert(names, plr.DisplayName)
			local place = i
			local medal = if place == 1 then "🥇" elseif place == 2 then "🥈" else "🥉"
			fireClip(plr, string.format("%s CLIP — Aura Podium #%d!", medal, place), {
				moment = "aura_podium",
				place = place,
				role = "winner",
			})
		end
	end
	if #names > 0 then
		broadcastClip(
			string.format("🎬 CLIP — Aura Podium: %s", table.concat(names, " · ")),
			{ moment = "aura_podium", winners = winners }
		)
	end
end

function ClipMomentService.Init()
	if wired then
		return
	end
	wired = true
	-- Optional: warm requires so first clip isn't cold
	getFeedback()
	getJuice()
end

return ClipMomentService
