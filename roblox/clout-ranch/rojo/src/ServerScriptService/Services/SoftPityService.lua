--!strict
-- Server ModuleScript: carpet soft pity — after N Commons in a row, force Uncommon+
-- Fair F2P protection (documented in RetentionGDD). No paywall; counter resets on Uncommon+.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local COMMON_STREAK_FORCE = 8 -- after this many Commons, next roll is Uncommon+
local RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Secret" }

do
	local cfgFolder = ReplicatedStorage:FindFirstChild("Config")
	local mod = cfgFolder and cfgFolder:FindFirstChild("SoftPityConfig")
	if mod and mod:IsA("ModuleScript") then
		local ok, cfg = pcall(require, mod)
		if ok and cfg then
			if typeof(cfg.CommonStreakForce) == "number" then
				COMMON_STREAK_FORCE = cfg.CommonStreakForce
			end
			if typeof(cfg.RarityOrder) == "table" then
				RARITY_ORDER = cfg.RarityOrder
			end
		end
	else
		-- TODO: ensure Config/SoftPityConfig is synced via Rojo
	end
end

export type PityState = {
	commonStreak: number,
	forcedNext: boolean,
}

local states: { [number]: PityState } = {}

local SoftPityService = {}

local function getState(player: Player): PityState
	local s = states[player.UserId]
	if not s then
		s = { commonStreak = 0, forcedNext = false }
		states[player.UserId] = s
	end
	return s
end

local function rarityRank(rarity: string): number
	for i, r in RARITY_ORDER do
		if r == rarity then
			return i
		end
	end
	return 1
end

function SoftPityService.GetCommonStreak(player: Player): number
	return getState(player).commonStreak
end

function SoftPityService.GetThreshold(): number
	return COMMON_STREAK_FORCE
end

--- True if the next carpet replacement for this player should be Uncommon+.
function SoftPityService.ShouldForceUncommonPlus(player: Player): boolean
	local s = getState(player)
	return s.forcedNext or s.commonStreak >= COMMON_STREAK_FORCE
end

--- Minimum rarity name when pity is active; nil when normal rolls apply.
function SoftPityService.GetForcedMinRarity(player: Player): string?
	if SoftPityService.ShouldForceUncommonPlus(player) then
		return "Uncommon"
	end
	return nil
end

--- Filter / bump a rolled rarity up to at least minRarity.
function SoftPityService.ClampRarity(rarity: string, minRarity: string): string
	if rarityRank(rarity) < rarityRank(minRarity) then
		return minRarity
	end
	return rarity
end

--- Record the outcome of a player-facing carpet roll (replacement after buy).
--- Call AFTER the pet rarity is finalized.
function SoftPityService.RecordOutcome(player: Player, rarity: string)
	local s = getState(player)
	if rarity == "Common" then
		s.commonStreak += 1
		s.forcedNext = s.commonStreak >= COMMON_STREAK_FORCE
	else
		s.commonStreak = 0
		s.forcedNext = false
	end
	SoftPityService.Replicate(player)
end

function SoftPityService.Replicate(player: Player)
	local folder = player:FindFirstChild("CloutStats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "CloutStats"
		folder.Parent = player
	end
	local streak = folder:FindFirstChild("PityCommonStreak")
	if not streak then
		streak = Instance.new("IntValue")
		streak.Name = "PityCommonStreak"
		streak.Parent = folder
	end
	if streak:IsA("IntValue") then
		streak.Value = getState(player).commonStreak
	end
end

function SoftPityService.InitPlayer(player: Player)
	getState(player)
	SoftPityService.Replicate(player)
end

Players.PlayerRemoving:Connect(function(player)
	states[player.UserId] = nil
end)

return SoftPityService
