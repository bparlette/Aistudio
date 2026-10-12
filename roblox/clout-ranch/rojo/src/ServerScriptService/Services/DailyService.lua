--!strict
-- Server ModuleScript: daily login streak (1..7 soft cycle), claimable rewards, one missed-day grace
-- Day keys are UTC midnight buckets via os.time() // 86400 — server authoritative.

local Players = game:GetService("Players")

local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local LuckService = require(script.Parent:WaitForChild("LuckService"))
local AuraService = require(script.Parent:WaitForChild("AuraService"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))

local SECONDS_PER_DAY = 86400
local MAX_STREAK = 7

export type DailyReward = {
	cash: number?,
	luckMult: number?,
	luckMinutes: number?,
	aura: number?,
	label: string,
}

export type DailyState = {
	streak: number, -- 0 = never claimed; 1..7 after claims
	lastClaimDay: number?, -- day key
	graceUsed: boolean, -- once per soft cycle
	claimedToday: boolean,
}

local states: { [number]: DailyState } = {}

local REWARDS: { DailyReward } = {
	{ cash = 100, label = "Day 1 — Pocket Cash" },
	{ luckMult = 1.25, luckMinutes = 15, label = "Day 2 — Carpet Luck" },
	{ cash = 250, label = "Day 3 — Stack Cash" },
	{ aura = 25, label = "Day 4 — Aura Drip" },
	{ cash = 400, luckMult = 1.35, luckMinutes = 20, label = "Day 5 — Flex Pack" },
	{ aura = 40, cash = 200, label = "Day 6 — Clout Mix" },
	{ cash = 1000, luckMult = 1.5, luckMinutes = 30, aura = 75, label = "Day 7 — Weekly Flex" },
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

local DailyService = {}

local function dayKey(unix: number?): number
	return math.floor((unix or os.time()) / SECONDS_PER_DAY)
end

local function getState(player: Player): DailyState
	local s = states[player.UserId]
	if not s then
		s = {
			streak = 0,
			lastClaimDay = nil,
			graceUsed = false,
			claimedToday = false,
		}
		states[player.UserId] = s
	end
	local today = dayKey()
	s.claimedToday = (s.lastClaimDay == today)
	return s
end

local function grantReward(player: Player, reward: DailyReward)
	if reward.cash and reward.cash > 0 then
		EconomyService.AddCash(player, reward.cash)
	end
	if reward.luckMult and reward.luckMinutes and reward.luckMinutes > 0 then
		LuckService.AddBoost(player, reward.luckMult, reward.luckMinutes * 60)
	end
	if reward.aura and reward.aura > 0 then
		AuraService.AddAura(player, reward.aura)
	end
end

local function advanceStreak(current: number): number
	if current >= MAX_STREAK then
		return 1 -- soft cycle restart
	end
	return current + 1
end

--- Restore streak state from DataService.
function DailyService.ApplyState(player: Player, data: { streak: number, lastClaimDay: number?, graceUsed: boolean })
	local today = dayKey()
	states[player.UserId] = {
		streak = data.streak or 0,
		lastClaimDay = data.lastClaimDay,
		graceUsed = data.graceUsed == true,
		claimedToday = (data.lastClaimDay == today),
	}
end

function DailyService.GetStreak(player: Player): number
	return getState(player).streak
end

function DailyService.GetState(player: Player): DailyState
	local s = getState(player)
	return {
		streak = s.streak,
		lastClaimDay = s.lastClaimDay,
		graceUsed = s.graceUsed,
		claimedToday = s.claimedToday,
	}
end

function DailyService.GetNextRewardPreview(player: Player): DailyReward
	local s = getState(player)
	local today = dayKey()
	local nextDay: number
	if s.lastClaimDay == today then
		nextDay = advanceStreak(s.streak)
	elseif s.lastClaimDay == nil then
		nextDay = 1
	elseif s.lastClaimDay == today - 1 then
		nextDay = advanceStreak(s.streak)
	elseif s.lastClaimDay == today - 2 and not s.graceUsed then
		nextDay = advanceStreak(s.streak)
	else
		nextDay = 1
	end
	return REWARDS[nextDay]
end

--- Claim today's streak reward. One grace for a single missed calendar day.
function DailyService.TryClaim(player: Player): (boolean, string?, DailyReward?)
	local s = getState(player)
	local today = dayKey()

	if s.lastClaimDay == today then
		return false, "Already claimed today", nil
	end

	local nextStreak = 1
	local usedGrace = false
	local softCycled = false

	if s.lastClaimDay == nil then
		nextStreak = 1
	elseif s.lastClaimDay == today - 1 then
		nextStreak = advanceStreak(s.streak)
		softCycled = (s.streak >= MAX_STREAK)
	elseif s.lastClaimDay == today - 2 and not s.graceUsed then
		usedGrace = true
		nextStreak = advanceStreak(s.streak)
		softCycled = (s.streak >= MAX_STREAK)
	else
		-- 2+ day miss, or grace already burned — soft reset
		nextStreak = 1
		s.graceUsed = false
	end

	if softCycled then
		s.graceUsed = false -- new 1..7 cycle restores grace
	end
	if usedGrace and not softCycled then
		s.graceUsed = true
	elseif usedGrace and softCycled then
		-- Grace was needed to reach the wrap; restore for the new cycle
		s.graceUsed = false
	end

	local reward = REWARDS[nextStreak]
	if not reward then
		return false, "Bad reward table", nil
	end

	s.streak = nextStreak
	s.lastClaimDay = today
	s.claimedToday = true

	grantReward(player, reward)
	SessionService.NotifyDailyClaimed(player)
	notifyDirty(player)
	local folder = player:FindFirstChild("CloutStats")
	if folder then
		local streakVal = folder:FindFirstChild("DailyStreak")
		if not streakVal then
			streakVal = Instance.new("NumberValue")
			streakVal.Name = "DailyStreak"
			streakVal.Parent = folder
		end
		if streakVal:IsA("NumberValue") then
			streakVal.Value = s.streak
		end
	end

	local msg = reward.label
	if usedGrace then
		msg ..= " (grace used)"
	end
	return true, msg, reward
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

return DailyService
