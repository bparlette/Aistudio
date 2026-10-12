--!strict
-- Server ModuleScript: timed luck multipliers for Carpet rarity rolls
-- Boosts stack multiplicatively, hard-capped. Expired entries prune on read.

local Players = game:GetService("Players")

local DEFAULT_LUCK = 1
local MAX_LUCK = 5 -- hard stack cap (product of all active boosts, after clamp)
local MAX_ACTIVE_BOOSTS = 8

export type LuckBoost = {
	mult: number,
	expiresAt: number, -- os.clock()
}

export type LuckState = {
	boosts: { LuckBoost },
}

local states: { [number]: LuckState } = {}

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

local LuckService = {}

local function getState(player: Player): LuckState
	local s = states[player.UserId]
	if not s then
		s = { boosts = {} }
		states[player.UserId] = s
	end
	return s
end

local function prune(state: LuckState, now: number)
	local kept: { LuckBoost } = {}
	for _, b in state.boosts do
		if b.expiresAt > now and b.mult > 1 then
			table.insert(kept, b)
		end
	end
	state.boosts = kept
end

--- Effective luck multiplier (>= 1). Expired boosts are dropped.
function LuckService.GetLuck(player: Player): number
	local state = getState(player)
	local now = os.clock()
	prune(state, now)
	local product = DEFAULT_LUCK
	for _, b in state.boosts do
		product *= b.mult
	end
	return math.clamp(product, DEFAULT_LUCK, MAX_LUCK)
end

--- Stack a timed luck multiplier. durationSec must be > 0; mult must be > 1.
function LuckService.AddBoost(player: Player, mult: number, durationSec: number): boolean
	if typeof(mult) ~= "number" or typeof(durationSec) ~= "number" then
		return false
	end
	if mult <= 1 or durationSec <= 0 then
		return false
	end
	local state = getState(player)
	local now = os.clock()
	prune(state, now)
	if #state.boosts >= MAX_ACTIVE_BOOSTS then
		-- Drop soonest-expiring to make room (FOMO boosts still apply)
		table.sort(state.boosts, function(a, b)
			return a.expiresAt < b.expiresAt
		end)
		table.remove(state.boosts, 1)
	end
	table.insert(state.boosts, {
		mult = math.clamp(mult, 1.05, 3),
		expiresAt = now + durationSec,
	})
	notifyDirty(player)
	return true
end

--- Bias rarity weights toward rarer tiers. Higher luck pulls mass from Common/Uncommon.
--- baseWeights: map rarity -> weight (e.g. CarpetService WEIGHTS). Returns a new table.
function LuckService.ApplyToWeights(baseWeights: { [string]: number }, luck: number): { [string]: number }
	local out: { [string]: number } = {}
	local L = math.max(DEFAULT_LUCK, luck)
	-- Soft rarity tiers: commons shrink, secrets grow with luck
	local bias: { [string]: number } = {
		Common = 1 / L,
		Uncommon = 1 / math.sqrt(L),
		Rare = 1,
		Epic = L,
		Secret = L * L,
	}
	for rarity, w in baseWeights do
		local b = bias[rarity] or 1
		out[rarity] = math.max(0.01, w * b)
	end
	return out
end

--- Convenience: ApplyToWeights using the player's current luck.
function LuckService.ApplyForPlayer(player: Player, baseWeights: { [string]: number }): { [string]: number }
	return LuckService.ApplyToWeights(baseWeights, LuckService.GetLuck(player))
end

--- Remaining seconds on the longest active boost (UI helper). 0 if none.
function LuckService.GetLongestRemaining(player: Player): number
	local state = getState(player)
	local now = os.clock()
	prune(state, now)
	local best = 0
	for _, b in state.boosts do
		best = math.max(best, b.expiresAt - now)
	end
	return best
end


--- Export active boosts as unix-expiry records for DataService.
function LuckService.GetPersistedBoosts(player: Player): { { mult: number, expiresUnix: number } }
	local state = getState(player)
	local nowClock = os.clock()
	prune(state, nowClock)
	local nowUnix = os.time()
	local out = {}
	for _, b in state.boosts do
		local remaining = b.expiresAt - nowClock
		if remaining > 0 then
			table.insert(out, {
				mult = b.mult,
				expiresUnix = nowUnix + math.floor(remaining),
			})
		end
	end
	return out
end

--- Restore boosts from DataService (unix expiry → remaining duration).
function LuckService.ApplyPersistedBoosts(player: Player, boosts: { { mult: number, expiresUnix: number } })
	local state = getState(player)
	state.boosts = {}
	local nowUnix = os.time()
	local nowClock = os.clock()
	for _, b in boosts do
		if typeof(b) == "table" and typeof(b.mult) == "number" and typeof(b.expiresUnix) == "number" then
			local remaining = b.expiresUnix - nowUnix
			if remaining > 0 and b.mult > 1 then
				table.insert(state.boosts, {
					mult = math.clamp(b.mult, 1.05, 3),
					expiresAt = nowClock + remaining,
				})
			end
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	task.defer(function()
		if Players:GetPlayerByUserId(userId) then
			return
		end
		states[userId] = nil
	end)
end)

return LuckService
