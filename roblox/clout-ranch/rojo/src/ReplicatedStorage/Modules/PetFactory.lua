--!strict
-- Builds procedural pet Models for ranch slots / carry (~4 studs tall).
-- Art law: gold #F5C84B / purple #5B2A9E / cream #FFF6E0 / heat pink rare only.
-- Offline Brain (trend_offline_brain): empty glowing skull critter — 64px gate silhouette.

local PetCatalog = require(script.Parent:WaitForChild("PetCatalog"))
local RarityColors = require(script.Parent:WaitForChild("RarityColors"))

local GOLD = Color3.fromRGB(245, 200, 75)
local PURPLE = Color3.fromRGB(91, 42, 158)
local CREAM = Color3.fromRGB(255, 246, 224)
local NIGHT = Color3.fromRGB(26, 18, 40)
local HEAT_PINK = Color3.fromRGB(255, 77, 184)

local PetFactory = {}

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function applyRarityRim(model: Model, rarity: string)
	local swatch = RarityColors.Get(rarity)
	local hl = Instance.new("Highlight")
	hl.Name = "RarityRim"
	hl.Adornee = model
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.FillTransparency = 0.92
	hl.OutlineTransparency = 0.15
	if rarity == "Secret" or rarity == "Mythic" or rarity == "Legendary" then
		-- thin heat-pink + gold rim (Secret/Mythic)
		hl.FillColor = HEAT_PINK
		hl.OutlineColor = GOLD
		hl.FillTransparency = 0.88
		hl.OutlineTransparency = 0.05
	elseif rarity == "Epic" then
		hl.FillColor = PURPLE
		hl.OutlineColor = GOLD
	elseif rarity == "Rare" then
		hl.FillColor = GOLD
		hl.OutlineColor = GOLD
	elseif rarity == "Uncommon" then
		hl.FillColor = swatch.primary
		hl.OutlineColor = swatch.primary
		hl.OutlineTransparency = 0.35
	else
		hl.FillTransparency = 1
		hl.OutlineColor = CREAM
		hl.OutlineTransparency = 0.55
	end
	hl.Parent = model
end

local function addSecretDrip(primary: BasePart)
	-- One drip particle only — no particle soup on idle
	local att = Instance.new("Attachment")
	att.Name = "DripAttach"
	att.Position = Vector3.new(0, -0.55, 0)
	att.Parent = primary

	local pe = Instance.new("ParticleEmitter")
	pe.Name = "SecretDrip"
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(GOLD, Color3.fromRGB(201, 166, 255))
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(1, 0.06),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetimeetime = NumberRange.new(0.8, 1.2)
	pe.Speed = NumberRange.new(0.35, 0.65)
	pe.SpreadAngle = Vector2.new(8, 8)
	pe.Acceleration = Vector3.new(0, -2, 0)
	pe.Rate = 1.2
	pe.RotSpeed = NumberRange.new(0)
	pe.LightEmission = 0.4
	pe.Parent = att
end

--- Offline Brain: empty glowing skull critter (~4 studs). Signature = cracked dome spike.
local function buildOfflineBrain(): Model
	local model = Instance.new("Model")
	model.Name = "OfflineBrain"

	local origin = CFrame.new(0, 2.35, 0)

	-- Purple neon skull shell
	local head = part(model, "Primary", Vector3.new(2.5, 2.5, 2.5), origin, PURPLE, Enum.Material.Neon, Enum.PartType.Ball)

	-- Inner void (hollow feel via contrasting night sphere)
	local void = part(
		model,
		"SkullVoid",
		Vector3.new(1.75, 1.75, 1.75),
		origin * CFrame.new(0, 0.05, 0.08),
		NIGHT,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	weld(head, void)

	-- Cream belly / jaw trim
	local belly = part(
		model,
		"CreamBelly",
		Vector3.new(2.0, 0.9, 1.65),
		origin * CFrame.new(0, -1.0, 0.2),
		CREAM,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	weld(head, belly)

	local jaw = part(
		model,
		"JawTrim",
		Vector3.new(1.55, 0.32, 1.05),
		origin * CFrame.new(0, -1.2, 0.4),
		CREAM,
		Enum.Material.SmoothPlastic
	)
	weld(head, jaw)

	-- Dark eye sockets (64px silhouette punches)
	local eyeL = part(
		model,
		"EyeSocketL",
		Vector3.new(0.58, 0.7, 0.38),
		origin * CFrame.new(-0.58, 0.12, 1.0),
		NIGHT,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	weld(head, eyeL)

	local eyeR = part(
		model,
		"EyeSocketR",
		Vector3.new(0.58, 0.7, 0.38),
		origin * CFrame.new(0.58, 0.12, 1.0),
		NIGHT,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	weld(head, eyeR)

	local irisL = part(
		model,
		"IrisL",
		Vector3.new(0.24, 0.24, 0.14),
		eyeL.CFrame * CFrame.new(0, 0, 0.14),
		GOLD,
		Enum.Material.Neon,
		Enum.PartType.Ball
	)
	weld(head, irisL)

	local irisR = part(
		model,
		"IrisR",
		Vector3.new(0.24, 0.24, 0.14),
		eyeR.CFrame * CFrame.new(0, 0, 0.14),
		GOLD,
		Enum.Material.Neon,
		Enum.PartType.Ball
	)
	weld(head, irisR)

	-- Signature spike: gold crack line + raised dome shard
	local crack = part(
		model,
		"GoldCrack",
		Vector3.new(0.16, 1.4, 0.12),
		origin * CFrame.new(0.18, 0.9, -0.12) * CFrame.Angles(0, 0, math.rad(18)),
		GOLD,
		Enum.Material.Neon
	)
	weld(head, crack)

	local spike = part(
		model,
		"CrackSpike",
		Vector3.new(0.48, 0.95, 0.36),
		origin * CFrame.new(0.4, 1.55, -0.18) * CFrame.Angles(0, 0, math.rad(-28)),
		GOLD,
		Enum.Material.Metal
	)
	weld(head, spike)

	-- Chunky stub legs + cream feet
	local legL = part(
		model,
		"LegL",
		Vector3.new(0.58, 0.72, 0.58),
		origin * CFrame.new(-0.58, -1.65, 0.1),
		PURPLE,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	weld(head, legL)

	local legR = part(
		model,
		"LegR",
		Vector3.new(0.58, 0.72, 0.58),
		origin * CFrame.new(0.58, -1.65, 0.1),
		PURPLE,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	weld(head, legR)

	local footL = part(
		model,
		"FootL",
		Vector3.new(0.52, 0.22, 0.58),
		legL.CFrame * CFrame.new(0, -0.42, 0.06),
		CREAM,
		Enum.Material.SmoothPlastic
	)
	weld(head, footL)

	local footR = part(
		model,
		"FootR",
		Vector3.new(0.52, 0.22, 0.58),
		legR.CFrame * CFrame.new(0, -0.42, 0.06),
		CREAM,
		Enum.Material.SmoothPlastic
	)
	weld(head, footR)

	model.PrimaryPart = head
	model:SetAttribute("PetId", "trend_offline_brain")
	model:SetAttribute("Silhouette", "OfflineBrain")

	applyRarityRim(model, "Secret")
	addSecretDrip(head)

	return model
end

--- Generic chunky blob fallback (~4 studs) until bespoke art.
local function buildGeneric(petId: string, rarity: string): Model
	local model = Instance.new("Model")
	model.Name = petId

	local origin = CFrame.new(0, 2.0, 0)
	local body = part(model, "Primary", Vector3.new(2.3, 2.1, 2.1), origin, PURPLE, Enum.Material.SmoothPlastic, Enum.PartType.Ball)

	local belly = part(
		model,
		"CreamBelly",
		Vector3.new(1.7, 1.15, 1.45),
		origin * CFrame.new(0, -0.4, 0.4),
		CREAM,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	weld(body, belly)

	local trim = part(
		model,
		"GoldTrim",
		Vector3.new(0.4, 0.4, 0.4),
		origin * CFrame.new(0, 1.05, 0),
		GOLD,
		Enum.Material.Neon,
		Enum.PartType.Ball
	)
	weld(body, trim)

	local legL = part(model, "LegL", Vector3.new(0.55, 0.7, 0.55), origin * CFrame.new(-0.55, -1.35, 0), PURPLE)
	weld(body, legL)
	local legR = part(model, "LegR", Vector3.new(0.55, 0.7, 0.55), origin * CFrame.new(0.55, -1.35, 0), PURPLE)
	weld(body, legR)

	model.PrimaryPart = body
	model:SetAttribute("PetId", petId)

	applyRarityRim(model, rarity)
	if rarity == "Secret" or rarity == "Mythic" then
		addSecretDrip(body)
	end

	return model
end

function PetFactory.BuildModel(petId: string): Model
	local def = PetCatalog.Get(petId)
	local rarity = if def then def.rarity else "Common"

	local model: Model
	if petId == "trend_offline_brain" then
		model = buildOfflineBrain()
	else
		model = buildGeneric(petId, rarity)
	end

	if def then
		model:SetAttribute("DisplayName", def.name)
		model:SetAttribute("Rarity", def.rarity)
	end
	model:SetAttribute("PetId", petId)
	return model
end

return PetFactory
