--!strict
-- Soft pity: after N Commons in a row, force Uncommon+ (F2P fairness — not uncapped auto-roll).

local SoftPityConfig = {
	CommonStreakForce = 8,
	ForcedMinRarity = "Uncommon",
	RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Secret" },
}

return SoftPityConfig
