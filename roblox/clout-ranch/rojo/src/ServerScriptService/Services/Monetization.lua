--!strict
-- Clout Ranch monetization — SKU catalog from docs/monetization-sku-table.md
-- Paste real Creator Dashboard IDs into PASS / PRODUCT before publish.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local RanchService = require(script.Parent:WaitForChild("RanchService"))

-- Gamepasses (permanent) — prices are design targets in Robux
local PASS = {
	VIP = 0, -- GP-VIP 799: lock 120s + badge ONLY (no income power — CloutDev gate)
	DoubleCash = 0, -- GP-X2Cash 449: ×2 ranch idle only
	AutoCollect = 0, -- GP-AutoCollect 249
	ExtraPet = 0, -- GP-ExtraPet 349: 4th slot @ 75% power
	FastTravel = 0, -- GP-FastTravel 149
	FlexQueue = 0, -- GP-FlexPriority 199
}

-- Dev products (consumable)
local PRODUCT = {
	Starter = 0, -- DP-Starter 175 one-time
	Comeback = 0, -- DP-Comeback 99
	CashS = 0, -- 49 → 150k
	CashM = 0, -- 149 → 900k
	CashL = 0, -- 399 → 5M
	CashXL = 0, -- 999 → 25M (max 3/day)
	Egg1 = 0, -- 99
	Egg3 = 0, -- 249
	LockRefill = 0, -- 79
	SkipCD = 0, -- 49
	FlexTicket = 0, -- 39
	Reroll = 0, -- 59
	BattlePass = 0, -- BP-Premium 799
	BattlePassPlus = 0, -- 1199
	WeeklyAura = 0, -- LM-Aura-Week 349
	WeeklyPetSkin = 0, -- 299
}

local CASH_GRANTS = {
	CashS = 150_000,
	CashM = 900_000,
	CashL = 5_000_000,
	CashXL = 25_000_000,
	Starter = 500_000,
	Comeback = 500_000,
}

local owned: { [number]: { [string]: boolean } } = {}
local xlToday: { [number]: { day: number, count: number } } = {}
local starterBought: { [number]: boolean } = {}

local Monetization = {}

local function flag(player: Player, key: string)
	owned[player.UserId] = owned[player.UserId] or {}
	owned[player.UserId][key] = true
end

function Monetization.Has(player: Player, key: string): boolean
	return owned[player.UserId] ~= nil and owned[player.UserId][key] == true
end

function Monetization.GrantFlag(player: Player, key: string)
	flag(player, key)
	local mod = script.Parent:FindFirstChild("DataService")
	if mod then
		local ok, ds = pcall(require, mod)
		if ok and ds and ds.MarkDirty then
			ds.MarkDirty(player)
		end
	end
end

--- Optional cache for DataService (Marketplace remains source of truth on join).
function Monetization.GetOwnedFlags(player: Player): { [string]: boolean }
	local bag = owned[player.UserId]
	local out: { [string]: boolean } = {}
	if bag then
		for k, v in bag do
			if v then
				out[k] = true
			end
		end
	end
	return out
end

function Monetization.ApplyCachedFlags(player: Player, flags: { [string]: boolean })
	if typeof(flags) ~= "table" then
		return
	end
	owned[player.UserId] = owned[player.UserId] or {}
	for k, v in flags do
		if v then
			owned[player.UserId][k] = true
		end
	end
end

function Monetization.GetCatalog()
	return {
		passes = PASS,
		products = PRODUCT,
		prices = {
			VIP = 799,
			DoubleCash = 449,
			AutoCollect = 249,
			ExtraPet = 349,
			FastTravel = 149,
			FlexQueue = 199,
			Starter = 175,
			BattlePass = 799,
			BattlePassPlus = 1199,
		},
	}
end

-- Idle ranch multiplier only (never applied to steal cash).
-- VIP does NOT multiply income (ship gate). Rebirth + 2×Cash only.
function Monetization.GetIdleMult(player: Player): number
	local rebirth = 0
	local mod = script.Parent:FindFirstChild("RebirthService")
	if mod then
		local ok, rs = pcall(require, mod)
		if ok and rs and rs.GetLevel then
			rebirth = rs.GetLevel(player)
		end
	end
	local mult = 1.0 + rebirth * 0.25
	if Monetization.Has(player, "DoubleCash") then
		mult *= 2.0
	end
	-- timed luck boosts from packs are separate (LuckService), not VIP
	return mult
end

local function lockSecsFromConfig(vip: boolean): number
	local RS = game:GetService("ReplicatedStorage")
	local cfgFolder = RS:FindFirstChild("Config")
	local mod = cfgFolder and cfgFolder:FindFirstChild("EconomyConfig")
	local f2p, vipSecs = 45, 120
	if mod and mod:IsA("ModuleScript") then
		local ok, cfg = pcall(require, mod)
		if ok and cfg then
			if typeof(cfg.LockSecondsF2P) == "number" then
				f2p = cfg.LockSecondsF2P
			end
			if typeof(cfg.LockSecondsVIP) == "number" then
				vipSecs = cfg.LockSecondsVIP
			end
		end
	end
	return if vip then vipSecs else f2p
end

function Monetization.GetLockSeconds(player: Player): number
	return lockSecsFromConfig(Monetization.IsVIP(player))
end

function Monetization.ApplyOwned(player: Player)
	EconomyService.SetIncomeMult(player, Monetization.GetIdleMult(player))
	if Monetization.Has(player, "ExtraPet") then
		RanchService.ExpandSlots(player, 4)
	end
end

function Monetization.IsVIP(player: Player): boolean
	return Monetization.Has(player, "VIP")
end

--- Count PASS+PRODUCT keys still at 0 (CloutDev: HARD FAIL publish if >0 on live purchase paths).
function Monetization.CountUnsetIds(): number
	local n = 0
	for _, id in PASS do
		if id == 0 then
			n += 1
		end
	end
	for _, id in PRODUCT do
		if id == 0 then
			n += 1
		end
	end
	return n
end

--- True only when every catalog ID is non-zero.
function Monetization.HasLivePurchaseIds(): boolean
	return Monetization.CountUnsetIds() == 0
end

--- Soft-launch min set: VIP, DoubleCash, Starter, BattlePass.
function Monetization.HasSoftFunnelIds(): boolean
	return PASS.VIP ~= 0 and PASS.DoubleCash ~= 0 and PRODUCT.Starter ~= 0 and PRODUCT.BattlePass ~= 0
end

-- Soft-funnel SKUs only (Starter → 2×Cash → VIP → BP). Never invent IDs.
local SOFT_SKU: { [string]: { kind: string, key: string, price: number } } = {
	Starter = { kind = "product", key = "Starter", price = 175 },
	DoubleCash = { kind = "pass", key = "DoubleCash", price = 449 },
	VIP = { kind = "pass", key = "VIP", price = 799 },
	BattlePass = { kind = "product", key = "BattlePass", price = 799 },
}

function Monetization.GetPassId(key: string): number
	local id = PASS[key]
	return if typeof(id) == "number" then id else 0
end

function Monetization.GetProductId(key: string): number
	local id = PRODUCT[key]
	return if typeof(id) == "number" then id else 0
end

--- True when this soft-funnel SKU has a non-zero Marketplace ID.
function Monetization.IsSkuLive(sku: string): boolean
	local def = SOFT_SKU[sku]
	if not def then
		return false
	end
	if def.kind == "pass" then
		return Monetization.GetPassId(def.key) ~= 0
	end
	return Monetization.GetProductId(def.key) ~= 0
end

--- Soft catalog for OfferService / HUD — prices + live flags, never invents IDs.
function Monetization.GetSoftFunnelCatalog(): { [string]: { price: number, live: boolean, kind: string } }
	local out: { [string]: { price: number, live: boolean, kind: string } } = {}
	for sku, def in SOFT_SKU do
		out[sku] = {
			price = def.price,
			live = Monetization.IsSkuLive(sku),
			kind = def.kind,
		}
	end
	return out
end


export type PromptStatus = "prompted" | "coming_soon" | "unknown" | "owned"

--- Soft-safe GamePass prompt. ID 0 → never calls Marketplace (coming_soon).
function Monetization.PromptPass(player: Player, key: string): PromptStatus
	local passId = Monetization.GetPassId(key)
	if passId == 0 then
		return "coming_soon"
	end
	if Monetization.Has(player, key) then
		return "owned"
	end
	local ok = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, passId)
	end)
	return if ok then "prompted" else "unknown"
end

--- Soft-safe DevProduct prompt. ID 0 → never calls Marketplace (coming_soon).
function Monetization.PromptProduct(player: Player, key: string): PromptStatus
	local productId = Monetization.GetProductId(key)
	if productId == 0 then
		return "coming_soon"
	end
	local ok = pcall(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)
	return if ok then "prompted" else "unknown"
end

--- Soft-funnel allowlist prompt. ID 0 → coming_soon (never Prompt* with 0).
function Monetization.TryPrompt(player: Player, sku: string): (boolean, string)
	local def = SOFT_SKU[sku]
	if not def then
		return false, "unknown_sku"
	end
	local status: PromptStatus
	if def.kind == "pass" then
		status = Monetization.PromptPass(player, def.key)
	else
		status = Monetization.PromptProduct(player, def.key)
	end
	if status == "prompted" then
		return true, "prompted"
	end
	return false, status
end

local function ownPass(player: Player, passId: number, key: string)
	if passId == 0 then
		return
	end
	local ok, has = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	if ok and has then
		flag(player, key)
	end
end

local function refreshPasses(player: Player)
	ownPass(player, PASS.VIP, "VIP")
	ownPass(player, PASS.DoubleCash, "DoubleCash")
	ownPass(player, PASS.AutoCollect, "AutoCollect")
	ownPass(player, PASS.ExtraPet, "ExtraPet")
	ownPass(player, PASS.FastTravel, "FastTravel")
	ownPass(player, PASS.FlexQueue, "FlexQueue")
	Monetization.ApplyOwned(player)
end

local function dayKey(): number
	return math.floor(os.time() / 86400)
end

local function canBuyXL(player: Player): boolean
	local rec = xlToday[player.UserId]
	local d = dayKey()
	if not rec or rec.day ~= d then
		xlToday[player.UserId] = { day = d, count = 0 }
		rec = xlToday[player.UserId]
	end
	return rec.count < 3
end

local function noteXL(player: Player)
	local rec = xlToday[player.UserId]
	local d = dayKey()
	if not rec or rec.day ~= d then
		xlToday[player.UserId] = { day = d, count = 1 }
	else
		rec.count += 1
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if not wasPurchased then
		return
	end
	if passId == PASS.VIP then
		flag(player, "VIP")
	elseif passId == PASS.DoubleCash then
		flag(player, "DoubleCash")
	elseif passId == PASS.AutoCollect then
		flag(player, "AutoCollect")
	elseif passId == PASS.ExtraPet then
		flag(player, "ExtraPet")
	elseif passId == PASS.FastTravel then
		flag(player, "FastTravel")
	elseif passId == PASS.FlexQueue then
		flag(player, "FlexQueue")
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
	local pid = receipt.ProductId

	if pid == PRODUCT.Starter then
		if starterBought[player.UserId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted -- already owned; don't double grant
		end
		starterBought[player.UserId] = true
		EconomyService.AddCash(player, CASH_GRANTS.Starter)
		local Luck = script.Parent:FindFirstChild("LuckService")
		if Luck then
			local ok, luck = pcall(require, Luck)
			if ok and luck.AddBoost then
				luck.AddBoost(player, 2, 30 * 60)
			end
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if pid == PRODUCT.Comeback then
		EconomyService.AddCash(player, CASH_GRANTS.Comeback)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	for key, amount in CASH_GRANTS do
		if key ~= "Starter" and key ~= "Comeback" and PRODUCT[key] == pid then
			if key == "CashXL" and not canBuyXL(player) then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
			EconomyService.AddCash(player, amount)
			if key == "CashXL" then
				noteXL(player)
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	if pid == PRODUCT.BattlePass or pid == PRODUCT.BattlePassPlus then
		flag(player, "BattlePass")
		local bp = script.Parent:FindFirstChild("BattlePassService")
		if bp then
			local ok, svc = pcall(require, bp)
			if ok and svc.SetPremium then
				svc.SetPremium(player, true)
				if pid == PRODUCT.BattlePassPlus and svc.AddXp then
					svc.AddXp(player, 1000) -- ~10 tiers
				end
			end
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if pid == PRODUCT.WeeklyAura then
		flag(player, "WeeklyAura")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

Players.PlayerAdded:Connect(refreshPasses)
for _, p in Players:GetPlayers() do
	task.spawn(refreshPasses, p)
end

-- Hoisted boot warn: fires on require so unset IDs are visible even if bootstrap tail changes.
-- Pre-alpha: WARN only (soft funnel OK with zeros). HARD FAIL is a publish gate for Brad — not a runtime halt.
do
	local unset = Monetization.CountUnsetIds()
	if unset > 0 then
		warn(
			"[CloutRanch] Marketplace IDs unset:",
			unset,
			"— paste from Creator Dashboard (docs/MARKETPLACE_IDS.md). HARD FAIL publish while 0."
		)
	else
		print("[CloutRanch] Marketplace IDs: all set")
	end
end

return Monetization
