--!strict
-- Server ModuleScript: rotating shop stock on the Red Carpet

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetCatalog"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local RanchService = require(script.Parent:WaitForChild("RanchService"))

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

local stock: { string } = {}
local nextRotate = 0

local CarpetService = {}

local function weightedPick(): string
	local total = 0
	for _, w in WEIGHTS do
		total += w
	end
	local roll = math.random() * total
	local acc = 0
	local rarity = "Common"
	for r, w in WEIGHTS do
		acc += w
		if roll <= acc then
			rarity = r
			break
		end
	end
	local ids = PetCatalog.IdsByRarity(rarity)
	if #ids == 0 then
		ids = PetCatalog.IdsByRarity("Common")
	end
	return ids[math.random(1, #ids)]
end

function CarpetService.Rotate()
	table.clear(stock)
	for _ = 1, STOCK_SIZE do
		table.insert(stock, weightedPick())
	end
	nextRotate = os.clock() + ROTATE_EVERY
end

function CarpetService.GetStock(): { string }
	return table.clone(stock)
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
	local price = CarpetService.GetPrice(petId)
	if not price then
		return false, "Bad pet"
	end
	if not EconomyService.TrySpend(player, price) then
		return false, "Not enough cash"
	end
	local ok, err = RanchService.TryPlacePet(player, petId)
	if not ok then
		EconomyService.AddCash(player, price) -- refund
		return false, err
	end
	stock[stockIndex] = weightedPick() -- replace purchased
	RanchService.Lock(player, false)
	return true, nil
end

function CarpetService.Tick()
	if os.clock() >= nextRotate or #stock == 0 then
		CarpetService.Rotate()
	end
end

return CarpetService
