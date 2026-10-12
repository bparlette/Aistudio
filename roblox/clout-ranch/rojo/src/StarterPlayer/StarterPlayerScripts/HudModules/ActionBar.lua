--!strict
-- Mobile-friendly big action buttons — density pass: BUY + STEAL + LOCK + DEPOSIT
-- Optimistic micro-juice: Util.pulse + SoundHooksApi.PlayKind BEFORE remote returns.
-- pre-alpha-onboard-1: sticky NextHint + highlight next verb (BUY→STEAL→LOCK→DEPOSIT).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Util = require(script.Parent:WaitForChild("Util"))
local SoundHooksApi = require(script.Parent:WaitForChild("SoundHooksApi"))
local Maid = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Maid"))

local ActionBar = {}

export type Handle = {
	Destroy: (self: Handle) -> (),
}

type ActionDef = {
	id: string,
	label: string,
	color: Color3,
	remote: string?,
	sfx: string?,
	openShop: boolean?,
}

local ACTIONS: { ActionDef } = {
	{ id = "buy", label = "✨ BUY", color = Theme.Colors.Gold, remote = nil, sfx = "buy", openShop = true },
	{ id = "steal", label = "🥷 STEAL", color = Theme.Colors.Pink, remote = "StealClosest", sfx = "steal" },
	{ id = "lock", label = "🔒 LOCK", color = Theme.Colors.Purple, remote = "RequestLock", sfx = "lock" },
	{ id = "deposit", label = "📦 DEPOSIT", color = Theme.Colors.Mint, remote = "DepositPet", sfx = "place" },
}

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

-- Must match NextHint + gold stroke for EVERY onboard step (incl. ≥5).
-- Step 5 copy is LOCK · CLAIM DAILY — highlight LOCK (no daily ActionBar button).
-- Step ≥6 ladder is informational; verb "done" matches no button.
local function nextVerb(step: number, carrying: boolean): string
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

function ActionBar.mount(root: Frame, onFeedback: ((string, string?) -> ())?, parentMaid: any?, shopOpen: (() -> ())?): Handle
	local maid = Maid.new()
	if parentMaid and typeof(parentMaid.Give) == "function" then
		parentMaid:Give(function()
			maid:DoCleaning()
		end)
	end

	local bar = Instance.new("Frame")
	bar.Name = "ActionBar"
	bar.AnchorPoint = Vector2.new(0, 1)
	bar.Position = UDim2.new(0, 16, 1, -24)
	bar.Size = UDim2.new(0, 200, 0, 268)
	bar.BackgroundTransparency = 1
	bar.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 8)
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bar

	local hint = Instance.new("TextLabel")
	hint.Name = "NextHint"
	hint.Size = UDim2.new(1, 0, 0, 32)
	hint.BackgroundColor3 = Theme.Colors.BgDeep
	hint.BackgroundTransparency = 0.15
	hint.Font = Theme.Fonts.Body
	hint.TextSize = 11
	hint.TextColor3 = Theme.Colors.Cream
	hint.Text = "NEXT · BUY"
	hint.LayoutOrder = 0
	hint.Parent = bar
	Theme.corner(hint, 8)
	Theme.stroke(hint, Theme.Colors.Gold, 1.5, 0.45)

	local remotesFolder: Folder? = nil
	task.spawn(function()
		remotesFolder = Util.waitRemotes(30)
	end)

	local player = Players.LocalPlayer
	local buttons: { [string]: TextButton } = {}
	local strokes: { [string]: UIStroke } = {}

	local function refreshHint()
		local folder = player:FindFirstChild("CloutStats")
		local step = 2
		local v = folder and folder:FindFirstChild("OnboardingStep")
		if v and (v:IsA("NumberValue") or v:IsA("IntValue")) then
			step = (v :: NumberValue).Value
		end
		local carrying = isCarrying(player)
		local verb = nextVerb(step, carrying)

		if carrying then
			hint.Text = "NEXT → DEPOSIT"
			hint.TextColor3 = Theme.Colors.Mint
		elseif step <= 2 then
			hint.Text = "NEXT → BUY"
			hint.TextColor3 = Theme.Colors.Gold
		elseif step == 3 then
			hint.Text = "NEXT → STEAL"
			hint.TextColor3 = Theme.Colors.Pink
		elseif step == 4 then
			hint.Text = "NEXT → LOCK"
			hint.TextColor3 = Theme.Colors.PurpleHot
		elseif step == 5 then
			hint.Text = "LOCK · CLAIM DAILY"
			hint.TextColor3 = Theme.Colors.Cream
		else
			hint.Text = "BUY → STEAL → LOCK → DEPOSIT"
			hint.TextColor3 = Theme.Colors.Cream
		end

		for id, btn in buttons do
			local stroke = strokes[id]
			-- Gold stroke only when verb is a real ActionBar id (never fall through to buy on step≥5)
			local active = (verb == "buy" or verb == "steal" or verb == "lock" or verb == "deposit")
				and id == verb
				and step < 6
			if stroke then
				if active then
					stroke.Color = Theme.Colors.Gold
					stroke.Thickness = 3
					stroke.Transparency = 0.1
				else
					stroke.Color = Theme.Colors.White
					stroke.Thickness = 1.5
					stroke.Transparency = 0.55
				end
			end
			if active then
				Util.pulse(btn, 1.05)
			end
		end
	end

	for i, def in ACTIONS do
		local b = Instance.new("TextButton")
		b.Name = def.id
		b.Size = UDim2.new(1, 0, 0, 48)
		b.BackgroundColor3 = def.color
		b.Font = Theme.Fonts.Title
		b.TextSize = 15
		b.AutoButtonColor = false
		b.Text = def.label
		b.LayoutOrder = i
		b.Parent = bar
		Theme.corner(b, 12)
		local stroke = Theme.stroke(b, Theme.Colors.White, 1.5, 0.55)
		buttons[def.id] = b
		strokes[def.id] = stroke
		if def.id == "buy" or def.id == "deposit" then
			b.TextColor3 = Theme.Colors.BgDeep
		else
			b.TextColor3 = Theme.Colors.White
		end

		maid:GiveConnection(b.MouseButton1Click:Connect(function()
			Util.pulse(b, 1.07)
			if def.sfx then
				SoundHooksApi.PlayKind(def.sfx)
			end
			if def.openShop then
				if shopOpen then
					shopOpen()
				end
				if onFeedback then
					onFeedback("Red Carpet open — pick a pet!", "buy")
				end
				return
			end
			local remotes = remotesFolder or Util.waitRemotes(2)
			if not remotes then
				if onFeedback then
					onFeedback("Remotes offline", "error")
				end
				return
			end
			local r = Util.getRemoteEvent(remotes, def.remote :: string)
			if not r then
				if onFeedback then
					onFeedback((def.remote or "?") .. " missing", "error")
				end
				return
			end
			r:FireServer()
			if def.id == "steal" and onFeedback then
				onFeedback("Looking for prey…", "steal")
			elseif def.id == "lock" and onFeedback then
				onFeedback("Ranch locked", "info")
			elseif def.id == "deposit" and onFeedback then
				onFeedback("Depositing at your ranch…", "info")
			end
			task.defer(refreshHint)
		end))
	end

	refreshHint()
	task.spawn(function()
		while bar.Parent do
			refreshHint()
			task.wait(0.75)
		end
	end)

	maid:GiveConnection(player.CharacterAdded:Connect(function(char)
		task.delay(0.3, refreshHint)
		maid:GiveConnection(char.ChildAdded:Connect(function()
			refreshHint()
		end))
		maid:GiveConnection(char.ChildRemoved:Connect(function()
			refreshHint()
		end))
	end))
	if player.Character then
		local char = player.Character
		maid:GiveConnection(char.ChildAdded:Connect(function()
			refreshHint()
		end))
		maid:GiveConnection(char.ChildRemoved:Connect(function()
			refreshHint()
		end))
	end

	maid:GiveInstance(bar)

	return {
		Destroy = function()
			maid:DoCleaning()
		end,
	}
end

return ActionBar
