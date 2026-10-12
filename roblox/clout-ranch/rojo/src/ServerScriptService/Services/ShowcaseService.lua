--!strict
-- Server ModuleScript: pin 1 pet to a ranch billboard for flex (cosmetic showcase)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShowcaseService = {}

local pinned: { [number]: string } = {} -- userId -> petId

local function tryRanch(): any?
	local mod = script.Parent:FindFirstChild("RanchService")
	if mod and mod:IsA("ModuleScript") then
		local ok, result = pcall(require, mod)
		if ok then
			return result
		end
	end
	return nil
end

local function tryCatalog(): any?
	local modules = ReplicatedStorage:FindFirstChild("Modules")
	local cat = modules and modules:FindFirstChild("PetCatalog")
	if cat and cat:IsA("ModuleScript") then
		local ok, result = pcall(require, cat)
		if ok then
			return result
		end
	end
	return nil
end

local function plotModel(plotName: string): Instance?
	local folder = workspace:FindFirstChild("Ranches")
	if not folder then
		return nil
	end
	return folder:FindFirstChild(plotName)
end

local function attachPoint(plot: Instance): BasePart?
	local existing = plot:FindFirstChild("ShowcaseAnchor", true)
	if existing and existing:IsA("BasePart") then
		return existing
	end
	local primary: BasePart? = nil
	if plot:IsA("Model") and plot.PrimaryPart then
		primary = plot.PrimaryPart
	else
		primary = plot:FindFirstChildWhichIsA("BasePart", true)
	end
	if not primary then
		return nil
	end
	local anchor = Instance.new("Part")
	anchor.Name = "ShowcaseAnchor"
	anchor.Size = Vector3.new(0.4, 0.4, 0.4)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CFrame = primary.CFrame * CFrame.new(0, 10, 0)
	anchor.Parent = plot
	return anchor
end

local function clearBillboard(plot: Instance)
	local old = plot:FindFirstChild("PetShowcaseBillboard", true)
	if old then
		old:Destroy()
	end
end

local function rarityColor(rarity: string): Color3
	if rarity == "Secret" then
		return Color3.fromRGB(255, 200, 60)
	elseif rarity == "Epic" then
		return Color3.fromRGB(190, 90, 255)
	elseif rarity == "Rare" then
		return Color3.fromRGB(70, 150, 255)
	elseif rarity == "Uncommon" then
		return Color3.fromRGB(80, 220, 120)
	end
	return Color3.fromRGB(200, 200, 210)
end

local function rebuildBillboard(player: Player, petId: string)
	local Ranch = tryRanch()
	local Catalog = tryCatalog()
	if not Ranch or not Catalog then
		return
	end
	local state = Ranch.GetByUser(player.UserId)
	if not state then
		return
	end
	local plot = plotModel(state.plotName)
	if not plot then
		return
	end
	clearBillboard(plot)
	local def = Catalog.Get(petId)
	local name = if def then def.name else petId
	local rarity = if def then def.rarity else "Common"
	local anchor = attachPoint(plot)
	if not anchor then
		return
	end

	local bb = Instance.new("BillboardGui")
	bb.Name = "PetShowcaseBillboard"
	bb.Size = UDim2.fromOffset(220, 72)
	bb.StudsOffset = Vector3.new(0, 1.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 120
	bb.Adornee = anchor
	bb.Parent = anchor

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(18, 12, 32)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = rarityColor(rarity)
	stroke.Thickness = 2
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -12, 0, 28)
	title.Position = UDim2.fromOffset(6, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = rarityColor(rarity)
	title.Text = "✨ " .. name
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = frame

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -12, 0, 22)
	sub.Position = UDim2.fromOffset(6, 38)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamMedium
	sub.TextSize = 13
	sub.TextColor3 = Color3.fromRGB(200, 190, 220)
	sub.Text = player.DisplayName .. "'s flex · " .. rarity
	sub.TextXAlignment = Enum.TextXAlignment.Center
	sub.Parent = frame
end

--- Pin pet from ranch slot (1-based) or by petId string. One pin per player.
function ShowcaseService.Pin(player: Player, slotOrPetId: any): (boolean, string?)
	local Ranch = tryRanch()
	if not Ranch then
		return false, "Ranch offline"
	end
	local state = Ranch.GetByUser(player.UserId)
	if not state then
		return false, "No ranch"
	end

	local petId: string? = nil
	if typeof(slotOrPetId) == "number" then
		local slot = math.floor(slotOrPetId)
		petId = state.slots[slot]
		if not petId then
			return false, "Empty slot"
		end
	elseif typeof(slotOrPetId) == "string" then
		local found = Ranch.FindPetSlot(state, slotOrPetId)
		if not found then
			return false, "Pet not on ranch"
		end
		petId = slotOrPetId
	else
		return false, "Bad args"
	end

	pinned[player.UserId] = petId :: string
	rebuildBillboard(player, petId :: string)
	return true, nil
end

function ShowcaseService.Clear(player: Player)
	pinned[player.UserId] = nil
	local Ranch = tryRanch()
	if not Ranch then
		return
	end
	local state = Ranch.GetByUser(player.UserId)
	if not state then
		return
	end
	local plot = plotModel(state.plotName)
	if plot then
		clearBillboard(plot)
	end
end

function ShowcaseService.GetPinned(userId: number): string?
	return pinned[userId]
end

function ShowcaseService.Refresh(player: Player)
	local petId = pinned[player.UserId]
	if petId then
		rebuildBillboard(player, petId)
	end
end

Players.PlayerRemoving:Connect(function(player)
	ShowcaseService.Clear(player)
	pinned[player.UserId] = nil
end)

return ShowcaseService
