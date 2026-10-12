--!strict
-- Big satisfying center feedback for steal / buy / rebirth
-- Prefers Remotes.Feedback (payload {message, tone}) — also accepts ListenFeedback

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Util = require(script.Parent:WaitForChild("Util"))
local Maid = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Maid"))

local FeedbackToast = {}

export type Handle = {
	Show: (self: Handle, text: string, kind: string?) -> (),
	Destroy: (self: Handle) -> (),
}

local TONE_TO_KIND = {
	info = "info",
	success = "buy",
	warn = "error",
	error = "error",
	clout = "rebirth",
	steal = "steal",
	buy = "buy",
	rebirth = "rebirth",
	daily = "daily",
	aura = "aura",
	clip = "clip",
	rare = "rare", -- Rare/Epic/Legendary hatch toast (cosmetic)
	mythic = "mythic",
}

local KIND_COLOR = {
	steal = Theme.Colors.Pink,
	buy = Theme.Colors.Mint,
	rebirth = Theme.Colors.Gold,
	daily = Theme.Colors.PurpleHot,
	aura = Theme.Colors.Purple,
	clip = Theme.Colors.Pink,
	rare = Theme.Colors.Gold, -- Rare/Epic/Legendary hatch (align w/ rare bus tone)
	mythic = Theme.Colors.HeatPink,
	error = Theme.Colors.Danger,
	info = Theme.Colors.White,
	success = Theme.Colors.Mint,
	clout = Theme.Colors.Gold,
}

function FeedbackToast.mount(root: Frame, parentMaid: any?): Handle
	local maid = Maid.new()
	if parentMaid and typeof(parentMaid.Give) == "function" then
		parentMaid:Give(function()
			maid:DoCleaning()
		end)
	end

	local label = Instance.new("TextLabel")
	label.Name = "FeedbackToast"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.38)
	label.Size = UDim2.new(0.9, 0, 0, 72)
	label.BackgroundTransparency = 1
	label.Font = Theme.Fonts.Title
	label.TextSize = 36
	label.TextColor3 = Theme.Colors.Gold
	label.TextStrokeColor3 = Theme.Colors.Shadow
	label.TextStrokeTransparency = 0.4
	label.TextTransparency = 1
	label.Text = ""
	label.ZIndex = 50
	label.Parent = root

	local glow = Instance.new("TextLabel")
	glow.Name = "Glow"
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.38)
	glow.Size = UDim2.new(0.9, 0, 0, 72)
	glow.BackgroundTransparency = 1
	glow.Font = Theme.Fonts.Title
	glow.TextSize = 40
	glow.TextColor3 = Theme.Colors.Purple
	glow.TextTransparency = 1
	glow.Text = ""
	glow.ZIndex = 49
	glow.Parent = root

	local token = 0

	local function show(text: string, kind: string?)
		token += 1
		local my = token
		local color = KIND_COLOR[kind or "info"] or Theme.Colors.White
		label.Text = text
		glow.Text = text
		label.TextColor3 = color
		label.TextTransparency = 0
		label.TextSize = 28
		glow.TextTransparency = 0.55
		glow.TextSize = 32
		label.Position = UDim2.fromScale(0.5, 0.42)
		glow.Position = UDim2.fromScale(0.5, 0.42)

		Util.tween(label, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = 40,
			Position = UDim2.fromScale(0.5, 0.36),
		})
		Util.tween(glow, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = 48,
			Position = UDim2.fromScale(0.5, 0.36),
		})

		task.delay(1.6, function()
			if my ~= token then
				return
			end
			Util.tween(label, 0.45, { TextTransparency = 1, TextSize = 28 })
			Util.tween(glow, 0.45, { TextTransparency = 1 })
		end)
	end

	local function handlePayload(a: any, b: any)
		if typeof(a) == "table" then
			local msg = a.message or a.text or a.Text
			local tone = a.tone or a.kind or a.Kind
			if typeof(msg) == "string" then
				local kind = if typeof(tone) == "string" then (TONE_TO_KIND[tone] or tone) else "info"
				show(msg, kind)
			end
		elseif typeof(a) == "string" then
			local kind = if typeof(b) == "string" then (TONE_TO_KIND[b] or b) else nil
			show(a, kind)
		end
	end

	task.spawn(function()
		local remotes = Util.waitRemotes(30)
		if not remotes then
			return
		end
		local names = { "Feedback", "ListenFeedback" }
		for _, name in names do
			local src: Instance? = remotes:FindFirstChild(name) or ReplicatedStorage:FindFirstChild(name)
			if not src and name == "Feedback" then
				src = remotes:WaitForChild(name, 5)
			end
			if src and src:IsA("RemoteEvent") then
				maid:GiveConnection(src.OnClientEvent:Connect(handlePayload))
			elseif src and src:IsA("BindableEvent") then
				maid:GiveConnection(src.Event:Connect(handlePayload))
			end
		end
		-- listeners bound via maid; warn once if neither remote found
		local hasFb = remotes:FindFirstChild("Feedback") or remotes:FindFirstChild("ListenFeedback")
		if not hasFb then
			warn("[CloutRanch HUD] Feedback remote missing — toasts idle")
		end
	end)

	maid:GiveInstance(label)
	maid:GiveInstance(glow)

	return {
		Show = function(_, text, kind)
			show(text, kind)
		end,
		Destroy = function()
			maid:DoCleaning()
		end,
	}
end

return FeedbackToast
