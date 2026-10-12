--!strict
-- Server ModuleScript: 5-step guided first session (soft guide, never hard-blocks)
-- Steps: 1 claim ranch → 2 buy first pet → 3 earn 10s → 4 steal OR lock → 5 claim daily
-- pre-alpha-onboard-1: toast copy only — mirrors client NEXT verbs BUY→STEAL→LOCK→DEPOSIT.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RanchService = require(script.Parent:WaitForChild("RanchService"))
local FeedbackService = require(script.Parent:WaitForChild("FeedbackService"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))

local STEP_CLAIM_RANCH = 1
local STEP_BUY_PET = 2
local STEP_EARN_10S = 3
local STEP_STEAL_OR_LOCK = 4
local STEP_CLAIM_DAILY = 5
local STEP_DONE = 6

local TOASTS: { [number]: string } = {
	[STEP_CLAIM_RANCH] = "🏡 Ranch claimed — NEXT → BUY on the Red Carpet!",
	[STEP_BUY_PET] = "✨ NEXT → BUY your first pet (Red Carpet / tap BUY).",
	[STEP_EARN_10S] = "💰 Cash ticking — next: STEAL → LOCK → DEPOSIT.",
	[STEP_STEAL_OR_LOCK] = "🔒 NEXT → LOCK (or STEAL→DEPOSIT if carrying)!",
	[STEP_CLAIM_DAILY] = "🎁 NEXT → LOCK · CLAIM DAILY for streak cash!",
	[STEP_DONE] = "🔥 Loop live: BUY → STEAL → LOCK → DEPOSIT!",
}

export type OnboardFlags = {
	claimedRanch: boolean,
	boughtPet: boolean,
	earned10s: boolean,
	stoleOrLocked: boolean,
	claimedDaily: boolean,
	earnStartedAt: number?, -- os.clock when first pet placed
	step: number,
}

local flags: { [number]: OnboardFlags } = {}

local OnboardingService = {}

local function ensureStatsFolder(player: Player): Folder
	local folder = player:FindFirstChild("CloutStats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "CloutStats"
		folder.Parent = player
	end
	return folder :: Folder
end

local function ensureNumber(folder: Folder, name: string, initial: number): NumberValue
	local v = folder:FindFirstChild(name)
	if not v then
		v = Instance.new("NumberValue")
		v.Name = name
		v.Value = initial
		v.Parent = folder
	elseif not v:IsA("NumberValue") then
		v:Destroy()
		v = Instance.new("NumberValue")
		v.Name = name
		v.Value = initial
		v.Parent = folder
	end
	return v :: NumberValue
end

local function ensureBool(folder: Folder, name: string, initial: boolean): BoolValue
	local v = folder:FindFirstChild(name)
	if not v then
		v = Instance.new("BoolValue")
		v.Name = name
		v.Value = initial
		v.Parent = folder
	elseif not v:IsA("BoolValue") then
		v:Destroy()
		v = Instance.new("BoolValue")
		v.Name = name
		v.Value = initial
		v.Parent = folder
	end
	return v :: BoolValue
end

local function replicate(player: Player, f: OnboardFlags)
	local folder = ensureStatsFolder(player)
	ensureNumber(folder, "OnboardingStep", f.step).Value = f.step
	ensureBool(folder, "OnboardClaimedRanch", f.claimedRanch).Value = f.claimedRanch
	ensureBool(folder, "OnboardBoughtPet", f.boughtPet).Value = f.boughtPet
	ensureBool(folder, "OnboardEarned10s", f.earned10s).Value = f.earned10s
	ensureBool(folder, "OnboardStoleOrLocked", f.stoleOrLocked).Value = f.stoleOrLocked
	ensureBool(folder, "OnboardClaimedDaily", f.claimedDaily).Value = f.claimedDaily
end

local function computeStep(f: OnboardFlags): number
	if not f.claimedRanch then
		return STEP_CLAIM_RANCH
	end
	if not f.boughtPet then
		return STEP_BUY_PET
	end
	if not f.earned10s then
		return STEP_EARN_10S
	end
	if not f.stoleOrLocked then
		return STEP_STEAL_OR_LOCK
	end
	if not f.claimedDaily then
		return STEP_CLAIM_DAILY
	end
	return STEP_DONE
end

local function toastStep(player: Player, step: number)
	local msg = TOASTS[step]
	if msg then
		FeedbackService.Tell(player, msg, if step >= STEP_DONE then "clout" else "info")
	end
end

local function advance(player: Player, f: OnboardFlags)
	local prev = f.step
	f.step = computeStep(f)
	replicate(player, f)
	if f.step ~= prev then
		toastStep(player, f.step)
		if f.step >= STEP_DONE then
			SessionService.MarkTutorial(player, "completedIntro")
		end
	end
end

function OnboardingService.GetFlags(player: Player): OnboardFlags
	local f = flags[player.UserId]
	if not f then
		OnboardingService.InitPlayer(player)
		f = flags[player.UserId]
	end
	return f
end

function OnboardingService.GetStep(player: Player): number
	return OnboardingService.GetFlags(player).step
end

function OnboardingService.InitPlayer(player: Player)
	local uid = player.UserId
	if flags[uid] then
		replicate(player, flags[uid])
		return
	end
	local first = SessionService.IsFirstSession(player)
	local f: OnboardFlags = {
		claimedRanch = false,
		boughtPet = false,
		earned10s = false,
		stoleOrLocked = false,
		claimedDaily = false,
		earnStartedAt = nil,
		step = STEP_CLAIM_RANCH,
	}
	-- Returning players on this server: soft-skip guided toasts but keep flags honest
	if not first then
		f.claimedRanch = RanchService.GetByUser(uid) ~= nil
		f.boughtPet = true
		f.earned10s = true
		f.stoleOrLocked = true
		f.claimedDaily = true
		f.step = STEP_DONE
	end
	flags[uid] = f
	replicate(player, f)
	if first then
		task.delay(1.2, function()
			if player.Parent and flags[uid] then
				-- Ranch assign may land in the same frame as Init — re-check
				if RanchService.GetByUser(uid) then
					OnboardingService.NotifyRanchClaimed(player)
				else
					toastStep(player, f.step)
				end
			end
		end)
	end
end

function OnboardingService.NotifyRanchClaimed(player: Player)
	local f = OnboardingService.GetFlags(player)
	if f.claimedRanch then
		return
	end
	f.claimedRanch = true
	advance(player, f)
	-- Auto-open Red Carpet so first action is obvious
	task.delay(0.8, function()
		if not player.Parent then
			return
		end
		local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
		local openShop = remotes and remotes:FindFirstChild("OpenShop")
		if openShop and openShop:IsA("RemoteEvent") then
			openShop:FireClient(player, { open = true, reason = "onboard" })
		end
	end)
end

function OnboardingService.NotifyPetBought(player: Player)
	local f = OnboardingService.GetFlags(player)
	if not f.boughtPet then
		f.boughtPet = true
		if not f.earnStartedAt then
			f.earnStartedAt = os.clock()
		end
		FeedbackService.Tell(player, "🐾 First pet secured — cash is ticking!", "buy")
	end
	advance(player, f)
end

function OnboardingService.NotifyStealOrLock(player: Player)
	local f = OnboardingService.GetFlags(player)
	if not f.stoleOrLocked then
		f.stoleOrLocked = true
	end
	advance(player, f)
end

function OnboardingService.NotifyDailyClaimed(player: Player)
	local f = OnboardingService.GetFlags(player)
	if not f.claimedDaily then
		f.claimedDaily = true
	end
	advance(player, f)
end

--- Soft poll: earn 10s after first pet (income ticking). No permanent block.
function OnboardingService.Tick()
	for uid, f in flags do
		if f.boughtPet and not f.earned10s and f.earnStartedAt then
			if os.clock() - f.earnStartedAt >= 10 then
				local player = Players:GetPlayerByUserId(uid)
				if player then
					f.earned10s = true
					FeedbackService.Tell(player, "💵 10s of drip banked — you're printing!", "buy")
					advance(player, f)
				end
			end
		elseif f.boughtPet and not f.earned10s and not f.earnStartedAt then
			-- Pet may have been placed before notify; start clock once ranch has a pet
			local ranch = RanchService.GetByUser(uid)
			if ranch then
				local hasPet = false
				for i = 1, ranch.maxSlots do
					if ranch.slots[i] then
						hasPet = true
						break
					end
				end
				if hasPet then
					f.earnStartedAt = os.clock()
				end
			end
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	flags[player.UserId] = nil
end)

-- Heartbeat tick for earn-10s (cheap)
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc >= 0.5 then
		acc = 0
		OnboardingService.Tick()
	end
end)

return OnboardingService
