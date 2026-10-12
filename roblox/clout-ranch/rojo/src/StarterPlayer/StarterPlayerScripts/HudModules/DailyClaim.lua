--!strict
-- Daily claim button + streak display (fires ClaimDaily remote)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Util = require(script.Parent:WaitForChild("Util"))
local Maid = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Maid"))

local DailyClaim = {}

export type Handle = {
	Destroy: (self: Handle) -> (),
}

function DailyClaim.mount(root: Frame, onClaimed: ((string) -> ())?, parentMaid: any?): Handle
	local player = Players.LocalPlayer
	local maid = Maid.new()
	if parentMaid and typeof(parentMaid.Give) == "function" then
		parentMaid:Give(function()
			maid:DoCleaning()
		end)
	end

	local btn = Instance.new("TextButton")
	btn.Name = "DailyClaim"
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.Position = UDim2.new(0.5, 0, 1, -24)
	btn.Size = UDim2.new(0, 260, 0, 56)
	btn.BackgroundColor3 = Theme.Colors.BgCard
	btn.Font = Theme.Fonts.Title
	btn.TextSize = 16
	btn.TextColor3 = Theme.Colors.Gold
	btn.AutoButtonColor = false
	btn.Text = "🎁 CLAIM DAILY"
	btn.Parent = root
	Theme.corner(btn, 14)
	Theme.stroke(btn, Theme.Colors.Gold, 2, 0.25)
	Theme.gradient(btn, Color3.fromRGB(50, 30, 90), Color3.fromRGB(30, 18, 50), 90)

	local streak = Instance.new("TextLabel")
	streak.Name = "Streak"
	streak.AnchorPoint = Vector2.new(0.5, 1)
	streak.Position = UDim2.new(0.5, 0, 1, -84)
	streak.Size = UDim2.new(0, 260, 0, 22)
	streak.BackgroundTransparency = 1
	streak.Font = Theme.Fonts.Body
	streak.TextSize = 13
	streak.TextColor3 = Theme.Colors.Muted
	streak.Text = "Streak: …"
	streak.Parent = root

	local function readStreak()
		local folder = player:FindFirstChild("CloutStats")
		local s = folder and folder:FindFirstChild("DailyStreak")
		if s and (s:IsA("NumberValue") or s:IsA("IntValue")) then
			streak.Text = string.format("🔥 Daily streak: %d", (s :: NumberValue).Value)
		else
			streak.Text = "🔥 Daily streak: — (server: CloutStats.DailyStreak)"
		end
	end

	readStreak()
	maid:GiveConnection(player.ChildAdded:Connect(function(c)
		if c.Name == "CloutStats" then
			readStreak()
			maid:GiveConnection(c.ChildAdded:Connect(function(ch)
				if ch.Name == "DailyStreak" then
					readStreak()
					maid:GiveConnection(ch:GetPropertyChangedSignal("Value"):Connect(readStreak))
				end
			end))
			local existing = c:FindFirstChild("DailyStreak")
			if existing then
				maid:GiveConnection(existing:GetPropertyChangedSignal("Value"):Connect(readStreak))
			end
		end
	end))

	local stats = player:FindFirstChild("CloutStats")
	local streakVal = stats and stats:FindFirstChild("DailyStreak")
	if streakVal then
		maid:GiveConnection(streakVal:GetPropertyChangedSignal("Value"):Connect(readStreak))
	end

	maid:GiveConnection(btn.MouseButton1Click:Connect(function()
		Util.pulse(btn, 1.08)
		local remotes = Util.waitRemotes(2)
		if not remotes then
			if onClaimed then
				onClaimed("Remotes missing")
			end
			return
		end
		local claim = Util.getRemoteEvent(remotes, "ClaimDaily")
		if not claim then
			btn.Text = "⚠ ClaimDaily missing"
			task.delay(1.5, function()
				btn.Text = "🎁 CLAIM DAILY"
			end)
			if onClaimed then
				onClaimed("Server must add ClaimDaily RemoteEvent")
			end
			return
		end
		claim:FireServer()
		btn.Text = "✨ Claimed!"
		task.delay(1.2, function()
			btn.Text = "🎁 CLAIM DAILY"
			readStreak()
		end)
		if onClaimed then
			onClaimed("Daily claim sent")
		end
	end))

	maid:GiveInstance(btn)
	maid:GiveInstance(streak)

	return {
		Destroy = function()
			maid:DoCleaning()
		end,
	}
end

return DailyClaim
