--!strict
-- Server ModuleScript: rebirth for permanent multipliers + slots

local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local RanchService = require(script.Parent:WaitForChild("RanchService"))

local rebirthLevel: { [number]: number } = {}

local RebirthService = {}

local function costFor(level: number): number
	-- 500, 1500, 4500, ...
	return math.floor(500 * (3 ^ level))
end

function RebirthService.GetLevel(player: Player): number
	return rebirthLevel[player.UserId] or 0
end

function RebirthService.GetCost(player: Player): number
	return costFor(RebirthService.GetLevel(player))
end

function RebirthService.TryRebirth(player: Player): (boolean, string?)
	local level = RebirthService.GetLevel(player)
	local cost = costFor(level)
	if not EconomyService.TrySpend(player, cost) then
		return false, "Need $" .. tostring(cost)
	end
	local state = RanchService.GetByUser(player.UserId)
	if state then
		for i = 1, state.maxSlots do
			state.slots[i] = nil
		end
	end
	local newLevel = level + 1
	rebirthLevel[player.UserId] = newLevel
	-- permanent: +0.25 income mult per rebirth, +1 slot every 2 rebirths
	EconomyService.SetIncomeMult(player, 1 + newLevel * 0.25)
	local slots = 3 + math.floor(newLevel / 2)
	RanchService.ExpandSlots(player, slots)
	return true, nil
end

return RebirthService
