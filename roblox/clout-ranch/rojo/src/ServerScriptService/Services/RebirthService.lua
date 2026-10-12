--!strict
-- Server ModuleScript: rebirth for permanent multipliers + slots

local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local RanchService = require(script.Parent:WaitForChild("RanchService"))

local rebirthLevel: { [number]: number } = {}

local function notifyDirty(player: Player)
	local mod = script.Parent:FindFirstChild("DataService")
	if not mod then
		return
	end
	local ok, ds = pcall(require, mod)
	if ok and ds and ds.MarkDirty then
		ds.MarkDirty(player)
	end
end

local RebirthService = {}

local function costFor(level: number): number
	-- 500, 1500, 4500, ...
	return math.floor(500 * (3 ^ level))
end

function RebirthService.GetLevel(player: Player): number
	return rebirthLevel[player.UserId] or 0
end

function RebirthService.SetLevel(player: Player, level: number)
	rebirthLevel[player.UserId] = math.max(0, math.floor(level))
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
	-- permanent rebirth + re-apply pass mults (2×Cash etc). VIP never in idle mult.
	local slots = 3 + math.floor(newLevel / 2)
	RanchService.ExpandSlots(player, slots)
	local mon = script.Parent:FindFirstChild("Monetization")
	if mon then
		local ok, M = pcall(require, mon)
		if ok and M and M.ApplyOwned then
			M.ApplyOwned(player)
		else
			EconomyService.SetIncomeMult(player, 1 + newLevel * 0.25)
		end
	else
		EconomyService.SetIncomeMult(player, 1 + newLevel * 0.25)
	end
	local juiceMod = script.Parent:FindFirstChild("JuiceService")
	if juiceMod then
		local jok, juice = pcall(require, juiceMod)
		if jok and juice and juice.Rebirth then
			juice.Rebirth(player)
		end
	end
	notifyDirty(player)
	return true, nil
end

return RebirthService
