--!strict
-- Server ModuleScript: rotating shop stock on the Red Carpet
-- Soft pity: player replacement rolls force Uncommon+ after N Commons (SoftPityService).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetCatalog"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local RanchService = require(script.Parent:WaitForChild("RanchService"))

local SoftPityService: any = nil
do
	local mod = script.Parent:FindFirstChild("SoftPityService")
	if mod then
		local ok, result = pcall(require, mod)
		if ok then
			SoftPityService = result
		end
	end
end

local ROTATE_EVERY = 30
local STOCK_SIZE = 4

local PRICES = {
	Common = 25,
	Uncommon = 100,
	Rare = 400,
	Epic = 1500,
	Secret = 8000,
}

local WEIGHTS = {
	Common = 50,
	Uncommon = 30,
	Rare = 15,
	Epic = 4,
	Secret = 1,
}

local FEATURED_PICK_CHANCE_CFG: number? = nil
do
	local cfgFolder = ReplicatedStorage:FindFirstChild("Config")
	local mod = cfgFolder and cfgFolder:FindFirstChild("CarpetWeights")
	if mod and mod:IsA("ModuleScript") then
		local ok, cfg = pcall(require, mod)
		if ok and cfg then
			if typeof(cfg.RotateEvery) == "number" then
				ROTATE_EVERY = cfg.RotateEvery
			end
			if typeof(cfg.StockSize) == "number" then
				STOCK_SIZE = cfg.StockSize
			end
			if typeof(cfg.FeaturedPickChance) == "number" then
				FEATURED_PICK_CHANCE_CFG = cfg.FeaturedPickChance
			end
			if typeof(cfg.Prices) == "table" then
				PRICES = cfg.Prices
			end
			if typeof(cfg.Weights) == "table" then
				WEIGHTS = cfg.Weights
			end
		end
	else
		-- TODO: ensure Config/CarpetWeights is synced via Rojo
	end
end

export type StockEntry = {
	id: string,
	name: string,
	rarity: string,
	price: number,
}

export type WeightTransform = (base: { [string]: number }, player: Player?) -> { [string]: number }

local stock: { string } = {}
local nextRotate = 0
local weightTransform: WeightTransform? = nil
local featuredPetId: string? = nil
local FEATURED_PICK_CHANCE = FEATURED_PICK_CHANCE_CFG or 0.6
local onRotated: (() -> ())? = nil

local CarpetService = {}

function CarpetService.SetOnRotated(fn: (() -> ())?)
	onRotated = fn
end

local function notifyRotated()
	if onRotated then
		local ok, err = pcall(onRotated)
		if not ok then
			warn("[CarpetService] OnRotated failed:", err)
		end
	end
end

function CarpetService.SetWeightTransform(fn: WeightTransform?)
	weightTransform = fn
end

function CarpetService.SetFeaturedPetId(petId: string?)
	featuredPetId = petId
end

function CarpetService.GetFeaturedPetId(): string?
	return featuredPetId
end

function CarpetService.GetBaseWeights(): { [string]: number }
	return table.clone(WEIGHTS)
end

local function resolveWeights(player: Player?): { [string]: number }
	if weightTransform then
		return weightTransform(WEIGHTS, player)
	end
	return WEIGHTS
end

local function pickIdForRarity(rarity: string): string
	local ids = PetCatalog.IdsByRarity(rarity)
	if #ids == 0 then
		ids = PetCatalog.IdsByRarity("Common")
		rarity = "Common"
	end
	-- Trend Week: bias matching-rarity rolls toward the featured Secret
	if featuredPetId then
		local feat = PetCatalog.Get(featuredPetId)
		if feat and feat.rarity == rarity and math.random() < FEATURED_PICK_CHANCE then
			return featuredPetId
		end
	end
	return ids[math.random(1, #ids)]
end

local function weightedPick(player: Player?): string
	local weights = resolveWeights(player)
	-- Soft pity: zero out Common (and below min) when streak threshold hit
	if player and SoftPityService and SoftPityService.GetForcedMinRarity then
		local minR = SoftPityService.GetForcedMinRarity(player)
		if minR then
			local filtered: { [string]: number } = {}
			local order = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Secret = 5 }
			local minRank = order[minR] or 2
			for r, w in weights do
				if (order[r] or 1) >= minRank then
					filtered[r] = w
				end
			end
			if next(filtered) ~= nil then
				weights = filtered
			end
		end
	end

	local total = 0
	for _, w in weights do
		total += w
	end
	if total <= 0 then
		total = 1
	end
	local roll = math.random() * total
	local acc = 0
	local rarity = "Common"
	for r, w in weights do
		acc += w
		if roll <= acc then
			rarity = r
			break
		end
	end

	if player and SoftPityService and SoftPityService.GetForcedMinRarity then
		local minR = SoftPityService.GetForcedMinRarity(player)
		if minR and SoftPityService.ClampRarity then
			rarity = SoftPityService.ClampRarity(rarity, minR)
		end
	end

	return pickIdForRarity(rarity)
end

function CarpetService.Rotate()
	table.clear(stock)
	for _ = 1, STOCK_SIZE do
		-- Global rotate uses base weights (no player context / no pity)
		table.insert(stock, weightedPick(nil))
	end
	-- Featured trend pet always visible in slot 1 (FOMO — may be expensive; commons fill rest)
	if featuredPetId and PetCatalog.Get(featuredPetId) then
		stock[1] = featuredPetId
	end
	nextRotate = os.clock() + ROTATE_EVERY
	notifyRotated()
end

function CarpetService.GetStock(): { string }
	return table.clone(stock)
end

function CarpetService.GetStockDetailed(): { StockEntry }
	local out: { StockEntry } = {}
	for _, petId in stock do
		local def = PetCatalog.Get(petId)
		if def then
			table.insert(out, {
				id = def.id,
				name = def.name,
				rarity = def.rarity,
				price = PRICES[def.rarity] or 25,
			})
		end
	end
	return out
end

function CarpetService.GetPrice(petId: string): number?
	local def = PetCatalog.Get(petId)
	if not def then
		return nil
	end
	return PRICES[def.rarity] or 25
end

function CarpetService.TryBuy(player: Player, stockIndex: number): (boolean, string?)
	local petId = stock[stockIndex]
	if not petId then
		return false, "Empty slot"
	end
	local listedId = petId
	-- Soft pity: after N Commons, upgrade this purchase to Uncommon+ (still pay listed price)
	local listed = PetCatalog.Get(petId)
	if (
		listed
		and listed.rarity == "Common"
		and SoftPityService
		and SoftPityService.ShouldForceUncommonPlus
		and SoftPityService.ShouldForceUncommonPlus(player)
	) then
		petId = pickIdForRarity("Uncommon")
	end
	local price = CarpetService.GetPrice(listedId) -- pay what the slot showed
	if not price then
		return false, "Bad pet"
	end
	if not EconomyService.TrySpend(player, price) then
		return false, "Not enough cash"
	end
	local ok, err = RanchService.TryPlacePet(player, petId)
	if not ok then
		EconomyService.AddCash(player, price, true) -- refund (no quest)
		return false, err
	end
	-- Soft pity tracks what the player actually received
	local bought = PetCatalog.Get(petId)
	if SoftPityService and SoftPityService.RecordOutcome and bought then
		SoftPityService.RecordOutcome(player, bought.rarity)
	end
	-- Replacement roll uses luck-biased weights + soft pity when player known
	stock[stockIndex] = weightedPick(player)
	notifyRotated()
	RanchService.Lock(player, false)
	local juiceMod = script.Parent:FindFirstChild("JuiceService")
	if juiceMod then
		local jok, juice = pcall(require, juiceMod)
		if jok and juice and juice.Hatch then
			local rarity = if bought then bought.rarity else "Common"
			juice.Hatch(player, rarity, petId)
		end
	end
	return true, nil
end

function CarpetService.Tick()
	if os.clock() >= nextRotate or #stock == 0 then
		CarpetService.Rotate()
	end
end

return CarpetService
