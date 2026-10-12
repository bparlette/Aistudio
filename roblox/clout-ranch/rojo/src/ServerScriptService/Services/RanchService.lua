--!strict
-- Server ModuleScript: ranch plots, slots, locks
-- Expects workspace.Ranches: Folder of Models named Ranch1..Ranch6 with attributes OwnerUserId

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetCatalog"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

export type RanchState = {
	plotName: string,
	ownerUserId: number?,
	slots: { string? }, -- pet ids
	maxSlots: number,
	lockUntil: number, -- os.clock()
	newbieProtectedUntil: number,
}

local NEWBIE_LOCK = 45
local LOCK_F2P = 45
local LOCK_VIP = 120
do
	local cfgFolder = ReplicatedStorage:FindFirstChild("Config")
	local mod = cfgFolder and cfgFolder:FindFirstChild("EconomyConfig")
	if mod and mod:IsA("ModuleScript") then
		local ok, cfg = pcall(require, mod)
		if ok and cfg then
			if typeof(cfg.NewbieLockSeconds) == "number" then
				NEWBIE_LOCK = cfg.NewbieLockSeconds
			end
			if typeof(cfg.LockSecondsF2P) == "number" then
				LOCK_F2P = cfg.LockSecondsF2P
			end
			if typeof(cfg.LockSecondsVIP) == "number" then
				LOCK_VIP = cfg.LockSecondsVIP
			end
		end
	end
end

local ranches: { [string]: RanchState } = {}
local userToPlot: { [number]: string } = {}

local RanchService = {}


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


local function notifyDirty(player: Player?)
	if not player then
		return
	end
	local mod = script.Parent:FindFirstChild("DataService")
	if not mod then
		return
	end
	local ok, ds = pcall(require, mod)
	if ok and ds and ds.MarkDirty then
		ds.MarkDirty(player)
	end
end

local function tryParty(): any?
	local mod = script.Parent:FindFirstChild("PartyService")
	if mod and mod:IsA("ModuleScript") then
		local ok, result = pcall(require, mod)
		if ok then
			return result
		end
	end
	return nil
end


local function emptySlots(n: number): { string? }
	local t = table.create(n)
	for i = 1, n do
		t[i] = nil
	end
	return t
end

function RanchService.BootstrapFromWorkspace()
	local folder = workspace:FindFirstChild("Ranches")
	if not folder then
		warn("[RanchService] workspace.Ranches missing — create 6 ranch plots")
		return
	end
	for _, plot in folder:GetChildren() do
		if plot:IsA("Model") or plot:IsA("BasePart") or plot:IsA("Folder") then
			ranches[plot.Name] = {
				plotName = plot.Name,
				ownerUserId = nil,
				slots = emptySlots(3),
				maxSlots = 3,
				lockUntil = 0,
				newbieProtectedUntil = 0,
			}
		end
	end
end

local function isClaimableOwner(ownerUserId: number?): boolean
	if ownerUserId == nil then
		return true
	end
	-- Negative = DemoRivalService solo fodder — reclaimable by real players
	return ownerUserId < 0
end

local function teleportToPlot(player: Player, plotName: string)
	local folder = workspace:FindFirstChild("Ranches")
	local plot = folder and folder:FindFirstChild(plotName)
	if not plot or not plot:IsA("Model") then
		return
	end
	local spawn = plot:FindFirstChild("Spawn")
	local target: BasePart? = if spawn and spawn:IsA("BasePart") then spawn else (plot.PrimaryPart or plot:FindFirstChild("Base") :: BasePart?)
	if not target then
		return
	end
	local function place(char: Model)
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			-- Face Carpet (origin)
			local pos = target.Position + Vector3.new(0, 3, 0)
			hrp.CFrame = CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0))
		end
	end
	if player.Character then
		place(player.Character)
	end
	local conn: RBXScriptConnection? = nil
	conn = player.CharacterAdded:Connect(function(char)
		if conn then
			conn:Disconnect()
		end
		task.defer(place, char)
	end)
end

local function notifyDemoAssigned(plotName: string, userId: number)
	local mod = script.Parent:FindFirstChild("DemoRivalService")
	if mod and mod:IsA("ModuleScript") then
		local ok, demo = pcall(require, mod)
		if ok and demo and demo.OnPlotAssigned then
			pcall(demo.OnPlotAssigned, plotName, userId)
		end
	end
end

local function syncPlotAttributes(plotName: string, state: RanchState)
	local folder = workspace:FindFirstChild("Ranches")
	local plot = folder and folder:FindFirstChild(plotName)
	if plot then
		plot:SetAttribute("OwnerUserId", state.ownerUserId)
		local base = if plot:IsA("Model") then (plot.PrimaryPart or plot:FindFirstChild("Base")) else nil
		if base and base:IsA("BasePart") and state.ownerUserId and state.ownerUserId > 0 then
			local bill = base:FindFirstChild("RanchNameBillboard")
			if bill and bill:IsA("BillboardGui") then
				local lbl = bill:FindFirstChild("Label")
				if lbl and lbl:IsA("TextLabel") then
					lbl.Text = "YOUR RANCH"
				end
			end
		end
	end
end

--- Replicate OwnerUserId (and ranch billboard) onto the plot model for client guides.
function RanchService.SyncPlotAttributes(plotName: string)
	local state = ranches[plotName]
	if state then
		syncPlotAttributes(plotName, state)
	end
end

function RanchService.AssignPlot(player: Player): RanchState?
	for name, state in ranches do
		if isClaimableOwner(state.ownerUserId) then
			-- Clear demo visuals before claim
			local vis = tryPetVisual()
			if vis and vis.ClearRanch then
				pcall(vis.ClearRanch, state.plotName)
			end
			state.ownerUserId = player.UserId
			state.slots = emptySlots(state.maxSlots)
			state.lockUntil = os.clock() + NEWBIE_LOCK
			state.newbieProtectedUntil = os.clock() + NEWBIE_LOCK
			userToPlot[player.UserId] = name
			syncPlotAttributes(name, state)
			notifyDemoAssigned(name, player.UserId)
			teleportToPlot(player, name)
			return state
		end
	end
	return nil
end

function RanchService.GetByUser(userId: number): RanchState?
	local plot = userToPlot[userId]
	return if plot then ranches[plot] else nil
end

function RanchService.GetByPlot(plotName: string): RanchState?
	return ranches[plotName]
end

function RanchService.IsLocked(state: RanchState): boolean
	return os.clock() < state.lockUntil
end

--- Apply ranch lock. Refuses while already locked (anti-mash: no refresh/stack).
--- Canon duration: F2P 45s / VIP 120s (via Monetization.GetLockSeconds).
function RanchService.Lock(player: Player, vip: boolean): (boolean, string?)
	local state = RanchService.GetByUser(player.UserId)
	if not state then
		return false, "No ranch"
	end
	if RanchService.IsLocked(state) then
		local left = math.max(1, math.ceil(state.lockUntil - os.clock()))
		return false, "Already locked — " .. tostring(left) .. "s left"
	end
	local secs = if vip then LOCK_VIP else LOCK_F2P
	local mon = script.Parent:FindFirstChild("Monetization")
	if mon then
		local ok, M = pcall(require, mon)
		if ok and M and M.GetLockSeconds then
			secs = M.GetLockSeconds(player)
		end
	end
	-- party assist
	local party = tryParty()
	if party and party.GetLockAssistSeconds then
		secs += party.GetLockAssistSeconds(player) or 0
	end
	state.lockUntil = os.clock() + secs
	return true, nil
end

function RanchService.TryPlacePet(player: Player, petId: string): (boolean, string?)
	local def = PetCatalog.Get(petId)
	if not def then
		return false, "Unknown pet"
	end
	local state = RanchService.GetByUser(player.UserId)
	if not state then
		return false, "No ranch"
	end
	for i = 1, state.maxSlots do
		if state.slots[i] == nil then
			state.slots[i] = petId
			local vis = tryPetVisual()
			if vis and vis.SpawnOnSlot then
				pcall(vis.SpawnOnSlot, state.plotName, i, petId)
			end
			local wi = script.Parent:FindFirstChild("WorldInteract")
			if wi then
				local wok, WI = pcall(require, wi)
				if wok and WI and WI.RefreshSlotLabels then
					pcall(WI.RefreshSlotLabels, state.plotName)
				end
			end
			notifyDirty(player)
			return true, nil
		end
	end
	return false, "Ranch full"
end

function RanchService.RemovePetAt(state: RanchState, slotIndex: number): string?
	local petId = state.slots[slotIndex]
	state.slots[slotIndex] = nil
	local vis = tryPetVisual()
	if vis and vis.ClearSlot then
		pcall(vis.ClearSlot, state.plotName, slotIndex)
	end
	if state.ownerUserId then
		local owner = Players:GetPlayerByUserId(state.ownerUserId)
		notifyDirty(owner)
	end
	return petId
end

function RanchService.FindPetSlot(state: RanchState, petId: string): number?
	for i, id in state.slots do
		if id == petId then
			return i
		end
	end
	return nil
end


--- Restore ranch pets from DataService profile (spawns visuals via PetVisualService).
function RanchService.ApplyPets(player: Player, petsBySlot: { [number]: string })
	local state = RanchService.GetByUser(player.UserId)
	if not state then
		return
	end
	local vis = tryPetVisual()
	for i = 1, state.maxSlots do
		state.slots[i] = nil
		if vis and vis.ClearSlot then
			pcall(vis.ClearSlot, state.plotName, i)
		end
	end
	for slotIndex, petId in petsBySlot do
		if typeof(slotIndex) == "number" and typeof(petId) == "string" and petId ~= "" then
			if slotIndex >= 1 and slotIndex <= state.maxSlots then
				state.slots[slotIndex] = petId
				if vis and vis.SpawnOnSlot then
					pcall(vis.SpawnOnSlot, state.plotName, slotIndex, petId)
				end
			end
		end
	end
end

local function ensureIncomeRate(player: Player, rate: number)
	local folder = player:FindFirstChild("CloutStats")
	if not folder then
		return
	end
	local v = folder:FindFirstChild("IncomePerSec")
	if not v then
		v = Instance.new("NumberValue")
		v.Name = "IncomePerSec"
		v.Parent = folder
	end
	if v:IsA("NumberValue") then
		v.Value = rate
	end
end

function RanchService.TickIncome(dt: number)
	for _, state in ranches do
		if state.ownerUserId and state.ownerUserId > 0 then
			local player = Players:GetPlayerByUserId(state.ownerUserId)
			if player then
				local wallet = EconomyService.Get(player)
				local sum = 0
				for _, petId in state.slots do
					if petId then
						local def = PetCatalog.Get(petId)
						if def then
							sum += def.incomePerSec
						end
					end
				end
				local mult = wallet.incomeMult
				local Party = tryParty()
				if Party and Party.GetCashBonusMult then
					mult *= Party.GetCashBonusMult(player)
				end
				local rate = sum * mult
				ensureIncomeRate(player, rate)
				EconomyService.AddCash(player, rate * dt)
			end
		end
	end
end

function RanchService.ExpandSlots(player: Player, newMax: number)
	local state = RanchService.GetByUser(player.UserId)
	if not state then
		return
	end
	while #state.slots < newMax do
		table.insert(state.slots, nil)
	end
	state.maxSlots = newMax
end

function RanchService.Release(player: Player)
	local plot = userToPlot[player.UserId]
	if not plot then
		return
	end
	local state = ranches[plot]
	if state then
		local vis = tryPetVisual()
		if vis and vis.ClearRanch then
			pcall(vis.ClearRanch, state.plotName)
		end
		state.ownerUserId = nil
		state.slots = emptySlots(3)
		state.maxSlots = 3
		state.lockUntil = 0
	end
	userToPlot[player.UserId] = nil
end

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	local plotAtLeave = userToPlot[userId]
	-- Defer so DataService can Capture+Save while ranch pets still exist
	task.defer(function()
		if Players:GetPlayerByUserId(userId) then
			return -- fast rejoin — do not wipe the new session
		end
		if plotAtLeave and userToPlot[userId] == plotAtLeave then
			local fake = { UserId = userId }
			RanchService.Release(fake :: any)
		end
	end)
end)

return RanchService
