--!strict
-- First-session join funnel: auto-open Red Carpet, WORLD beams YOUR RANCH → BUY HERE → STEAL → LOCK → DEPOSIT,
-- sticky next-action chip. Modular — ClientHud mounts once; no new core loop.
-- pre-alpha-onboard-1: verb ladder BUY→STEAL→LOCK→DEPOSIT always readable; carry forces DEPOSIT.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Util = require(script.Parent:WaitForChild("Util"))
local Maid = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Maid"))

local JoinFunnel = {}

export type Handle = {
	Destroy: (self: Handle) -> (),
}

local function findCarpet(): BasePart?
	local carpet = Workspace:FindFirstChild("Carpet")
	if carpet and carpet:IsA("BasePart") then
		return carpet
	end
	return nil
end

local function padsFromPlot(plot: Model): (BasePart?, BasePart?, BasePart?)
	local base = plot.PrimaryPart or plot:FindFirstChild("Base")
	-- recursive: pads may sit under a folder on some map builds
	local lockPad = plot:FindFirstChild("LockPad", true)
	local deposit = plot:FindFirstChild("DepositPad", true)
	local b = if base and base:IsA("BasePart") then base else nil
	local l = if lockPad and lockPad:IsA("BasePart") then lockPad else nil
	local d = if deposit and deposit:IsA("BasePart") then deposit else nil
	return b, l, d
end

-- Prefer owned plot pads. Ranch1 is ONLY for pre-claim (no owned plot).
-- Never beam Ranch1 DepositPad when the player already owns another ranch.
local function findOwnedRanchBase(player: Player): (BasePart?, BasePart?, BasePart?)
	local folder = Workspace:FindFirstChild("Ranches")
	if not folder then
		return nil, nil, nil
	end
	local owned: Model? = nil
	for _, plot in folder:GetChildren() do
		if plot:IsA("Model") then
			local owner = plot:GetAttribute("OwnerUserId")
			if typeof(owner) == "number" and owner == player.UserId then
				owned = plot
				break
			end
		end
	end
	if owned then
		return padsFromPlot(owned)
	end
	-- No owned plot yet — world guide only
	local first = folder:FindFirstChild("Ranch1")
	if first and first:IsA("Model") then
		return padsFromPlot(first)
	end
	return nil, nil, nil
end

local function isCarrying(player: Player): boolean
	local char = player.Character
	if not char then
		return false
	end
	for _, ch in char:GetChildren() do
		if typeof(ch.Name) == "string" and string.sub(ch.Name, 1, 9) == "CarryPet_" then
			return true
		end
	end
	return false
end

local function findStealTarget(): BasePart?
	local folder = Workspace:FindFirstChild("Ranches")
	if not folder then
		return nil
	end
	for _, plot in folder:GetChildren() do
		if plot:IsA("Model") then
			local owner = plot:GetAttribute("OwnerUserId")
			if typeof(owner) == "number" and owner < 0 then
				local slot = plot:FindFirstChild("Slot1")
				if slot and slot:IsA("BasePart") then
					return slot
				end
			end
		end
	end
	return nil
end

local function clearBeams(maidBeams: { Instance })
	for _, b in maidBeams do
		if b and b.Parent then
			b:Destroy()
		end
	end
	table.clear(maidBeams)
end

local function makeBeam(fromPart: BasePart, toPart: BasePart, name: string, c0: Color3, c1: Color3): Beam
	local a0 = fromPart:FindFirstChild(name .. "A0")
	if not a0 then
		a0 = Instance.new("Attachment")
		a0.Name = name .. "A0"
		a0.Parent = fromPart
	end
	local a1 = toPart:FindFirstChild(name .. "A1")
	if not a1 then
		a1 = Instance.new("Attachment")
		a1.Name = name .. "A1"
		a1.Position = Vector3.new(0, 2, 0)
		a1.Parent = toPart
	end
	local beam = Instance.new("Beam")
	beam.Name = name
	beam.Attachment0 = a0 :: Attachment
	beam.Attachment1 = a1 :: Attachment
	beam.FaceCamera = true
	beam.Width0 = 0.6
	beam.Width1 = 1.0
	beam.Color = ColorSequence.new(c0, c1)
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0.4),
	})
	beam.LightEmission = 0.75
	beam.Segments = 14
	beam.Parent = fromPart
	return beam
end

local function ensureWorldArrow(adornee: BasePart, name: string, text: string)
	local host = adornee:FindFirstChild(name)
	if not host then
		host = Instance.new("Part")
		host.Name = name
		host.Size = Vector3.new(1, 1, 1)
		host.Transparency = 1
		host.Anchored = true
		host.CanCollide = false
		host.CFrame = adornee.CFrame * CFrame.new(0, 7, 0)
		host.Parent = adornee
	end
	local bill = host:FindFirstChild("ArrowBill")
	if not bill then
		bill = Instance.new("BillboardGui")
		bill.Name = "ArrowBill"
		bill.Size = UDim2.fromOffset(200, 48)
		bill.AlwaysOnTop = true
		bill.MaxDistance = 220
		bill.Adornee = host
		bill.Parent = host
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Label"
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 22
		lbl.TextColor3 = Theme.Colors.Gold
		lbl.TextStrokeColor3 = Theme.Colors.NightVoid
		lbl.TextStrokeTransparency = 0.15
		lbl.Text = text
		lbl.Parent = bill
	else
		local lbl = bill:FindFirstChild("Label")
		if lbl and lbl:IsA("TextLabel") then
			lbl.Text = text
		end
	end
	return host
end

function JoinFunnel.mount(
	root: Frame,
	shop: { Open: (self: any) -> (), Refresh: ((self: any) -> ())? }?,
	toast: ((string, string?) -> ())?,
	parentMaid: any?
): Handle
	local maid = Maid.new()
	if parentMaid and typeof(parentMaid.Give) == "function" then
		parentMaid:Give(function()
			maid:DoCleaning()
		end)
	end

	local player = Players.LocalPlayer
	local openedOnce = false
	local liveBeams: { Instance } = {}
	local arrowHosts: { Instance } = {}

	-- Sticky NEXT chip (always on until step 6)
	local chip = Instance.new("Frame")
	chip.Name = "NextActionChip"
	chip.Position = UDim2.new(0, 16, 0, 88)
	chip.Size = UDim2.new(0, 320, 0, 78)
	chip.BackgroundColor3 = Theme.Colors.BgDeep
	chip.BackgroundTransparency = 0.1
	chip.BorderSizePixel = 0
	chip.ZIndex = 25
	chip.Parent = root
	Theme.corner(chip, 12)
	Theme.stroke(chip, Theme.Colors.Gold, 2.5, 0.25)

	local chipTitle = Instance.new("TextLabel")
	chipTitle.Size = UDim2.new(1, -16, 0, 14)
	chipTitle.Position = UDim2.fromOffset(10, 6)
	chipTitle.BackgroundTransparency = 1
	chipTitle.Font = Theme.Fonts.Body
	chipTitle.TextSize = 11
	chipTitle.TextColor3 = Theme.Colors.Gold
	chipTitle.TextXAlignment = Enum.TextXAlignment.Left
	chipTitle.Text = "ONBOARD · NEXT"
	chipTitle.ZIndex = 26
	chipTitle.Parent = chip

	local ladder = Instance.new("TextLabel")
	ladder.Name = "VerbLadder"
	ladder.Size = UDim2.new(1, -16, 0, 14)
	ladder.Position = UDim2.fromOffset(10, 20)
	ladder.BackgroundTransparency = 1
	ladder.Font = Theme.Fonts.Mono
	ladder.TextSize = 10
	ladder.TextColor3 = Theme.Colors.Muted
	ladder.TextXAlignment = Enum.TextXAlignment.Left
	ladder.Text = "BUY → STEAL → LOCK → DEPOSIT"
	ladder.ZIndex = 26
	ladder.Parent = chip

	local chipBody = Instance.new("TextLabel")
	chipBody.Name = "Body"
	chipBody.Size = UDim2.new(1, -16, 0, 36)
	chipBody.Position = UDim2.fromOffset(10, 36)
	chipBody.BackgroundTransparency = 1
	chipBody.Font = Theme.Fonts.Title
	chipBody.TextSize = 14
	chipBody.TextColor3 = Theme.Colors.Cream
	chipBody.TextXAlignment = Enum.TextXAlignment.Left
	chipBody.TextWrapped = true
	chipBody.Text = "NEXT: BUY — open Red Carpet"
	chipBody.ZIndex = 26
	chipBody.Parent = chip

	maid:GiveInstance(chip)

	-- Single next-verb copy (carry overrides to DEPOSIT)
	local NEXT_BY_STEP: { [number]: string } = {
		[1] = "NEXT: BUY — follow gold beam to Carpet",
		[2] = "NEXT: BUY — tap a pet on Red Carpet",
		[3] = "NEXT: STEAL — pink STEAL / unlocked Slot",
		[4] = "NEXT: LOCK — purple pad (STEAL→DEPOSIT if carrying)",
		[5] = "NEXT: LOCK then CLAIM DAILY — keep the loop",
		[6] = "Loop live — BUY → STEAL → LOCK → DEPOSIT",
	}

	local LADDER_BY_VERB: { [string]: string } = {
		buy = "BUY → steal → lock → deposit",
		steal = "buy → STEAL → lock → deposit",
		lock = "buy → steal → LOCK → deposit",
		deposit = "buy → steal → lock → DEPOSIT",
		done = "BUY → STEAL → LOCK → DEPOSIT",
	}

	local function stepFromStats(): number
		local folder = player:FindFirstChild("CloutStats")
		local v = folder and folder:FindFirstChild("OnboardingStep")
		if v and (v:IsA("NumberValue") or v:IsA("IntValue")) then
			return (v :: NumberValue).Value
		end
		return 2
	end

	-- Aligned with ActionBar.nextVerb: step 5 = LOCK (CLAIM DAILY is DailyClaim HUD).
	local function activeVerb(step: number, carrying: boolean): string
		if carrying then
			return "deposit"
		end
		if step <= 2 then
			return "buy"
		elseif step == 3 then
			return "steal"
		elseif step == 4 or step == 5 then
			return "lock"
		end
		return "done"
	end

	local function rebuildWorldGuide(step: number, carrying: boolean)
		clearBeams(liveBeams)
		-- arrowHosts retained; labels refreshed via ensureWorldArrow below
		local _ = arrowHosts
		local carpet = findCarpet()
		local ranchBase, lockPad, depositPad = findOwnedRanchBase(player)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp or not hrp:IsA("BasePart") then
			return
		end

		-- Carry always wins: mint beam → DepositPad
		if carrying and depositPad then
			local b = makeBeam(hrp, depositPad, "JoinBeamDeposit", Theme.Colors.Mint, Theme.Colors.Gold)
			table.insert(liveBeams, b)
			maid:GiveInstance(b)
			ensureWorldArrow(depositPad, "JoinArrowDeposit", "▼ DEPOSIT")
			if ranchBase then
				ensureWorldArrow(ranchBase, "JoinArrowRanch", "YOUR RANCH")
			end
			return
		end

		if step <= 2 and carpet then
			local b = makeBeam(hrp, carpet, "JoinBeamBuy", Theme.Colors.Gold, Theme.Colors.HeatPink)
			table.insert(liveBeams, b)
			maid:GiveInstance(b)
			local host = ensureWorldArrow(carpet, "JoinArrowBuy", "▼ BUY HERE")
			table.insert(arrowHosts, host)
			if ranchBase then
				local b2 = makeBeam(ranchBase, carpet, "JoinBeamRanchToBuy", Theme.Colors.Mint, Theme.Colors.Gold)
				table.insert(liveBeams, b2)
				maid:GiveInstance(b2)
				ensureWorldArrow(ranchBase, "JoinArrowRanch", "YOUR RANCH")
			end
		elseif step == 3 then
			local stealTarget = findStealTarget()
			if stealTarget then
				local b = makeBeam(hrp, stealTarget, "JoinBeamSteal", Theme.Colors.HeatPink, Theme.Colors.Gold)
				table.insert(liveBeams, b)
				maid:GiveInstance(b)
				ensureWorldArrow(stealTarget, "JoinArrowSteal", "▼ STEAL")
			end
			if ranchBase then
				ensureWorldArrow(ranchBase, "JoinArrowRanch", "CASH TICKING")
			end
		elseif step == 4 then
			local stealTarget = findStealTarget()
			if lockPad then
				local b = makeBeam(hrp, lockPad, "JoinBeamLock", Theme.Colors.PurpleHot, Theme.Colors.Gold)
				table.insert(liveBeams, b)
				maid:GiveInstance(b)
				ensureWorldArrow(lockPad, "JoinArrowLock", "▼ LOCK")
			end
			if stealTarget then
				local b = makeBeam(hrp, stealTarget, "JoinBeamSteal", Theme.Colors.HeatPink, Theme.Colors.Gold)
				table.insert(liveBeams, b)
				maid:GiveInstance(b)
				ensureWorldArrow(stealTarget, "JoinArrowSteal", "▼ STEAL")
			end
			if depositPad then
				ensureWorldArrow(depositPad, "JoinArrowDeposit", "DEPOSIT PAD")
			end
		else
			clearBeams(liveBeams)
		end
	end

	local function refreshNext()
		local step = stepFromStats()
		local carrying = isCarrying(player)
		local verb = activeVerb(step, carrying)
		local verbLabel = string.upper(if verb == "done" then "LOOP" else verb)
		if carrying then
			chipBody.Text = "NEXT: DEPOSIT — mint pad at YOUR RANCH"
			chipBody.TextColor3 = Theme.Colors.Mint
			chipTitle.Text = "ONBOARD · NEXT → DEPOSIT"
		else
			chipBody.Text = NEXT_BY_STEP[step] or NEXT_BY_STEP[2]
			chipBody.TextColor3 = Theme.Colors.Cream
			chipTitle.Text = "ONBOARD · NEXT → " .. verbLabel
		end
		ladder.Text = LADDER_BY_VERB[verb] or LADDER_BY_VERB.done
		chip.Visible = step < 6 or carrying
		Util.pulse(chip, 1.03)
		rebuildWorldGuide(step, carrying)
	end

	local function tryOpenShop(reason: string)
		if openedOnce and reason == "join" then
			return
		end
		openedOnce = true
		if shop and shop.Open then
			shop:Open()
			if shop.Refresh then
				shop:Refresh()
			end
		end
		if toast then
			toast("✨ Red Carpet open — BUY your first pet!", "buy")
		end
		Util.pulse(chip, 1.08)
		print("[CloutRanch] JoinFunnel auto-open shop:", reason)
	end

	task.spawn(function()
		Util.waitRemotes(20)
		task.wait(1.2)
		if not player.Parent then
			return
		end
		local step = stepFromStats()
		if step <= 2 then
			tryOpenShop("join")
		end
		refreshNext()
	end)

	maid:GiveConnection(player.CharacterAdded:Connect(function(char)
		task.delay(0.5, refreshNext)
		maid:GiveConnection(char.ChildAdded:Connect(function()
			refreshNext()
		end))
		maid:GiveConnection(char.ChildRemoved:Connect(function()
			refreshNext()
		end))
	end))
	if player.Character then
		local char = player.Character
		maid:GiveConnection(char.ChildAdded:Connect(function()
			refreshNext()
		end))
		maid:GiveConnection(char.ChildRemoved:Connect(function()
			refreshNext()
		end))
	end

	local function bindStats(folder: Instance)
		local stepVal = folder:FindFirstChild("OnboardingStep")
		if stepVal and (stepVal:IsA("NumberValue") or stepVal:IsA("IntValue")) then
			refreshNext()
			maid:GiveConnection(stepVal:GetPropertyChangedSignal("Value"):Connect(refreshNext))
		end
		maid:GiveConnection(folder.ChildAdded:Connect(function(ch)
			if ch.Name == "OnboardingStep" then
				refreshNext()
				maid:GiveConnection(ch:GetPropertyChangedSignal("Value"):Connect(refreshNext))
			end
		end))
	end

	local stats = player:FindFirstChild("CloutStats")
	if stats then
		bindStats(stats)
	end
	maid:GiveConnection(player.ChildAdded:Connect(function(c)
		if c.Name == "CloutStats" then
			bindStats(c)
		end
	end))

	task.spawn(function()
		local remotes = Util.waitRemotes(30)
		if not remotes then
			return
		end
		local ev = Util.getRemoteEvent(remotes, "OpenShop")
		if ev then
			maid:GiveConnection(ev.OnClientEvent:Connect(function()
				openedOnce = false
				tryOpenShop("remote")
			end))
		end
	end)

	-- Bob BUY / DEPOSIT arrows
	task.spawn(function()
		while chip.Parent do
			local carpet = findCarpet()
			local host = carpet and carpet:FindFirstChild("JoinArrowBuy")
			if host and host:IsA("BasePart") and carpet then
				local y = 7 + math.sin(os.clock() * 3) * 0.7
				host.CFrame = carpet.CFrame * CFrame.new(0, y, 0)
			end
			local _, _, depositPad = findOwnedRanchBase(player)
			local dHost = depositPad and depositPad:FindFirstChild("JoinArrowDeposit")
			if dHost and dHost:IsA("BasePart") and depositPad then
				local y = 7 + math.sin(os.clock() * 3.2) * 0.7
				dHost.CFrame = depositPad.CFrame * CFrame.new(0, y, 0)
			end
			task.wait(0.05)
		end
	end)

	-- Poll carry state (attach can lag a frame behind steal)
	task.spawn(function()
		while chip.Parent do
			refreshNext()
			task.wait(0.8)
		end
	end)

	chip.BackgroundTransparency = 0.5
	TweenService:Create(chip, TweenInfo.new(0.45), { BackgroundTransparency = 0.1 }):Play()

	return {
		Destroy = function()
			clearBeams(liveBeams)
			maid:DoCleaning()
		end,
	}
end

return JoinFunnel
