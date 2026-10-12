--!strict
-- Server ModuleScript: ProximityPrompts for Steal / Deposit / Lock / OpenShop
-- Density pass: ≥7-stud slots + rims, 8-stud Deposit/Lock, always-readable prompts + billboards

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local RanchService = require(script.Parent:WaitForChild("RanchService"))
local StealService = require(script.Parent:WaitForChild("StealService"))
local Monetization = require(script.Parent:WaitForChild("Monetization"))

local WorldInteract = {}

local SLOT_SIZE = Vector3.new(7, 0.45, 7)
local ACTION_PAD_SIZE = Vector3.new(8, 0.5, 8)

local SLOT_OFFSETS = {
	Vector3.new(-10, 0.9, 2),
	Vector3.new(0, 0.9, 2),
	Vector3.new(10, 0.9, 2),
	Vector3.new(-5, 0.9, 12),
	Vector3.new(5, 0.9, 12),
}

local GOLD = Color3.fromRGB(245, 200, 75)
local LILAC = Color3.fromRGB(201, 166, 255)
local CREAM = Color3.fromRGB(255, 246, 224)
local MINT = Color3.fromRGB(80, 220, 160)
local PURPLE = Color3.fromRGB(91, 42, 158)
local HEAT = Color3.fromRGB(255, 77, 184)

local wired: { [Instance]: boolean } = {}

local function ensureBillboard(adornee: BasePart, name: string, text: string, studsOffset: Vector3, textSize: number?)
	local existing = adornee:FindFirstChild(name)
	local label: TextLabel?
	if existing and existing:IsA("BillboardGui") then
		label = existing:FindFirstChild("Label") :: TextLabel?
		if label then
			label.Text = text
			return existing
		end
		existing:Destroy()
	elseif existing then
		existing:Destroy()
	end
	local bill = Instance.new("BillboardGui")
	bill.Name = name
	bill.Size = UDim2.fromOffset(240, 40)
	bill.StudsOffset = studsOffset
	bill.AlwaysOnTop = true
	bill.MaxDistance = 140
	bill.Adornee = adornee
	bill.Parent = adornee
	local lbl = Instance.new("TextLabel")
	lbl.Name = "Label"
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = textSize or 20
	lbl.TextColor3 = CREAM
	lbl.TextStrokeColor3 = GOLD
	lbl.TextStrokeTransparency = 0.2
	lbl.Text = text
	lbl.Parent = bill
	return bill
end

local function ensureRim(slot: BasePart, color: Color3)
	local rim = slot:FindFirstChild("Rim")
	if not rim or not rim:IsA("BasePart") then
		if rim then
			rim:Destroy()
		end
		rim = Instance.new("Part")
		rim.Name = "Rim"
		rim.Anchored = true
		rim.CanCollide = false
		rim.Material = Enum.Material.Neon
		rim.Parent = slot
	end
	local r = rim :: BasePart
	r.Size = Vector3.new(slot.Size.X + 0.8, 0.2, slot.Size.Z + 0.8)
	r.Transparency = 0.25
	r.Color = color
	r.CFrame = slot.CFrame * CFrame.new(0, -0.15, 0)
end

local function ensurePrompt(parent: BasePart, name: string, props: { [string]: any }): ProximityPrompt
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("ProximityPrompt") then
		for k, v in props do
			(existing :: any)[k] = v
		end
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local p = Instance.new("ProximityPrompt")
	p.Name = name
	p.MaxActivationDistance = 16
	p.RequiresLineOfSight = false
	p.Style = Enum.ProximityPromptStyle.Default
	p.UIOffset = Vector2.new(0, -40)
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function ensureSlotPart(plot: Model, slotIndex: number): BasePart?
	local base = plot.PrimaryPart or plot:FindFirstChild("Base")
	if not base or not base:IsA("BasePart") then
		return nil
	end
	local name = "Slot" .. tostring(slotIndex)
	local offset = SLOT_OFFSETS[((slotIndex - 1) % #SLOT_OFFSETS) + 1]
	local existing = plot:FindFirstChild(name)
	local part: BasePart
	if existing and existing:IsA("BasePart") then
		part = existing
	else
		if existing then
			existing:Destroy()
		end
		part = Instance.new("Part")
		part.Name = name
		part.Parent = plot
	end
	part.Size = SLOT_SIZE
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 0.35
	part.Material = Enum.Material.Neon
	part.Color = LILAC
	part.CFrame = base.CFrame * CFrame.new(offset)
	part:SetAttribute("SlotIndex", slotIndex)
	part:SetAttribute("PlotName", plot.Name)
	CollectionService:AddTag(part, "CloutSlot")
	ensureRim(part, GOLD)
	ensureBillboard(part, "SlotLabel", "SLOT " .. tostring(slotIndex), Vector3.new(0, 3.2, 0), 18)
	return part
end

local function ensureRanchPads(plot: Model): (BasePart?, BasePart?)
	local base = plot.PrimaryPart or plot:FindFirstChild("Base")
	if not base or not base:IsA("BasePart") then
		return nil, nil
	end

	local function pad(name: string, offset: Vector3, color: Color3, label: string): BasePart
		local existing = plot:FindFirstChild(name)
		local part: BasePart
		if existing and existing:IsA("BasePart") then
			part = existing
		else
			if existing then
				existing:Destroy()
			end
			part = Instance.new("Part")
			part.Name = name
			part.Parent = plot
		end
		part.Size = ACTION_PAD_SIZE
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 0.25
		part.Material = Enum.Material.Neon
		part.Color = color
		part.CFrame = base.CFrame * CFrame.new(offset)
		ensureRim(part, color)
		ensureBillboard(part, name .. "Billboard", label, Vector3.new(0, 4, 0), 20)
		return part
	end

	local deposit = pad("DepositPad", Vector3.new(0, 1.0, -14), MINT, "DEPOSIT")
	local lockPad = pad("LockPad", Vector3.new(14, 1.0, -10), PURPLE, "🔒 LOCK")
	return deposit, lockPad
end

local function refreshSlotBillboard(slotPart: BasePart, plotName: string, slotIndex: number)
	local state = RanchService.GetByPlot(plotName)
	local petId = state and state.slots[slotIndex] or nil
	local isDemo = state and typeof(state.ownerUserId) == "number" and (state.ownerUserId :: number) < 0
	if petId then
		local label = if isDemo then "🥷 STEAL" else "🥷 STEAL"
		ensureBillboard(slotPart, "SlotLabel", label, Vector3.new(0, 3.5, 0), 20)
		slotPart.Color = HEAT
		ensureRim(slotPart, HEAT)
	else
		ensureBillboard(slotPart, "SlotLabel", "SLOT " .. tostring(slotIndex) .. " · EMPTY", Vector3.new(0, 3.2, 0), 16)
		slotPart.Color = LILAC
		ensureRim(slotPart, GOLD)
	end
end

local function wireStealPrompt(slotPart: BasePart)
	if wired[slotPart] then
		-- still refresh labels periodically via Bootstrap refresh
		return
	end
	wired[slotPart] = true
	local plotName = slotPart:GetAttribute("PlotName")
	local slotIndex = slotPart:GetAttribute("SlotIndex")
	if typeof(plotName) ~= "string" or typeof(slotIndex) ~= "number" then
		local parent = slotPart.Parent
		if parent then
			plotName = parent.Name
		end
		local n = tonumber(string.match(slotPart.Name, "%d+"))
		slotIndex = n or 1
	end

	local prompt = ensurePrompt(slotPart, "StealPrompt", {
		ActionText = "Steal",
		ObjectText = "Pet Slot",
		HoldDuration = 0.35,
		KeyboardKeyCode = Enum.KeyCode.E,
		MaxActivationDistance = 18,
	})

	prompt.Triggered:Connect(function(player: Player)
		if typeof(plotName) ~= "string" or typeof(slotIndex) ~= "number" then
			return
		end
		local state = RanchService.GetByPlot(plotName)
		if not state or not state.ownerUserId then
			return
		end
		if state.ownerUserId == player.UserId then
			return
		end
		StealService.TrySteal(player, plotName, slotIndex)
		refreshSlotBillboard(slotPart, plotName, slotIndex)
	end)
end

local function wireOwnRanch(plot: Model)
	local depositPad, lockPad = ensureRanchPads(plot)
	if depositPad and not wired[depositPad] then
		wired[depositPad] = true
		local dep = ensurePrompt(depositPad, "DepositPrompt", {
			ActionText = "Deposit",
			ObjectText = "Your Ranch",
			HoldDuration = 0.2,
			KeyboardKeyCode = Enum.KeyCode.E,
			MaxActivationDistance = 18,
		})
		dep.Triggered:Connect(function(player: Player)
			local state = RanchService.GetByPlot(plot.Name)
			if not state or state.ownerUserId ~= player.UserId then
				return
			end
			StealService.TryDeposit(player)
		end)
	end

	if lockPad and not wired[lockPad] then
		wired[lockPad] = true
		local lp = ensurePrompt(lockPad, "LockPrompt", {
			ActionText = "Lock Ranch",
			ObjectText = "Vault",
			HoldDuration = 0.15,
			KeyboardKeyCode = Enum.KeyCode.F,
			MaxActivationDistance = 18,
		})
		lp.Triggered:Connect(function(player: Player)
			local state = RanchService.GetByPlot(plot.Name)
			if not state or state.ownerUserId ~= player.UserId then
				return
			end
			local vip = Monetization.IsVIP(player)
			local ok, err = RanchService.Lock(player, vip)
			if not ok then
				local fbMod = script.Parent:FindFirstChild("FeedbackService")
				if fbMod then
					local fok, fb = pcall(require, fbMod)
					if fok and fb and fb.Tell then
						fb.Tell(player, err or "Already locked", "warn")
					end
				end
				return
			end
			local Juice = script.Parent:FindFirstChild("JuiceService")
			if Juice then
				local jok, juice = pcall(require, Juice)
				if jok and juice.Lock then
					juice.Lock(player, vip)
				end
			end
			local Onboard = script.Parent:FindFirstChild("OnboardingService")
			if Onboard then
				local ook, ob = pcall(require, Onboard)
				if ook and ob.NotifyStealOrLock then
					ob.NotifyStealOrLock(player)
				end
			end
			local Offer = script.Parent:FindFirstChild("OfferService")
			if Offer then
				local ook, offers = pcall(require, Offer)
				if ook and offers and offers.MarkDopamine then
					offers.MarkDopamine(player, "lock")
				end
			end
		end)
	end
end

local function wireCarpet()
	local carpet = Workspace:FindFirstChild("Carpet")
	if not carpet or not carpet:IsA("BasePart") then
		return
	end
	ensureBillboard(carpet, "CarpetBillboard", "✨ BUY CARPET", Vector3.new(0, 8, 0), 26)

	if wired[carpet] then
		-- Still refresh prompt props if already wired
		ensurePrompt(carpet, "OpenShopPrompt", {
			ActionText = "Open Shop",
			ObjectText = "BUY CARPET",
			HoldDuration = 0,
			MaxActivationDistance = 36,
			KeyboardKeyCode = Enum.KeyCode.E,
			RequiresLineOfSight = false,
			ClickablePrompt = true,
		})
		return
	end
	wired[carpet] = true

	local prompt = ensurePrompt(carpet, "OpenShopPrompt", {
		ActionText = "Open Shop",
		ObjectText = "BUY CARPET",
		HoldDuration = 0,
		MaxActivationDistance = 36,
		KeyboardKeyCode = Enum.KeyCode.E,
		RequiresLineOfSight = false,
		ClickablePrompt = true,
	})

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	local openShop = remotes:FindFirstChild("OpenShop")
	if not openShop then
		openShop = Instance.new("RemoteEvent")
		openShop.Name = "OpenShop"
		openShop.Parent = remotes
	elseif not openShop:IsA("RemoteEvent") then
		openShop:Destroy()
		openShop = Instance.new("RemoteEvent")
		openShop.Name = "OpenShop"
		openShop.Parent = remotes
	end
	local openEv = openShop :: RemoteEvent

	prompt.Triggered:Connect(function(player: Player)
		openEv:FireClient(player, { open = true })
	end)
end

local function wirePlot(plot: Instance)
	if not plot:IsA("Model") then
		return
	end
	if not string.match(plot.Name, "^Ranch%d+$") then
		return
	end
	local maxSlots = 5
	for i = 1, maxSlots do
		local slot = ensureSlotPart(plot, i)
		if slot then
			wireStealPrompt(slot)
			refreshSlotBillboard(slot, plot.Name, i)
		end
	end
	wireOwnRanch(plot)
end

function WorldInteract.RefreshSlotLabels(plotName: string?)
	local folder = Workspace:FindFirstChild("Ranches")
	if not folder then
		return
	end
	for _, plot in folder:GetChildren() do
		if plot:IsA("Model") and string.match(plot.Name, "^Ranch%d+$") then
			if plotName and plot.Name ~= plotName then
				continue
			end
			for i = 1, 5 do
				local slot = plot:FindFirstChild("Slot" .. tostring(i))
				if slot and slot:IsA("BasePart") then
					refreshSlotBillboard(slot, plot.Name, i)
				end
			end
		end
	end
end

--- Idempotent: build slot pads + prompts after MapBootstrap / Ranch bootstrap.
function WorldInteract.Bootstrap()
	local folder = Workspace:FindFirstChild("Ranches")
	if folder then
		for _, plot in folder:GetChildren() do
			wirePlot(plot)
		end
		folder.ChildAdded:Connect(function(child)
			task.defer(wirePlot, child)
		end)
	end
	wireCarpet()
	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "Carpet" and child:IsA("BasePart") then
			task.defer(wireCarpet)
		end
	end)
	task.delay(0.5, wireCarpet)
	task.delay(2, wireCarpet)
	-- Periodic label refresh so STEAL markers light up after demo seed / buys
	task.spawn(function()
		while true do
			task.wait(2)
			WorldInteract.RefreshSlotLabels(nil)
		end
	end)
end

WorldInteract.Build = WorldInteract.Bootstrap

return WorldInteract
