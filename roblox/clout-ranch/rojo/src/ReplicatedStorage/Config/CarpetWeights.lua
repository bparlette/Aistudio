--!strict
-- Red Carpet rarity weights + prices (shared; CarpetService reads these).

local CarpetWeights = {
	RotateEvery = 30,
	StockSize = 4,
	FeaturedPickChance = 0.6,

	Weights = {
		Common = 50,
		Uncommon = 30,
		Rare = 15,
		Epic = 4,
		Secret = 1,
	},

	Prices = {
		Common = 25,
		Uncommon = 100,
		Rare = 400,
		Epic = 1500,
		Secret = 8000,
	},
}

return CarpetWeights
