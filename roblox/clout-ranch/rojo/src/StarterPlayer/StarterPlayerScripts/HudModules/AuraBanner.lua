--!strict
-- Aura Flex banner — watches ReplicatedStorage.CloutState.Phase / EndsAt

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Util = require(script.Parent:WaitForChild("Util"))
local Maid = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Maid"))

local AuraBanner = {}

export type Handle = {
	Destroy: (self: Handle) -> (),
}

local PHASE_COPY = {
	idle = nil :: string?,
	flex = "⚡ AURA FLEX — VOTE NOW",
	podium = "🏆 PODIUM — FLEX KINGS",
}

local function soloFlexCopy(): string
	local state = ReplicatedStorage:FindFirstChild("CloutState")
	local riv = state and state:FindFirstChild("RivalUserId")
	if riv then
		return "⚡ AURA FLEX — vote Rival Dummy on stage!"
	end
	return "⚡ AURA FLEX — invite a friend to vote (2P)"
end

-- Fallback durations (seconds) when EndsAt is os.clock()-based and unusable on client
local FALLBACK_DUR = {
	flex = 20,
	podium = 8,
}

function AuraBanner.mount(root: Frame, onFeedback: ((string, string?) -> ())?, parentMaid: any?): Handle
	local banner = Instance.new("Frame")
	banner.Name = "AuraBanner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, -80)
	banner.Size = UDim2.new(0, 460, 0, 68)
	banner.BackgroundColor3 = Theme.Colors.Purple
	banner.BorderSizePixel = 0
	banner.Visible = false
	banner.ZIndex = 40
	banner.Parent = root
	Theme.corner(banner, 14)
	Theme.stroke(banner, Theme.Colors.Gold, 2.5, 0.2)
	Theme.gradient(banner, Color3.fromRGB(120, 50, 220), Color3.fromRGB(40, 10, 80), 0)

	local text = Instance.new("TextLabel")
	text.Name = "Label"
	text.Size = UDim2.new(1, -24, 0, 34)
	text.Position = UDim2.fromOffset(12, 6)
	text.BackgroundTransparency = 1
	text.Font = Theme.Fonts.Title
	text.TextSize = 22
	text.TextColor3 = Theme.Colors.Gold
	text.Text = ""
	text.ZIndex = 41
	text.Parent = banner

	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.Size = UDim2.new(1, -140, 0, 18)
	timer.Position = UDim2.fromOffset(12, 38)
	timer.BackgroundTransparency = 1
	timer.Font = Theme.Fonts.Body
	timer.TextSize = 13
	timer.TextColor3 = Theme.Colors.White
	timer.Text = ""
	timer.ZIndex = 41
	timer.Parent = banner

	local voteBtn = Instance.new("TextButton")
	voteBtn.Name = "VoteRival"
	voteBtn.AnchorPoint = Vector2.new(1, 0.5)
	voteBtn.Position = UDim2.new(1, -10, 0.5, 8)
	voteBtn.Size = UDim2.fromOffset(110, 36)
	voteBtn.BackgroundColor3 = Theme.Colors.HeatPink
	voteBtn.Font = Theme.Fonts.Title
	voteBtn.TextSize = 13
	voteBtn.TextColor3 = Theme.Colors.White
	voteBtn.Text = "VOTE RIVAL"
	voteBtn.Visible = false
	voteBtn.ZIndex = 42
	voteBtn.Parent = banner
	Theme.corner(voteBtn, 8)
	Theme.stroke(voteBtn, Theme.Colors.Gold, 1.5, 0.3)

	local shown = false
	local localEnds: number? = nil
	local lastPhase = ""
	local maid = Maid.new()
	if parentMaid and typeof(parentMaid.Give) == "function" then
		parentMaid:Give(function()
			maid:DoCleaning()
		end)
	end
	local phaseVal: StringValue? = nil
	local endsVal: NumberValue? = nil

	local function hide()
		if not shown then
			return
		end
		shown = false
		voteBtn.Visible = false
		Util.tween(banner, 0.35, { Position = UDim2.new(0.5, 0, 0, -80) }, function()
			if not shown then
				banner.Visible = false
			end
		end)
	end

	local function show(copy: string)
		banner.Visible = true
		text.Text = copy
		shown = true
		voteBtn.Visible = lastPhase == "flex" or copy:find("FLEX") ~= nil
		banner.Position = UDim2.new(0.5, 0, 0, -80)
		Util.tween(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, 16),
		})
		if onFeedback then
			onFeedback(copy, "aura")
		end
	end

	local function remainingSeconds(): number?
		if endsVal then
			local ends = endsVal.Value
			-- Prefer server-synced unix / GetServerTimeNow style values
			if ends > 1e9 then
				return math.max(0, ends - workspace:GetServerTimeNow())
			end
		end
		if localEnds then
			return math.max(0, localEnds - os.clock())
		end
		return nil
	end

	local function applyPhase(phase: string)
		if phase == lastPhase then
			return
		end
		lastPhase = phase
		local copy = PHASE_COPY[phase]
		if copy then
			if phase == "flex" then
				copy = soloFlexCopy()
				voteBtn.Text = "VOTE RIVAL"
				voteBtn.Active = true
			end
			localEnds = os.clock() + (FALLBACK_DUR[phase] or 15)
			-- If EndsAt looks like absolute time, prefer it
			if endsVal and endsVal.Value > 1e9 then
				localEnds = nil
			end
			show(copy)
		else
			hide()
			localEnds = nil
		end
	end

	local function bindState(folder: Folder)
		phaseVal = folder:FindFirstChild("Phase") :: StringValue?
		endsVal = folder:FindFirstChild("EndsAt") :: NumberValue?
		if phaseVal and phaseVal:IsA("StringValue") then
			applyPhase(phaseVal.Value)
			maid:GiveConnection(phaseVal:GetPropertyChangedSignal("Value"):Connect(function()
				applyPhase(phaseVal.Value)
			end))
		end
		if endsVal and endsVal:IsA("NumberValue") then
			maid:GiveConnection(endsVal:GetPropertyChangedSignal("Value"):Connect(function()
				-- refresh timer source only
			end))
		end
	end

	maid:GiveConnection(voteBtn.MouseButton1Click:Connect(function()
		Util.pulse(voteBtn, 1.06)
		local remotes = Util.waitRemotes(2)
		if not remotes then
			return
		end
		local vote = Util.getRemoteEvent(remotes, "VoteAura")
		if not vote then
			return
		end
		local state = ReplicatedStorage:FindFirstChild("CloutState")
		local riv = state and state:FindFirstChild("RivalUserId")
		local id = if riv and riv:IsA("NumberValue") then riv.Value else -9001
		vote:FireServer(id)
		if onFeedback then
			onFeedback("Voted Rival Dummy!", "aura")
		end
		voteBtn.Text = "VOTED ✓"
		voteBtn.Active = false
	end))

	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild("CloutState", 30)
		if folder and folder:IsA("Folder") then
			bindState(folder)
		else
			warn("[CloutRanch HUD] CloutState missing — aura banner idle")
		end
	end)

	maid:GiveConnection(RunService.RenderStepped:Connect(function()
		if not shown then
			return
		end
		local rem = remainingSeconds()
		if rem ~= nil then
			timer.Text = string.format("%.0fs left", rem)
			if rem <= 0 and lastPhase ~= "idle" then
				-- wait for Phase change from server; soft-hide after grace
			end
		else
			timer.Text = "LIVE"
		end
	end))

	maid:GiveInstance(banner)

	return {
		Destroy = function()
			maid:DoCleaning()
		end,
	}
end

return AuraBanner
