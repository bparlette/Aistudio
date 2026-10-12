--!strict
-- Scrolling steal / slap / aura feed (CloutFeed + FeedEvent)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Util = require(script.Parent:WaitForChild("Util"))
local Maid = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Maid"))

local Killfeed = {}

export type Handle = {
	Destroy: (self: Handle) -> (),
}

local MAX_VISIBLE = 6
local LINE_LIFE = 6

function Killfeed.mount(root: Frame, parentMaid: any?): Handle
	local panel = Instance.new("Frame")
	panel.Name = "Killfeed"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -16, 0, 110)
	panel.Size = UDim2.fromOffset(320, 200)
	panel.BackgroundTransparency = 1
	panel.ZIndex = 15
	panel.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel

	local order = 0
	local maid = Maid.new()
	if parentMaid and typeof(parentMaid.Give) == "function" then
		parentMaid:Give(function()
			maid:DoCleaning()
		end)
	end

	local function push(text: string)
		order += 1
		local myOrder = order
		local row = Instance.new("TextLabel")
		row.Name = "Line"
		row.Size = UDim2.new(1, 0, 0, 22)
		row.BackgroundColor3 = Theme.Colors.BgPanel
		row.BackgroundTransparency = 0.35
		row.Font = Theme.Fonts.Body
		row.TextSize = 13
		row.TextColor3 = Theme.Colors.White
		row.TextXAlignment = Enum.TextXAlignment.Right
		row.Text = text
		row.TextTransparency = 1
		row.LayoutOrder = myOrder
		row.ZIndex = 16
		row.Parent = panel
		Theme.corner(row, 6)
		Theme.padding(row, 4)

		-- pink flash for yeet energy
		if string.find(string.lower(text), "yeet") or string.find(string.lower(text), "yoink") or string.find(string.lower(text), "snatch") then
			row.TextColor3 = Theme.Colors.Pink
		elseif string.find(string.lower(text), "aura") then
			row.TextColor3 = Theme.Colors.PurpleHot
		elseif string.find(string.lower(text), "slap") then
			row.TextColor3 = Theme.Colors.Mint
		end

		Util.tween(row, 0.2, { TextTransparency = 0, BackgroundTransparency = 0.25 })

		-- prune old rows
		local kids = {}
		for _, c in panel:GetChildren() do
			if c:IsA("TextLabel") then
				table.insert(kids, c)
			end
		end
		table.sort(kids, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		while #kids > MAX_VISIBLE do
			local old = table.remove(kids, 1)
			if old then
				old:Destroy()
			end
		end

		task.delay(LINE_LIFE, function()
			if row.Parent then
				Util.tween(row, 0.35, { TextTransparency = 1, BackgroundTransparency = 1 }, function()
					row:Destroy()
				end)
			end
		end)
	end

	task.spawn(function()
		local remotes = Util.waitRemotes(30)
		if remotes then
			local feed = Util.getRemoteEvent(remotes, "FeedEvent")
			if feed then
				maid:GiveConnection(feed.OnClientEvent:Connect(function(line: any)
					if typeof(line) == "string" then
						push(line)
					end
				end))
			end
		end

		local folder = ReplicatedStorage:WaitForChild("CloutFeed", 30)
		if folder and folder:IsA("Folder") then
			-- seed recent lines for late join
			local kids = folder:GetChildren()
			table.sort(kids, function(a, b)
				return a.Name < b.Name
			end)
			local start = math.max(1, #kids - 4)
			for i = start, #kids do
				local sv = kids[i]
				if sv:IsA("StringValue") and #sv.Value > 0 then
					push(sv.Value)
				end
			end
			maid:GiveConnection(folder.ChildAdded:Connect(function(child)
				if child:IsA("StringValue") and #child.Value > 0 then
					-- FeedEvent already pushed live; skip duplicate if remote exists
					if not remotes or not remotes:FindFirstChild("FeedEvent") then
						push(child.Value)
					end
				end
			end))
		end
	end)

	maid:GiveInstance(panel)

	return {
		Destroy = function()
			maid:DoCleaning()
		end,
	}
end

return Killfeed
