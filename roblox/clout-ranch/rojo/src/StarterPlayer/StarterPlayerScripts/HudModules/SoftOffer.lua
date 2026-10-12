--!strict
-- Soft monetization modal — sole SoftOffer remote owner (Starter / VIP funnel).
-- When Marketplace IDs are 0 (payload.live=false): hide Prompt path, show kid-safe Coming soon.
-- Never invents IDs; never gates BUY/STEAL/LOCK/DEPOSIT; no X/Twitter/TikTok copy.
-- VIP note = lock time only (not idle). SoftFunnel is disabled — do not remount a second listener.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Util = require(script.Parent:WaitForChild("Util"))
local Maid = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Maid"))

local SoftOffer = {}

export type Handle = {
	Show: (self: Handle, payload: any) -> (),
	Hide: (self: Handle) -> (),
	Destroy: (self: Handle) -> (),
}

local AUTO_HIDE_SEC = 8

local function clip(s: string, maxLen: number): string
	if #s <= maxLen then
		return s
	end
	return string.sub(s, 1, maxLen - 1) .. "…"
end

function SoftOffer.mount(root: Frame, onFeedback: ((string, string?) -> ())?, parentMaid: any?): Handle
	local maid = Maid.new()
	if parentMaid and typeof(parentMaid.Give) == "function" then
		parentMaid:Give(function()
			maid:DoCleaning()
		end)
	end

	local dim = Instance.new("TextButton")
	dim.Name = "SoftOfferDim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Theme.Colors.NightVoid
	dim.BackgroundTransparency = 0.45
	dim.BorderSizePixel = 0
	dim.Text = ""
	dim.AutoButtonColor = false
	dim.Visible = false
	dim.ZIndex = 60
	dim.Parent = root

	local panel = Instance.new("Frame")
	panel.Name = "SoftOffer"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.48)
	panel.Size = UDim2.fromOffset(320, 280)
	panel.BackgroundColor3 = Theme.Colors.BgPanel
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ZIndex = 61
	panel.Parent = root
	Theme.corner(panel, 16)
	Theme.stroke(panel, Theme.Colors.Gold, 2, 0.2)
	Theme.gradient(panel, Theme.Colors.BgPanel, Color3.fromRGB(45, 22, 78), 90)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -24, 0, 28)
	title.Position = UDim2.fromOffset(12, 14)
	title.BackgroundTransparency = 1
	title.Font = Theme.Fonts.Title
	title.TextSize = 20
	title.TextColor3 = Theme.Colors.Gold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Offer"
	title.ZIndex = 62
	title.Parent = panel

	local tag = Instance.new("TextLabel")
	tag.Name = "Tag"
	tag.Size = UDim2.new(1, -24, 0, 40)
	tag.Position = UDim2.fromOffset(12, 46)
	tag.BackgroundTransparency = 1
	tag.Font = Theme.Fonts.Body
	tag.TextSize = 13
	tag.TextColor3 = Theme.Colors.Cream
	tag.TextWrapped = true
	tag.TextXAlignment = Enum.TextXAlignment.Left
	tag.TextYAlignment = Enum.TextYAlignment.Top
	tag.Text = ""
	tag.ZIndex = 62
	tag.Parent = panel

	local bullets = Instance.new("TextLabel")
	bullets.Name = "Bullets"
	bullets.Size = UDim2.new(1, -24, 0, 72)
	bullets.Position = UDim2.fromOffset(12, 94)
	bullets.BackgroundTransparency = 1
	bullets.Font = Theme.Fonts.Body
	bullets.TextSize = 13
	bullets.TextColor3 = Theme.Colors.Lilac
	bullets.TextWrapped = true
	bullets.TextXAlignment = Enum.TextXAlignment.Left
	bullets.TextYAlignment = Enum.TextYAlignment.Top
	bullets.Text = ""
	bullets.ZIndex = 62
	bullets.Parent = panel

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -24, 0, 18)
	status.Position = UDim2.fromOffset(12, 172)
	status.BackgroundTransparency = 1
	status.Font = Theme.Fonts.Body
	status.TextSize = 12
	status.TextColor3 = Theme.Colors.Muted
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Text = ""
	status.ZIndex = 62
	status.Parent = panel

	local cta = Instance.new("TextButton")
	cta.Name = "Cta"
	cta.AnchorPoint = Vector2.new(0.5, 1)
	cta.Position = UDim2.new(0.5, 0, 1, -52)
	cta.Size = UDim2.new(1, -24, 0, 40)
	cta.BackgroundColor3 = Theme.Colors.Gold
	cta.Font = Theme.Fonts.Title
	cta.TextSize = 16
	cta.TextColor3 = Theme.Colors.NightVoid
	cta.AutoButtonColor = true
	cta.Text = "Get it"
	cta.ZIndex = 62
	cta.Parent = panel
	Theme.corner(cta, 12)

	local dismiss = Instance.new("TextButton")
	dismiss.Name = "Dismiss"
	dismiss.AnchorPoint = Vector2.new(0.5, 1)
	dismiss.Position = UDim2.new(0.5, 0, 1, -14)
	dismiss.Size = UDim2.new(1, -24, 0, 28)
	dismiss.BackgroundTransparency = 1
	dismiss.Font = Theme.Fonts.Body
	dismiss.TextSize = 13
	dismiss.TextColor3 = Theme.Colors.Muted
	dismiss.AutoButtonColor = false
	dismiss.Text = "Maybe later"
	dismiss.ZIndex = 62
	dismiss.Parent = panel

	local currentSku: string? = nil
	local currentLive = false
	local hideToken = 0

	local function hide()
		hideToken += 1
		panel.Visible = false
		dim.Visible = false
		currentSku = nil
		currentLive = false
	end

	local function show(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		local sku = payload.sku
		if typeof(sku) ~= "string" then
			return
		end
		currentSku = sku
		currentLive = payload.live == true and payload.comingSoon ~= true

		title.Text = clip(if typeof(payload.title) == "string" then payload.title else "Offer", 18)
		tag.Text = clip(if typeof(payload.tag) == "string" then payload.tag else "", 72)

		local lines: { string } = {}
		if typeof(payload.bullets) == "table" then
			for _, b in payload.bullets do
				if typeof(b) == "string" and #lines < 3 then
					table.insert(lines, "• " .. clip(b, 28))
				end
			end
		end
		bullets.Text = table.concat(lines, "\n")

		local priceHint = payload.priceHint
		local priceBit = if typeof(priceHint) == "number" then string.format(" · ~%d R$", priceHint) else ""

		-- VIP = lock time only (never idle cash / never wins)
		local vipNote = if sku == "VIP" then " · Lock time only — not idle" else ""

		if currentLive then
			status.Text = "Ready when you are" .. priceBit .. vipNote
			status.TextColor3 = Theme.Colors.Mint
			cta.Text = clip(if typeof(payload.cta) == "string" then payload.cta else "Get it", 18)
			cta.BackgroundColor3 = Theme.Colors.Gold
			cta.TextColor3 = Theme.Colors.NightVoid
			cta.Active = true
			cta.AutoButtonColor = true
		else
			-- Zero Marketplace IDs: Prompt path hidden/disabled — kid-safe soft CTA
			status.Text = "Coming soon — free loop stays open" .. vipNote
			status.TextColor3 = Theme.Colors.Muted
			cta.Text = "Coming soon"
			cta.BackgroundColor3 = Theme.Colors.BgCard
			cta.TextColor3 = Theme.Colors.Muted
			cta.Active = true -- soft dismiss only; never RequestPurchase / Prompt*
			cta.AutoButtonColor = true
		end

		dismiss.Text = if typeof(payload.dismiss) == "string" then payload.dismiss else "Maybe later"
		panel.Visible = true
		dim.Visible = true
		Util.pulse(panel, 1.04)

		hideToken += 1
		local my = hideToken
		task.delay(AUTO_HIDE_SEC, function()
			if my == hideToken then
				hide()
			end
		end)
	end

	maid:GiveConnection(dismiss.MouseButton1Click:Connect(function()
		hide()
	end))
	maid:GiveConnection(dim.MouseButton1Click:Connect(function()
		hide()
	end))

	maid:GiveConnection(cta.MouseButton1Click:Connect(function()
		if not currentLive or not currentSku then
			-- Soft ack when IDs unset — never Prompt*
			if onFeedback then
				onFeedback("Coming soon — packs open when ready.", "info")
			end
			hide()
			return
		end
		Util.pulse(cta, 1.06)
		local remotes = Util.waitRemotes(2)
		if not remotes then
			if onFeedback then
				onFeedback("Remotes offline", "error")
			end
			return
		end
		local req = Util.getRemoteEvent(remotes, "RequestPurchase")
		if not req then
			if onFeedback then
				onFeedback("Purchase path offline", "error")
			end
			return
		end
		req:FireServer(currentSku)
		hide()
	end))

	-- Sole client listener for Remotes.SoftOffer (SoftFunnel disabled)
	task.spawn(function()
		local remotes = Util.waitRemotes(30)
		if not remotes then
			return
		end
		local ev = Util.getRemoteEvent(remotes, "SoftOffer")
		if not ev then
			ev = remotes:WaitForChild("SoftOffer", 8) :: RemoteEvent?
		end
		if ev and ev:IsA("RemoteEvent") then
			maid:GiveConnection(ev.OnClientEvent:Connect(function(payload: any)
				show(payload)
			end))
		end
	end)

	maid:GiveInstance(dim)
	maid:GiveInstance(panel)

	local handle: Handle = {
		Show = function(_self, payload: any)
			show(payload)
		end,
		Hide = function(_self)
			hide()
		end,
		Destroy = function(_self)
			maid:DoCleaning()
		end,
	}
	return handle
end

return SoftOffer
