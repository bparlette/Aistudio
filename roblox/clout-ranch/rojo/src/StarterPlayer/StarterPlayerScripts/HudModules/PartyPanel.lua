--!strict
-- Minimal Clout Crew party UI: invite / accept / leave + huddle bonus chip

local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Util = require(script.Parent:WaitForChild("Util"))

local PartyPanel = {}

export type Handle = {
	Destroy: (self: Handle) -> (),
}

function PartyPanel.mount(root: Frame, onFeedback: ((string, string?) -> ())?): Handle
	local player = Players.LocalPlayer

	local panel = Instance.new("Frame")
	panel.Name = "PartyPanel"
	panel.AnchorPoint = Vector2.new(0, 0)
	panel.Position = UDim2.new(0, 16, 0, 110)
	panel.Size = UDim2.fromOffset(210, 168)
	panel.BackgroundColor3 = Theme.Colors.BgPanel
	panel.BackgroundTransparency = 0.2
	panel.BorderSizePixel = 0
	panel.ZIndex = 14
	panel.Parent = root
	Theme.corner(panel, 12)
	Theme.stroke(panel, Theme.Colors.Purple, 1.5, 0.35)
	Theme.padding(panel, 10)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 20)
	title.BackgroundTransparency = 1
	title.Font = Theme.Fonts.Title
	title.TextSize = 14
	title.TextColor3 = Theme.Colors.PurpleHot
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "CLOUT CREW"
	title.Parent = panel

	local members = Instance.new("TextLabel")
	members.Name = "Members"
	members.Size = UDim2.new(1, 0, 0, 40)
	members.Position = UDim2.fromOffset(0, 24)
	members.BackgroundTransparency = 1
	members.Font = Theme.Fonts.Body
	members.TextSize = 12
	members.TextColor3 = Theme.Colors.Muted
	members.TextXAlignment = Enum.TextXAlignment.Left
	members.TextYAlignment = Enum.TextYAlignment.Top
	members.TextWrapped = true
	members.Text = "Solo vibes — invite a friend"
	members.Parent = panel

	local bonus = Instance.new("TextLabel")
	bonus.Name = "Bonus"
	bonus.Size = UDim2.new(1, 0, 0, 16)
	bonus.Position = UDim2.fromOffset(0, 66)
	bonus.BackgroundTransparency = 1
	bonus.Font = Theme.Fonts.Body
	bonus.TextSize = 11
	bonus.TextColor3 = Theme.Colors.Mint
	bonus.TextXAlignment = Enum.TextXAlignment.Left
	bonus.Text = ""
	bonus.Parent = panel

	local input = Instance.new("TextBox")
	input.Name = "InviteBox"
	input.Size = UDim2.new(1, 0, 0, 28)
	input.Position = UDim2.fromOffset(0, 88)
	input.BackgroundColor3 = Theme.Colors.BgCard
	input.Font = Theme.Fonts.Mono
	input.TextSize = 13
	input.TextColor3 = Theme.Colors.White
	input.PlaceholderText = "name or userId…"
	input.PlaceholderColor3 = Theme.Colors.Muted
	input.Text = ""
	input.ClearTextOnFocus = false
	input.Parent = panel
	Theme.corner(input, 8)
	Theme.stroke(input, Theme.Colors.Stroke, 1, 0.4)

	local row = Instance.new("Frame")
	row.Name = "Buttons"
	row.Size = UDim2.new(1, 0, 0, 28)
	row.Position = UDim2.fromOffset(0, 122)
	row.BackgroundTransparency = 1
	row.Parent = panel

	local function makeBtn(name: string, text: string, color: Color3, xScale: number, order: number): TextButton
		local b = Instance.new("TextButton")
		b.Name = name
		b.Size = UDim2.new(xScale, -4, 1, 0)
		b.Position = UDim2.new(order * xScale, if order > 0 then 2 else 0, 0, 0)
		b.BackgroundColor3 = color
		b.Font = Theme.Fonts.Title
		b.TextSize = 11
		b.TextColor3 = Theme.Colors.White
		b.Text = text
		b.AutoButtonColor = false
		b.Parent = row
		Theme.corner(b, 8)
		return b
	end

	local inviteBtn = makeBtn("Invite", "INVITE", Theme.Colors.Purple, 0.34, 0)
	local acceptBtn = makeBtn("Accept", "ACCEPT", Theme.Colors.Mint, 0.33, 1)
	acceptBtn.TextColor3 = Theme.Colors.BgDeep
	local leaveBtn = makeBtn("Leave", "LEAVE", Theme.Colors.Danger, 0.33, 2)

	acceptBtn.Visible = false

	local remotesFolder: Folder? = nil
	local connections: { RBXScriptConnection } = {}

	local function fire(remoteName: string, ...: any)
		local remotes = remotesFolder or Util.waitRemotes(2)
		if not remotes then
			if onFeedback then
				onFeedback("Remotes offline", "error")
			end
			return
		end
		local r = Util.getRemoteEvent(remotes, remoteName)
		if not r then
			if onFeedback then
				onFeedback(remoteName .. " missing", "error")
			end
			return
		end
		r:FireServer(...)
	end

	inviteBtn.MouseButton1Click:Connect(function()
		Util.pulse(inviteBtn)
		local q = input.Text
		if #q == 0 then
			if onFeedback then
				onFeedback("Type a username", "warn")
			end
			return
		end
		fire("PartyInvite", q)
		input.Text = ""
	end)

	acceptBtn.MouseButton1Click:Connect(function()
		Util.pulse(acceptBtn)
		fire("PartyAccept")
	end)

	leaveBtn.MouseButton1Click:Connect(function()
		Util.pulse(leaveBtn)
		fire("PartyLeave")
	end)

	local function applySync(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		local party = payload.party
		if typeof(party) == "table" and typeof(party.members) == "table" and #party.members > 0 then
			local names = {}
			for _, m in party.members do
				if typeof(m) == "table" and typeof(m.name) == "string" then
					local tag = m.name
					if m.userId == player.UserId then
						tag = tag .. " (you)"
					elseif party.leaderUserId == m.userId then
						tag = tag .. " ★"
					end
					table.insert(names, tag)
				end
			end
			members.Text = table.concat(names, "\n")
			members.TextColor3 = Theme.Colors.White
			title.Text = string.format("CLOUT CREW (%d/4)", #party.members)
		else
			members.Text = "Solo vibes — invite a friend"
			members.TextColor3 = Theme.Colors.Muted
			title.Text = "CLOUT CREW"
		end

		if payload.cashBonusActive then
			bonus.Text = "💰 +10% huddle cash (crew nearby)"
			bonus.TextColor3 = Theme.Colors.Mint
		else
			bonus.Text = "Lock assist +5s when mate nearby"
			bonus.TextColor3 = Theme.Colors.Muted
		end

		local pending = payload.pendingFrom
		if typeof(pending) == "string" and #pending > 0 then
			acceptBtn.Visible = true
			acceptBtn.Text = "JOIN"
			if onFeedback then
				-- soft nudge once per sync with pending is noisy; skip toast
			end
		else
			acceptBtn.Visible = false
		end
	end

	task.spawn(function()
		remotesFolder = Util.waitRemotes(30)
		if not remotesFolder then
			return
		end
		local sync = Util.getRemoteEvent(remotesFolder, "PartySync")
		if sync then
			table.insert(connections, sync.OnClientEvent:Connect(applySync))
		end
	end)

	return {
		Destroy = function()
			for _, c in connections do
				c:Disconnect()
			end
			panel:Destroy()
		end,
	}
end

return PartyPanel
