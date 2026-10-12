--!strict
-- Clout Ranch — starter pet catalog (place as ModuleScript under ReplicatedStorage)

export type PetDef = {
	id: string,
	name: string,
	rarity: string,
	incomePerSec: number,
	carrySlow: number, -- 0..1, fraction of WalkSpeed while carrying
}

local catalog: { [string]: PetDef } = {
	c1 = { id = "c1", name = "Drip Mutt", rarity = "Common", incomePerSec = 5, carrySlow = 0.15 },
	c2 = { id = "c2", name = "Cap Crab", rarity = "Common", incomePerSec = 6, carrySlow = 0.15 },
	u1 = { id = "u1", name = "Ratio Raven", rarity = "Uncommon", incomePerSec = 15, carrySlow = 0.2 },
	u2 = { id = "u2", name = "Main Character", rarity = "Uncommon", incomePerSec = 18, carrySlow = 0.2 },
	r1 = { id = "r1", name = "Aura Gator", rarity = "Rare", incomePerSec = 45, carrySlow = 0.25 },
	r2 = { id = "r2", name = "Timeline Titan", rarity = "Rare", incomePerSec = 55, carrySlow = 0.25 },
	e1 = { id = "e1", name = "Clout Kraken", rarity = "Epic", incomePerSec = 120, carrySlow = 0.3 },
	s1 = { id = "s1", name = "Viral Wisp", rarity = "Secret", incomePerSec = 400, carrySlow = 0.35 },
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
