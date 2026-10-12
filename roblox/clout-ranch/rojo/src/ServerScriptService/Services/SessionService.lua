--!strict
-- Server ModuleScript: session length, tutorial flags, post-daily return bonus, LastSeen
-- Return bonus: income / reward edge for the first RETURN_BONUS_WINDOW after a daily claim.
-- LastSeen: unix seconds in memory + CloutStats.LastSeen IntValue (ComebackService reads gap).

local Players = game:GetService("Players")

local RETURN_BONUS_WINDOW = 600 -- 10 minutes
local RETURN_BONUS_MULT = 1.5

export type TutorialFlags = {
	seenCarpet: boolean,
	seenSteal: boolean,
	seenAura: boolean,
	seenDaily: boolean,
	seenRebirth: boolean,
	completedIntro: boolean,
}

export type SessionState = {
	joinedAt: number, -- os.clock()
	returnBonusUntil: number, -- os.clock(); 0 = inactive
	tutorial: TutorialFlags,
	isFirstSession: boolean,
}

local states: { [number]: SessionState } = {}
local everSeen: { [number]: boolean } = {} -- soft first-time until DataStore; survives rejoin this server
local lastSeenUnix: { [number]: number } = {} -- persists across leave/join on this server

local SessionService = {}

local function defaultTutorial(): TutorialFlags
	return {
		seenCarpet = false,
		seenSteal = false,
		seenAura = false,
		seenDaily = false,
		seenRebirth = false,
		completedIntro = false,
	}
end

local function ensureLastSeenValue(player: Player): IntValue
	local folder = player:FindFirstChild("CloutStats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "CloutStats"
		folder.Parent = player
	end
	local v = folder:FindFirstChild("LastSeen")
	if not v then
		v = Instance.new("IntValue")
		v.Name = "LastSeen"
		v.Parent = folder
	end
	return v :: IntValue
end

--- Write LastSeen = now to memory + IntValue.
function SessionService.TouchLastSeen(player: Player)
	local now = os.time()
	lastSeenUnix[player.UserId] = now
	local v = ensureLastSeenValue(player)
	v.Value = now
end

--- Previous LastSeen unix (before this join's touch), or nil if never seen on this server.
function SessionService.GetLastSeenUnix(player: Player): number?
	local mem = lastSeenUnix[player.UserId]
	if mem and mem > 0 then
		return mem
	end
	local folder = player:FindFirstChild("CloutStats")
	local v = folder and folder:FindFirstChild("LastSeen")
	if v and v:IsA("IntValue") and v.Value > 0 then
		return v.Value
	end
	return nil
end

function SessionService.InitPlayer(player: Player)
	local uid = player.UserId
	if states[uid] then
		-- Idempotent: PlayerAdded + Bootstrap both call Init; keep first-session flags
		ensureLastSeenValue(player)
		return
	end
	local first = not everSeen[uid]
	everSeen[uid] = true
	states[uid] = {
		joinedAt = os.clock(),
		returnBonusUntil = 0,
		tutorial = defaultTutorial(),
		isFirstSession = first,
	}
	-- Replicate any prior LastSeen into CloutStats before Comeback reads gap;
	-- ComebackService / Bootstrap call TouchLastSeen after gap check.
	local prior = lastSeenUnix[uid]
	if prior and prior > 0 then
		local v = ensureLastSeenValue(player)
		v.Value = prior
	else
		ensureLastSeenValue(player)
	end
end

local function get(player: Player): SessionState
	local s = states[player.UserId]
	if not s then
		SessionService.InitPlayer(player)
		s = states[player.UserId]
	end
	return s
end

function SessionService.GetState(player: Player): SessionState
	return get(player)
end

--- Seconds in the current server session.
function SessionService.GetSessionLength(player: Player): number
	return math.max(0, os.clock() - get(player).joinedAt)
end

function SessionService.IsFirstSession(player: Player): boolean
	return get(player).isFirstSession
end

function SessionService.GetTutorial(player: Player): TutorialFlags
	return get(player).tutorial
end

--- Mark a tutorial beat. Returns true if this was newly set.
function SessionService.MarkTutorial(player: Player, key: string): boolean
	local t = get(player).tutorial
	if key == "seenCarpet" and not t.seenCarpet then
		t.seenCarpet = true
		return true
	elseif key == "seenSteal" and not t.seenSteal then
		t.seenSteal = true
		return true
	elseif key == "seenAura" and not t.seenAura then
		t.seenAura = true
		return true
	elseif key == "seenDaily" and not t.seenDaily then
		t.seenDaily = true
		return true
	elseif key == "seenRebirth" and not t.seenRebirth then
		t.seenRebirth = true
		return true
	elseif key == "completedIntro" and not t.completedIntro then
		t.completedIntro = true
		return true
	end
	return false
end

--- Called by DailyService.TryClaim after a successful claim.
function SessionService.NotifyDailyClaimed(player: Player)
	local s = get(player)
	s.returnBonusUntil = os.clock() + RETURN_BONUS_WINDOW
	SessionService.MarkTutorial(player, "seenDaily")
end

--- Multiplier for idle income / short live-ops windows. 1 when inactive.
function SessionService.GetReturnBonusMult(player: Player): number
	local s = get(player)
	if s.returnBonusUntil > 0 and os.clock() < s.returnBonusUntil then
		return RETURN_BONUS_MULT
	end
	return 1
end

function SessionService.GetReturnBonusRemaining(player: Player): number
	local s = get(player)
	if s.returnBonusUntil <= 0 then
		return 0
	end
	return math.max(0, s.returnBonusUntil - os.clock())
end

Players.PlayerAdded:Connect(SessionService.InitPlayer)
Players.PlayerRemoving:Connect(function(player)
	SessionService.TouchLastSeen(player)
	states[player.UserId] = nil
	-- everSeen + lastSeenUnix kept for soft first-session / comeback across rejoin on same server
end)

return SessionService
