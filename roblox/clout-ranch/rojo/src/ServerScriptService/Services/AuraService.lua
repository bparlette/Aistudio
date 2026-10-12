--!strict
-- Server ModuleScript: Aura Flex rounds every few minutes

local Players = game:GetService("Players")

local ROUND_INTERVAL = 180
local FIRST_FLEX_IDLE = 45 -- solo density: first Flex within 45s
local ROUND_DURATION = 20
local PODIUM_HOLD = 8
local firstFlexDone = false

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
	endsAt = workspace:GetServerTimeNow() + FIRST_FLEX_IDLE,
	votes = {},
	voted = {},
	winners = {},
}

local function rivalUserId(): number?
	local mod = script.Parent:FindFirstChild("DemoRivalService")
	if mod and mod:IsA("ModuleScript") then
		local ok, demo = pcall(require, mod)
		if ok and demo and demo.GetRivalUserId then
			return demo.GetRivalUserId()
		end
	end
	local state = game:GetService("ReplicatedStorage"):FindFirstChild("CloutState")
	local v = state and state:FindFirstChild("RivalUserId")
	if v and v:IsA("NumberValue") then
		return v.Value
	end
	return -9001
end

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

local AuraService = {}

function AuraService.GetAura(player: Player): number
	return aura[player.UserId] or 0
end

function AuraService.SetAura(player: Player, amount: number)
	aura[player.UserId] = math.max(0, if typeof(amount) == "number" then amount else 0)
end

function AuraService.AddAura(player: Player, amount: number)
	if typeof(amount) ~= "number" or amount == 0 then
		return
	end
	local uid = player.UserId
	aura[uid] = math.max(0, (aura[uid] or 0) + amount)
	local plr = Players:GetPlayerByUserId(uid)
	if plr then
		notifyDirty(plr)
	end
end

function AuraService.GetRound(): AuraRound
	return round
end

local function resetVotes()
	table.clear(round.votes)
	table.clear(round.voted)
	table.clear(round.winners)
end

local function softJuice(fnName: string, ...)
	local mod = script.Parent:FindFirstChild("JuiceService")
	if not mod then
		return
	end
	local ok, juice = pcall(require, mod)
	if ok and juice and juice[fnName] then
		juice[fnName](...)
	end
end

local function startFlex()
	round.phase = "flex"
	round.endsAt = workspace:GetServerTimeNow() + ROUND_DURATION
	resetVotes()
	firstFlexDone = true
	softJuice("FlexShock")
	-- Soft tip for solo: rival dummy is a valid vote target
	for _, plr in Players:GetPlayers() do
		local fb = script.Parent:FindFirstChild("FeedbackService")
		if fb then
			local ok, F = pcall(require, fb)
			if ok and F and F.Tell then
				if #Players:GetPlayers() < 2 then
					F.Tell(plr, "⚡ AURA FLEX — vote the Rival Dummy on stage (or invite a friend)!", "aura")
				end
			end
		end
	end
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
	local podiumXp = { 60, 40, 25 }
	for i = 1, math.min(3, #ranked) do
		local userId = ranked[i].userId
		table.insert(round.winners, userId)
		aura[userId] = (aura[userId] or 0) + (4 - i) * 10
		local plr = Players:GetPlayerByUserId(userId)
		if plr then
			local ok, BPS = pcall(function()
				return require(script.Parent:WaitForChild("BattlePassService"))
			end)
			if ok and BPS then
				BPS.AddXp(plr, podiumXp[i], "AuraPodium")
			end
			local qsMod = script.Parent:FindFirstChild("QuestService")
			if qsMod and qsMod:IsA("ModuleScript") then
				local okQ, QS = pcall(require, qsMod)
				if okQ and QS and QS.Progress then
					QS.Progress(plr, "win_aura", 1)
				end
			end
			local okO, offers = pcall(function()
				return require(script.Parent:WaitForChild("OfferService"))
			end)
			if okO and offers and offers.MarkDopamine then
				offers.MarkDopamine(plr, "podium")
			end
		end
	end
	local kfMod = script.Parent:FindFirstChild("KillfeedService")
	if kfMod and kfMod:IsA("ModuleScript") then
		local ok, KF = pcall(require, kfMod)
		if ok and KF and KF.AnnounceAura then
			KF.AnnounceAura(round.winners)
		end
	end
end

local function startPodium()
	tallyWinners()
	round.phase = "podium"
	round.endsAt = workspace:GetServerTimeNow() + PODIUM_HOLD
	-- Clip bait: podium placements
	local clipMod = script.Parent:FindFirstChild("ClipMomentService")
	if clipMod then
		local ok, Clip = pcall(require, clipMod)
		if ok and Clip and Clip.OnAuraPodium then
			Clip.OnAuraPodium(round.winners)
		end
	end
	softJuice("AuraBeams", round.winners)
	-- Cross-server FOMO for podium #1
	if round.winners[1] then
		local first = Players:GetPlayerByUserId(round.winners[1])
		if first then
			local fomoMod = script.Parent:FindFirstChild("FomoBroadcastService")
			if fomoMod then
				pcall(function()
					local Fomo = require(fomoMod)
					if Fomo and Fomo.OnAuraPodiumFirst then
						Fomo.OnAuraPodiumFirst(first)
					end
				end)
			end
		end
	end
end

local function startIdle()
	round.phase = "idle"
	local waitSec = if firstFlexDone then ROUND_INTERVAL else FIRST_FLEX_IDLE
	round.endsAt = workspace:GetServerTimeNow() + waitSec
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
	local riv = rivalUserId()
	local isRival = riv ~= nil and targetUserId == riv
	if not isRival and not Players:GetPlayerByUserId(targetUserId) then
		return false, "Gone"
	end
	round.voted[voter.UserId] = true
	round.votes[targetUserId] = (round.votes[targetUserId] or 0) + 1
	-- Cosmetic FOV/shake punch (Rival Dummy solo path + 2P votes)
	softJuice("VotePunch", voter, targetUserId, isRival)
	return true, nil
end

--- Force next flex soon (onboarding / solo density). Does not extend endsAt past a live flex.
function AuraService.ForceEarlyFlex(withinSeconds: number?)
	if round.phase ~= "idle" then
		return
	end
	local sec = withinSeconds or 8
	local target = workspace:GetServerTimeNow() + sec
	if round.endsAt > target then
		round.endsAt = target
	end
end

function AuraService.Tick()
	if workspace:GetServerTimeNow() < round.endsAt then
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
	local userId = player.UserId
	round.voted[userId] = nil
	round.votes[userId] = nil
	task.defer(function()
		if Players:GetPlayerByUserId(userId) then
			return
		end
		aura[userId] = nil
	end)
end)

return AuraService
