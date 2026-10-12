--!strict
-- Server ModuleScript: Season 1 battle pass — 20 free + 20 premium tracks
-- XP sources: steals (deposit), rebirths, aura podium finishes.
-- Premium via Monetization.Has(player, "BattlePass") or SetPremium.

local Players = game:GetService("Players")

local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local Monetization = require(script.Parent:WaitForChild("Monetization"))

local SEASON_ID = 1
local MAX_TIER = 20
local XP_PER_TIER = 100

export type RewardKind = "cash" | "aura" | "pet" | "luck"

export type TierReward = {
	kind: RewardKind,
	amount: number?,
	petId: string?,
	luckMult: number?,
	label: string,
}

export type Progress = {
	seasonId: number,
	xp: number,
	tier: number,
	premium: boolean,
	claimedFree: { [number]: boolean },
	claimedPremium: { [number]: boolean },
}

local progress: { [number]: Progress } = {}

local FREE: { TierReward } = {
	{ kind = "cash", amount = 75, label = "S1 Free 1 — Seed Cash" },
	{ kind = "luck", amount = 10, luckMult = 1.2, label = "S1 Free 2 — Luck Sip" },
	{ kind = "cash", amount = 120, label = "S1 Free 3 — Stack" },
	{ kind = "aura", amount = 15, label = "S1 Free 4 — Aura Chip" },
	{ kind = "pet", petId = "c1", label = "S1 Free 5 — Drip Mutt" },
	{ kind = "cash", amount = 200, label = "S1 Free 6 — Bank" },
	{ kind = "luck", amount = 15, luckMult = 1.25, label = "S1 Free 7 — Carpet Edge" },
	{ kind = "aura", amount = 25, label = "S1 Free 8 — Glow" },
	{ kind = "cash", amount = 300, label = "S1 Free 9 — Payday" },
	{ kind = "pet", petId = "c2", label = "S1 Free 10 — Cap Crab" },
	{ kind = "cash", amount = 350, label = "S1 Free 11 — Float" },
	{ kind = "luck", amount = 20, luckMult = 1.3, label = "S1 Free 12 — Hot Hand" },
	{ kind = "aura", amount = 35, label = "S1 Free 13 — Stage Light" },
	{ kind = "cash", amount = 450, label = "S1 Free 14 — Vault" },
	{ kind = "pet", petId = "u1", label = "S1 Free 15 — Ratio Raven" },
	{ kind = "cash", amount = 550, label = "S1 Free 16 — Clout Check" },
	{ kind = "luck", amount = 25, luckMult = 1.35, label = "S1 Free 17 — Bias" },
	{ kind = "aura", amount = 50, label = "S1 Free 18 — Podium Prep" },
	{ kind = "cash", amount = 700, label = "S1 Free 19 — Big Bag" },
	{ kind = "pet", petId = "u2", label = "S1 Free 20 — Main Character" },
}

local PREMIUM: { TierReward } = {
	{ kind = "cash", amount = 200, label = "S1 Prem 1 — Fast Start" },
	{ kind = "luck", amount = 20, luckMult = 1.4, label = "S1 Prem 2 — Loaded Dice" },
	{ kind = "aura", amount = 40, label = "S1 Prem 3 — Spotlight" },
	{ kind = "pet", petId = "r1", label = "S1 Prem 4 — Aura Gator" },
	{ kind = "cash", amount = 400, label = "S1 Prem 5 — Cash Spike" },
	{ kind = "luck", amount = 30, luckMult = 1.5, label = "S1 Prem 6 — Carpet Storm" },
	{ kind = "aura", amount = 60, label = "S1 Prem 7 — Flex Fuel" },
	{ kind = "cash", amount = 500, label = "S1 Prem 8 — Payroll" },
	{ kind = "pet", petId = "r2", label = "S1 Prem 9 — Timeline Titan" },
	{ kind = "luck", amount = 30, luckMult = 1.5, label = "S1 Prem 10 — Mid-Season Edge" },
	{ kind = "cash", amount = 650, label = "S1 Prem 11 — Deep Pockets" },
	{ kind = "aura", amount = 80, label = "S1 Prem 12 — Crowd Favorite" },
	{ kind = "pet", petId = "e1", label = "S1 Prem 13 — Clout Kraken" },
	{ kind = "cash", amount = 800, label = "S1 Prem 14 — Tycoon Kick" },
	{ kind = "luck", amount = 40, luckMult = 1.6, label = "S1 Prem 15 — Secret Bias" },
	{ kind = "aura", amount = 100, label = "S1 Prem 16 — Legend Light" },
	{ kind = "cash", amount = 1000, label = "S1 Prem 17 — Endgame Cash" },
	{ kind = "luck", amount = 45, luckMult = 1.75, label = "S1 Prem 18 — Final Roll" },
	{ kind = "aura", amount = 125, label = "S1 Prem 19 — Curtain Call" },
	{ kind = "pet", petId = "s1", label = "S1 Prem 20 — Viral Wisp" },
}

local function notifyDirty(player: Player)
	local mod = script.Parent:FindFirstChild("DataService")
	if not mod then
		return
	end
	local ok, ds = pcall(require, mod)
	if ok and ds and ds.MarkDirty then
		ds.MarkDirty(player)
	end
end

local BattlePassService = {}

local function tierFromXp(xpAmount: number): number
	return math.clamp(math.floor(xpAmount / XP_PER_TIER), 0, MAX_TIER)
end

local function ensure(player: Player): Progress
	local p = progress[player.UserId]
	if not p then
		p = {
			seasonId = SEASON_ID,
			xp = 0,
			tier = 0,
			premium = false,
			claimedFree = {},
			claimedPremium = {},
		}
		progress[player.UserId] = p
	end
	if Monetization.Has(player, "BattlePass") then
		p.premium = true
	end
	p.tier = tierFromXp(p.xp)
	return p
end

local function grant(player: Player, reward: TierReward): (boolean, string?)
	if reward.kind == "cash" then
		EconomyService.AddCash(player, reward.amount or 0)
		return true, nil
	elseif reward.kind == "aura" then
		local AuraService = require(script.Parent:WaitForChild("AuraService"))
		AuraService.AddAura(player, reward.amount or 0)
		return true, nil
	elseif reward.kind == "luck" then
		local LuckService = require(script.Parent:WaitForChild("LuckService"))
		local minutes = reward.amount or 10
		LuckService.AddBoost(player, reward.luckMult or 1.25, minutes * 60)
		return true, nil
	elseif reward.kind == "pet" then
		local petId = reward.petId
		if not petId then
			return false, "Missing petId"
		end
		local RanchService = require(script.Parent:WaitForChild("RanchService"))
		local ok, err = RanchService.TryPlacePet(player, petId)
		if not ok then
			return false, err or "No ranch slot"
		end
		return true, nil
	end
	return false, "Unknown reward"
end

function BattlePassService.InitPlayer(player: Player)
	ensure(player)
end

function BattlePassService.ApplyProgress(player: Player, data: {
	seasonId: number?,
	xp: number?,
	tier: number?,
	premium: boolean?,
	claimedFree: { [number]: boolean }?,
	claimedPremium: { [number]: boolean }?,
})
	local claimedFree: { [number]: boolean } = {}
	local claimedPremium: { [number]: boolean } = {}
	if data.claimedFree then
		for k, v in data.claimedFree do
			if v then
				claimedFree[k] = true
			end
		end
	end
	if data.claimedPremium then
		for k, v in data.claimedPremium do
			if v then
				claimedPremium[k] = true
			end
		end
	end
	local xp = data.xp or 0
	progress[player.UserId] = {
		seasonId = data.seasonId or SEASON_ID,
		xp = xp,
		tier = tierFromXp(xp),
		premium = data.premium == true,
		claimedFree = claimedFree,
		claimedPremium = claimedPremium,
	}
	if data.premium then
		Monetization.GrantFlag(player, "BattlePass")
	end
end

function BattlePassService.SetPremium(player: Player, enabled: boolean)
	local p = ensure(player)
	p.premium = enabled
	if enabled then
		Monetization.GrantFlag(player, "BattlePass")
	end
	notifyDirty(player)
end

function BattlePassService.HasPremium(player: Player): boolean
	return ensure(player).premium or Monetization.Has(player, "BattlePass")
end

function BattlePassService.AddXp(player: Player, amount: number, _source: string?): number
	if typeof(amount) ~= "number" or amount <= 0 then
		return ensure(player).xp
	end
	local p = ensure(player)
	p.xp += math.floor(amount)
	p.tier = tierFromXp(p.xp)
	notifyDirty(player)
	return p.xp
end

function BattlePassService.GetXp(player: Player): number
	return ensure(player).xp
end

function BattlePassService.GetLevel(player: Player): number
	return math.max(1, ensure(player).tier)
end

function BattlePassService.GetProgress(player: Player): Progress
	local p = ensure(player)
	return {
		seasonId = p.seasonId,
		xp = p.xp,
		tier = p.tier,
		premium = BattlePassService.HasPremium(player),
		claimedFree = table.clone(p.claimedFree),
		claimedPremium = table.clone(p.claimedPremium),
	}
end

function BattlePassService.GetTier(player: Player): number
	return ensure(player).tier
end

function BattlePassService.GetTierReward(tier: number, track: "free" | "premium"): TierReward?
	if tier < 1 or tier > MAX_TIER then
		return nil
	end
	if track == "free" then
		return FREE[tier]
	end
	return PREMIUM[tier]
end

--- Claim by explicit tier + track (preferred).
function BattlePassService.TryClaimTier(player: Player, tierOrTrack: number | string, trackMaybe: ("free" | "premium")?): (boolean, string?)
	-- Compat: TryClaimTier(player, "free"|"premium") claims next sequential tier
	if typeof(tierOrTrack) == "string" then
		local track = tierOrTrack :: string
		if track ~= "free" and track ~= "premium" then
			return false, "Bad track"
		end
		local p = ensure(player)
		if track == "premium" and not BattlePassService.HasPremium(player) then
			return false, "Premium required"
		end
		local claimed = if track == "free" then p.claimedFree else p.claimedPremium
		local nextTier = 1
		for i = 1, MAX_TIER do
			if not claimed[i] then
				nextTier = i
				break
			end
			if i == MAX_TIER then
				return false, "Nothing to claim"
			end
		end
		if p.tier < nextTier then
			return false, "Tier locked"
		end
		local reward = BattlePassService.GetTierReward(nextTier, track :: any)
		if not reward then
			return false, "No reward"
		end
		local ok, err = grant(player, reward)
		if not ok then
			return false, err
		end
		claimed[nextTier] = true
		notifyDirty(player)
		return true, reward.label
	end

	local tier = tierOrTrack :: number
	local track = trackMaybe
	if typeof(tier) ~= "number" or typeof(track) ~= "string" then
		return false, "Bad args"
	end
	tier = math.floor(tier)
	if tier < 1 or tier > MAX_TIER then
		return false, "Invalid tier"
	end
	if track ~= "free" and track ~= "premium" then
		return false, "Invalid track"
	end

	local p = ensure(player)
	if p.tier < tier then
		return false, "Tier locked"
	end
	if track == "premium" and not BattlePassService.HasPremium(player) then
		return false, "Premium required"
	end

	local claimed = if track == "free" then p.claimedFree else p.claimedPremium
	if claimed[tier] then
		return false, "Already claimed"
	end

	local reward = BattlePassService.GetTierReward(tier, track)
	if not reward then
		return false, "No reward"
	end

	local ok, err = grant(player, reward)
	if not ok then
		return false, err
	end
	claimed[tier] = true
	notifyDirty(player)
	return true, reward.label
end

BattlePassService.XP = {
	StealDeposit = 25,
	Rebirth = 80,
	AuraPodium1 = 60,
	AuraPodium2 = 40,
	AuraPodium3 = 25,
}

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	task.defer(function()
		if Players:GetPlayerByUserId(userId) then
			return
		end
		progress[userId] = nil
	end)
end)

return BattlePassService
