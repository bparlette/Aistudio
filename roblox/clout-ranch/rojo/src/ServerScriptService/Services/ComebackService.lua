--!strict
-- Server ModuleScript: welcome-back bundle after 48h+ absence
-- Eligibility once per return gap; soft Feedback toast (no dark patterns / fake urgency).

local Players = game:GetService("Players")

local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local LuckService = require(script.Parent:WaitForChild("LuckService"))
local FeedbackService = require(script.Parent:WaitForChild("FeedbackService"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))

local COMEBACK_GAP_SEC = 48 * 3600
local BUNDLE_CASH = 400
local BUNDLE_LUCK_MULT = 1.35
local BUNDLE_LUCK_MINUTES = 20

export type ComebackState = {
	eligible: boolean,
	granted: boolean, -- granted this return session
	gapSec: number,
}

local states: { [number]: ComebackState } = {}

local ComebackService = {}

local function ensureStats(player: Player)
	local folder = player:FindFirstChild("CloutStats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "CloutStats"
		folder.Parent = player
	end
	local lastSeen = folder:FindFirstChild("LastSeen")
	if not lastSeen then
		lastSeen = Instance.new("IntValue")
		lastSeen.Name = "LastSeen"
		lastSeen.Parent = folder
	end
	local eligible = folder:FindFirstChild("ComebackEligible")
	if not eligible then
		eligible = Instance.new("BoolValue")
		eligible.Name = "ComebackEligible"
		eligible.Parent = folder
	end
	return folder :: Folder, lastSeen :: IntValue, eligible :: BoolValue
end

local function syncReplicated(player: Player, state: ComebackState)
	local _, lastSeenVal, eligibleVal = ensureStats(player)
	local mem = SessionService.GetLastSeenUnix(player)
	if mem then
		lastSeenVal.Value = mem
	end
	eligibleVal.Value = state.eligible and not state.granted
end

function ComebackService.InitPlayer(player: Player)
	local uid = player.UserId
	-- Idempotent: Bootstrap may call setupPlayer twice for late joiners
	if states[uid] then
		syncReplicated(player, states[uid])
		return
	end

	local now = os.time()
	local previous = SessionService.GetLastSeenUnix(player)
	local gap = 0
	local eligible = false

	if previous and previous > 0 then
		gap = math.max(0, now - previous)
		eligible = gap >= COMEBACK_GAP_SEC
	end

	-- Mark join as seen (also updates IntValue via SessionService hook)
	SessionService.TouchLastSeen(player)

	local state: ComebackState = {
		eligible = eligible,
		granted = false,
		gapSec = gap,
	}
	states[uid] = state
	syncReplicated(player, state)

	if eligible then
		-- Soft prompt only — grant once via TryGrant (auto on join is fine + ethical)
		task.defer(function()
			if player.Parent then
				local hours = math.floor(gap / 3600)
				FeedbackService.Tell(
					player,
					string.format("Welcome back! (%dh away) — Comeback bundle ready.", hours),
					"clout"
				)
				ComebackService.TryGrant(player)
			end
		end)
	end
end

function ComebackService.GetState(player: Player): ComebackState
	local s = states[player.UserId]
	if not s then
		return { eligible = false, granted = false, gapSec = 0 }
	end
	return {
		eligible = s.eligible,
		granted = s.granted,
		gapSec = s.gapSec,
	}
end

--- Grant cash + timed luck once when eligible. Returns false if already granted / not eligible.
function ComebackService.TryGrant(player: Player): (boolean, string?)
	local s = states[player.UserId]
	if not s then
		ComebackService.InitPlayer(player)
		s = states[player.UserId]
	end
	if not s or not s.eligible then
		return false, "Not eligible"
	end
	if s.granted then
		return false, "Already granted"
	end

	s.granted = true
	s.eligible = false
	EconomyService.AddCash(player, BUNDLE_CASH, true) -- comeback grant
	LuckService.AddBoost(player, BUNDLE_LUCK_MULT, BUNDLE_LUCK_MINUTES * 60)
	syncReplicated(player, s)

	FeedbackService.Tell(
		player,
		string.format(
			"Comeback bundle: $%d + %.0f%% luck for %dm. Glad you're here.",
			BUNDLE_CASH,
			(BUNDLE_LUCK_MULT - 1) * 100,
			BUNDLE_LUCK_MINUTES
		),
		"success"
	)
	return true, "Granted"
end

function ComebackService.GetGapThresholdSec(): number
	return COMEBACK_GAP_SEC
end

Players.PlayerRemoving:Connect(function(player)
	-- SessionService already persists LastSeen on leave
	states[player.UserId] = nil
end)

return ComebackService
