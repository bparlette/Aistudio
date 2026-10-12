--!strict
-- Timed soft offers — CloutSell funnel (Starter @ ~6 min after dopamine)
-- When Marketplace IDs are 0: SoftOffer UI shows kid-safe "Coming soon" (no Prompt*).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Monetization = require(script.Parent:WaitForChild("Monetization"))

local STARTER_AFTER = 6 * 60
local VIP_AFTER = 8 * 60

local sessionStart: { [number]: number } = {}
local starterOffered: { [number]: boolean } = {}
local vipOffered: { [number]: boolean } = {}
local dopamine: { [number]: boolean } = {} -- steal deposit or aura podium or rare buy

local OfferService = {}

local function feedbackRemote(): RemoteEvent?
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local ev = remotes and remotes:FindFirstChild("Feedback")
	if ev and ev:IsA("RemoteEvent") then
		return ev
	end
	return nil
end

local function softOfferRemote(): RemoteEvent?
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local ev = remotes and remotes:FindFirstChild("SoftOffer")
	if ev and ev:IsA("RemoteEvent") then
		return ev
	end
	return nil
end

local function toast(player: Player, message: string, tone: string)
	local ev = feedbackRemote()
	if ev then
		ev:FireClient(player, { message = message, tone = tone })
	end
end

--- Fire SoftOffer once to Remotes.SoftOffer (sole client owner = SoftOffer.lua; SoftFunnel disabled).
--- live=false → Coming soon (Prompt path disabled). Never dual-fire.
local function fireSoftOffer(player: Player, payload: { [string]: any })
	local key = payload.sku
	local live = false
	if typeof(key) == "string" then
		live = Monetization.IsSkuLive(key)
	end
	payload.live = live
	payload.comingSoon = not live
	-- Never send Marketplace IDs to client (zeros or otherwise) — server Prompt* only.
	local ev = softOfferRemote()
	if ev then
		ev:FireClient(player, payload)
	end
end

function OfferService.InitPlayer(player: Player)
	sessionStart[player.UserId] = os.clock()
	starterOffered[player.UserId] = false
	vipOffered[player.UserId] = false
	dopamine[player.UserId] = false
end

function OfferService.MarkDopamine(player: Player, kind: string?)
	dopamine[player.UserId] = true
	-- kind "steal" → prefer copy B on next starter offer
	if kind == "steal" then
		dopamine[player.UserId] = true
		-- reuse starterOffered false path; store preference on player attribute
		player:SetAttribute("OfferStarterVariant", "B")
	end
end

function OfferService.Tick()
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local uid = player.UserId
		local start = sessionStart[uid]
		if not start then
			continue
		end
		local elapsed = now - start
		if not starterOffered[uid] and dopamine[uid] and elapsed >= STARTER_AFTER then
			starterOffered[uid] = true
			local variant = player:GetAttribute("OfferStarterVariant")
			local tag = "One pack. Instant vibes. Cash + pet + aura."
			local toastMsg = tag
			if variant == "B" then
				tag = "You hit. Cash + pet + aura — keep the streak."
				toastMsg = tag
			end
			toast(player, toastMsg, "buy")
			fireSoftOffer(player, {
				sku = "Starter",
				kind = "product",
				title = "Starter Pack",
				tag = tag,
				bullets = { "Cash to keep flexing", "Pet that shows off", "Aura for the look" },
				cta = "Get Starter",
				dismiss = "Maybe later",
				priceHint = 175,
			})
		elseif not vipOffered[uid] and starterOffered[uid] and elapsed >= VIP_AFTER then
			vipOffered[uid] = true
			-- VIP = longer lock time + badge ONLY (never idle mult / never wins)
			local tag = "Longer locks + VIP badge. Flex more. Never buys wins."
			toast(player, tag, "clout")
			fireSoftOffer(player, {
				sku = "VIP",
				kind = "pass",
				title = "VIP Pass",
				tag = tag,
				bullets = { "VIP badge flex", "Longer lock timer", "Never buys wins" },
				cta = "Get VIP",
				dismiss = "Maybe later",
				priceHint = 799,
			})
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	sessionStart[player.UserId] = nil
	starterOffered[player.UserId] = nil
	vipOffered[player.UserId] = nil
	dopamine[player.UserId] = nil
end)

return OfferService
