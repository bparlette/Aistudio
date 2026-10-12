--!strict
-- Clout Ranch — original pet catalog (place as ModuleScript under ReplicatedStorage)

export type PetDef = {
	id: string,
	name: string,
	rarity: string,
	incomePerSec: number,
	carrySlow: number, -- 0..1, fraction of WalkSpeed while carrying
	auraBonus: number?, -- optional Aura Flex vote weight / score bonus
}

local catalog: { [string]: PetDef } = {
	-- Common (6)
	c1 = { id = "c1", name = "Drip Mutt", rarity = "Common", incomePerSec = 5, carrySlow = 0.15 },
	c2 = { id = "c2", name = "Cap Crab", rarity = "Common", incomePerSec = 6, carrySlow = 0.15 },
	c3 = { id = "c3", name = "Based Frog", rarity = "Common", incomePerSec = 5, carrySlow = 0.14 },
	c4 = { id = "c4", name = "Sus Goose", rarity = "Common", incomePerSec = 7, carrySlow = 0.16 },
	c5 = { id = "c5", name = "Mid Mole", rarity = "Common", incomePerSec = 6, carrySlow = 0.15 },
	c6 = { id = "c6", name = "Cope Corgi", rarity = "Common", incomePerSec = 8, carrySlow = 0.17 },

	-- Uncommon (6)
	u1 = { id = "u1", name = "Ratio Raven", rarity = "Uncommon", incomePerSec = 15, carrySlow = 0.2 },
	u2 = { id = "u2", name = "Main Character", rarity = "Uncommon", incomePerSec = 18, carrySlow = 0.2 },
	u3 = { id = "u3", name = "Flex Fox", rarity = "Uncommon", incomePerSec = 16, carrySlow = 0.19, auraBonus = 1 },
	u4 = { id = "u4", name = "Vibe Viper", rarity = "Uncommon", incomePerSec = 17, carrySlow = 0.2 },
	u5 = { id = "u5", name = "Stan Stallion", rarity = "Uncommon", incomePerSec = 19, carrySlow = 0.21 },
	u6 = { id = "u6", name = "Algo Alpaca", rarity = "Uncommon", incomePerSec = 20, carrySlow = 0.22 },

	-- Rare (5)
	r1 = { id = "r1", name = "Aura Gator", rarity = "Rare", incomePerSec = 45, carrySlow = 0.25, auraBonus = 2 },
	r2 = { id = "r2", name = "Timeline Titan", rarity = "Rare", incomePerSec = 55, carrySlow = 0.25 },
	r3 = { id = "r3", name = "Rizz Rhino", rarity = "Rare", incomePerSec = 48, carrySlow = 0.24, auraBonus = 2 },
	r4 = { id = "r4", name = "Soft Launch Seal", rarity = "Rare", incomePerSec = 52, carrySlow = 0.26 },
	r5 = { id = "r5", name = "Parasocial Panda", rarity = "Rare", incomePerSec = 58, carrySlow = 0.27, auraBonus = 1 },

	-- Epic (4)
	e1 = { id = "e1", name = "Clout Kraken", rarity = "Epic", incomePerSec = 120, carrySlow = 0.3, auraBonus = 3 },
	e2 = { id = "e2", name = "Trend Tsunami", rarity = "Epic", incomePerSec = 135, carrySlow = 0.31, auraBonus = 2 },
	e3 = { id = "e3", name = "For You Phoenix", rarity = "Epic", incomePerSec = 150, carrySlow = 0.32, auraBonus = 4 },
	e4 = { id = "e4", name = "Discourse Dragon", rarity = "Epic", incomePerSec = 140, carrySlow = 0.3, auraBonus = 3 },

	-- Secret (3 base + weekly trend seeds — ORIGINAL names only)
	s1 = { id = "s1", name = "Viral Wisp", rarity = "Secret", incomePerSec = 400, carrySlow = 0.35, auraBonus = 5 },
	s2 = { id = "s2", name = "Shadowban Specter", rarity = "Secret", incomePerSec = 450, carrySlow = 0.36, auraBonus = 6 },
	s3 = { id = "s3", name = "Autumn Corecore", rarity = "Secret", incomePerSec = 500, carrySlow = 0.38, auraBonus = 8 },

	-- Trend Week Secrets (generic meme energy — never licensed IP names)
	st_fraud_whistle = {
		id = "st_fraud_whistle",
		name = "Whistle Fraudling",
		rarity = "Secret",
		incomePerSec = 520,
		carrySlow = 0.37,
		auraBonus = 7,
	}, -- sports-fraud meme energy
	st_aura_harvester = {
		id = "st_aura_harvester",
		name = "Aura Harvester",
		rarity = "Secret",
		incomePerSec = 540,
		carrySlow = 0.37,
		auraBonus = 9,
	}, -- aura-farming vibes
	st_capsule_charm = {
		id = "st_capsule_charm",
		name = "Capsule Charmling",
		rarity = "Secret",
		incomePerSec = 510,
		carrySlow = 0.36,
		auraBonus = 7,
	}, -- blind-box charm energy
	st_ribbon_reveal = {
		id = "st_ribbon_reveal",
		name = "Ribbon Debutante",
		rarity = "Secret",
		incomePerSec = 530,
		carrySlow = 0.38,
		auraBonus = 8,
	}, -- soft-reveal / doll-unbox vibes
	trend_offline_brain = { id = "trend_offline_brain", name = "Offline Brain", rarity = "Secret", incomePerSec = 450, carrySlow = 0.35, auraBonus = 15 },
	trend_stolen_mascot = { id = "trend_stolen_mascot", name = "Stolen Mascot", rarity = "Secret", incomePerSec = 420, carrySlow = 0.32, auraBonus = 12 },
	trend_flex_bag = { id = "trend_flex_bag", name = "Flex Bag", rarity = "Secret", incomePerSec = 480, carrySlow = 0.38, auraBonus = 18 },

}

local PetCatalog = {}

function PetCatalog.Get(id: string): PetDef?
	return catalog[id]
end

function PetCatalog.All(): { PetDef }
	local list = {}
	for _, def in catalog do
		table.insert(list, def)
	end
	return list
end

function PetCatalog.IdsByRarity(rarity: string): { string }
	local ids = {}
	for id, def in catalog do
		if def.rarity == rarity then
			table.insert(ids, id)
		end
	end
	return ids
end

return PetCatalog
