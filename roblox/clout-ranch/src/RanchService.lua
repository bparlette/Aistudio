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
local BASE_LOCK = 20
local VIP_EXTRA_LOCK = 10

local ranches: { [string]: RanchState } = {}
local userToPlot: { [number]: string } = {}

local RanchService = {}

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

function RanchService.AssignPlot(player: Player): RanchState?
	for name, state in ranches do
		if state.ownerUserId == nil then
			state.ownerUserId = player.UserId
			state.slots = emptySlots(state.maxSlots)
			state.lockUntil = os.clock() + NEWBIE_LOCK
			state.newbieProtectedUntil = os.clock() + NEWBIE_LOCK
			userToPlot[player.UserId] = name
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

function RanchService.Lock(player: Player, vip: boolean)
	local state = RanchService.GetByUser(player.UserId)
	if not state then
		return
	end
	local extra = if vip then VIP_EXTRA_LOCK else 0
	state.lockUntil = os.clock() + BASE_LOCK + extra
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
			return true, nil
		end
	end
	return false, "Ranch full"
end

function RanchService.RemovePetAt(state: RanchState, slotIndex: number): string?
	local petId = state.slots[slotIndex]
	state.slots[slotIndex] = nil
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

function RanchService.TickIncome(dt: number)
	for _, state in ranches do
		if state.ownerUserId then
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
				EconomyService.AddCash(player, sum * wallet.incomeMult * dt)
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
		state.ownerUserId = nil
		state.slots = emptySlots(3)
		state.maxSlots = 3
		state.lockUntil = 0
	end
	userToPlot[player.UserId] = nil
end

Players.PlayerRemoving:Connect(function(player)
	RanchService.Release(player)
end)

return RanchService
