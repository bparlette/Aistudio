--!strict
-- Spawns / despawns pet Models on ranch Slot markers; attaches carry visuals to thieves.
-- Uses PetFactory.BuildModel (pcall-safe from RanchService / StealService).

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PetFactory = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetFactory"))
local PetCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetCatalog"))

local CARRY_OFFSET = CFrame.new(0, 2.2, -1.6)
local SLOT_Y_LIFT = 1.35

-- plotName → slotIndex → Model
local slotModels: { [string]: { [number]: Model } } = {}
-- userId → Model
local carryModels: { [number]: Model } = {}

local PetVisualService = {}

local function findSlotPart(plotName: string, slotIndex: number): BasePart?
	local folder = Workspace:FindFirstChild("Ranches")
	if not folder then
		return nil
	end
	local plot = folder:FindFirstChild(plotName)
	if not plot then
		return nil
	end
	local slot = plot:FindFirstChild("Slot" .. tostring(slotIndex))
	if slot and slot:IsA("BasePart") then
		return slot
	end
	return nil
end

local function destroyModel(model: Model?)
	if model and model.Parent then
		model:Destroy()
	end
end

local function ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function PetVisualService.ClearSlot(plotName: string, slotIndex: number)
	local byPlot = slotModels[plotName]
	if not byPlot then
		return
	end
	local model = byPlot[slotIndex]
	if model then
		destroyModel(model)
		byPlot[slotIndex] = nil
	end
end

function PetVisualService.SpawnOnSlot(plotName: string, slotIndex: number, petId: string)
	PetVisualService.ClearSlot(plotName, slotIndex)

	local slotPart = findSlotPart(plotName, slotIndex)
	local model = PetFactory.BuildModel(petId)
	local primary = model.PrimaryPart
	if not primary then
		model:Destroy()
		warn("[PetVisualService] BuildModel missing PrimaryPart", petId)
		return
	end

	-- Anchor for ranch display
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end

	local folder = Workspace:FindFirstChild("Ranches")
	local plot = folder and folder:FindFirstChild(plotName)
	local host: Instance = plot or Workspace
	local visuals = ensureFolder(host, "PetVisuals")

	if slotPart then
		local cf = slotPart.CFrame * CFrame.new(0, SLOT_Y_LIFT, 0)
		model:PivotTo(cf)
	else
		-- Fallback: park on plot Base (never world origin — looks like empty ranch)
		warn("[PetVisualService] Slot marker missing", plotName, slotIndex)
		local base = plot and (plot:IsA("Model") and (plot.PrimaryPart or plot:FindFirstChild("Base")))
		local ox = ((slotIndex - 1) % 3 - 1) * 8
		if base and base:IsA("BasePart") then
			model:PivotTo(base.CFrame * CFrame.new(ox, SLOT_Y_LIFT + 1, 2))
		else
			model:PivotTo(CFrame.new(ox, SLOT_Y_LIFT + 1, 0))
		end
	end

	model.Name = "Pet_" .. petId .. "_S" .. tostring(slotIndex)
	model:SetAttribute("PlotName", plotName)
	model:SetAttribute("SlotIndex", slotIndex)
	-- Floating $/sec so idle cash is obvious on pads
	local def = PetCatalog.Get(petId)
	if primary and def and typeof(def.incomePerSec) == "number" then
		local existingBill = primary:FindFirstChild("IncomeBillboard")
		if existingBill then
			existingBill:Destroy()
		end
		local bill = Instance.new("BillboardGui")
		bill.Name = "IncomeBillboard"
		bill.Size = UDim2.fromOffset(120, 36)
		bill.StudsOffset = Vector3.new(0, 3.2, 0)
		bill.AlwaysOnTop = true
		bill.MaxDistance = 90
		bill.Adornee = primary
		bill.Parent = primary
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 16
		lbl.TextColor3 = Color3.fromRGB(125, 255, 179)
		lbl.TextStrokeColor3 = Color3.fromRGB(26, 18, 40)
		lbl.TextStrokeTransparency = 0.25
		lbl.Text = "+$" .. tostring(math.floor(def.incomePerSec)) .. "/s"
		lbl.Parent = bill
	end
	model.Parent = visuals

	if not slotModels[plotName] then
		slotModels[plotName] = {}
	end
	slotModels[plotName][slotIndex] = model
end

function PetVisualService.ClearCarry(player: Player)
	local model = carryModels[player.UserId]
	if model then
		destroyModel(model)
		carryModels[player.UserId] = nil
	end
end

function PetVisualService.AttachCarry(player: Player, petId: string)
	PetVisualService.ClearCarry(player)

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	local model = PetFactory.BuildModel(petId)
	local primary = model.PrimaryPart
	if not primary then
		model:Destroy()
		return
	end

	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.Massless = true
			d.CanCollide = false
		end
	end

	model.Name = "CarryPet_" .. petId
	model:SetAttribute("CarryUserId", player.UserId)
	model.Parent = char

	model:PivotTo(root.CFrame * CARRY_OFFSET)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = primary
	weld.Parent = primary

	carryModels[player.UserId] = model
end

function PetVisualService.ClearRanch(plotName: string)
	local byPlot = slotModels[plotName]
	if not byPlot then
		return
	end
	for idx, model in byPlot do
		destroyModel(model)
		byPlot[idx] = nil
	end
	slotModels[plotName] = nil
end

function PetVisualService.SyncRanch(plotName: string, slots: { string? })
	PetVisualService.ClearRanch(plotName)
	for i, petId in slots do
		if petId then
			PetVisualService.SpawnOnSlot(plotName, i, petId)
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	PetVisualService.ClearCarry(player)
end)

return PetVisualService
