--!strict
-- Server ModuleScript: idempotent world scaffold — Ranches, Carpet, Aura Flex stage
-- Art canon: gold disc + purple neon ring + gold pillars + night void
-- Density pass (pre-alpha-feel-dense-1): big labeled pads, near-carpet spawn, path lights
-- overnight-autonomy-2: Slot1..3 + DepositPad + LockPad (+ labels/rims) baked under
-- Workspace/Ranches/Ranch1..6 for Edit-mode density. ensurePart / ensureRim / ensureBillboard
-- still upgrade at Play — safe if parts already exist on disk (no wipe of Base/Spawn).

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local PLOT_COUNT = 6
local RING_RADIUS = 56 -- ≥55 so 6×40 pads have clear gaps (centers at RING; need RING > BASE≈40)
local BASE_SIZE = Vector3.new(40, 1.2, 40)
local SPAWN_RING = 16 -- arc near Carpet (≤20 studs); orientation faces OWN ranch, not origin
local SLOT_SIZE = Vector3.new(7, 0.45, 7)
local SLOT_COUNT = 3

-- Art palette
local GOLD = Color3.fromRGB(245, 200, 75)
local DEEP_PURPLE = Color3.fromRGB(91, 42, 158)
local LILAC = Color3.fromRGB(201, 166, 255)
local CREAM = Color3.fromRGB(255, 246, 224)
local NIGHT_VOID = Color3.fromRGB(26, 18, 40)
local MINT = Color3.fromRGB(80, 220, 160)
local HEAT = Color3.fromRGB(255, 77, 184)

local PLOT_COLORS: { Color3 } = {
	Color3.fromRGB(140, 210, 130), -- light mint grass
	Color3.fromRGB(150, 190, 255), -- soft sky
	Color3.fromRGB(255, 180, 140), -- cream peach
	Color3.fromRGB(240, 210, 120), -- warm cream gold
	Color3.fromRGB(210, 170, 245), -- soft lilac
	Color3.fromRGB(130, 220, 210), -- light aqua
}

local SLOT_OFFSETS = {
	Vector3.new(-10, 0.9, 2),
	Vector3.new(0, 0.9, 2),
	Vector3.new(10, 0.9, 2),
	Vector3.new(-5, 0.9, 12),
	Vector3.new(5, 0.9, 12),
}

local MapBootstrap = {}

local function ensurePart(parent: Instance, name: string, props: { [string]: any }): BasePart
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("BasePart") then
		for key, value in props do
			(existing :: any)[key] = value
		end
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	for key, value in props do
		(part :: any)[key] = value
	end
	part.Parent = parent
	return part
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

local function ensureBillboard(adornee: BasePart, name: string, text: string, studsOffset: Vector3, textSize: number?)
	local existing = adornee:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local bill = Instance.new("BillboardGui")
	bill.Name = name
	bill.Size = UDim2.fromOffset(260, 44)
	bill.StudsOffset = studsOffset
	bill.AlwaysOnTop = true
	bill.MaxDistance = 280
	bill.Adornee = adornee
	bill.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize or 22
	label.TextColor3 = CREAM
	label.TextStrokeColor3 = GOLD
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = bill
	return bill
end

local function ensureRim(slot: BasePart, color: Color3)
	local rim = slot:FindFirstChild("Rim")
	if rim and rim:IsA("BasePart") then
		rim.Size = Vector3.new(slot.Size.X + 0.8, 0.2, slot.Size.Z + 0.8)
		rim.CFrame = slot.CFrame * CFrame.new(0, -0.15, 0)
		rim.Color = color
		return
	end
	if rim then
		rim:Destroy()
	end
	local r = Instance.new("Part")
	r.Name = "Rim"
	r.Size = Vector3.new(slot.Size.X + 0.8, 0.2, slot.Size.Z + 0.8)
	r.Anchored = true
	r.CanCollide = false
	r.Material = Enum.Material.Neon
	r.Color = color
	r.Transparency = 0.25
	r.CFrame = slot.CFrame * CFrame.new(0, -0.15, 0)
	r.Parent = slot
end

local function ensureSlotOnPlot(model: Model, base: BasePart, slotIndex: number)
	local name = "Slot" .. tostring(slotIndex)
	local offset = SLOT_OFFSETS[((slotIndex - 1) % #SLOT_OFFSETS) + 1]
	local slot = ensurePart(model, name, {
		Size = SLOT_SIZE,
		Anchored = true,
		CanCollide = false,
		Transparency = 0.35,
		Material = Enum.Material.Neon,
		Color = LILAC,
		CFrame = base.CFrame * CFrame.new(offset),
	})
	slot:SetAttribute("SlotIndex", slotIndex)
	slot:SetAttribute("PlotName", model.Name)
	CollectionService:AddTag(slot, "CloutSlot")
	ensureRim(slot, GOLD)
	ensureBillboard(slot, "SlotLabel", "SLOT " .. tostring(slotIndex), Vector3.new(0, 3.2, 0), 18)
end

local function ensureActionPad(model: Model, base: BasePart, name: string, offset: Vector3, color: Color3, label: string): BasePart
	local pad = ensurePart(model, name, {
		Size = Vector3.new(8, 0.5, 8),
		Anchored = true,
		CanCollide = false,
		Transparency = 0.25,
		Material = Enum.Material.Neon,
		Color = color,
		CFrame = base.CFrame * CFrame.new(offset),
	})
	ensureRim(pad, color)
	ensureBillboard(pad, name .. "Billboard", label, Vector3.new(0, 4, 0), 20)
	return pad
end

local function createOrUpgradeRanchPlot(folder: Folder, index: number, angle: number)
	local name = "Ranch" .. tostring(index)
	local model = folder:FindFirstChild(name)
	if not model or not model:IsA("Model") then
		if model then
			model:Destroy()
		end
		model = Instance.new("Model")
		model.Name = name
		model.Parent = folder
	end

	local cx = math.cos(angle) * RING_RADIUS
	local cz = math.sin(angle) * RING_RADIUS

	local base = ensurePart(model, "Base", {
		Size = BASE_SIZE,
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Grass,
		Color = PLOT_COLORS[((index - 1) % #PLOT_COLORS) + 1],
		CFrame = CFrame.new(cx, 0.6, cz),
	})
	model.PrimaryPart = base

	-- Bright gold neon outline so pads pop against PlazaFloor
	ensurePart(model, "BaseRim", {
		Size = Vector3.new(BASE_SIZE.X + 1.6, 0.35, BASE_SIZE.Z + 1.6),
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Color = GOLD,
		Transparency = 0.15,
		CFrame = CFrame.new(cx, 0.35, cz),
	})

	-- Bright PointLight so ranch pads read from Carpet even under night fog
	local baseLight = base:FindFirstChild("BaseLight")
	if not baseLight then
		baseLight = Instance.new("PointLight")
		baseLight.Name = "BaseLight"
		baseLight.Parent = base
	end
	local basePl = baseLight :: PointLight
	basePl.Color = CREAM
	basePl.Brightness = 2.4
	basePl.Range = 48

	-- gold fence trim posts (luxury barn read) — corners of 40-stud pad
	local half = 18
	for i = 1, 4 do
		local ox = if i <= 2 then -half else half
		local oz = if i % 2 == 1 then -half else half
		ensurePart(model, "GoldPost" .. tostring(i), {
			Size = Vector3.new(0.8, 5, 0.8),
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Metal,
			Color = GOLD,
			CFrame = CFrame.new(cx + ox, 3, cz + oz),
		})
	end

	-- Spawn on arc near Carpet (SPAWN_RING ≤20), oriented OUTWARD toward THIS plot's Base
	-- (not lookAt origin — that put farms behind the camera)
	local spawnAngle = angle
	local sx = math.cos(spawnAngle) * SPAWN_RING
	local sz = math.sin(spawnAngle) * SPAWN_RING
	local spawnPos = Vector3.new(sx, 1.5, sz)
	local baseCenter = Vector3.new(cx, 1.5, cz)
	local spawnCf = CFrame.new(spawnPos)
	if (baseCenter - spawnPos).Magnitude > 0.01 then
		spawnCf = CFrame.lookAt(spawnPos, baseCenter)
	end
	do
		local existingSpawn = model:FindFirstChild("Spawn")
		if existingSpawn and not existingSpawn:IsA("SpawnLocation") then
			existingSpawn:Destroy()
			existingSpawn = nil
		end
		local sl: SpawnLocation
		if existingSpawn and existingSpawn:IsA("SpawnLocation") then
			sl = existingSpawn
		else
			sl = Instance.new("SpawnLocation")
			sl.Name = "Spawn"
			sl.Parent = model
		end
		sl.Size = Vector3.new(6, 1, 6)
		sl.Anchored = true
		sl.CanCollide = true
		sl.Neutral = true
		sl.Duration = 0
		sl.Transparency = 0.25
		sl.BrickColor = BrickColor.new("Bright yellow")
		sl.Material = Enum.Material.Neon
		sl.CFrame = spawnCf
	end

	local attach = base:FindFirstChild("SpawnAttachment")
	if not attach then
		attach = Instance.new("Attachment")
		attach.Name = "SpawnAttachment"
		attach.Parent = base
	end
	(attach :: Attachment).Position = Vector3.new(0, 2, 0)

	ensureBillboard(base, "RanchNameBillboard", "RANCH " .. tostring(index), Vector3.new(0, 10, 0), 24)
	ensureBillboard(base, "RanchHintBillboard", "PET PADS →", Vector3.new(0, 7.5, 0), 16)

	-- Density pads: prefer disk bake (Edit view); ensure* keeps Play idempotent
	for i = 1, SLOT_COUNT do
		ensureSlotOnPlot(model, base, i)
	end

	ensureActionPad(model, base, "DepositPad", Vector3.new(0, 1.0, -14), MINT, "DEPOSIT")
	ensureActionPad(model, base, "LockPad", Vector3.new(14, 1.0, -10), DEEP_PURPLE, "🔒 LOCK")

	-- Path light toward carpet
	local pathFolder = ensureFolder(model, "PathLights")
	for _, c in pathFolder:GetChildren() do
		c:Destroy()
	end
	for step = 1, 4 do
		local t = step / 5
		local px = sx + (0 - sx) * t * 0.55
		local pz = sz + (0 - sz) * t * 0.55
		local lamp = Instance.new("Part")
		lamp.Name = "PathLamp" .. tostring(step)
		lamp.Size = Vector3.new(1.2, 0.35, 1.2)
		lamp.Anchored = true
		lamp.CanCollide = false
		lamp.Material = Enum.Material.Neon
		lamp.Color = GOLD
		lamp.Transparency = 0.15
		lamp.CFrame = CFrame.new(px, 0.4, pz)
		lamp.Parent = pathFolder
		local pl = Instance.new("PointLight")
		pl.Color = GOLD
		pl.Brightness = 1.2
		pl.Range = 18
		pl.Parent = lamp
	end

	model:SetAttribute("PlotIndex", index)
	model:SetAttribute("DensePad", true)
	return model
end

local function buildCarpet()
	local carpet = ensurePart(Workspace, "Carpet", {
		Size = Vector3.new(32, 0.6, 16),
		CFrame = CFrame.new(0, 0.3, 0),
		Color = Color3.fromRGB(160, 28, 48),
		Material = Enum.Material.Fabric,
		Anchored = true,
		CanCollide = true,
	})

	local stripeFolder = ensureFolder(carpet, "Stripes")
	for _, child in stripeFolder:GetChildren() do
		child:Destroy()
	end
	for i = 1, 8 do
		local stripe = Instance.new("Part")
		stripe.Name = "Stripe" .. tostring(i)
		stripe.Size = Vector3.new(32, 0.1, 0.8)
		stripe.Anchored = true
		stripe.CanCollide = false
		stripe.Material = Enum.Material.Neon
		stripe.Color = if i % 2 == 1 then GOLD else CREAM
		local z = -6.5 + (i - 1) * 1.85
		stripe.CFrame = carpet.CFrame * CFrame.new(0, 0.35, z)
		stripe.Parent = stripeFolder
	end

	-- Glow rim
	ensurePart(carpet, "CarpetRim", {
		Size = Vector3.new(34, 0.25, 18),
		CFrame = carpet.CFrame * CFrame.new(0, -0.2, 0),
		Color = GOLD,
		Material = Enum.Material.Neon,
		Anchored = true,
		CanCollide = false,
		Transparency = 0.35,
	})

	ensureBillboard(carpet, "CarpetBillboard", "✨ BUY CARPET", Vector3.new(0, 8, 0), 26)
	ensureBillboard(carpet, "CarpetSubBillboard", "TAP E · OPEN SHOP", Vector3.new(0, 5.5, 0), 16)

	local light = carpet:FindFirstChild("CarpetLight")
	if not light then
		light = Instance.new("PointLight")
		light.Name = "CarpetLight"
		light.Parent = carpet
	end
	local carpetPl = light :: PointLight
	carpetPl.Color = HEAT
	carpetPl.Brightness = 2.2
	carpetPl.Range = 36
end

local function buildAuraStage()
	local legacy = Workspace:FindFirstChild("AuraStage")
	local stageModel: Model
	if legacy and legacy:IsA("Model") then
		stageModel = legacy
	else
		if legacy then
			legacy:Destroy()
		end
		stageModel = Instance.new("Model")
		stageModel.Name = "AuraStage"
		stageModel.Parent = Workspace
	end

	local cx, cz = 0, -28

	local voidPad = ensurePart(stageModel, "NightVoid", {
		Size = Vector3.new(48, 0.4, 36),
		CFrame = CFrame.new(cx, 0.2, cz),
		Color = NIGHT_VOID,
		Material = Enum.Material.SmoothPlastic,
		Anchored = true,
		CanCollide = true,
		Transparency = 0,
	})

	local disc = ensurePart(stageModel, "GoldDisc", {
		Size = Vector3.new(1.2, 22, 22),
		CFrame = CFrame.new(cx, 0.85, cz) * CFrame.Angles(0, 0, math.rad(90)),
		Color = GOLD,
		Material = Enum.Material.Neon,
		Anchored = true,
		CanCollide = true,
		Shape = Enum.PartType.Cylinder,
	})

	local pad = ensurePart(stageModel, "StagePad", {
		Size = Vector3.new(20, 0.6, 20),
		CFrame = CFrame.new(cx, 1.1, cz),
		Color = GOLD,
		Material = Enum.Material.Neon,
		Anchored = true,
		CanCollide = true,
		Transparency = 0.15,
	})
	stageModel.PrimaryPart = pad

	local ringFolder = ensureFolder(stageModel, "PurpleNeonRing")
	for _, c in ringFolder:GetChildren() do
		c:Destroy()
	end
	local RING_R = 12
	local SEGMENTS = 24
	for i = 1, SEGMENTS do
		local a0 = ((i - 1) / SEGMENTS) * math.pi * 2
		local a1 = (i / SEGMENTS) * math.pi * 2
		local mid = (a0 + a1) * 0.5
		local seg = Instance.new("Part")
		seg.Name = "RingSeg" .. tostring(i)
		seg.Anchored = true
		seg.CanCollide = false
		seg.Material = Enum.Material.Neon
		seg.Color = DEEP_PURPLE
		seg.Size = Vector3.new(3.4, 0.45, 0.55)
		local x = cx + math.cos(mid) * RING_R
		local z = cz + math.sin(mid) * RING_R
		seg.CFrame = CFrame.new(x, 1.35, z) * CFrame.Angles(0, -mid + math.pi / 2, 0)
		seg.Parent = ringFolder
	end

	local outerFolder = ensureFolder(stageModel, "LilacRing")
	for _, c in outerFolder:GetChildren() do
		c:Destroy()
	end
	local OUTER_R = 14.5
	for i = 1, SEGMENTS do
		local a0 = ((i - 1) / SEGMENTS) * math.pi * 2
		local a1 = (i / SEGMENTS) * math.pi * 2
		local mid = (a0 + a1) * 0.5
		local seg = Instance.new("Part")
		seg.Name = "OuterSeg" .. tostring(i)
		seg.Anchored = true
		seg.CanCollide = false
		seg.Material = Enum.Material.Neon
		seg.Color = LILAC
		seg.Transparency = 0.35
		seg.Size = Vector3.new(3.9, 0.25, 0.35)
		local x = cx + math.cos(mid) * OUTER_R
		local z = cz + math.sin(mid) * OUTER_R
		seg.CFrame = CFrame.new(x, 1.2, z) * CFrame.Angles(0, -mid + math.pi / 2, 0)
		seg.Parent = outerFolder
	end

	local pillars = ensureFolder(stageModel, "GoldPillars")
	for _, c in pillars:GetChildren() do
		c:Destroy()
	end
	local pillarOffsets = {
		Vector3.new(-16, 0, -10),
		Vector3.new(16, 0, -10),
		Vector3.new(-16, 0, 10),
		Vector3.new(16, 0, 10),
	}
	for i, off in pillarOffsets do
		local pillar = Instance.new("Part")
		pillar.Name = "Pillar" .. tostring(i)
		pillar.Size = Vector3.new(1.4, 18, 1.4)
		pillar.Anchored = true
		pillar.CanCollide = true
		pillar.Material = Enum.Material.Metal
		pillar.Color = GOLD
		pillar.CFrame = CFrame.new(cx + off.X, 9.2, cz + off.Z)
		pillar.Parent = pillars

		local tip = Instance.new("Part")
		tip.Name = "PillarNeon" .. tostring(i)
		tip.Size = Vector3.new(1.6, 1.2, 1.6)
		tip.Anchored = true
		tip.CanCollide = false
		tip.Material = Enum.Material.Neon
		tip.Color = DEEP_PURPLE
		tip.CFrame = CFrame.new(cx + off.X, 18.5, cz + off.Z)
		tip.Parent = pillars

		local light = Instance.new("PointLight")
		light.Color = if i % 2 == 0 then GOLD else LILAC
		light.Brightness = 2
		light.Range = 28
		light.Parent = tip
	end

	local lightFolder = ensureFolder(stageModel, "Lights")
	for _, c in lightFolder:GetChildren() do
		c:Destroy()
	end
	local spot = Instance.new("Part")
	spot.Name = "CenterLightHost"
	spot.Anchored = true
	spot.CanCollide = false
	spot.Transparency = 1
	spot.Size = Vector3.new(1, 1, 1)
	spot.CFrame = CFrame.new(cx, 10, cz)
	spot.Parent = lightFolder
	local pl = Instance.new("PointLight")
	pl.Color = GOLD
	pl.Brightness = 1.5
	pl.Range = 40
	pl.Parent = spot

	ensureBillboard(pad, "AuraStageBillboard", "AURA FLEX", Vector3.new(0, 10, 0), 24)
	ensureBillboard(pad, "AuraTipBillboard", "SOLO? VOTE THE RIVAL DUMMY", Vector3.new(0, 7.5, 0), 14)

	stageModel:SetAttribute("FlexReady", true)
	voidPad.Parent = stageModel
	disc.Parent = stageModel
end

local function applyNightAtmosphere()
	-- Soft night: keep mood but keep ranch pads readable vs PlazaFloor / Carpet
	Lighting.Ambient = Color3.fromRGB(58, 42, 85)
	Lighting.OutdoorAmbient = Color3.fromRGB(90, 69, 120)
	Lighting.Brightness = 2
	Lighting.ClockTime = 21.5
	Lighting.FogColor = Color3.fromRGB(42, 26, 64)
	Lighting.FogEnd = 600
	Lighting.FogStart = 150

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Color = Color3.fromRGB(74, 48, 128)
	atmosphere.Decay = DEEP_PURPLE
	atmosphere.Density = 0.12
	atmosphere.Offset = 0.15
	atmosphere.Glare = 0.1
	atmosphere.Haze = 0.35
end

local function buildPlazaGround()
	ensurePart(Workspace, "PlazaFloor", {
		Size = Vector3.new(180, 1, 180),
		CFrame = CFrame.new(0, -0.4, 0),
		Color = NIGHT_VOID,
		Material = Enum.Material.SmoothPlastic,
		Anchored = true,
		CanCollide = true,
		Transparency = 0,
	})
end

--- Idempotent: ensure Workspace.Ranches has 6 dense plots, Carpet + Aura Flex + near spawns.
function MapBootstrap.Build()
	applyNightAtmosphere()
	buildPlazaGround()

	local ranches = Workspace:FindFirstChild("Ranches")
	if not ranches then
		ranches = Instance.new("Folder")
		ranches.Name = "Ranches"
		ranches.Parent = Workspace
	elseif not ranches:IsA("Folder") then
		ranches:Destroy()
		ranches = Instance.new("Folder")
		ranches.Name = "Ranches"
		ranches.Parent = Workspace
	end

	local folder = ranches :: Folder
	-- Always upgrade (resize + labels) — Studio Play persists old tiny pads otherwise
	for i = 1, PLOT_COUNT do
		local angle = ((i - 1) / PLOT_COUNT) * math.pi * 2 - math.pi / 2
		createOrUpgradeRanchPlot(folder, i, angle)
	end

	buildCarpet()
	buildAuraStage()
	print("============================================================")
	print("[CloutRanch] MapBootstrap.Build OK — dense pads upgraded (disk bake + ensurePart)")
	print("[CloutRanch] RING", RING_RADIUS, "BASE", BASE_SIZE, "SPAWN", SPAWN_RING, "SLOTS", SLOT_COUNT)
	print("[CloutRanch] RanchesChildren", #folder:GetChildren(), "Carpet/AuraStage runtime-created")
	print("============================================================")
end

MapBootstrap.EnsureWorld = MapBootstrap.Build

return MapBootstrap
