--!strict
-- Solo Studio density: seed stealable demo pets on foreign ranches + Aura Flex rival dummy.
-- Demo owners use negative UserIds so AssignPlot / real players are never blocked.
-- Does NOT touch VIP idle, paywalls, endsAt, or client-trusted economy.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RanchService = require(script.Parent:WaitForChild("RanchService"))

local DEMO_OWNER_BASE = -9100 -- Ranch1 → -9101, etc.
local RIVAL_USER_ID = -9001
local DEMO_PETS = { "c1", "c2", "c4", "u1", "u3", "c6" }

local DemoRivalService = {}

DemoRivalService.RIVAL_USER_ID = RIVAL_USER_ID

local function tryPetVisual(): any?
	local mod = script.Parent:FindFirstChild("PetVisualService")
	if mod and mod:IsA("ModuleScript") then
		local ok, result = pcall(require, mod)
		if ok then
			return result
		end
	end
	return nil
end

local function tryWorldInteract(): any?
	local mod = script.Parent:FindFirstChild("WorldInteract")
	if mod and mod:IsA("ModuleScript") then
		local ok, result = pcall(require, mod)
		if ok then
			return result
		end
	end
	return nil
end

local function ensureBillboard(adornee: BasePart, name: string, text: string, offset: Vector3)
	local ok, err = pcall(function()
		local existing = adornee:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
		local bill = Instance.new("BillboardGui")
		bill.Name = name
		bill.Size = UDim2.fromOffset(220, 48)
		bill.StudsOffset = offset
		bill.AlwaysOnTop = true
		bill.MaxDistance = 160
		bill.Adornee = adornee
		bill.Parent = adornee
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 18
		lbl.TextColor3 = Color3.fromRGB(255, 246, 224)
		lbl.TextStrokeColor3 = Color3.fromRGB(255, 77, 184)
		lbl.TextStrokeTransparency = 0.25
		lbl.Text = text
		lbl.Parent = bill
	end)
	if not ok then
		warn("[CloutRanch] DemoRivalService.ensureBillboard failed:", err)
	end
end

function DemoRivalService.IsDemoOwner(userId: number?): boolean
	if typeof(userId) ~= "number" then
		return false
	end
	return userId < 0
end

function DemoRivalService.GetRivalUserId(): number
	return RIVAL_USER_ID
end

--- Place 1–2 stealable commons on every unowned ranch so solo STEAL has prey.
function DemoRivalService.SeedForeignRanches()
	local folder = Workspace:FindFirstChild("Ranches")
	if not folder then
		return
	end
	local vis = tryPetVisual()
	local seeded = 0
	for _, plot in folder:GetChildren() do
		if plot:IsA("Model") and string.match(plot.Name, "^Ranch%d+$") then
			local state = RanchService.GetByPlot(plot.Name)
			if not state then
				continue
			end
			-- Skip plots owned by real players
			if state.ownerUserId and state.ownerUserId > 0 then
				continue
			end
			local idx = tonumber(string.match(plot.Name, "%d+")) or 1
			local demoOwner = DEMO_OWNER_BASE - idx
			state.ownerUserId = demoOwner
			state.lockUntil = 0 -- unlocked for steal practice
			state.newbieProtectedUntil = 0
			-- Clear then place 2 pets
			for i = 1, state.maxSlots do
				state.slots[i] = nil
				if vis and vis.ClearSlot then
					pcall(vis.ClearSlot, state.plotName, i)
				end
			end
			local petA = DEMO_PETS[((idx - 1) % #DEMO_PETS) + 1]
			local petB = DEMO_PETS[((idx + 2) % #DEMO_PETS) + 1]
			state.slots[1] = petA
			state.slots[2] = petB
			if vis and vis.SpawnOnSlot then
				pcall(vis.SpawnOnSlot, state.plotName, 1, petA)
				pcall(vis.SpawnOnSlot, state.plotName, 2, petB)
			end
			local base = plot.PrimaryPart or plot:FindFirstChild("Base")
			if base and base:IsA("BasePart") then
				ensureBillboard(base, "DemoStealBillboard", "🥷 STEAL ZONE · DEMO", Vector3.new(0, 12, 0))
			end
			plot:SetAttribute("DemoOwnerUserId", demoOwner)
			if RanchService.SyncPlotAttributes then
				RanchService.SyncPlotAttributes(plot.Name)
			end
			seeded += 1
		end
	end
	local wi = tryWorldInteract()
	if wi and wi.RefreshSlotLabels then
		wi.RefreshSlotLabels(nil)
	end
	print("[CloutRanch] DemoRivalService seeded", seeded, "foreign ranches for solo steal")
end

--- Clear demo ownership when a real player claims the plot (AssignPlot already sets owner).
function DemoRivalService.OnPlotAssigned(plotName: string, _realUserId: number)
	local folder = Workspace:FindFirstChild("Ranches")
	local plot = folder and folder:FindFirstChild(plotName)
	if plot then
		plot:SetAttribute("DemoOwnerUserId", nil)
		local base = plot:IsA("Model") and (plot.PrimaryPart or plot:FindFirstChild("Base"))
		if base and base:IsA("BasePart") then
			local b = base:FindFirstChild("DemoStealBillboard")
			if b then
				b:Destroy()
			end
			ensureBillboard(base, "RanchNameBillboard", "YOUR RANCH", Vector3.new(0, 10, 0))
		end
	end
	-- Re-seed any OTHER still-unowned plots that lost pets to steals
	task.defer(function()
		DemoRivalService.TopUpEmptyDemoPlots()
	end)
end

function DemoRivalService.TopUpEmptyDemoPlots()
	local folder = Workspace:FindFirstChild("Ranches")
	if not folder then
		return
	end
	local vis = tryPetVisual()
	for _, plot in folder:GetChildren() do
		if not plot:IsA("Model") or not string.match(plot.Name, "^Ranch%d+$") then
			continue
		end
		local state = RanchService.GetByPlot(plot.Name)
		if not state then
			continue
		end
		if state.ownerUserId and state.ownerUserId > 0 then
			continue
		end
		local hasPet = false
		for i = 1, state.maxSlots do
			if state.slots[i] then
				hasPet = true
				break
			end
		end
		if hasPet then
			continue
		end
		local idx = tonumber(string.match(plot.Name, "%d+")) or 1
		local demoOwner = DEMO_OWNER_BASE - idx
		state.ownerUserId = demoOwner
		state.lockUntil = 0
		state.newbieProtectedUntil = 0
		local petA = DEMO_PETS[((idx - 1) % #DEMO_PETS) + 1]
		state.slots[1] = petA
		if vis and vis.SpawnOnSlot then
			pcall(vis.SpawnOnSlot, state.plotName, 1, petA)
		end
		plot:SetAttribute("DemoOwnerUserId", demoOwner)
		if RanchService.SyncPlotAttributes then
			RanchService.SyncPlotAttributes(plot.Name)
		end
	end
end

--- Physical rival dummy on Aura stage for solo Flex voting.
function DemoRivalService.EnsureFlexRival()
	local stage = Workspace:FindFirstChild("AuraStage")
	local parent: Instance = if stage then stage else Workspace
	local existing = Workspace:FindFirstChild("CloutRival") or (stage and stage:FindFirstChild("CloutRival"))
	if existing then
		existing:SetAttribute("RivalUserId", RIVAL_USER_ID)
		return existing
	end

	local model = Instance.new("Model")
	model.Name = "CloutRival"
	model:SetAttribute("RivalUserId", RIVAL_USER_ID)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Anchored = true
	root.CanCollide = false
	root.Material = Enum.Material.SmoothPlastic
	root.Color = Color3.fromRGB(91, 42, 158)
	root.CFrame = CFrame.new(0, 3.5, -28)
	root.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.Neon
	head.Color = Color3.fromRGB(255, 77, 184)
	head.CFrame = root.CFrame * CFrame.new(0, 1.8, 0)
	head.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2.2, 2.2, 1.1)
	torso.Anchored = true
	torso.CanCollide = false
	torso.Material = Enum.Material.Metal
	torso.Color = Color3.fromRGB(245, 200, 75)
	torso.CFrame = root.CFrame * CFrame.new(0, 0.2, 0)
	torso.Parent = model

	model.PrimaryPart = root
	model.Parent = parent

	ensureBillboard(head, "RivalBillboard", "RIVAL DUMMY · VOTE ME", Vector3.new(0, 2.5, 0))
	ensureBillboard(root, "RivalTip", "AURA FLEX TARGET", Vector3.new(0, 5, 0))

	-- Replicate rival id for client tips
	local state = ReplicatedStorage:FindFirstChild("CloutState")
	if not state then
		state = Instance.new("Folder")
		state.Name = "CloutState"
		state.Parent = ReplicatedStorage
	end
	local riv = state:FindFirstChild("RivalUserId")
	if not riv then
		riv = Instance.new("NumberValue")
		riv.Name = "RivalUserId"
		riv.Parent = state
	end
	(riv :: NumberValue).Value = RIVAL_USER_ID

	print("[CloutRanch] DemoRivalService Flex rival dummy ready id=", RIVAL_USER_ID)
	return model
end

function DemoRivalService.Bootstrap()
	DemoRivalService.EnsureFlexRival()
	-- Delay seed until RanchService.BootstrapFromWorkspace + WorldInteract slots exist
	task.defer(function()
		task.wait(0.35)
		DemoRivalService.SeedForeignRanches()
	end)
	-- Top-up loop so solo steal always has prey
	task.spawn(function()
		while true do
			task.wait(12)
			DemoRivalService.TopUpEmptyDemoPlots()
		end
	end)
end

return DemoRivalService
