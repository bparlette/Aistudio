--!strict
-- Server ModuleScript: steal pets from unlocked ranches (readable chase + clear feedback)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetCatalog"))
local RanchService = require(script.Parent:WaitForChild("RanchService"))

local SOFT_PROTECT = 15
do
	local cfgFolder = ReplicatedStorage:FindFirstChild("Config")
	local mod = cfgFolder and cfgFolder:FindFirstChild("EconomyConfig")
	if mod and mod:IsA("ModuleScript") then
		local ok, cfg = pcall(require, mod)
		if ok and cfg and typeof(cfg.SoftProtectSeconds) == "number" then
			SOFT_PROTECT = cfg.SoftProtectSeconds
		end
	end
end
local STEAL_RANGE = 45 -- denser solo: spawn ring can reach adjacent demo pads
local SLAP_RANGE = 20
local DROP_IFRAMES = 0.5 -- slap immunity after drop
local BASE_WALK = 16
-- Readable carry: floor 7, amplify catalog carrySlow so chases feel fair
local CARRY_SLOW_MULT = 1.4
local CARRY_SLOW_MIN = 0.22
local CARRY_SLOW_MAX = 0.55
local CARRY_SPEED_FLOOR = 7

export type CarryState = {
	petId: string,
	fromPlot: string,
	fromSlot: number,
	ownerUserId: number,
}

local carrying: { [number]: CarryState } = {}
local lastStolenAt: { [number]: number } = {} -- victim userId
local dropIframesUntil: { [number]: number } = {} -- thief userId → os.clock()

local StealService = {}


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

local function tryKillfeed(): any?
	local mod = script.Parent:FindFirstChild("KillfeedService")
	if mod and mod:IsA("ModuleScript") then
		local ok, result = pcall(require, mod)
		if ok then
			return result
		end
	end
	return nil
end

local function victimDisplayName(userId: number): string
	local plr = Players:GetPlayerByUserId(userId)
	return if plr then plr.DisplayName else ("Ranch#" .. tostring(userId))
end


local function softFeedback(player: Player, message: string, tone: string?)
	local mod = script.Parent:FindFirstChild("FeedbackService")
	if not mod then
		return
	end
	local ok, fb = pcall(require, mod)
	if ok and fb and fb.Tell then
		fb.Tell(player, message, tone or "warn")
	end
end

local function softJuiceSteal(player: Player, petName: string?)
	local mod = script.Parent:FindFirstChild("JuiceService")
	if not mod then
		return
	end
	local ok, juice = pcall(require, mod)
	if ok and juice and juice.Steal then
		juice.Steal(player, petName)
	end
end

local function softOnboardSteal(player: Player)
	local mod = script.Parent:FindFirstChild("OnboardingService")
	if not mod then
		return
	end
	local ok, ob = pcall(require, mod)
	if ok and ob and ob.NotifyStealOrLock then
		ob.NotifyStealOrLock(player)
	end
end

local function softQuestSteal(player: Player)
	-- Shared path: StealPet/StealClosest remotes + WorldInteract E-steal
	local mod = script.Parent:FindFirstChild("QuestService")
	if not mod then
		return
	end
	local ok, Quest = pcall(require, mod)
	if ok and Quest and Quest.Progress then
		Quest.Progress(player, "steal_pet", 1)
	end
end


local function softMarkDopamine(player: Player, kind: string?)
	local mod = script.Parent:FindFirstChild("OfferService")
	if not mod then
		return
	end
	local ok, offers = pcall(require, mod)
	if ok and offers and offers.MarkDopamine then
		offers.MarkDopamine(player, kind)
	end
end

local function afterDepositHooks(player: Player)
	-- Shared path for DepositPet remote + WorldInteract DepositPad
	local qs = script.Parent:FindFirstChild("QuestService")
	if qs then
		local ok, Quest = pcall(require, qs)
		if ok and Quest and Quest.Progress then
			Quest.Progress(player, "deposit_steal", 1)
		end
	end
	local bp = script.Parent:FindFirstChild("BattlePassService")
	if bp then
		local ok, BPS = pcall(require, bp)
		if ok and BPS and BPS.AddXp then
			BPS.AddXp(player, 25)
		end
	end
	local juiceMod = script.Parent:FindFirstChild("JuiceService")
	local juiced = false
	if juiceMod then
		local jok, juice = pcall(require, juiceMod)
		if jok and juice and juice.Deposit then
			juice.Deposit(player)
			juiced = true
		end
	end
	if not juiced then
		softFeedback(player, "Pet secured on your ranch!", "steal")
	end
	local onboard = script.Parent:FindFirstChild("OnboardingService")
	if onboard then
		local ok, ob = pcall(require, onboard)
		if ok and ob and ob.NotifyStealOrLock then
			ob.NotifyStealOrLock(player)
		end
	end
	softMarkDopamine(player, "deposit")
end

local function isVipOwner(ownerUserId: number): boolean
	local plr = Players:GetPlayerByUserId(ownerUserId)
	if not plr then
		return false
	end
	local mod = script.Parent:FindFirstChild("Monetization")
	if not mod then
		return false
	end
	local ok, mon = pcall(require, mod)
	if ok and mon and mon.IsVIP then
		return mon.IsVIP(plr) == true
	end
	return false
end

local function applyCarrySlow(thief: Player, petId: string)
	local def = PetCatalog.Get(petId)
	local char = thief.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local slow = if def then def.carrySlow else 0.25
	slow = math.clamp(slow * CARRY_SLOW_MULT, CARRY_SLOW_MIN, CARRY_SLOW_MAX)
	hum.WalkSpeed = math.max(CARRY_SPEED_FLOOR, BASE_WALK * (1 - slow))
end

local function restoreSpeed(player: Player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = BASE_WALK
	end
end

function StealService.GetCarry(player: Player): CarryState?
	return carrying[player.UserId]
end

local function plotWorldPosition(plotName: string): Vector3?
	local folder = workspace:FindFirstChild("Ranches")
	if not folder then
		return nil
	end
	local plot = folder:FindFirstChild(plotName)
	if not plot then
		return nil
	end
	if plot:IsA("Model") and plot.PrimaryPart then
		return plot.PrimaryPart.Position
	end
	local part = plot:FindFirstChildWhichIsA("BasePart", true)
	return if part then part.Position else nil
end

local function fail(thief: Player, reason: string): (boolean, string?)
	softFeedback(thief, reason, "warn")
	return false, reason
end

function StealService.TrySteal(thief: Player, plotName: string, slotIndex: number): (boolean, string?)
	if carrying[thief.UserId] then
		return fail(thief, "Already carrying a pet — Deposit at your ranch!")
	end
	-- Range gate: StealPet remote must not bypass STEAL_RANGE (TryStealClosest already checks)
	local char = thief.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return fail(thief, "No character")
	end
	local plotPos = plotWorldPosition(plotName)
	if not plotPos or (plotPos - root.Position).Magnitude > STEAL_RANGE then
		return fail(thief, "Too far — get closer to a slot")
	end
	local state = RanchService.GetByPlot(plotName)
	if not state or not state.ownerUserId then
		return fail(thief, "Empty ranch — nothing to yoink")
	end
	-- Ownership: never steal from self
	if state.ownerUserId == thief.UserId then
		return fail(thief, "That's your own ranch")
	end
	if RanchService.IsLocked(state) then
		if isVipOwner(state.ownerUserId) then
			return fail(thief, "LOCKED — VIP timer")
		end
		return fail(thief, "LOCKED — vault sealed (wait it out)")
	end
	local victimId = state.ownerUserId
	-- Demo/NPC ranches (negative owner) skip soft protect so solo Studio always has prey
	if victimId > 0 then
		local last = lastStolenAt[victimId] or 0
		if os.clock() - last < SOFT_PROTECT then
			local left = math.ceil(SOFT_PROTECT - (os.clock() - last))
			return fail(thief, "Soft protect — try again in " .. tostring(left) .. "s")
		end
	end
	local petId = state.slots[slotIndex]
	if not petId then
		return fail(thief, "Empty slot")
	end
	RanchService.RemovePetAt(state, slotIndex)
	carrying[thief.UserId] = {
		petId = petId,
		fromPlot = plotName,
		fromSlot = slotIndex,
		ownerUserId = victimId,
	}
	lastStolenAt[victimId] = os.clock()

	applyCarrySlow(thief, petId)
	local vis = tryPetVisual()
	if vis and vis.AttachCarry then
		pcall(vis.AttachCarry, thief, petId)
	end
	local def = PetCatalog.Get(petId)
	local petName = if def then def.name else petId
	softJuiceSteal(thief, petName)
	softOnboardSteal(thief)
	softQuestSteal(thief)
	softFeedback(thief, "Slow & readable — sprint to Deposit!", "steal")
	local KF = tryKillfeed()
	if KF and KF.AnnounceSteal then
		KF.AnnounceSteal(thief, victimDisplayName(victimId), petName)
	end
	-- Clip bait: Secret steals are creator moments
	if def and def.rarity == "Secret" then
		local clipMod = script.Parent:FindFirstChild("ClipMomentService")
		if clipMod then
			local ok, Clip = pcall(require, clipMod)
			if ok and Clip and Clip.OnSecretStolen then
				Clip.OnSecretStolen(thief, petId, victimId)
			end
		end
		local fomoMod = script.Parent:FindFirstChild("FomoBroadcastService")
		if fomoMod then
			pcall(function()
				local Fomo = require(fomoMod)
				if Fomo and Fomo.OnSecretSteal then
					Fomo.OnSecretSteal(thief, petName)
				end
			end)
		end
	end
	softMarkDopamine(thief, "steal")
	return true, nil
end

--- Proximity-friendly: steal from nearest unlocked enemy ranch with a filled slot.
function StealService.TryStealClosest(thief: Player): (boolean, string?)
	if carrying[thief.UserId] then
		return fail(thief, "Already carrying a pet — Deposit at your ranch!")
	end
	local char = thief.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return fail(thief, "No character")
	end

	local folder = workspace:FindFirstChild("Ranches")
	if not folder then
		return fail(thief, "No ranches")
	end

	local bestPlot: string? = nil
	local bestSlot: number? = nil
	local bestDist = math.huge
	local lockedNearby = false
	local vipLocked = false

	for _, plot in folder:GetChildren() do
		local state = RanchService.GetByPlot(plot.Name)
		if state and state.ownerUserId and state.ownerUserId ~= thief.UserId then
			local pos = plotWorldPosition(plot.Name)
			local dist = if pos then (pos - root.Position).Magnitude else math.huge
			if RanchService.IsLocked(state) then
				if dist <= STEAL_RANGE then
					lockedNearby = true
					if isVipOwner(state.ownerUserId) then
						vipLocked = true
					end
				end
			else
				local firstSlot: number? = nil
				for i = 1, state.maxSlots do
					if state.slots[i] then
						firstSlot = i
						break
					end
				end
				if firstSlot and pos and dist < bestDist then
					bestDist = dist
					bestPlot = plot.Name
					bestSlot = firstSlot
				end
			end
		end
	end

	if not bestPlot or not bestSlot then
		if vipLocked then
			return fail(thief, "LOCKED — VIP timer")
		end
		if lockedNearby then
			return fail(thief, "LOCKED — vault sealed (wait it out)")
		end
		return fail(thief, "No unlocked prey nearby")
	end
	if bestDist > STEAL_RANGE then
		return fail(thief, "Too far — get closer to a slot")
	end
	return StealService.TrySteal(thief, bestPlot, bestSlot)
end

function StealService.Drop(thief: Player, returnToOwner: boolean)
	local carry = carrying[thief.UserId]
	if not carry then
		return
	end
	carrying[thief.UserId] = nil
	restoreSpeed(thief)
	local vis = tryPetVisual()
	if vis and vis.ClearCarry then
		pcall(vis.ClearCarry, thief)
	end
	-- 0.5s i-frames: can't be slapped again immediately after drop
	dropIframesUntil[thief.UserId] = os.clock() + DROP_IFRAMES
	if returnToOwner then
		local ownerRanch = RanchService.GetByUser(carry.ownerUserId)
		if ownerRanch then
			for i = 1, ownerRanch.maxSlots do
				if ownerRanch.slots[i] == nil then
					ownerRanch.slots[i] = carry.petId
					if vis and vis.SpawnOnSlot then
						pcall(vis.SpawnOnSlot, ownerRanch.plotName, i, carry.petId)
					end
					return
				end
			end
		end
	end
end

function StealService.TryDeposit(thief: Player): (boolean, string?)
	local carry = carrying[thief.UserId]
	if not carry then
		return fail(thief, "Not carrying — Steal a pet first")
	end
	local ok, err = RanchService.TryPlacePet(thief, carry.petId)
	if not ok then
		return fail(thief, err or "Can't deposit")
	end
	carrying[thief.UserId] = nil
	restoreSpeed(thief)
	local vis = tryPetVisual()
	if vis and vis.ClearCarry then
		pcall(vis.ClearCarry, thief)
	end
	RanchService.Lock(thief, false)
	local KF = tryKillfeed()
	if KF and KF.AnnounceDeposit then
		local def = PetCatalog.Get(carry.petId)
		KF.AnnounceDeposit(thief, if def then def.name else carry.petId)
	end
	afterDepositHooks(thief)
	return true, nil
end

function StealService.Slap(attacker: Player, target: Player): boolean
	local untilT = dropIframesUntil[target.UserId]
	if untilT and os.clock() < untilT then
		softFeedback(attacker, "I-frames — they just dropped (0.5s)", "info")
		return false
	end
	local aChar = attacker.Character
	local tChar = target.Character
	local aRoot = aChar and aChar:FindFirstChild("HumanoidRootPart")
	local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
	if not aRoot or not tRoot or not aRoot:IsA("BasePart") or not tRoot:IsA("BasePart") then
		return false
	end
	if (aRoot.Position - tRoot.Position).Magnitude > SLAP_RANGE then
		softFeedback(attacker, "Too far to slap (~20 studs)", "warn")
		return false
	end
	local carry = carrying[target.UserId]
	if not carry then
		return false
	end
	if carry.ownerUserId ~= attacker.UserId and RanchService.GetByUser(attacker.UserId) == nil then
		-- anyone can slap a thief; owner slap preferred thematically
	end
	local petName: string? = nil
	local def = PetCatalog.Get(carry.petId)
	if def then
		petName = def.name
	end
	StealService.Drop(target, true)
	softFeedback(target, "👋 Slapped — pet returned!", "warn")
	softFeedback(attacker, "👋 Nice slap — pet secured back!", "success")
	local KF = tryKillfeed()
	if KF and KF.AnnounceSlap then
		KF.AnnounceSlap(attacker, target.DisplayName, petName)
	end
	local juiceMod = script.Parent:FindFirstChild("JuiceService")
	if juiceMod then
		local jok, juice = pcall(require, juiceMod)
		if jok and juice then
			if juice.Play then
				juice.Play(attacker, "slap", { message = "slapped" })
				juice.Play(target, "slap", { message = "dropped" })
			elseif juice.Pop then
				juice.Pop(attacker, "slap")
			end
		end
	end
	return true
end

--- Slap nearest carrying thief within range (ProximityPrompt helper).
function StealService.SlapClosest(attacker: Player): boolean
	local char = attacker.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	local best: Player? = nil
	local bestDist = math.huge
	for _, other in Players:GetPlayers() do
		if other ~= attacker and carrying[other.UserId] then
			local oChar = other.Character
			local oRoot = oChar and oChar:FindFirstChild("HumanoidRootPart")
			if oRoot and oRoot:IsA("BasePart") then
				local dist = (oRoot.Position - root.Position).Magnitude
				if dist < bestDist and dist <= SLAP_RANGE then
					bestDist = dist
					best = other
				end
			end
		end
	end
	if not best then
		softFeedback(attacker, "No carrying thief in range", "info")
		return false
	end
	return StealService.Slap(attacker, best)
end

Players.PlayerRemoving:Connect(function(player)
	if carrying[player.UserId] then
		StealService.Drop(player, true)
	end
	dropIframesUntil[player.UserId] = nil
	lastStolenAt[player.UserId] = nil
end)

return StealService
