--!strict
-- Server ModuleScript: weekly original trend pets (no licensed IP names)
-- HARD RULE: endsAt is authoritative and immutable at runtime.
-- There is intentionally NO Extend / SetEndsAt / bump API — weeks die on schedule.
-- Active drop features a Secret on the Carpet and drives Trend Week banner copy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetCatalog"))

export type TrendDrop = {
	weekId: string,
	petId: string,
	displayName: string,
	startsAt: number, -- unix (GetServerTimeNow)
	endsAt: number,
	trailerLine: string,
}

-- Seeded future weeks — ORIGINAL names only (meme energy, not marks)
local DROPS: { TrendDrop } = {
	{
		weekId = "2026-W36",
		petId = "trend_offline_brain",
		displayName = "Offline Brain",
		startsAt = 1788480000, -- 2026-09-04 00:00 UTC
		endsAt = 1788825600, -- hard Sunday-adjacent kill → 2026-09-08 UTC (no extend)
		trailerLine = "AI went down so we raised our own Offline Brain.",
	},
	{
		weekId = "2026-W37",
		petId = "st_fraud_whistle",
		displayName = "Whistle Fraudling",
		startsAt = 1788825600, -- 2026-09-08 UTC
		endsAt = 1789430400, -- 2026-09-15 UTC
		trailerLine = "When the call looks fake — the Fraudling goes viral.",
	},
	{
		weekId = "2026-W38",
		petId = "st_aura_harvester",
		displayName = "Aura Harvester",
		startsAt = 1789430400,
		endsAt = 1790035200, -- 2026-09-22
		trailerLine = "Touch grass? Nah. Farm aura. Harvest the lobby.",
	},
	{
		weekId = "2026-W39",
		petId = "st_capsule_charm",
		displayName = "Capsule Charmling",
		startsAt = 1790035200,
		endsAt = 1790640000, -- 2026-09-29
		trailerLine = "Shake the capsule. Pray for the shiny. Clip the reveal.",
	},
	{
		weekId = "2026-W40",
		petId = "st_ribbon_reveal",
		displayName = "Ribbon Debutante",
		startsAt = 1790640000,
		endsAt = 1791244800, -- 2026-10-06
		trailerLine = "Big soft-launch energy. Untie the ribbon. Own the timeline.",
	},
}

local SECRET_WEIGHT_MULT = 2.5
local lastSyncedPetId: string? = nil
local carpetService: any = nil

local TrendDropService = {}

local function nowUnix(): number
	return workspace:GetServerTimeNow()
end

function TrendDropService.GetDrops(): { TrendDrop }
	return table.clone(DROPS)
end

function TrendDropService.GetAll(): { TrendDrop }
	return DROPS
end

function TrendDropService.GetActive(now: number?): TrendDrop?
	local t = now or nowUnix()
	for _, drop in DROPS do
		if t >= drop.startsAt and t < drop.endsAt then
			return drop
		end
	end
	return nil
end

function TrendDropService.GetUpcoming(now: number?): TrendDrop?
	local t = now or nowUnix()
	local best: TrendDrop? = nil
	for _, drop in DROPS do
		if drop.startsAt > t then
			if not best or drop.startsAt < best.startsAt then
				best = drop
			end
		end
	end
	return best
end

function TrendDropService.GetBannerTitle(drop: TrendDrop?): string
	if not drop then
		return ""
	end
	return string.format("TREND WEEK · %s", drop.displayName)
end

--- Bias rarity weights toward Secret while a trend drop is live.
function TrendDropService.ApplyFeaturedWeights(base: { [string]: number }): { [string]: number }
	local drop = TrendDropService.GetActive()
	if not drop then
		return base
	end
	local out: { [string]: number } = table.clone(base)
	if out.Secret then
		out.Secret = out.Secret * SECRET_WEIGHT_MULT
	end
	return out
end

function TrendDropService.GetFeaturedPetId(): string?
	local drop = TrendDropService.GetActive()
	return if drop then drop.petId else nil
end

function TrendDropService.BindCarpet(svc: any)
	carpetService = svc
	TrendDropService.SyncCarpet()
end

--- Push featured pet id into CarpetService when the active week changes.
function TrendDropService.SyncCarpet()
	if not carpetService or not carpetService.SetFeaturedPetId then
		return
	end
	local petId = TrendDropService.GetFeaturedPetId()
	if petId ~= lastSyncedPetId then
		lastSyncedPetId = petId
		carpetService.SetFeaturedPetId(petId)
		if petId then
			local drop = TrendDropService.GetActive()
			print("[CloutRanch][TrendDrop] featured", petId, drop and drop.weekId or "?")
		else
			print("[CloutRanch][TrendDrop] no active week — featured cleared")
		end
	end
end

--- Optional direct replicate (SeasonService prefers BindCloutState + Tick).
function TrendDropService.ReplicateToState(stateFolder: Folder)
	local title = stateFolder:FindFirstChild("TrendTitle")
	if not title then
		title = Instance.new("StringValue")
		title.Name = "TrendTitle"
		title.Parent = stateFolder
	end
	local ends = stateFolder:FindFirstChild("TrendEndsAt")
	if not ends then
		ends = Instance.new("NumberValue")
		ends.Name = "TrendEndsAt"
		ends.Parent = stateFolder
	end
	local active = TrendDropService.GetActive()
	if title:IsA("StringValue") and ends:IsA("NumberValue") then
		if active then
			title.Value = TrendDropService.GetBannerTitle(active)
			ends.Value = active.endsAt
		else
			title.Value = ""
			ends.Value = 0
		end
	end
end

function TrendDropService.Tick(_dt: number?)
	TrendDropService.SyncCarpet()
end

-- Validate catalog ids once at require time (warn only)
for _, drop in DROPS do
	if not PetCatalog.Get(drop.petId) then
		warn("[CloutRanch][TrendDrop] missing PetCatalog entry:", drop.petId)
	end
end

return TrendDropService
