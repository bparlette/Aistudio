--!strict
-- Server ModuleScript: steal pets from unlocked ranches

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetCatalog = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetCatalog"))
local RanchService = require(script.Parent:WaitForChild("RanchService"))

local SOFT_PROTECT = 15

export type CarryState = {
	petId: string,
	fromPlot: string,
	fromSlot: number,
	ownerUserId: number,
}

local carrying: { [number]: CarryState } = {}
local lastStolenAt: { [number]: number } = {} -- victim userId

local StealService = {}

function StealService.GetCarry(player: Player): CarryState?
	return carrying[player.UserId]
end

function StealService.TrySteal(thief: Player, plotName: string, slotIndex: number): (boolean, string?)
	if carrying[thief.UserId] then
		return false, "Already carrying"
	end
	local state = RanchService.GetByPlot(plotName)
	if not state or not state.ownerUserId then
		return false, "Empty ranch"
	end
	if state.ownerUserId == thief.UserId then
		return false, "Own ranch"
	end
	if RanchService.IsLocked(state) then
		return false, "Locked"
	end
	local victimId = state.ownerUserId
	local last = lastStolenAt[victimId] or 0
	if os.clock() - last < SOFT_PROTECT then
		return false, "Recently stolen"
	end
	local petId = state.slots[slotIndex]
	if not petId then
		return false, "Empty slot"
	end
	RanchService.RemovePetAt(state, slotIndex)
	carrying[thief.UserId] = {
		petId = petId,
		fromPlot = plotName,
		fromSlot = slotIndex,
		ownerUserId = victimId,
	}
	lastStolenAt[victimId] = os.clock()

	local def = PetCatalog.Get(petId)
	local char = thief.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and def then
		hum.WalkSpeed = math.max(8, 16 * (1 - def.carrySlow))
	end
	return true, nil
end

function StealService.Drop(thief: Player, returnToOwner: boolean)
	local carry = carrying[thief.UserId]
	if not carry then
		return
	end
	carrying[thief.UserId] = nil
	local char = thief.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 16
	end
	if returnToOwner then
		local ownerRanch = RanchService.GetByUser(carry.ownerUserId)
		if ownerRanch then
			for i = 1, ownerRanch.maxSlots do
				if ownerRanch.slots[i] == nil then
					ownerRanch.slots[i] = carry.petId
					return
				end
			end
		end
	end
end

function StealService.TryDeposit(thief: Player): (boolean, string?)
	local carry = carrying[thief.UserId]
	if not carry then
		return false, "Not carrying"
	end
	local ok, err = RanchService.TryPlacePet(thief, carry.petId)
	if not ok then
		return false, err
	end
	carrying[thief.UserId] = nil
	local char = thief.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 16
	end
	RanchService.Lock(thief, false)
	return true, nil
end

function StealService.Slap(attacker: Player, target: Player): boolean
	local carry = carrying[target.UserId]
	if not carry then
		return false
	end
	if carry.ownerUserId ~= attacker.UserId and RanchService.GetByUser(attacker.UserId) == nil then
		-- anyone can slap a thief; owner slap preferred thematically
	end
	StealService.Drop(target, true)
	return true
end

Players.PlayerRemoving:Connect(function(player)
	if carrying[player.UserId] then
		StealService.Drop(player, true)
	end
end)

return StealService
