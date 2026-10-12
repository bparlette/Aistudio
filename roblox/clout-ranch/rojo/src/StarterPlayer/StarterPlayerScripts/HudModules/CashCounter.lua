--!strict
-- Animated cash counter — counts up/down when CloutStats.Cash changes

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Util = require(script.Parent:WaitForChild("Util"))
local Maid = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Maid"))

local CashCounter = {}

export type Handle = {
	Destroy: (self: Handle) -> (),
}

function CashCounter.mount(root: Frame, parentMaid: any?): Handle
	local player = Players.LocalPlayer
	local maid = Maid.new()
	if parentMaid and typeof(parentMaid.Give) == "function" then
		parentMaid:Give(function()
			maid:DoCleaning()
		end)
	end

	local wrap = Instance.new("Frame")
	wrap.Name = "CashCounter"
	wrap.Size = UDim2.new(0, 220, 0, 72)
	wrap.Position = UDim2.new(0, 16, 0, 16)
	wrap.BackgroundColor3 = Theme.Colors.BgPanel
	wrap.BorderSizePixel = 0
	wrap.Parent = root
	Theme.corner(wrap, 14)
	Theme.stroke(wrap, Theme.Colors.Gold, 2, 0.35)
	Theme.gradient(wrap, Theme.Colors.BgPanel, Color3.fromRGB(36, 24, 10), 0)

	local tag = Instance.new("TextLabel")
	tag.Size = UDim2.new(1, -20, 0, 18)
	tag.Position = UDim2.fromOffset(12, 8)
	tag.BackgroundTransparency = 1
	tag.Font = Theme.Fonts.Body
	tag.TextSize = 12
	tag.TextColor3 = Theme.Colors.GoldDim
	tag.TextXAlignment = Enum.TextXAlignment.Left
	tag.Text = "CASH"
	tag.Parent = wrap

	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.Size = UDim2.new(1, -20, 0, 28)
	amount.Position = UDim2.fromOffset(12, 24)
	amount.BackgroundTransparency = 1
	amount.Font = Theme.Fonts.Title
	amount.TextSize = 26
	amount.TextColor3 = Theme.Colors.Gold
	amount.TextXAlignment = Enum.TextXAlignment.Left
	amount.Text = "$0"
	amount.Parent = wrap

	local rateLbl = Instance.new("TextLabel")
	rateLbl.Name = "IncomeRate"
	rateLbl.Size = UDim2.new(1, -20, 0, 14)
	rateLbl.Position = UDim2.fromOffset(12, 50)
	rateLbl.BackgroundTransparency = 1
	rateLbl.Font = Theme.Fonts.Body
	rateLbl.TextSize = 12
	rateLbl.TextColor3 = Theme.Colors.Mint
	rateLbl.TextXAlignment = Enum.TextXAlignment.Left
	rateLbl.Text = "+$0/s"
	rateLbl.Parent = wrap

	local deltaFlash = Instance.new("TextLabel")
	deltaFlash.Name = "Delta"
	deltaFlash.Size = UDim2.new(0, 100, 0, 22)
	deltaFlash.Position = UDim2.new(1, -110, 0, 8)
	deltaFlash.BackgroundTransparency = 1
	deltaFlash.Font = Theme.Fonts.Body
	deltaFlash.TextSize = 14
	deltaFlash.TextColor3 = Theme.Colors.Mint
	deltaFlash.TextXAlignment = Enum.TextXAlignment.Right
	deltaFlash.TextTransparency = 1
	deltaFlash.Text = ""
	deltaFlash.Parent = wrap

	local displayed = 0
	local target = 0
	local cashConn: RBXScriptConnection?

	local function flashDelta(d: number)
		if math.abs(d) < 0.5 then
			return
		end
		deltaFlash.Text = (d >= 0 and "+" or "") .. Theme.formatCash(d):gsub("%$", "")
		deltaFlash.TextColor3 = if d >= 0 then Theme.Colors.Mint else Theme.Colors.Danger
		deltaFlash.TextTransparency = 0
		deltaFlash.Position = UDim2.new(1, -110, 0, 8)
		Util.tween(deltaFlash, 0.9, {
			TextTransparency = 1,
			Position = UDim2.new(1, -110, 0, -4),
		})
		Util.tween(amount, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = 30,
		}, function()
			Util.tween(amount, 0.15, { TextSize = 26 })
		end)
	end

	local function setTarget(newVal: number)
		local old = target
		target = newVal
		flashDelta(newVal - old)
	end

	local function bindCash(cash: NumberValue)
		if cashConn then
			cashConn:Disconnect()
			cashConn = nil
		end
		setTarget(cash.Value)
		cashConn = cash:GetPropertyChangedSignal("Value"):Connect(function()
			setTarget(cash.Value)
		end)
		maid:GiveConnection(cashConn)
	end

	local function bindRate(rate: NumberValue)
		local function apply()
			local v = rate.Value
			if v >= 0.5 then
				rateLbl.Text = "+" .. Theme.formatCash(v):gsub("%$", "") .. "/s"
				rateLbl.TextTransparency = 0
			else
				rateLbl.Text = "+$0/s — buy a pet!"
				rateLbl.TextTransparency = 0.15
			end
		end
		apply()
		maid:GiveConnection(rate:GetPropertyChangedSignal("Value"):Connect(apply))
	end

	local function tryBind()
		local folder = player:FindFirstChild("CloutStats")
		if not folder then
			amount.Text = "$…"
			return
		end
		local cash = folder:FindFirstChild("Cash")
		if cash and cash:IsA("NumberValue") then
			bindCash(cash)
		end
		local rate = folder:FindFirstChild("IncomePerSec")
		if rate and rate:IsA("NumberValue") then
			bindRate(rate)
		end
	end

	tryBind()
	maid:GiveConnection(player.ChildAdded:Connect(function(child)
		if child.Name == "CloutStats" then
			task.defer(tryBind)
			maid:GiveConnection(child.ChildAdded:Connect(function(c)
				if c.Name == "Cash" and c:IsA("NumberValue") then
					bindCash(c)
				elseif c.Name == "IncomePerSec" and c:IsA("NumberValue") then
					bindRate(c)
				end
			end))
		end
	end))

	-- Smooth count-up toward target
	maid:GiveConnection(RunService.RenderStepped:Connect(function(dt)
		local diff = target - displayed
		if math.abs(diff) < 0.5 then
			displayed = target
		else
			-- Ease: catch up faster on big jumps
			local speed = math.clamp(math.abs(diff) * 8, 40, 5000)
			displayed += math.sign(diff) * math.min(math.abs(diff), speed * dt)
		end
		amount.Text = Theme.formatCash(displayed)
	end))

	maid:GiveInstance(wrap)

	return {
		Destroy = function()
			maid:DoCleaning()
		end,
	}
end

return CashCounter
