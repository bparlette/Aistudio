--!strict
-- Art direction palette — rarity + brand tokens

export type Swatch = {
	primary: Color3,
	secondary: Color3,
	glow: Color3,
	hex: string,
}

local Brand = {
	Gold = Color3.fromRGB(245, 200, 75),
	DeepPurple = Color3.fromRGB(91, 42, 158),
	Lilac = Color3.fromRGB(201, 166, 255),
	Cream = Color3.fromRGB(255, 246, 224),
	NightVoid = Color3.fromRGB(26, 18, 40),
	HeatPink = Color3.fromRGB(255, 77, 184),
}

local Rarity: { [string]: Swatch } = {
	Common = {
		primary = Brand.Cream,
		secondary = Color3.fromRGB(107, 90, 138),
		glow = Brand.NightVoid,
		hex = "#FFF6E0",
	},
	Uncommon = {
		primary = Brand.Lilac,
		secondary = Brand.DeepPurple,
		glow = Brand.Lilac,
		hex = "#C9A6FF",
	},
	Rare = {
		primary = Brand.Gold,
		secondary = Brand.DeepPurple,
		glow = Brand.Gold,
		hex = "#F5C84B",
	},
	Epic = {
		primary = Brand.Gold,
		secondary = Brand.Lilac,
		glow = Brand.DeepPurple,
		hex = "#F5C84B",
	},
	Legendary = {
		primary = Brand.Gold,
		secondary = Brand.HeatPink,
		glow = Brand.HeatPink,
		hex = "#FF4DB8",
	},
	-- Secret maps to Mythic presentation
	Secret = {
		primary = Brand.Gold,
		secondary = Brand.HeatPink,
		glow = Brand.HeatPink,
		hex = "#FF4DB8",
	},
	Mythic = {
		primary = Brand.Gold,
		secondary = Brand.HeatPink,
		glow = Brand.HeatPink,
		hex = "#FF4DB8",
	},
}

local RarityColors = {}

function RarityColors.Brand()
	return Brand
end

function RarityColors.Get(rarity: string): Swatch
	return Rarity[rarity] or Rarity.Common
end

function RarityColors.All(): { [string]: Swatch }
	return Rarity
end

return RarityColors
