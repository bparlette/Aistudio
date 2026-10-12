--!strict
-- Cross-server FOMO banners via MessagingService (kid-safe; no platform brands).
-- Triggers: Secret steal success, Mythic/Secret hatch, Aura podium #1.

local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local RunService = game:GetService("RunService")

local TOPIC = "CloutRanchFomo"
local RATE_LIMIT_SEC = 8 -- per-server publish cooldown between FOMO events
local LOCAL_ECHO = true -- also show on publishing server (subscribe may not echo)

export type FomoPayload = {
	kind: string, -- "secret_steal" | "mythic_hatch" | "aura_podium"
	displayName: string, -- pet / moment label
	playerName: string, -- DisplayName of the star
}

local FomoBroadcastService = {}

local lastPublishAt = 0
local subscribed = false
local bootstrapped = false

local function softFeedbackBroadcast(message: string, tone: string?)
	local mod = script.Parent:FindFirstChild("FeedbackService")
	if not mod then
		return
	end
	local ok, fb = pcall(require, mod)
	if ok and fb and fb.Broadcast then
		fb.Broadcast(message, tone or "clout")
	end
end

local function softJuiceBroadcast(kind: string, meta: { [string]: any }?)
	local mod = script.Parent:FindFirstChild("JuiceService")
	if not mod then
		return
	end
	local ok, juice = pcall(require, mod)
	if ok and juice and juice.Broadcast then
		juice.Broadcast(kind, meta)
	end
end

local function bannerFor(payload: FomoPayload): (string, string)
	local who = payload.playerName or "Someone"
	local what = payload.displayName or "a flex"
	local kind = payload.kind or "clout"
	if kind == "secret_steal" then
		return who .. " yoinked Secret: " .. what .. "!", "steal"
	elseif kind == "mythic_hatch" then
		return who .. " hatched " .. what .. "!", "mythic"
	elseif kind == "aura_podium" then
		return who .. " took Aura podium #1!", "clout"
	end
	return who .. " — " .. what, "clout"
end

local function showLocal(payload: FomoPayload)
	local msg, tone = bannerFor(payload)
	softFeedbackBroadcast(msg, tone)
	softJuiceBroadcast("fomo_banner", {
		message = msg,
		kind = payload.kind,
		displayName = payload.displayName,
		playerName = payload.playerName,
	})
end

local function sanitize(payload: FomoPayload): FomoPayload?
	if typeof(payload) ~= "table" then
		return nil
	end
	local kind = payload.kind
	if kind ~= "secret_steal" and kind ~= "mythic_hatch" and kind ~= "aura_podium" then
		return nil
	end
	local displayName = tostring(payload.displayName or "something cool")
	local playerName = tostring(payload.playerName or "A rancher")
	-- kid-safe: strip URLs / brand-ish spam length
	displayName = string.sub(displayName, 1, 48)
	playerName = string.sub(playerName, 1, 32)
	return {
		kind = kind,
		displayName = displayName,
		playerName = playerName,
	}
end

function FomoBroadcastService.Publish(kind: string, displayName: string?, player: Player?)
	local payload = sanitize({
		kind = kind,
		displayName = displayName or "a flex",
		playerName = if player then player.DisplayName else "A rancher",
	})
	if not payload then
		return
	end

	local now = os.clock()
	if now - lastPublishAt < RATE_LIMIT_SEC then
		return
	end
	lastPublishAt = now

	if LOCAL_ECHO then
		showLocal(payload)
	end

	task.spawn(function()
		local ok, err = pcall(function()
			MessagingService:PublishAsync(TOPIC, payload)
		end)
		if not ok then
			-- Studio / MessagingService unavailable — local banner already shown
			if not RunService:IsStudio() then
				warn("[FomoBroadcastService] PublishAsync failed", err)
			end
		end
	end)
end

function FomoBroadcastService.OnSecretSteal(player: Player, petName: string?)
	FomoBroadcastService.Publish("secret_steal", petName or "Secret pet", player)
end

function FomoBroadcastService.OnMythicHatch(player: Player, displayName: string?)
	FomoBroadcastService.Publish("mythic_hatch", displayName or "Mythic", player)
end

function FomoBroadcastService.OnAuraPodiumFirst(player: Player)
	FomoBroadcastService.Publish("aura_podium", "Aura Flex #1", player)
end

function FomoBroadcastService.Bootstrap()
	if bootstrapped then
		return
	end
	bootstrapped = true

	if subscribed then
		return
	end
	local ok, err = pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(message)
			local data = message and message.Data
			local payload = sanitize(data :: any)
			if not payload then
				return
			end
			-- Skip duplicate if we just published the same (local echo already shown)
			if LOCAL_ECHO and (os.clock() - lastPublishAt) < 1.5 then
				-- Still show cross-server events from others; only skip near-instant self echo
				-- Heuristic: if any local player matches playerName and we just published, skip
				for _, plr in Players:GetPlayers() do
					if plr.DisplayName == payload.playerName then
						return
					end
				end
			end
			showLocal(payload)
		end)
	end)
	if ok then
		subscribed = true
		print("[FomoBroadcastService] Subscribed", TOPIC)
	else
		if RunService:IsStudio() then
			print("[FomoBroadcastService] MessagingService unavailable in Studio — local FOMO only")
		else
			warn("[FomoBroadcastService] SubscribeAsync failed", err)
		end
	end
end

return FomoBroadcastService
