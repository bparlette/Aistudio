--!strict
-- Server ModuleScript: wire GamePass / DevProduct IDs after you create them in Creator Dashboard
-- Replace PLACEHOLDER ids before going live.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local RanchService = require(script.Parent:WaitForChild("RanchService"))

-- TODO: paste real IDs from Creator Dashboard
local PASS = {
	DoubleCash = 0, -- GamePass
	VIP = 0, -- GamePass
}

local PRODUCT = {
	CashPackSmall = 0, -- DevProduct
}

local owned: { [number]: { [string]: boolean } } = {}

local Monetization = {}

local function flag(player: Player, key: string)
	owned[player.UserId] = owned[player.UserId] or {}
	owned[player.UserId][key] = true
end

function Monetization.Has(player: Player, key: string): boolean
	return owned[player.UserId] ~= nil and owned[player.UserId][key] == true
end

function Monetization.ApplyOwned(player: Player)
	local mult = 1
	if Monetization.Has(player, "DoubleCash") then
		mult += 1
	end
	if Monetization.Has(player, "VIP") then
		mult += 0.5
	end
	-- rebirth mult is set by RebirthService; compose carefully in a later pass
	if mult > 1 then
		EconomyService.SetIncomeMult(player, mult)
	end
end

function Monetization.IsVIP(player: Player): boolean
	return Monetization.Has(player, "VIP")
end

local function refreshPasses(player: Player)
	if PASS.DoubleCash ~= 0 then
		local ok, has = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, PASS.DoubleCash)
		end)
		if ok and has then
			flag(player, "DoubleCash")
		end
	end
	if PASS.VIP ~= 0 then
		local ok, has = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, PASS.VIP)
		end)
		if ok and has then
			flag(player, "VIP")
		end
	end
	Monetization.ApplyOwned(player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if not wasPurchased then
		return
	end
	if passId == PASS.DoubleCash then
		flag(player, "DoubleCash")
	elseif passId == PASS.VIP then
		flag(player, "VIP")
	end
	Monetization.ApplyOwned(player)
	if Monetization.IsVIP(player) then
		RanchService.Lock(player, true)
	end
end)

MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if receipt.ProductId == PRODUCT.CashPackSmall then
		EconomyService.AddCash(player, 500)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

Players.PlayerAdded:Connect(refreshPasses)

return Monetization
