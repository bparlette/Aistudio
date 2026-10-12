--!strict
-- Client juice VFX — Art Direction signature moments (pure Luau Instances, no paid assets)
-- Listens to Remotes.Juice. Uses RarityColors brand tokens.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RarityColors = require(Modules:WaitForChild("RarityColors"))
local Maid = require(Modules:WaitForChild("Maid"))

local Brand = RarityColors.Brand()
local GOLD = Brand.Gold
local LILAC = Brand.Lilac
local CREAM = Brand.Cream
local HEAT = Brand.HeatPink
local PURPLE = Brand.DeepPurple
local VOID = Brand.NightVoid


local function getAuraStagePart(): BasePart?
	local stage = workspace:FindFirstChild("AuraStage")
	if stage and stage:IsA("BasePart") then
		return stage
	end
	if stage and stage:IsA("Model") then
		if stage.PrimaryPart then
			return stage.PrimaryPart
		end
		local pad = stage:FindFirstChild("StagePad") or stage:FindFirstChild("GoldDisc")
		if pad and pad:IsA("BasePart") then
			return pad
		end
	end
	return nil
end

local localPlayer = Players.LocalPlayer
local VfxService = {}

local flexClearToken = 0
local folder: Folder? = nil
local serviceMaid = Maid.new()
-- Holder so Start cleanup always cleans the current FX pool after resets
local fxPool = { maid = Maid.new(), active = 0 }
local MAX_CONCURRENT_FX = 24

-- Slight camera FOV punch for Rare+/Mythic juice (TweenService only; Maid-cleaned)
local fovPunchToken = 0
local fovPunchMaid = Maid.new()

local function cameraFovPunch(delta: number, outSec: number?, backSec: number?)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	fovPunchToken += 1
	local my = fovPunchToken
	fovPunchMaid:DoCleaning()
	fovPunchMaid = Maid.new()

	local base = cam.FieldOfView
	local outT = outSec or 0.08
	local backT = backSec or 0.18
	local target = math.clamp(base + delta, 55, 85)

	local twOut = TweenService:Create(
		cam,
		TweenInfo.new(outT, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = target }
	)
	fovPunchMaid:Give(function()
		twOut:Cancel()
		if cam and cam.Parent then
			cam.FieldOfView = base
		end
	end)
	twOut:Play()

	fovPunchMaid:Give(task.delay(outT, function()
		if my ~= fovPunchToken then
			return
		end
		if not cam or not cam.Parent then
			return
		end
		local twBack = TweenService:Create(
			cam,
			TweenInfo.new(backT, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ FieldOfView = base }
		)
		fovPunchMaid:Give(function()
			twBack:Cancel()
			if cam and cam.Parent then
				cam.FieldOfView = base
			end
		end)
		twBack:Play()
	end))
end

local function rarityWantsFovPunch(rarity: string): boolean
	return rarity == "Rare"
		or rarity == "Epic"
		or rarity == "Legendary"
		or rarity == "Mythic"
		or rarity == "Secret"
end

local function trackFx(inst: Instance, lifetime: number?): Instance
	if fxPool.active >= MAX_CONCURRENT_FX then
		-- Cap concurrent: wipe pool when saturated (keeps juice from stacking forever)
		fxPool.maid:DoCleaning()
		fxPool.maid = Maid.new()
		fxPool.active = 0
	end
	fxPool.active += 1
	fxPool.maid:GiveInstance(inst)
	local life = lifetime or 2
	fxPool.maid:Give(task.delay(life, function()
		if inst.Parent then
			inst:Destroy()
		end
		fxPool.active = math.max(0, fxPool.active - 1)
	end))
	return inst
end

local function vfxFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "CloutRanchVfx"
	f.Parent = workspace
	folder = f
	return f
end

local function resolvePosition(meta: { [string]: any }?): Vector3?
	if not meta then
		return nil
	end
	local p = meta.position
	if typeof(p) == "Vector3" then
		return p
	end
	if typeof(p) == "table" and typeof(p.x) == "number" then
		return Vector3.new(p.x, p.y, p.z)
	end
	local uid = meta.subjectUserId or meta.targetUserId
	if typeof(uid) == "number" then
		local plr = Players:GetPlayerByUserId(uid)
		local char = plr and plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root.Position
		end
	end
	local char = localPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

local function makeAnchor(at: Vector3, lifetime: number): BasePart
	local part = Instance.new("Part")
	part.Name = "VfxAnchor"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = CFrame.new(at)
	part.Parent = vfxFolder()
	trackFx(part, lifetime)
	return part
end

local function flashHighlight(adornee: Instance, fill: Color3, outline: Color3, duration: number)
	local h = Instance.new("Highlight")
	h.Name = "JuiceHighlight"
	h.Adornee = adornee
	h.FillColor = fill
	h.OutlineColor = outline
	h.FillTransparency = 0.35
	h.OutlineTransparency = 0.1
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = vfxFolder()
	trackFx(h, duration + 0.05)
	TweenService:Create(h, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FillTransparency = 1,
		OutlineTransparency = 1,
	}):Play()
end

local function screenFlash(color: Color3, peakTransparency: number, duration: number)
	local pg = localPlayer:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return
	end
	local gui = pg:FindFirstChild("CloutRanchVfxGui")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "CloutRanchVfxGui"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 80
		gui.Parent = pg
	end
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = color
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.ZIndex = 100
	f.Parent = gui
	TweenService:Create(f, TweenInfo.new(duration * 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = peakTransparency,
	}):Play()
	task.delay(duration * 0.25, function()
		local tw = TweenService:Create(f, TweenInfo.new(duration * 0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		})
		tw:Play()
		tw.Completed:Once(function()
			f:Destroy()
		end)
	end)
end

local function clearEphemeralVfx()
	local f = vfxFolder()
	for _, child in f:GetChildren() do
		if child:GetAttribute("FlexClearable") == true then
			child:Destroy()
		end
	end
end


--- Big place VFX — gold shock ring + floating PLACED stamp (post-buy pad pop)
function VfxService.PlaceBurst(meta: { [string]: any }?)
	local at = resolvePosition(meta)
	if not at then
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			at = hrp.Position
		else
			at = Vector3.new(0, 3, 0)
		end
	end
	cameraFovPunch(4)
	local anchor = makeAnchor(at + Vector3.new(0, 2.5, 0), 1.8)
	flashHighlight(anchor, GOLD, HEAT, 0.7)

	local ring = Instance.new("Part")
	ring.Name = "PlaceShock"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.4, 2, 2)
	ring.CFrame = CFrame.new(at + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = GOLD
	ring.Transparency = 0.2
	ring.Parent = folder or workspace
	TweenService:Create(
		ring,
		TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.2, 18, 18), Transparency = 1 }
	):Play()
	task.delay(0.6, function()
		if ring.Parent then
			ring:Destroy()
		end
	end)

	local bill = Instance.new("BillboardGui")
	bill.Name = "PlaceStamp"
	bill.Size = UDim2.fromOffset(180, 48)
	bill.StudsOffset = Vector3.new(0, 3, 0)
	bill.AlwaysOnTop = true
	bill.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 26
	label.TextColor3 = GOLD
	label.TextStrokeColor3 = VOID
	label.TextStrokeTransparency = 0.15
	label.Text = "🐾 PLACED!"
	label.Parent = bill
	task.delay(1.4, function()
		if bill.Parent then
			bill:Destroy()
		end
	end)
end

--- 1) Hatch drip — gold pour into pet (skip particle soup on Common)
function VfxService.HatchDrip(meta: { [string]: any }?)
	local rarity = if meta and typeof(meta.rarity) == "string" then meta.rarity else "Common"
	if rarity == "Common" then
		-- cream flash only — Art kill-list: no particle soup on Common
		local at = resolvePosition(meta)
		if at then
			local anchor = makeAnchor(at + Vector3.new(0, 3, 0), 0.6)
			flashHighlight(anchor, CREAM, GOLD, 0.45)
		end
		return
	end

	local at = resolvePosition(meta) or Vector3.new(0, 2, 0)
	local anchor = makeAnchor(at + Vector3.new(0, 5, 0), 1.4)
	anchor:SetAttribute("FlexClearable", true)

	if rarityWantsFovPunch(rarity) then
		local punch = if rarity == "Mythic" or rarity == "Secret" then 6 else if rarity == "Legendary" then 5 else 3.5
		cameraFovPunch(punch)
	end

	local att = Instance.new("Attachment")
	att.Parent = anchor

	local pour = Instance.new("ParticleEmitter")
	pour.Name = "HatchDrip"
	pour.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pour.Color = ColorSequence.new(GOLD, LILAC)
	pour.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(1, 0.08),
	})
	pour.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	pour.Lifetime = NumberRange.new(0.55, 0.85)
	pour.Speed = NumberRange.new(2, 4)
	pour.SpreadAngle = Vector2.new(12, 12)
	pour.Acceleration = Vector3.new(0, -28, 0)
	pour.Rate = 0
	pour.LightEmission = 0.6
	pour.Parent = att

	local burstCount = if rarity == "Mythic" or rarity == "Secret" or rarity == "Legendary" then 28 else if rarity == "Epic" then 18 else 12
	pour:Emit(burstCount)

	-- Rare+ stamp billboard
	local bill = Instance.new("BillboardGui")
	bill.Name = "HatchStamp"
	bill.Size = UDim2.fromOffset(120, 36)
	bill.StudsOffset = Vector3.new(0, -2.5, 0)
	bill.AlwaysOnTop = true
	bill.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 22
	label.TextColor3 = CREAM
	label.TextStrokeColor3 = GOLD
	label.TextStrokeTransparency = 0.2
	label.Text = string.upper(rarity)
	label.Parent = bill

	if rarity == "Mythic" or rarity == "Secret" or rarity == "Legendary" then
		VfxService.MythicEntrance(meta)
	end
end

--- 2) Flex shock-ring gold→lilac + purple afterimage
function VfxService.FlexShockRing(meta: { [string]: any }?)
	flexClearToken += 1
	clearEphemeralVfx()

	local stage = getAuraStagePart()
	local at: Vector3
	if stage then
		at = stage.Position + Vector3.new(0, 1.2, 0)
	else
		at = resolvePosition(meta) or Vector3.new(0, 1, -28)
	end

	local ring = Instance.new("Part")
	ring.Name = "FlexShockRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = GOLD
	ring.Size = Vector3.new(0.35, 4, 4)
	ring.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	ring:SetAttribute("FlexClearable", true)
	ring.Parent = vfxFolder()

	local after = ring:Clone()
	after.Name = "FlexAfterimage"
	after.Color = PURPLE
	after.Transparency = 0.45
	after.Size = Vector3.new(0.25, 3.2, 3.2)
	after.Parent = vfxFolder()

	TweenService:Create(ring, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.2, 28, 28),
		Color = LILAC,
		Transparency = 1,
	}):Play()
	TweenService:Create(after, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.15, 34, 34),
		Transparency = 1,
	}):Play()
	trackFx(ring, 0.9)
	trackFx(after, 1.0)

	-- cream type stamp with gold outline
	local stampAnchor = makeAnchor(at + Vector3.new(0, 4, 0), 1.2)
	stampAnchor:SetAttribute("FlexClearable", true)
	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(200, 48)
	bill.AlwaysOnTop = true
	bill.Parent = stampAnchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 28
	label.TextColor3 = CREAM
	label.TextStrokeColor3 = GOLD
	label.TextStrokeTransparency = 0.15
	label.Text = "AURA FLEX"
	label.Parent = bill
end

--- Aura podium beams (gold #1, lilac/purple #2/#3)
function VfxService.AuraPodiumBeams(meta: { [string]: any }?)
	VfxService.FlexShockRing(meta)

	local winners = if meta and typeof(meta.winners) == "table" then meta.winners else {}
	local stage = getAuraStagePart()
	local stagePos = if stage then stage.Position else Vector3.new(0, 0.5, -28)

	local colors = { GOLD, LILAC, PURPLE }
	for i, uid in winners do
		if i > 3 then
			break
		end
		local plr = typeof(uid) == "number" and Players:GetPlayerByUserId(uid) or nil
		local char = plr and plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			flashHighlight(char :: Model, colors[i], GOLD, 3.5)
			local att0 = Instance.new("Attachment")
			att0.Name = "PodiumBeam0"
			att0.Position = Vector3.new(0, 0.5, 0)
			att0.Parent = if stage then stage else makeAnchor(stagePos, 4)
			local att1 = Instance.new("Attachment")
			att1.Name = "PodiumBeam1"
			att1.Parent = root
			local beam = Instance.new("Beam")
			beam.Attachment0 = att0
			beam.Attachment1 = att1
			beam.Color = ColorSequence.new(colors[i], GOLD)
			beam.Width0 = 1.4
			beam.Width1 = 0.35
			beam.FaceCamera = true
			beam.LightEmission = 0.85
			beam.Transparency = NumberSequence.new(0.15, 0.55)
			beam.Parent = vfxFolder()
			trackFx(att0, 4)
			trackFx(att1, 4)
			trackFx(beam, 4)
		end
	end
end

--- 3) Steal/trade slap: cream flash + short gold coin arc (+ FOV punch)
function VfxService.StealCreamFlash(meta: { [string]: any }?)
	screenFlash(CREAM, 0.55, 0.28)
	cameraFovPunch(5, 0.07, 0.2)
	local at = resolvePosition(meta) or Vector3.new(0, 3, 0)
	local anchor = makeAnchor(at + Vector3.new(0, 2, 0), 1.0)
	anchor:SetAttribute("FlexClearable", true)

	local att = Instance.new("Attachment")
	att.Parent = anchor
	local coins = Instance.new("ParticleEmitter")
	coins.Name = "CoinArc"
	coins.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	coins.Color = ColorSequence.new(GOLD)
	coins.Size = NumberSequence.new(0.35, 0.1)
	coins.Transparency = NumberSequence.new(0.1, 1)
	coins.Lifetime = NumberRange.new(0.35, 0.55)
	coins.Speed = NumberRange.new(8, 14)
	coins.SpreadAngle = Vector2.new(35, 15)
	coins.Acceleration = Vector3.new(0, -40, 0)
	coins.EmissionDirection = Enum.NormalId.Top
	coins.Rate = 0
	coins.LightEmission = 0.7
	coins.Parent = att
	coins:Emit(10)

	-- Prefer subjectUserId (server Steal payload); fall back to local thief so DemoRival steals still trail
	local uid = meta and meta.subjectUserId
	local plr = if typeof(uid) == "number" then Players:GetPlayerByUserId(uid) else localPlayer
	local char = plr and plr.Character
	if char then
		flashHighlight(char, CREAM, GOLD, 0.55)
		-- steal trail while carrying: light gold drip only if not Common-locked soup
		local root = char:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local trailAtt0 = Instance.new("Attachment")
			trailAtt0.Position = Vector3.new(0, 1.2, 0)
			trailAtt0.Parent = root
			local trail = Instance.new("ParticleEmitter")
			trail.Name = "StealTrail"
			trail.Texture = "rbxasset://textures/particles/smoke_main.dds"
			trail.Color = ColorSequence.new(GOLD, CREAM)
			trail.Size = NumberSequence.new(0.25, 0.05)
			trail.Transparency = NumberSequence.new(0.4, 1)
			trail.Lifetime = NumberRange.new(0.3, 0.5)
			trail.Speed = NumberRange.new(0.2, 0.6)
			trail.Rate = 8
			trail.LightEmission = 0.4
			trail.Parent = trailAtt0
			trackFx(trailAtt0, 8)
		end
	end
end

--- Slap alias → cream flash + coin arc
function VfxService.Slap(meta: { [string]: any }?)
	VfxService.StealCreamFlash(meta)
end

--- 4) Rebirth / ranch level-up flash (purple→gold chase feel)
function VfxService.RebirthFlash(meta: { [string]: any }?)
	screenFlash(GOLD, 0.4, 0.55)
	local at = resolvePosition(meta) or Vector3.new(0, 3, 0)
	local anchor = makeAnchor(at, 1.2)
	local att = Instance.new("Attachment")
	att.Parent = anchor
	local burst = Instance.new("ParticleEmitter")
	burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	burst.Color = ColorSequence.new(PURPLE, GOLD)
	burst.Size = NumberSequence.new(0.5, 0.05)
	burst.Transparency = NumberSequence.new(0.2, 1)
	burst.Lifetime = NumberRange.new(0.4, 0.7)
	burst.Speed = NumberRange.new(6, 12)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Rate = 0
	burst.LightEmission = 0.8
	burst.Parent = att
	burst:Emit(22)
end

--- 5) Mythic entrance — heat-pink sky flash + local gold drip rain 1.5s
function VfxService.MythicEntrance(meta: { [string]: any }?)
	screenFlash(HEAT, 0.5, 0.45)
	cameraFovPunch(7, 0.1, 0.22)

	-- brief Lighting nudge (local client only)
	local prev = Lighting.Ambient
	Lighting.Ambient = HEAT:Lerp(VOID, 0.55)
	task.delay(0.35, function()
		Lighting.Ambient = prev
	end)

	local at = resolvePosition(meta) or Vector3.new(0, 8, 0)
	local rainAnchor = makeAnchor(at + Vector3.new(0, 10, 0), 1.8)
	rainAnchor:SetAttribute("FlexClearable", true)
	local att = Instance.new("Attachment")
	att.Parent = rainAnchor
	local rain = Instance.new("ParticleEmitter")
	rain.Name = "GoldDripRain"
	rain.Texture = "rbxasset://textures/particles/smoke_main.dds"
	rain.Color = ColorSequence.new(GOLD)
	rain.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	rain.Transparency = NumberSequence.new(0.2, 1)
	rain.Lifetime = NumberRange.new(0.6, 1.0)
	rain.Speed = NumberRange.new(10, 16)
	rain.SpreadAngle = Vector2.new(40, 40)
	rain.Acceleration = Vector3.new(0, -20, 0)
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.Rate = 40
	rain.LightEmission = 0.65
	rain.Parent = att
	task.delay(1.5, function()
		rain.Enabled = false
		rain.Rate = 0
	end)
end

function VfxService.Handle(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	local kind = payload.kind
	if typeof(kind) ~= "string" then
		return
	end

	if kind == "place_burst" or kind == "place" then
		VfxService.PlaceBurst(payload)
	elseif kind == "hatch_burst" or kind == "hatch_drip" or kind == "buy" then
		VfxService.HatchDrip(payload)
		if payload.place == true then
			VfxService.PlaceBurst(payload)
		end
	elseif kind == "aura_beams" or kind == "flex_shock" or kind == "flex" then
		VfxService.AuraPodiumBeams(payload)
	elseif kind == "steal_trail" or kind == "steal" then
		VfxService.StealCreamFlash(payload)
	elseif kind == "slap" then
		VfxService.Slap(payload)
	elseif kind == "rebirth_flash" or kind == "rebirth" then
		VfxService.RebirthFlash(payload)
	elseif kind == "mythic" or kind == "mythic_entrance" then
		VfxService.MythicEntrance(payload)
	elseif kind == "rare" then
		cameraFovPunch(3.5)
		local at = resolvePosition(payload)
		if at then
			local a = makeAnchor(at + Vector3.new(0, 2, 0), 0.6)
			flashHighlight(a, GOLD, LILAC, 0.4)
		end
	elseif kind == "deposit" or kind == "lock" or kind == "clip" or kind == "pop" then
		-- soft cream pop
		local at = resolvePosition(payload)
		if at then
			local a = makeAnchor(at + Vector3.new(0, 2, 0), 0.5)
			flashHighlight(a, CREAM, GOLD, 0.35)
		end
	elseif kind == "vote_punch" then
		-- Aura Flex rival/player vote confirm — FOV + cream stamp (cosmetic only)
		local rival = payload.rival == true
		cameraFovPunch(if rival then 6.5 else 4.5, 0.07, 0.22)
		screenFlash(if rival then HEAT else CREAM, if rival then 0.62 else 0.7, 0.22)
		local at = resolvePosition(payload) or Vector3.new(0, 3, -28)
		local stage = getAuraStagePart()
		if stage then
			at = stage.Position + Vector3.new(0, 2.5, 0)
		end
		local stampAnchor = makeAnchor(at, 1.1)
		stampAnchor:SetAttribute("FlexClearable", true)
		local bill = Instance.new("BillboardGui")
		bill.Size = UDim2.fromOffset(200, 44)
		bill.AlwaysOnTop = true
		bill.Parent = stampAnchor
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 24
		label.TextColor3 = CREAM
		label.TextStrokeColor3 = if rival then HEAT else GOLD
		label.TextStrokeTransparency = 0.15
		label.Text = if rival then "VOTED RIVAL!" else "VOTE LOCKED!"
		label.Parent = bill
	elseif kind == "shake" then
		screenFlash(CREAM, 0.7, 0.2)
	end
end

function VfxService.Start(parentMaid: any?)
	-- Reset FX pool maid under service lifetime
	fxPool.maid:DoCleaning()
	fxPool.maid = Maid.new()
	fxPool.active = 0
	fovPunchMaid:DoCleaning()
	fovPunchMaid = Maid.new()
	fovPunchToken += 1
	serviceMaid:DoCleaning()
	serviceMaid = Maid.new()
	serviceMaid:Give(function()
		fxPool.maid:DoCleaning()
		fovPunchMaid:DoCleaning()
	end)
	if parentMaid and typeof(parentMaid.Give) == "function" then
		parentMaid:Give(function()
			serviceMaid:DoCleaning()
		end)
	end

	local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
	if not remotes then
		warn("[CloutRanch] VfxService: Remotes missing")
		return
	end
	local juice = remotes:WaitForChild("Juice", 10)
	if not juice or not juice:IsA("RemoteEvent") then
		warn("[CloutRanch] VfxService: Remotes.Juice missing")
		return
	end
	serviceMaid:GiveConnection(juice.OnClientEvent:Connect(function(payload)
		VfxService.Handle(payload)
	end))

	-- Also react to Aura phase → flex shock when podium/flex begins
	local state = ReplicatedStorage:FindFirstChild("CloutState")
	if state then
		local phase = state:FindFirstChild("Phase")
		if phase and phase:IsA("StringValue") then
			local last = phase.Value
			serviceMaid:GiveConnection(phase:GetPropertyChangedSignal("Value"):Connect(function()
				local v = phase.Value
				if v == "flex" and last ~= "flex" then
					VfxService.FlexShockRing({ kind = "flex_shock" })
				elseif v == "podium" and last ~= "podium" then
					VfxService.AuraPodiumBeams({ kind = "aura_beams" })
				end
				last = v
			end))
		end
	end

	print("[CloutRanch] VfxService online (Maid-tracked FX, cap=" .. tostring(MAX_CONCURRENT_FX) .. ")")
end

return VfxService
