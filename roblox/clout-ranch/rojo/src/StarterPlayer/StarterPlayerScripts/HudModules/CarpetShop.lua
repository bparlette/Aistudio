--!strict
-- Carpet shop panel — 4 stock slots via GetCarpetStock RemoteFunction
-- Stock cards show pet silhouettes via ViewportFrame + PetFactory.BuildModel

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Util = require(script.Parent:WaitForChild("Util"))
local SoundHooksApi = require(script.Parent:WaitForChild("SoundHooksApi"))

export type StockEntry = {
	id: string,
	name: string,
	rarity: string,
	price: number,
}

local CarpetShop = {}

export type Handle = {
	Refresh: (self: Handle) -> (),
	Open: (self: Handle) -> (),
	Close: (self: Handle) -> (),
	Destroy: (self: Handle) -> (),
}

local REFRESH_EVERY = 2
local ICON_PX = 52

local PetFactoryMod: any = false -- false = not resolved; nil = missing; table = module

local function resolvePetFactory(): any?
	if PetFactoryMod == false then
		local modules = ReplicatedStorage:FindFirstChild("Modules")
		local modScript = if modules then modules:FindFirstChild("PetFactory") else nil
		if modScript then
			local ok, mod = pcall(require, modScript)
			PetFactoryMod = if ok then mod else nil
		else
			PetFactoryMod = nil
		end
	end
	if typeof(PetFactoryMod) == "table" then
		return PetFactoryMod
	end
	return nil
end

local function clearIconHost(host: Frame)
	for _, child in host:GetChildren() do
		if child:IsA("ViewportFrame") or child:IsA("Frame") or child:IsA("ImageLabel") then
			child:Destroy()
		end
	end
end

local function anchorModelParts(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
		elseif d:IsA("ParticleEmitter") then
			-- Keep Secret drip readable but quiet in tiny thumbs
			d.Rate = math.min(d.Rate, 0.8)
		end
	end
end

--- Front-facing camera so Offline Brain eye punches / crack spike read at ~52px.
local function frameModelInViewport(vp: ViewportFrame, model: Model)
	local cam: Camera
	local existing = vp:FindFirstChildOfClass("Camera")
	if existing then
		cam = existing
	else
		cam = Instance.new("Camera")
		cam.Name = "IconCam"
		cam.Parent = vp
	end
	vp.CurrentCamera = cam

	local cf, size = model:GetBoundingBox()
	local maxDim = math.max(size.X, size.Y, size.Z, 0.5)
	-- Slightly closer for Secret skull so sockets punch at stamp size
	local isSkull = model:GetAttribute("Silhouette") == "OfflineBrain"
		or model:GetAttribute("PetId") == "trend_offline_brain"
	local distMul = if isSkull then 1.15 else 1.4
	local distance = maxDim * distMul
	local lookAt = cf.Position + Vector3.new(0, size.Y * 0.02, 0)
	-- +Z is pet front (eyes / face) in PetFactory builds
	cam.CFrame = CFrame.lookAt(lookAt + Vector3.new(0, maxDim * 0.08, distance), lookAt)
	cam.FieldOfView = if isSkull then 38 else 42
end

local function showRarityOrb(host: Frame, rarity: string)
	clearIconHost(host)
	local orb = Instance.new("Frame")
	orb.Name = "RarityOrb"
	orb.Size = UDim2.fromScale(1, 1)
	orb.BackgroundColor3 = Theme.rarityColor(rarity)
	orb.BorderSizePixel = 0
	orb.Parent = host
	Theme.corner(orb, ICON_PX)
	Theme.stroke(orb, Theme.Colors.Gold, 1.5, 0.35)
	-- Soft purple drip underlay
	local glow = Instance.new("Frame")
	glow.Name = "OrbCore"
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.fromScale(0.55, 0.55)
	glow.BackgroundColor3 = Theme.Colors.Cream
	glow.BackgroundTransparency = 0.35
	glow.BorderSizePixel = 0
	glow.Parent = orb
	Theme.corner(glow, ICON_PX)
end

local function showPetIcon(host: Frame, petId: string, rarity: string)
	clearIconHost(host)

	local factory = resolvePetFactory()
	if not factory or typeof(factory.BuildModel) ~= "function" or petId == "" then
		showRarityOrb(host, rarity)
		return
	end

	local ok, modelOrErr = pcall(function()
		return factory.BuildModel(petId)
	end)
	if not ok or typeof(modelOrErr) ~= "Instance" or not modelOrErr:IsA("Model") then
		showRarityOrb(host, rarity)
		return
	end

	local model = modelOrErr :: Model
	if not model.PrimaryPart then
		model:Destroy()
		showRarityOrb(host, rarity)
		return
	end

	anchorModelParts(model)

	local vp = Instance.new("ViewportFrame")
	vp.Name = "PetViewport"
	vp.Size = UDim2.fromScale(1, 1)
	vp.BackgroundColor3 = Theme.Colors.NightVoid
	vp.BackgroundTransparency = 0.15
	vp.BorderSizePixel = 0
	vp.Ambient = Color3.fromRGB(90, 70, 120)
	vp.LightColor = Theme.Colors.Gold
	vp.LightDirection = Vector3.new(-0.4, -1, -0.6)
	vp.Parent = host
	Theme.corner(vp, 10)
	Theme.stroke(vp, Theme.Colors.Gold, 1.25, 0.4)

	local world = Instance.new("WorldModel")
	world.Name = "PetWorld"
	world.Parent = vp

	model.Name = "ShopPet"
	model.Parent = world
	-- Center near origin for predictable framing
	if model.PrimaryPart then
		model:PivotTo(CFrame.new(0, 0, 0))
	end

	frameModelInViewport(vp, model)
end

function CarpetShop.mount(root: Frame, onBuy: (index: number) -> (), feedback: ((string, string?) -> ())?): Handle
	local panel = Instance.new("Frame")
	panel.Name = "CarpetShop"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -16, 0, 16)
	panel.Size = UDim2.new(0, 300, 0, 360)
	panel.Visible = false
	panel.ZIndex = 50
	panel.BackgroundColor3 = Theme.Colors.BgPanel
	panel.BorderSizePixel = 0
	panel.Parent = root
	Theme.corner(panel, 16)
	Theme.stroke(panel, Theme.Colors.Purple, 2, 0.3)
	Theme.gradient(panel, Theme.Colors.BgPanel, Color3.fromRGB(40, 20, 70), 90)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 28)
	title.Position = UDim2.fromOffset(12, 10)
	title.BackgroundTransparency = 1
	title.Font = Theme.Fonts.Title
	title.TextSize = 18
	title.TextColor3 = Theme.Colors.PurpleHot
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "✨ RED CARPET"
	title.Parent = panel

	local featured = Instance.new("TextLabel")
	featured.Name = "FeaturedBanner"
	featured.Size = UDim2.new(1, -24, 0, 18)
	featured.Position = UDim2.fromOffset(12, 34)
	featured.BackgroundTransparency = 1
	featured.Font = Theme.Fonts.Body
	featured.TextSize = 12
	featured.TextColor3 = Theme.Colors.HeatPink
	featured.TextXAlignment = Enum.TextXAlignment.Left
	featured.Text = "TREND · Offline Brain featured"
	featured.Parent = panel

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Status"
	subtitle.Size = UDim2.new(1, -24, 0, 16)
	subtitle.Position = UDim2.fromOffset(12, 50)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Theme.Fonts.Body
	subtitle.TextSize = 11
	subtitle.TextColor3 = Theme.Colors.Muted
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Text = "Loading stock…"
	subtitle.Parent = panel

	local list = Instance.new("Frame")
	list.Name = "Slots"
	list.Position = UDim2.fromOffset(10, 70)
	list.Size = UDim2.new(1, -20, 1, -78)
	list.BackgroundTransparency = 1
	list.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local slots: { Frame } = {}
	local iconHosts: { Frame } = {}
	local nameLabels: { TextLabel } = {}
	local rarityLabels: { TextLabel } = {}
	local buyButtons: { TextButton } = {}

	-- Text starts after icon (6 pad + ICON_PX + 8 gap) = 66; buy reserves ~86 from right
	local textLeft = 6 + ICON_PX + 8
	local textRightReserve = 86

	for i = 1, 4 do
		local card = Instance.new("Frame")
		card.Name = "Slot" .. i
		card.Size = UDim2.new(1, 0, 0, 56)
		card.BackgroundColor3 = Theme.Colors.BgCard
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.Parent = list
		Theme.corner(card, 10)
		Theme.stroke(card, Theme.Colors.Stroke, 1, 0.4)

		local iconHost = Instance.new("Frame")
		iconHost.Name = "IconHost"
		iconHost.Position = UDim2.fromOffset(6, 2)
		iconHost.Size = UDim2.fromOffset(ICON_PX, ICON_PX)
		iconHost.BackgroundTransparency = 1
		iconHost.BorderSizePixel = 0
		iconHost.ClipsDescendants = true
		iconHost.Parent = card

		local nm = Instance.new("TextLabel")
		nm.Size = UDim2.new(1, -(textLeft + textRightReserve), 0, 22)
		nm.Position = UDim2.fromOffset(textLeft, 8)
		nm.BackgroundTransparency = 1
		nm.Font = Theme.Fonts.Title
		nm.TextSize = 15
		nm.TextColor3 = Theme.Colors.White
		nm.TextXAlignment = Enum.TextXAlignment.Left
		nm.TextTruncate = Enum.TextTruncate.AtEnd
		nm.Text = "—"
		nm.Parent = card

		local rar = Instance.new("TextLabel")
		rar.Size = UDim2.new(1, -(textLeft + textRightReserve), 0, 16)
		rar.Position = UDim2.fromOffset(textLeft, 30)
		rar.BackgroundTransparency = 1
		rar.Font = Theme.Fonts.Body
		rar.TextSize = 12
		rar.TextColor3 = Theme.Colors.Muted
		rar.TextXAlignment = Enum.TextXAlignment.Left
		rar.Text = ""
		rar.Parent = card

		local buy = Instance.new("TextButton")
		buy.Name = "Buy"
		buy.AnchorPoint = Vector2.new(1, 0.5)
		buy.Position = UDim2.new(1, -8, 0.5, 0)
		buy.Size = UDim2.fromOffset(76, 40)
		buy.BackgroundColor3 = Theme.Colors.Purple
		buy.Font = Theme.Fonts.Title
		buy.TextSize = 13
		buy.TextColor3 = Theme.Colors.White
		buy.AutoButtonColor = false
		buy.Text = "$?"
		buy.ZIndex = 2
		buy.Parent = card
		Theme.corner(buy, 8)
		Theme.stroke(buy, Theme.Colors.Gold, 1.5, 0.45)

		buy.MouseButton1Click:Connect(function()
			-- Instant buy juice before BuyCarpet remote returns (server SoftFeedback on fail)
			Util.pulse(buy)
			SoundHooksApi.PlayKind("buy")
			onBuy(i)
		end)

		table.insert(slots, card)
		table.insert(iconHosts, iconHost)
		table.insert(nameLabels, nm)
		table.insert(rarityLabels, rar)
		table.insert(buyButtons, buy)
	end

	local getStock: RemoteFunction? = nil
	local alive = true

	local function clearAllIcons()
		for i = 1, 4 do
			clearIconHost(iconHosts[i])
		end
	end

	local function applyEmpty(reason: string)
		subtitle.Text = reason
		for i = 1, 4 do
			clearIconHost(iconHosts[i])
			nameLabels[i].Text = "Empty"
			rarityLabels[i].Text = "—"
			buyButtons[i].Text = "—"
			buyButtons[i].Active = false
			buyButtons[i].BackgroundColor3 = Theme.Colors.BgCard
		end
	end

	local function applyStock(entries: { StockEntry })
		subtitle.Text = "Tap BUY · stock rotates"
		for i = 1, 4 do
			local e = entries[i]
			-- Maid-like: always destroy previous viewport models before remount
			clearIconHost(iconHosts[i])
			if e then
				local isFeat = e.id == "trend_offline_brain" or e.name == "Offline Brain"
				nameLabels[i].Text = if isFeat then ("★ " .. e.name) else e.name
				rarityLabels[i].Text = if isFeat then (e.rarity .. " · FEATURED") else e.rarity
				rarityLabels[i].TextColor3 = Theme.rarityColor(e.rarity)
				Theme.stroke(slots[i], if isFeat then Theme.Colors.HeatPink else Theme.rarityColor(e.rarity), if isFeat then 2.5 else 1.5, 0.25)
				buyButtons[i].Text = Theme.formatCash(e.price)
				buyButtons[i].Active = true
				buyButtons[i].BackgroundColor3 = if isFeat then Theme.Colors.HeatPink else Theme.Colors.Purple
				if e.id ~= "" then
					showPetIcon(iconHosts[i], e.id, e.rarity)
				else
					showRarityOrb(iconHosts[i], e.rarity)
				end
			else
				nameLabels[i].Text = "Empty"
				rarityLabels[i].Text = "—"
				rarityLabels[i].TextColor3 = Theme.Colors.Muted
				buyButtons[i].Text = "—"
				buyButtons[i].Active = false
			end
		end
	end

	local function invokeStock(timeoutSec: number): (boolean, any)
		local done = false
		local okOut = false
		local resultOut: any = nil
		task.spawn(function()
			local ok, result = pcall(function()
				return (getStock :: RemoteFunction):InvokeServer()
			end)
			if not done then
				done = true
				okOut = ok
				resultOut = result
			end
		end)
		local t0 = os.clock()
		while not done and (os.clock() - t0) < timeoutSec do
			task.wait(0.05)
		end
		if not done then
			done = true
			return false, "timeout"
		end
		return okOut, resultOut
	end

	local function updateFeaturedBanner(entries: { StockEntry })
		local hasFeat = false
		for _, e in entries do
			if e.id == "trend_offline_brain" then
				hasFeat = true
				break
			end
		end
		local featLbl = panel:FindFirstChild("FeaturedBanner")
		if featLbl and featLbl:IsA("TextLabel") then
			featLbl.Text = if hasFeat then "TREND · Offline Brain in stock ★" else "TREND · Offline Brain week — watch the Carpet"
		end
	end

	local function entriesFromPayload(result: any): { StockEntry }
		local entries: { StockEntry } = {}
		if typeof(result) ~= "table" then
			return entries
		end
		for i, row in result :: { any } do
			if typeof(row) == "table" then
				table.insert(entries, {
					id = tostring(row.id or ""),
					name = tostring(row.name or "???"),
					rarity = tostring(row.rarity or "Common"),
					price = tonumber(row.price) or 0,
				})
			elseif typeof(row) == "string" then
				table.insert(entries, {
					id = row,
					name = row,
					rarity = "?",
					price = 0,
				})
			end
			if i >= 4 then
				break
			end
		end
		return entries
	end

	local function readReplicatedStock(timeoutSec: number): { StockEntry }?
		local state = ReplicatedStorage:FindFirstChild("CloutState")
		if not state then
			local okWait, got = pcall(function()
				return ReplicatedStorage:WaitForChild("CloutState", timeoutSec)
			end)
			if okWait and got and got:IsA("Folder") then
				state = got
			else
				return nil
			end
		end
		if not state or not state:IsA("Folder") then
			return nil
		end
		local stockFolder = state:FindFirstChild("CarpetStock")
		if not stockFolder then
			local okWait, got = pcall(function()
				return state:WaitForChild("CarpetStock", timeoutSec)
			end)
			if okWait and got and got:IsA("Folder") then
				stockFolder = got
			else
				return nil
			end
		end
		if not stockFolder or not stockFolder:IsA("Folder") then
			return nil
		end
		local entries: { StockEntry } = {}
		local filled = 0
		for i = 1, 4 do
			local slot = stockFolder:FindFirstChild("Slot" .. tostring(i))
			if slot and slot:IsA("StringValue") then
				local petId = slot.Value
				if petId ~= "" then
					filled += 1
					local priceAttr = slot:GetAttribute("Price")
					table.insert(entries, {
						id = petId,
						name = tostring(slot:GetAttribute("Name") or petId),
						rarity = tostring(slot:GetAttribute("Rarity") or "Common"),
						price = if typeof(priceAttr) == "number" then priceAttr else (tonumber(priceAttr) or 0),
					})
				end
			end
		end
		if filled > 0 then
			return entries
		end
		return nil
	end

	local stockListenConns: { RBXScriptConnection } = {}
	local stockFolderBound: Folder? = nil

	local function clearStockListeners()
		for _, c in stockListenConns do
			c:Disconnect()
		end
		table.clear(stockListenConns)
		stockFolderBound = nil
	end

	local function bindStockListeners()
		local state = ReplicatedStorage:FindFirstChild("CloutState")
		local stockFolder = if state and state:IsA("Folder") then state:FindFirstChild("CarpetStock") else nil
		if not stockFolder or not stockFolder:IsA("Folder") then
			return
		end
		if stockFolderBound == stockFolder then
			return
		end
		clearStockListeners()
		stockFolderBound = stockFolder
		local function onStockChanged()
			if not alive then
				return
			end
			local entries = readReplicatedStock(0.05)
			if entries and #entries > 0 then
				updateFeaturedBanner(entries)
				applyStock(entries)
			end
		end
		local function wireSlot(slot: Instance)
			if not slot:IsA("StringValue") then
				return
			end
			table.insert(stockListenConns, slot:GetPropertyChangedSignal("Value"):Connect(onStockChanged))
			table.insert(stockListenConns, slot.AttributeChanged:Connect(function(_attr)
				onStockChanged()
			end))
		end
		table.insert(stockListenConns, stockFolder.ChildAdded:Connect(function(child)
			wireSlot(child)
			onStockChanged()
		end))
		for _, slot in stockFolder:GetChildren() do
			wireSlot(slot)
		end
	end

	local function refresh()
		if not alive then
			return
		end
		bindStockListeners()
		-- 1) Prefer replicated CloutState.CarpetStock (works even if RF hangs)
		local replicated = readReplicatedStock(0.35)
		if replicated and #replicated > 0 then
			updateFeaturedBanner(replicated)
			applyStock(replicated)
			return
		end
		-- 2) Fallback: GetCarpetStock RF with short timeout
		if not getStock then
			local remotes = Util.waitRemotes(2)
			if remotes then
				getStock = Util.getRemoteFunction(remotes, "GetCarpetStock")
			end
		end
		if getStock then
			local ok, result = invokeStock(2)
			if ok and typeof(result) == "table" then
				local entries = entriesFromPayload(result)
				if #entries > 0 then
					updateFeaturedBanner(entries)
					applyStock(entries)
					bindStockListeners()
					return
				end
			elseif not ok and result == "timeout" then
				applyEmpty("Stock timed out — retrying")
				return
			elseif not ok then
				applyEmpty("Stock call failed")
				if feedback then
					feedback("Carpet stock offline", "error")
				end
				return
			end
		end
		-- 3) Empty
		applyEmpty("Stock unavailable — waiting…")
	end

	task.spawn(function()
		while alive do
			refresh()
			task.wait(REFRESH_EVERY)
		end
	end)

	local openConn: RBXScriptConnection? = nil
	local eConn: RBXScriptConnection? = nil
	local lastEOpen = 0.0
	eConn = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end
		if input.KeyCode ~= Enum.KeyCode.E then
			return
		end
		local now = os.clock()
		if now - lastEOpen < 0.4 then
			return
		end
		local carpet = Workspace:FindFirstChild("Carpet")
		if not carpet or not carpet:IsA("BasePart") then
			return
		end
		local char = Players.LocalPlayer and Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp or not hrp:IsA("BasePart") then
			return
		end
		if (hrp.Position - carpet.Position).Magnitude > 28 then
			return
		end
		lastEOpen = now
		panel.Visible = true
		refresh()
		if feedback then
			feedback("✨ Red Carpet open — pick a pet!", "buy")
		end
	end)
	task.spawn(function()
		local remotes = Util.waitRemotes(30)
		if not remotes then
			return
		end
		local ev = Util.getRemoteEvent(remotes, "OpenShop")
		if ev then
			openConn = ev.OnClientEvent:Connect(function(_payload: any)
				panel.Visible = true
				refresh()
				Util.pulse(panel, 1.04)
				if feedback then
					feedback("✨ Red Carpet open — pick a pet!", "buy")
				end
			end)
		end
	end)

	return {
		Refresh = function()
			refresh()
		end,
		Open = function()
			panel.Visible = true
			refresh()
		end,
		Close = function()
			panel.Visible = false
		end,
		Destroy = function()
			alive = false
			clearStockListeners()
			clearAllIcons()
			if openConn then
				openConn:Disconnect()
			end
			if eConn then
				eConn:Disconnect()
			end
			panel:Destroy()
		end,
	}
end

return CarpetShop
