--!strict
-- Server ModuleScript: Aura Flex rounds every few minutes

local Players = game:GetService("Players")

local ROUND_INTERVAL = 180
local ROUND_DURATION = 20
local PODIUM_HOLD = 8

export type AuraRound = {
	phase: "idle" | "flex" | "podium",
	endsAt: number,
	votes: { [number]: number }, -- targetUserId -> count
	voted: { [number]: boolean }, -- voterUserId
	winners: { number },
}

local aura: { [number]: number } = {} -- userId -> aura currency
local round: AuraRound = {
	phase = "idle",
	endsAt = os.clock() + ROUND_INTERVAL,
	votes = {},
	voted = {},
	winners = {},
}

local AuraService = {}

function AuraService.GetAura(player: Player): number
	return aura[player.UserId] or 0
end

function AuraService.GetRound(): AuraRound
	return round
end

local function resetVotes()
	table.clear(round.votes)
	table.clear(round.voted)
	table.clear(round.winners)
end

local function startFlex()
	round.phase = "flex"
	round.endsAt = os.clock() + ROUND_DURATION
	resetVotes()
end

local function tallyWinners()
	local ranked = {}
	for userId, count in round.votes do
		table.insert(ranked, { userId = userId, count = count })
	end
	table.sort(ranked, function(a, b)
		return a.count > b.count
	end)
	round.winners = {}
	for i = 1, math.min(3, #ranked) do
		local userId = ranked[i].userId
		table.insert(round.winners, userId)
		aura[userId] = (aura[userId] or 0) + (4 - i) * 10
	end
end

local function startPodium()
	tallyWinners()
	round.phase = "podium"
	round.endsAt = os.clock() + PODIUM_HOLD
end

local function startIdle()
	round.phase = "idle"
	round.endsAt = os.clock() + ROUND_INTERVAL
	resetVotes()
end

function AuraService.Vote(voter: Player, targetUserId: number): (boolean, string?)
	if round.phase ~= "flex" then
		return false, "Not flexing"
	end
	if round.voted[voter.UserId] then
		return false, "Already voted"
	end
	if voter.UserId == targetUserId then
		return false, "No self vote"
	end
	if not Players:GetPlayerByUserId(targetUserId) then
		return false, "Gone"
	end
	round.voted[voter.UserId] = true
	round.votes[targetUserId] = (round.votes[targetUserId] or 0) + 1
	return true, nil
end

function AuraService.Tick()
	if os.clock() < round.endsAt then
		return
	end
	if round.phase == "idle" then
		startFlex()
	elseif round.phase == "flex" then
		startPodium()
	else
		startIdle()
	end
end

Players.PlayerRemoving:Connect(function(player)
	aura[player.UserId] = nil
	round.voted[player.UserId] = nil
	round.votes[player.UserId] = nil
end)

return AuraService
