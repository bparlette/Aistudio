--!strict
-- Minimal daily quests panel — reads player.CloutQuests, fires ClaimQuest

local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Util = require(script.Parent:WaitForChild("Util"))

local QuestPanel = {}

export type Handle = {
	Destroy: (self: Handle) -> (),
}

local SLOT_COUNT = 3

local function readSlot(folder: Folder?, index: number): (string, number, number, boolean, boolean)
	if not folder then
		return "…", 0, 0, false, false
	end
	local slot = folder:FindFirstChild("Slot" .. index)
	if not slot then
		return "…", 0, 0, false, false
	end
	local label = slot:FindFirstChild("Label")
	local progress = slot:FindFirstChild("Progress")
	local target = slot:FindFirstChild("Target")
	local claimed = slot:FindFirstChild("Claimed")
	local ready = slot:FindFirstChild("Ready")
	local labelText = if label and label:IsA("StringValue") then label.Value else "Quest"
	local p = if progress and progress:IsA("NumberValue") then progress.Value else 0
	local t = if target and target:IsA("NumberValue") then target.Value else 0
	local c = if claimed and claimed:IsA("BoolValue") then claimed.Value else false
	local r = if ready and ready:IsA("BoolValue") then ready.Value else (p >= t and t > 0 and not c)
	return labelText, p, t, c, r
end

function QuestPanel.mount(root: Frame, onToast: ((string) -> ())?): Handle
	local player = Players.LocalPlayer
	local conns: { RBXScriptConnection } = {}

	local panel = Instance.new("Frame")
	panel.Name = "QuestPanel"
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, 12, 0.5, 0)
	panel.Size = UDim2.fromOffset(220, 168)
	panel.BackgroundColor3 = Theme.Colors.BgPanel
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.ZIndex = 8
	panel.Parent = root
	Theme.corner(panel, 12)
	Theme.stroke(panel, Theme.Colors.Purple, 1.5, 0.35)
	Theme.padding(panel, 8)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 20)
	title.BackgroundTransparency = 1
	title.Font = Theme.Fonts.Title
	title.TextSize = 13
	title.TextColor3 = Theme.Colors.PurpleHot
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "📋 DAILY QUESTS"
	title.ZIndex = 9
	title.Parent = panel

	local rows: { TextButton } = {}
	local labels: { TextLabel } = {}

	for i = 1, SLOT_COUNT do
		local row = Instance.new("TextButton")
		row.Name = "Quest" .. i
		row.Position = UDim2.new(0, 0, 0, 24 + (i - 1) * 44)
		row.Size = UDim2.new(1, 0, 0, 40)
		row.BackgroundColor3 = Theme.Colors.BgCard
		row.AutoButtonColor = false
		row.Text = ""
		row.ZIndex = 9
		row.Parent = panel
		Theme.corner(row, 8)
		Theme.stroke(row, Theme.Colors.Stroke, 1, 0.5)

		local lab = Instance.new("TextLabel")
		lab.Name = "Body"
		lab.Size = UDim2.new(1, -8, 1, 0)
		lab.Position = UDim2.fromOffset(4, 0)
		lab.BackgroundTransparency = 1
		lab.Font = Theme.Fonts.Body
		lab.TextSize = 11
		lab.TextColor3 = Theme.Colors.White
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.TextYAlignment = Enum.TextYAlignment.Center
		lab.TextWrapped = true
		lab.Text = "Loading…"
		lab.ZIndex = 10
		lab.Parent = row

		row.MouseButton1Click:Connect(function()
			Util.pulse(row, 1.04)
			local folder = player:FindFirstChild("CloutQuests")
			local _, _, _, claimed, ready = readSlot(folder :: Folder?, i)
			if claimed then
				if onToast then
					onToast("Already claimed")
				end
				return
			end
			if not ready then
				if onToast then
					onToast("Keep going!")
				end
				return
			end
			local remotes = Util.waitRemotes(2)
			if not remotes then
				if onToast then
					onToast("Remotes missing")
				end
				return
			end
			local claim = Util.getRemoteEvent(remotes, "ClaimQuest")
			if not claim then
				if onToast then
					onToast("ClaimQuest missing")
				end
				return
			end
			claim:FireServer(i)
			if onToast then
				onToast("Claiming quest…")
			end
		end)

		table.insert(rows, row)
		table.insert(labels, lab)
	end

	local function refresh()
		local folder = player:FindFirstChild("CloutQuests") :: Folder?
		for i = 1, SLOT_COUNT do
			local labelText, p, t, claimed, ready = readSlot(folder, i)
			local progStr: string
			if t <= 0 then
				progStr = "—"
			elseif t >= 100 then
				progStr = string.format("%d/%d", math.floor(p + 0.5), math.floor(t))
			else
				progStr = string.format("%d/%d", math.floor(p), math.floor(t))
			end
			if claimed then
				labels[i].Text = "✅ " .. labelText
				labels[i].TextColor3 = Theme.Colors.Muted
				rows[i].BackgroundColor3 = Theme.Colors.BgCard
			elseif ready then
				labels[i].Text = string.format("✨ %s  [%s] TAP", labelText, progStr)
				labels[i].TextColor3 = Theme.Colors.Gold
				rows[i].BackgroundColor3 = Theme.Colors.BgCardHover
			else
				labels[i].Text = string.format("%s  [%s]", labelText, progStr)
				labels[i].TextColor3 = Theme.Colors.White
				rows[i].BackgroundColor3 = Theme.Colors.BgCard
			end
		end
	end

	local function wireFolder(folder: Folder)
		table.insert(conns, folder.DescendantAdded:Connect(function()
			refresh()
		end))
		for _, d in folder:GetDescendants() do
			if d:IsA("NumberValue") or d:IsA("StringValue") or d:IsA("BoolValue") or d:IsA("IntValue") then
				table.insert(conns, d:GetPropertyChangedSignal("Value"):Connect(refresh))
			end
		end
		refresh()
	end

	local existing = player:FindFirstChild("CloutQuests")
	if existing and existing:IsA("Folder") then
		wireFolder(existing)
	else
		table.insert(conns, player.ChildAdded:Connect(function(c)
			if c.Name == "CloutQuests" and c:IsA("Folder") then
				wireFolder(c)
			end
		end))
	end
	refresh()

	return {
		Destroy = function()
			for _, c in conns do
				c:Disconnect()
			end
			panel:Destroy()
		end,
	}
end

return QuestPanel
