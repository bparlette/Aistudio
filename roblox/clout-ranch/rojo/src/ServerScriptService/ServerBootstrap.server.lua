--!strict
-- Server Script (Script, not Module): boots Clout Ranch MVP loop
-- Place under ServerScriptService. Ensure ModuleScripts live in ServerScriptService/Services
-- and PetCatalog in ReplicatedStorage/Modules.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = script.Parent:WaitForChild("Services")

local RanchService = require(Services:WaitForChild("RanchService"))
local CarpetService = require(Services:WaitForChild("CarpetService"))
local StealService = require(Services:WaitForChild("StealService"))
local AuraService = require(Services:WaitForChild("AuraService"))
local RebirthService = require(Services:WaitForChild("RebirthService"))
local Monetization = require(Services:WaitForChild("Monetization"))
local EconomyService = require(Services:WaitForChild("EconomyService"))

local function tryRequire(name: string)
	local mod = Services:FindFirstChild(name)
	if not mod then
		warn("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		warn("[CloutRanch] FATAL tryRequire — MODULE MISSING:", name)
		warn("[CloutRanch] Services child not found — check Rojo sync / Services folder")
		warn("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		return nil
	end
	local ok, result = pcall(require, mod)
	if ok then
		return result
	end
	warn("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	warn("[CloutRanch] FATAL tryRequire — REQUIRE FAILED:", name)
	warn("[CloutRanch] error:", result)
	warn("[CloutRanch] If this is MapBootstrap, Color3.fromHex or other top-level errors may be the cause — Ranches will stay EMPTY")
	warn("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	return nil
end

local MapBootstrap = tryRequire("MapBootstrap")
local DailyService = tryRequire("DailyService")
local BattlePassService = tryRequire("BattlePassService")
local LuckService = tryRequire("LuckService")
local SeasonService = tryRequire("SeasonService")
local FeedbackService = tryRequire("FeedbackService")
local SessionService = tryRequire("SessionService")
local PartyService = tryRequire("PartyService")
local KillfeedService = tryRequire("KillfeedService")
local FlexEmoteService = tryRequire("FlexEmoteService")
local ShowcaseService = tryRequire("ShowcaseService")
local JuiceService = tryRequire("JuiceService")
local OnboardingService = tryRequire("OnboardingService")
local WorldInteract = tryRequire("WorldInteract")
local QuestService = tryRequire("QuestService")
local ComebackService = tryRequire("ComebackService")
local SoftPityService = tryRequire("SoftPityService")
local TrendDropService = tryRequire("TrendDropService")
local OfferService = tryRequire("OfferService")
local ClipMomentService = tryRequire("ClipMomentService")
local DataService = tryRequire("DataService")
local FomoBroadcastService = tryRequire("FomoBroadcastService")
local DemoRivalService = tryRequire("DemoRivalService")

-- Remotes (create if missing)
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local function ensureRemote(name: string): RemoteEvent
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remotes
	elseif not r:IsA("RemoteEvent") then
		r:Destroy()
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remotes
	end
	return r :: RemoteEvent
end

local function ensureRemoteFunction(name: string): RemoteFunction
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteFunction")
		r.Name = name
		r.Parent = remotes
	elseif not r:IsA("RemoteFunction") then
		r:Destroy()
		r = Instance.new("RemoteFunction")
		r.Name = name
		r.Parent = remotes
	end
	return r :: RemoteFunction
end

local BuyCarpet = ensureRemote("BuyCarpet")
local StealPet = ensureRemote("StealPet")
local DepositPet = ensureRemote("DepositPet")
local SlapThief = ensureRemote("SlapThief")
local SlapPetPrompt = ensureRemote("SlapPetPrompt")
local VoteAura = ensureRemote("VoteAura")
local DoRebirth = ensureRemote("DoRebirth")
local RequestLock = ensureRemote("RequestLock")
local ClaimDaily = ensureRemote("ClaimDaily")
local ClaimBattlePass = ensureRemote("ClaimBattlePass")
local ClaimQuest = ensureRemote("ClaimQuest")
local StealClosest = ensureRemote("StealClosest")
local Feedback = ensureRemote("Feedback")
local PartyInvite = ensureRemote("PartyInvite")
local PartyAccept = ensureRemote("PartyAccept")
local PartyLeave = ensureRemote("PartyLeave")
local PartySync = ensureRemote("PartySync")
local FeedEvent = ensureRemote("FeedEvent")
local DuoFlex = ensureRemote("DuoFlex")
local PinShowcase = ensureRemote("PinShowcase")
ensureRemote("OpenShop") -- client listen; WorldInteract fires
ensureRemote("Juice") -- client camera shake; JuiceService also ensures
local SoftOffer = ensureRemote("SoftOffer") -- soft funnel card (OfferService)
local RequestPurchase = ensureRemote("RequestPurchase") -- gated Monetization.TryPrompt
local GetCarpetStock = ensureRemoteFunction("GetCarpetStock")
local CarpetStockPush = ensureRemote("CarpetStockPush")

-- EARLY carpet stock: bind RF + publish BEFORE MapBootstrap/DataService (avoids RF hang if later boot yields/errors)
local function ensureCloutState(): Folder
	local s = ReplicatedStorage:FindFirstChild("CloutState")
	if not s then
		s = Instance.new("Folder")
		s.Name = "CloutState"
		s.Parent = ReplicatedStorage
	elseif not s:IsA("Folder") then
		s:Destroy()
		s = Instance.new("Folder")
		s.Name = "CloutState"
		s.Parent = ReplicatedStorage
	end
	return s :: Folder
end

local function publishCarpetStock()
	local okPub, errPub = pcall(function()
		local stateFolder = ensureCloutState()
		local stockFolder = stateFolder:FindFirstChild("CarpetStock")
		if not stockFolder or not stockFolder:IsA("Folder") then
			if stockFolder then
				stockFolder:Destroy()
			end
			stockFolder = Instance.new("Folder")
			stockFolder.Name = "CarpetStock"
			stockFolder.Parent = stateFolder
		end

		local detailed: { any } = {}
		if CarpetService.GetStockDetailed then
			detailed = CarpetService.GetStockDetailed()
		end
		if #detailed == 0 and CarpetService.GetStock then
			local ids = CarpetService.GetStock()
			for _, id in ids do
				table.insert(detailed, { id = id, name = id, rarity = "?", price = 0 })
			end
		end

		for i = 1, 4 do
			local slotName = "Slot" .. tostring(i)
			local slot = stockFolder:FindFirstChild(slotName)
			if not slot or not slot:IsA("StringValue") then
				if slot then
					slot:Destroy()
				end
				slot = Instance.new("StringValue")
				slot.Name = slotName
				slot.Parent = stockFolder
			end
			local entry = detailed[i]
			if entry and typeof(entry) == "table" then
				local petId = tostring((entry :: any).id or "")
				;(slot :: StringValue).Value = petId
				slot:SetAttribute("Name", tostring((entry :: any).name or petId))
				slot:SetAttribute("Rarity", tostring((entry :: any).rarity or "Common"))
				local priceNum = tonumber((entry :: any).price)
				slot:SetAttribute("Price", if priceNum then priceNum else 0)
			else
				;(slot :: StringValue).Value = ""
				slot:SetAttribute("Name", "")
				slot:SetAttribute("Rarity", "")
				slot:SetAttribute("Price", 0)
			end
		end

		CarpetStockPush:FireAllClients(detailed)
	end)
	if not okPub then
		warn("[CloutRanch] publishCarpetStock failed:", errPub)
	end
end

local function handleGetCarpetStock(_player: Player): any
	local ok, result = pcall(function()
		if CarpetService.Tick then
			CarpetService.Tick()
		end
		local detailed = nil
		if CarpetService.GetStockDetailed then
			detailed = CarpetService.GetStockDetailed()
		end
		if (detailed == nil or #detailed == 0) and CarpetService.Rotate then
			CarpetService.Rotate()
			if CarpetService.GetStockDetailed then
				detailed = CarpetService.GetStockDetailed()
			end
		end
		publishCarpetStock()
		if detailed ~= nil and #detailed > 0 then
			return detailed
		end
		return CarpetService.GetStock()
	end)
	if not ok then
		warn("[CloutRanch] GetCarpetStock failed:", result)
		return {}
	end
	return result
end

-- Bind RF immediately (before MapBootstrap / tryRequire chain can hang clients)
GetCarpetStock.OnServerInvoke = handleGetCarpetStock
if CarpetService.SetOnRotated then
	CarpetService.SetOnRotated(publishCarpetStock)
end
CarpetService.Rotate()
publishCarpetStock()

-- Soft funnel purchase: never Prompt* when Marketplace ID is 0 (Coming soon path).
RequestPurchase.OnServerEvent:Connect(function(player, sku: any)
	if typeof(sku) ~= "string" then
		return
	end
	-- Allowlist soft-funnel SKUs only — no core-verb paywall
	if sku ~= "Starter" and sku ~= "DoubleCash" and sku ~= "VIP" and sku ~= "BattlePass" then
		return
	end
	local ok, reason = Monetization.TryPrompt(player, sku)
	if not ok and FeedbackService and FeedbackService.Tell then
		if reason == "coming_soon" then
			FeedbackService.Tell(player, "Coming soon — packs open when ready.", "info")
		elseif reason == "owned" then
			FeedbackService.Tell(player, "Already owned", "info")
		else
			FeedbackService.Tell(player, "Purchase unavailable", "warn")
		end
	end
end)

-- Map first, then ranch registry (AssignPlot happens on PlayerAdded after this)
-- Build twice: immediate + deferred — Rojo used to wipe empty Ranches folder mid-boot
local RING_RADIUS = 56
local GOLD_RGB = Color3.fromRGB(245, 200, 75)
local PLOT_COLORS = {
	Color3.fromRGB(140, 210, 130),
	Color3.fromRGB(150, 190, 255),
	Color3.fromRGB(255, 180, 140),
	Color3.fromRGB(240, 210, 120),
	Color3.fromRGB(210, 170, 245),
	Color3.fromRGB(130, 220, 210),
}

--- Fallback if MapBootstrap failed / Ranches wiped: ensure Workspace.Ranches + Ranch1..6
local function ensureRanchesExist()
	local Workspace = game:GetService("Workspace")
	local ranches = Workspace:FindFirstChild("Ranches")
	local childCount = 0
	if ranches then
		childCount = #ranches:GetChildren()
	end
	print("------------------------------------------------------------")
	print("[CloutRanch] ensureRanchesExist CHECK — RanchesPresent=", ranches ~= nil, "children=", childCount)

	if ranches and ranches:IsA("Folder") and childCount >= 6 then
		print("[CloutRanch] ensureRanchesExist OK — baked/runtime ranches present:", childCount)
		print("------------------------------------------------------------")
		return
	end

	warn("[CloutRanch] ensureRanchesExist FALLBACK — creating Ranches + Ranch1..6 (MapBootstrap missing or incomplete)")
	if ranches and not ranches:IsA("Folder") then
		ranches:Destroy()
		ranches = nil
	end
	if not ranches then
		ranches = Instance.new("Folder")
		ranches.Name = "Ranches"
		ranches.Parent = Workspace
		print("[CloutRanch] ensureRanchesExist created Folder Ranches")
	end

	local created = 0
	for i = 1, 6 do
		local name = "Ranch" .. tostring(i)
		local model = ranches:FindFirstChild(name)
		if not model or not model:IsA("Model") then
			if model then
				model:Destroy()
			end
			model = Instance.new("Model")
			model.Name = name
			model.Parent = ranches
			created += 1
		end

		local angle = ((i - 1) / 6) * math.pi * 2 - math.pi / 2
		local cx = math.cos(angle) * RING_RADIUS
		local cz = math.sin(angle) * RING_RADIUS

		local base = model:FindFirstChild("Base")
		if not base or not base:IsA("BasePart") then
			if base then
				base:Destroy()
			end
			base = Instance.new("Part")
			base.Name = "Base"
			base.Parent = model
		end
		base.Size = Vector3.new(40, 1.2, 40)
		base.Anchored = true
		base.CanCollide = true
		base.Material = Enum.Material.Grass
		base.Color = PLOT_COLORS[i]
		base.CFrame = CFrame.new(cx, 0.6, cz)
		model.PrimaryPart = base

		local rim = model:FindFirstChild("BaseRim")
		if not rim or not rim:IsA("BasePart") then
			if rim then
				rim:Destroy()
			end
			rim = Instance.new("Part")
			rim.Name = "BaseRim"
			rim.Parent = model
		end
		rim.Size = Vector3.new(41.6, 0.35, 41.6)
		rim.Anchored = true
		rim.CanCollide = false
		rim.Material = Enum.Material.Neon
		rim.Color = GOLD_RGB
		rim.Transparency = 0.15
		rim.CFrame = CFrame.new(cx, 0.35, cz)

		-- Spawn near carpet arc, facing OWN ranch (not carpet)
		local SPAWN_RING = 16
		local sx = math.cos(angle) * SPAWN_RING
		local sz = math.sin(angle) * SPAWN_RING
		local spawnPos = Vector3.new(sx, 1.5, sz)
		local baseCenter = Vector3.new(cx, 1.5, cz)
		local spawnCf = CFrame.lookAt(spawnPos, baseCenter)

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

		model:SetAttribute("PlotIndex", i)
	end

	local finalCount = #ranches:GetChildren()
	print("[CloutRanch] ensureRanchesExist DONE — createdModels=", created, "finalChildren=", finalCount, "RING=", RING_RADIUS)
	print("------------------------------------------------------------")
	if finalCount < 6 then
		warn("[CloutRanch] ensureRanchesExist WARNING — still only", finalCount, "children (expected 6)")
	end
end

local function runMapBootstrap()
	if not MapBootstrap or not MapBootstrap.Build then
		warn("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		warn("[CloutRanch] MapBootstrap missing — Ranches will stay empty unless fallback runs")
		warn("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		return
	end
	local ok, err = pcall(MapBootstrap.Build)
	if not ok then
		warn("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		warn("[CloutRanch] MapBootstrap.Build FAILED:", err)
		warn("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	end
end
runMapBootstrap()
ensureRanchesExist()
task.defer(function()
	runMapBootstrap()
	ensureRanchesExist()
end)
task.delay(0.5, ensureRanchesExist)
RanchService.BootstrapFromWorkspace()

-- DataStore + session locks (Studio falls back to in-memory mock)
if DataService and DataService.Bootstrap then
	DataService.Bootstrap()
end
if FomoBroadcastService and FomoBroadcastService.Bootstrap then
	FomoBroadcastService.Bootstrap()
end

-- Social systems (optional via tryRequire)
if KillfeedService and KillfeedService.Bootstrap then
	KillfeedService.Bootstrap()
end
if KillfeedService and KillfeedService.BindRemote then
	KillfeedService.BindRemote(FeedEvent)
end
if FlexEmoteService and FlexEmoteService.Bootstrap then
	FlexEmoteService.Bootstrap()
end
if FlexEmoteService and FlexEmoteService.BindRemote then
	FlexEmoteService.BindRemote(DuoFlex)
end
if PartyService and PartyService.BindRemotes then
	PartyService.BindRemotes(PartySync)
end
if PartyService and FeedbackService then
	PartyService.SetFeedback(function(player, msg, tone)
		if FeedbackService.Tell then
			FeedbackService.Tell(player, msg, tone)
		elseif FeedbackService.Notify then
			FeedbackService.Notify(player, tone or "info", msg)
		end
	end)
end


if WorldInteract and WorldInteract.Bootstrap then
	WorldInteract.Bootstrap()
end
if DemoRivalService and DemoRivalService.Bootstrap then
	DemoRivalService.Bootstrap()
end

-- Luck + Trend Week featured Secret bias on Carpet rolls
if CarpetService.SetWeightTransform then
	CarpetService.SetWeightTransform(function(base, player)
		local w = base
		if player and LuckService and LuckService.ApplyForPlayer then
			w = LuckService.ApplyForPlayer(player, w)
		end
		if TrendDropService and TrendDropService.ApplyFeaturedWeights then
			w = TrendDropService.ApplyFeaturedWeights(w)
		end
		return w
	end)
end
if TrendDropService and TrendDropService.BindCarpet then
	TrendDropService.BindCarpet(CarpetService)
elseif TrendDropService and TrendDropService.SyncCarpet then
	TrendDropService.SyncCarpet()
end
if ClipMomentService and ClipMomentService.Init then
	ClipMomentService.Init()
end
-- Carpet stock already rotated + RF bound early; re-publish after luck/trend transforms
if CarpetService.Rotate then
	CarpetService.Rotate()
end
publishCarpetStock()

-- Replicated CloutState: Aura phase + timers for clients (CarpetStock folder may already exist)
local state = ensureCloutState()
local function ensureSV(className: string, name: string)
	local v = state:FindFirstChild(name)
	if not v then
		v = Instance.new(className)
		v.Name = name
		v.Parent = state
	end
	return v
end
local phaseVal = ensureSV("StringValue", "Phase") :: StringValue
local endsVal = ensureSV("NumberValue", "EndsAt") :: NumberValue
local serverTimeVal = ensureSV("NumberValue", "ServerTime") :: NumberValue
local trendTitleVal = ensureSV("StringValue", "TrendTitle") :: StringValue
local trendEndsVal = ensureSV("NumberValue", "TrendEndsAt") :: NumberValue
if SeasonService and SeasonService.BindCloutState then
	SeasonService.BindCloutState(trendTitleVal, trendEndsVal)
else
	trendTitleVal.Value = ""
	trendEndsVal.Value = 0
end

local function syncDailyStats(player: Player)
	local folder = player:FindFirstChild("CloutStats")
	if not folder then
		return
	end
	local streak = folder:FindFirstChild("DailyStreak")
	if not streak then
		streak = Instance.new("NumberValue")
		streak.Name = "DailyStreak"
		streak.Parent = folder
	end
	if DailyService and DailyService.GetStreak and streak:IsA("NumberValue") then
		streak.Value = DailyService.GetStreak(player)
	end
end

-- Deposit side-effects (Quest / BP / Juice / Onboard / MarkDopamine) run inside
-- StealService.TryDeposit so DepositPet remote + WorldInteract DepositPad share one path.


ClaimBattlePass.OnServerEvent:Connect(function(player, track: any)
	if typeof(track) ~= "string" then
		return
	end
	if BattlePassService and BattlePassService.TryClaimTier then
		BattlePassService.TryClaimTier(player, track)
	end
end)

ClaimDaily.OnServerEvent:Connect(function(player)
	if DailyService and DailyService.TryClaim then
		local ok, msg = DailyService.TryClaim(player)
		if ok and SessionService and SessionService.NotifyDailyClaimed then
			SessionService.NotifyDailyClaimed(player)
		end
		if ok and BattlePassService and BattlePassService.AddXp then
			BattlePassService.AddXp(player, 10)
		end
		if ok then
			syncDailyStats(player)
		end
		if ok then
			if JuiceService and JuiceService.Daily then
				JuiceService.Daily(player, if typeof(msg) == "string" then msg else nil)
			elseif FeedbackService and FeedbackService.Notify then
				FeedbackService.Notify(player, "daily", "Daily reward claimed!")
			elseif FeedbackService and FeedbackService.Tell then
				FeedbackService.Tell(player, "Daily reward claimed!", "daily")
			end
			if OnboardingService and OnboardingService.NotifyDailyClaimed then
				OnboardingService.NotifyDailyClaimed(player)
			end
		elseif FeedbackService and FeedbackService.Tell and typeof(msg) == "string" then
			FeedbackService.Tell(player, msg, "warn")
		end
	end
end)

ClaimQuest.OnServerEvent:Connect(function(player, slotIndex: any)
	if QuestService and QuestService.TryClaim and typeof(slotIndex) == "number" then
		QuestService.TryClaim(player, slotIndex)
	end
end)

StealClosest.OnServerEvent:Connect(function(player)
	-- Quest Progress(steal_pet) lives in StealService.TrySteal (shared with WorldInteract)
	if StealService.TryStealClosest then
		StealService.TryStealClosest(player)
	end
end)

-- Client → server feedback/report; server→client toasts use the same remote via FeedbackService
Feedback.OnServerEvent:Connect(function(player, text: any)
	if FeedbackService and FeedbackService.Submit then
		FeedbackService.Submit(player, text)
	end
end)

-- ProximityPrompt-friendly slap: optional targetUserId, else nearest carrying thief
SlapPetPrompt.OnServerEvent:Connect(function(player, targetUserId: any)
	if typeof(targetUserId) == "number" then
		local target = Players:GetPlayerByUserId(targetUserId)
		if target then
			StealService.Slap(player, target)
		end
		return
	end
	if StealService.SlapClosest then
		StealService.SlapClosest(player)
	end
end)

local function setupPlayer(player: Player)
	-- Session lock + profile load BEFORE default InitPlayer cash (50)
	if DataService and DataService.LoadPlayer then
		local loaded = DataService.LoadPlayer(player)
		if not loaded then
			return -- soft-kicked: locked on another server
		end
	end
	-- InitPlayer is a no-op when DataService already applied a wallet
	EconomyService.InitPlayer(player)
	if OfferService and OfferService.InitPlayer then
		OfferService.InitPlayer(player)
	end
	syncDailyStats(player)
	if SessionService and SessionService.InitPlayer then
		SessionService.InitPlayer(player)
	end
	if OnboardingService and OnboardingService.InitPlayer then
		OnboardingService.InitPlayer(player)
	end
	if BattlePassService and BattlePassService.InitPlayer then
		BattlePassService.InitPlayer(player)
	end
	if SoftPityService and SoftPityService.InitPlayer then
		SoftPityService.InitPlayer(player)
	end
	if QuestService and QuestService.InitPlayer then
		QuestService.InitPlayer(player)
	end
	if ComebackService and ComebackService.InitPlayer then
		ComebackService.InitPlayer(player)
	end
	-- DataService.Apply may already have assigned plot + pets
	local ranch = RanchService.GetByUser(player.UserId) or RanchService.AssignPlot(player)
	if not ranch then
		warn("[CloutRanch] No free plot for", player.Name)
	elseif OnboardingService and OnboardingService.NotifyRanchClaimed then
		OnboardingService.NotifyRanchClaimed(player)
	end
	-- Join funnel: auto-open shop + schedule early Flex for first session
	task.delay(1.5, function()
		if not player.Parent then
			return
		end
		local openShop = remotes:FindFirstChild("OpenShop")
		if openShop and openShop:IsA("RemoteEvent") then
			openShop:FireClient(player, { open = true, reason = "join" })
		end
		if SessionService and SessionService.IsFirstSession and SessionService.IsFirstSession(player) then
			if AuraService and AuraService.ForceEarlyFlex then
				AuraService.ForceEarlyFlex(40)
			end
		elseif AuraService and AuraService.ForceEarlyFlex then
			-- Studio solo retest still gets a quick first flex
			AuraService.ForceEarlyFlex(45)
		end
	end)
end

Players.PlayerAdded:Connect(setupPlayer)

-- Late joiners already in game before this script finished
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end


PartyInvite.OnServerEvent:Connect(function(player, query: any)
	if PartyService and PartyService.Invite then
		local ok, err = PartyService.Invite(player, query)
		if not ok and FeedbackService and FeedbackService.Tell then
			FeedbackService.Tell(player, err or "Invite failed", "warn")
		end
	end
end)

PartyAccept.OnServerEvent:Connect(function(player)
	if PartyService and PartyService.Accept then
		local ok, err = PartyService.Accept(player)
		if not ok and FeedbackService and FeedbackService.Tell then
			FeedbackService.Tell(player, err or "Accept failed", "warn")
		end
	end
end)

PartyLeave.OnServerEvent:Connect(function(player)
	if PartyService and PartyService.Leave then
		PartyService.Leave(player)
	end
end)

PinShowcase.OnServerEvent:Connect(function(player, slotOrPetId: any)
	if ShowcaseService and ShowcaseService.Pin then
		local ok, err = ShowcaseService.Pin(player, slotOrPetId)
		if ok and FeedbackService and FeedbackService.Tell then
			FeedbackService.Tell(player, "Showcase pinned — flex on!", "clout")
		elseif not ok and FeedbackService and FeedbackService.Tell then
			FeedbackService.Tell(player, err or "Can't pin", "warn")
		end
	end
end)

-- BuyCarpet: places on caller's ranch only (RanchService.TryPlacePet via GetByUser).
-- Validates stock index + cash inside CarpetService.TryBuy; no cross-player ownership.
BuyCarpet.OnServerEvent:Connect(function(player, stockIndex: number)
	if typeof(stockIndex) ~= "number" or stockIndex ~= math.floor(stockIndex) or stockIndex < 1 or stockIndex > 8 then
		return
	end
	local ok, err = CarpetService.TryBuy(player, stockIndex)
	if ok then
		if QuestService and QuestService.Progress then
			QuestService.Progress(player, "buy_carpet", 1)
		end
		-- CarpetService.TryBuy fires JuiceService.Hatch when present; Buy is fallback only
		if JuiceService and JuiceService.Hatch then
			-- hatch juice already played inside TryBuy
		elseif JuiceService and JuiceService.Buy then
			JuiceService.Buy(player, nil)
		elseif FeedbackService and FeedbackService.Tell then
			FeedbackService.Tell(player, "🛒 Pet bought!", "buy")
		end
		if OnboardingService and OnboardingService.NotifyPetBought then
			OnboardingService.NotifyPetBought(player)
		end
		if SessionService and SessionService.MarkTutorial then
			SessionService.MarkTutorial(player, "seenCarpet")
		end
		if OfferService and OfferService.MarkDopamine then
			OfferService.MarkDopamine(player, "buy")
		end
	elseif FeedbackService and FeedbackService.Tell then
		FeedbackService.Tell(player, err or "Buy failed", "error")
	end
end)

-- StealPet: TrySteal enforces STEAL_RANGE + not-self + unlock + soft-protect.
StealPet.OnServerEvent:Connect(function(player, plotName: string, slotIndex: number)
	if typeof(plotName) ~= "string" or typeof(slotIndex) ~= "number" then
		return
	end
	-- Quest Progress(steal_pet) lives in StealService.TrySteal (shared with WorldInteract)
	StealService.TrySteal(player, plotName, slotIndex)
end)

DepositPet.OnServerEvent:Connect(function(player)
	-- StealService.TryDeposit runs shared afterDepositHooks
	StealService.TryDeposit(player)
end)

SlapThief.OnServerEvent:Connect(function(player, targetUserId: number)
	if typeof(targetUserId) ~= "number" then
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if target then
		StealService.Slap(player, target)
	end
end)

VoteAura.OnServerEvent:Connect(function(player, targetUserId: number)
	if typeof(targetUserId) ~= "number" then
		return
	end
	AuraService.Vote(player, targetUserId)
end)

DoRebirth.OnServerEvent:Connect(function(player)
	local ok, err = RebirthService.TryRebirth(player)
	if ok then
		local level = RebirthService.GetLevel(player)
		if JuiceService and JuiceService.Rebirth then
			JuiceService.Rebirth(player, level)
		elseif FeedbackService and FeedbackService.Tell then
			FeedbackService.Tell(player, "♻️ Rebirth complete!", "rebirth")
		end
		if SessionService and SessionService.MarkTutorial then
			SessionService.MarkTutorial(player, "seenRebirth")
		end
	elseif FeedbackService and FeedbackService.Tell then
		FeedbackService.Tell(player, err or "Rebirth failed", "error")
	end
end)

-- RequestLock: RanchService.Lock only affects caller's ranch (GetByUser) — ownership OK.
RequestLock.OnServerEvent:Connect(function(player)
	local vip = Monetization.IsVIP(player)
	local ok, err = RanchService.Lock(player, vip)
	if not ok then
		if FeedbackService and FeedbackService.Tell then
			FeedbackService.Tell(player, err or "Already locked", "warn")
		end
		return
	end
	if QuestService and QuestService.Progress then
		QuestService.Progress(player, "lock_ranch", 1)
	end
	if JuiceService and JuiceService.Lock then
		JuiceService.Lock(player, vip)
	elseif FeedbackService and FeedbackService.Tell then
		FeedbackService.Tell(player, if vip then "LOCKED — VIP timer" else "Ranch locked!", "info")
	end
	if OnboardingService and OnboardingService.NotifyStealOrLock then
		OnboardingService.NotifyStealOrLock(player)
	end
	if OfferService and OfferService.MarkDopamine then
		OfferService.MarkDopamine(player, "lock")
	end
end)

local acc = 0
local bpAcc = 0
local partySyncAcc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	bpAcc += dt
	CarpetService.Tick()
	AuraService.Tick()
	if OfferService and OfferService.Tick then
		OfferService.Tick()
	end
	if FlexEmoteService and FlexEmoteService.Tick then
		local roundFlex = AuraService.GetRound()
		FlexEmoteService.Tick(roundFlex.phase)
	end
	partySyncAcc += dt
	if partySyncAcc >= 2 and PartyService and PartyService.SyncPlayer then
		partySyncAcc = 0
		for _, plr in Players:GetPlayers() do
			if PartyService.GetParty(plr.UserId) then
				PartyService.SyncPlayer(plr)
			end
		end
	end
	if SeasonService and SeasonService.Tick then
		SeasonService.Tick(dt)
	end
	local round = AuraService.GetRound()
	phaseVal.Value = round.phase
	endsVal.Value = round.endsAt
	serverTimeVal.Value = workspace:GetServerTimeNow()
	if acc >= 0.25 then
		RanchService.TickIncome(acc)
		-- Occasional tiny BattlePass XP on income ticks
		if BattlePassService and BattlePassService.AddXp and bpAcc >= 2 then
			bpAcc = 0
			for _, player in Players:GetPlayers() do
				if RanchService.GetByUser(player.UserId) and math.random() < 0.35 then
					BattlePassService.AddXp(player, 1)
				end
			end
		end
		acc = 0
	end
end)

local loaded = {
	"Ranch",
	"Carpet",
	"Steal",
	"Aura",
	"Rebirth",
	"Economy",
	"Monetization",
}
if MapBootstrap then
	table.insert(loaded, "Map")
end
if WorldInteract then
	table.insert(loaded, "WorldInteract")
end
if DailyService then
	table.insert(loaded, "Daily")
end
if BattlePassService then
	table.insert(loaded, "BattlePass")
end
if LuckService then
	table.insert(loaded, "Luck")
end
if SeasonService then
	table.insert(loaded, "Season")
end
if FeedbackService then
	table.insert(loaded, "Feedback")
end
if SessionService then
	table.insert(loaded, "Session")
end
if PartyService then
	table.insert(loaded, "Party")
end
if KillfeedService then
	table.insert(loaded, "Killfeed")
end
if FlexEmoteService then
	table.insert(loaded, "FlexEmote")
end
if ShowcaseService then
	table.insert(loaded, "Showcase")
end
if JuiceService then
	table.insert(loaded, "Juice")
end
if OnboardingService then
	table.insert(loaded, "Onboarding")
end
if QuestService then
	table.insert(loaded, "Quest")
end
if ComebackService then
	table.insert(loaded, "Comeback")
end
if SoftPityService then
	table.insert(loaded, "SoftPity")
end
if TrendDropService then
	table.insert(loaded, "TrendDrop")
end
if OfferService then
	table.insert(loaded, "Offers")
end
if ClipMomentService then
	table.insert(loaded, "ClipMoment")
end
if DataService then
	table.insert(loaded, "Data")
end
if DemoRivalService then
	table.insert(loaded, "DemoRival")
end

print("========================================")
print("############################################################")
print("[CloutRanch] BOOT OK — MapBootstrap + ensureRanchesExist complete")
print("[CloutRanch] Edit-mode farms: Workspace.Ranches Ranch1..6 (baked on disk)")
print("############################################################")
print("[CloutRanch] services:", table.concat(loaded, ", "))
print("[CloutRanch] remotes: BuyCarpet StealPet DepositPet SlapThief SlapPetPrompt")
print("[CloutRanch]           VoteAura DoRebirth RequestLock ClaimDaily StealClosest")
print("[CloutRanch]           Feedback OpenShop Juice SoftOffer RequestPurchase ClaimQuest + GetCarpetStock(RF)")
print("[CloutRanch] retention: Quest Comeback SoftPity LastSeen")
print("[CloutRanch]           PartyInvite PartyAccept PartyLeave PartySync")
print("[CloutRanch]           FeedEvent DuoFlex PinShowcase")
print("[CloutRanch] CloutFeed + Social.DuoFlex (cosmetic only)")
print("[CloutRanch] CloutState: Phase EndsAt ServerTime TrendTitle TrendEndsAt + CarpetStock slots")
print("[CloutRanch]           CarpetStockPush RE + early GetCarpetStock RF")
print("[CloutRanch] CloutStats.OnboardingStep replicated for HUD tips")
print("========================================")

-- Marketplace unset-ID warn is hoisted onto Monetization require (fires at boot top).
print("[CloutRanch] SoftOffer + RequestPurchase remotes ready (ID 0 → Coming soon, no Prompt*)", SoftOffer.Name, RequestPurchase.Name)

