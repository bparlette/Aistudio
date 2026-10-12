--!strict
-- Server ModuleScript: 3 rotating daily quests from a fixed pool
-- Progress via Progress(player, kind, amount). Claim via ClaimQuest remote (Bootstrap).
-- Replicates under player.CloutQuests.

local Players = game:GetService("Players")

local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local AuraService = require(script.Parent:WaitForChild("AuraService"))
local BattlePassService = require(script.Parent:WaitForChild("BattlePassService"))
local FeedbackService = require(script.Parent:WaitForChild("FeedbackService"))

local SECONDS_PER_DAY = 86400
local ACTIVE_SLOTS = 3

export type QuestKind =
	"steal_pet"
	| "earn_cash"
	| "win_aura"
	| "buy_carpet"
	| "lock_ranch"
	| "deposit_steal"

export type QuestDef = {
	id: string,
	kind: QuestKind,
	target: number,
	label: string,
	cash: number?,
	aura: number?,
	bpXp: number?,
}

export type QuestSlot = {
	id: string,
	kind: QuestKind,
	target: number,
	progress: number,
	claimed: boolean,
	label: string,
	cash: number?,
	aura: number?,
	bpXp: number?,
}

export type QuestState = {
	dayKey: number,
	slots: { QuestSlot },
}

local POOL: { QuestDef } = {
	{
		id = "steal_pet",
		kind = "steal_pet",
		target = 1,
		label = "Steal 1 pet",
		cash = 150,
		bpXp = 15,
	},
	{
		id = "earn_cash",
		kind = "earn_cash",
		target = 500,
		label = "Earn $500",
		cash = 100,
		aura = 10,
		bpXp = 20,
	},
	{
		id = "win_aura",
		kind = "win_aura",
		target = 1,
		label = "Win Aura Flex (podium)",
		aura = 25,
		bpXp = 30,
	},
	{
		id = "buy_carpet",
		kind = "buy_carpet",
		target = 1,
		label = "Buy from the Carpet",
		cash = 75,
		bpXp = 10,
	},
	{
		id = "lock_ranch",
		kind = "lock_ranch",
		target = 2,
		label = "Lock your ranch twice",
		cash = 120,
		aura = 5,
		bpXp = 15,
	},
	{
		id = "deposit_steal",
		kind = "deposit_steal",
		target = 1,
		label = "Deposit a stolen pet",
		cash = 200,
		bpXp = 25,
	},
}

local states: { [number]: QuestState } = {}

local QuestService = {}

local function dayKey(unix: number?): number
	return math.floor((unix or os.time()) / SECONDS_PER_DAY)
end

--- Deterministic shuffle seed from day + userId (stable across rejoins same UTC day).
local function pickDailyQuests(uid: number, day: number): { QuestDef }
	local indices = {}
	for i = 1, #POOL do
		indices[i] = i
	end
	-- Fisher–Yates with LCG seeded by day/user
	local seed = (day * 7919 + uid * 104729) % 2147483647
	local function rand(): number
		seed = (seed * 1103515245 + 12345) % 2147483647
		return seed / 2147483647
	end
	for i = #indices, 2, -1 do
		local j = math.floor(rand() * i) + 1
		indices[i], indices[j] = indices[j], indices[i]
	end
	local out: { QuestDef } = {}
	for i = 1, math.min(ACTIVE_SLOTS, #POOL) do
		table.insert(out, POOL[indices[i]])
	end
	return out
end

local function ensureFolder(player: Player): Folder
	local folder = player:FindFirstChild("CloutQuests")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "CloutQuests"
		folder.Parent = player
	end
	return folder :: Folder
end

local function ensureValue(parent: Instance, className: string, name: string): Instance
	local v = parent:FindFirstChild(name)
	if not v then
		v = Instance.new(className)
		v.Name = name
		v.Parent = parent
	end
	return v
end

local function replicate(player: Player, state: QuestState)
	local folder = ensureFolder(player)
	local dayVal = ensureValue(folder, "IntValue", "DayKey") :: IntValue
	dayVal.Value = state.dayKey

	for i = 1, ACTIVE_SLOTS do
		local slot = state.slots[i]
		local slotFolder = folder:FindFirstChild("Slot" .. i)
		if not slotFolder then
			slotFolder = Instance.new("Folder")
			slotFolder.Name = "Slot" .. i
			slotFolder.Parent = folder
		end
		local idVal = ensureValue(slotFolder, "StringValue", "Id") :: StringValue
		local kindVal = ensureValue(slotFolder, "StringValue", "Kind") :: StringValue
		local labelVal = ensureValue(slotFolder, "StringValue", "Label") :: StringValue
		local progressVal = ensureValue(slotFolder, "NumberValue", "Progress") :: NumberValue
		local targetVal = ensureValue(slotFolder, "NumberValue", "Target") :: NumberValue
		local claimedVal = ensureValue(slotFolder, "BoolValue", "Claimed") :: BoolValue
		local readyVal = ensureValue(slotFolder, "BoolValue", "Ready") :: BoolValue

		if slot then
			idVal.Value = slot.id
			kindVal.Value = slot.kind
			labelVal.Value = slot.label
			progressVal.Value = slot.progress
			targetVal.Value = slot.target
			claimedVal.Value = slot.claimed
			readyVal.Value = (not slot.claimed) and slot.progress >= slot.target
		else
			idVal.Value = ""
			kindVal.Value = ""
			labelVal.Value = ""
			progressVal.Value = 0
			targetVal.Value = 0
			claimedVal.Value = false
			readyVal.Value = false
		end
	end
end

local function buildState(uid: number, day: number): QuestState
	local defs = pickDailyQuests(uid, day)
	local slots: { QuestSlot } = {}
	for _, def in defs do
		table.insert(slots, {
			id = def.id,
			kind = def.kind,
			target = def.target,
			progress = 0,
			claimed = false,
			label = def.label,
			cash = def.cash,
			aura = def.aura,
			bpXp = def.bpXp,
		})
	end
	return { dayKey = day, slots = slots }
end

local function getState(player: Player): QuestState
	local uid = player.UserId
	local today = dayKey()
	local s = states[uid]
	if not s or s.dayKey ~= today then
		s = buildState(uid, today)
		states[uid] = s
		replicate(player, s)
	end
	return s
end

function QuestService.InitPlayer(player: Player)
	getState(player)
end

function QuestService.GetState(player: Player): QuestState
	local s = getState(player)
	local slotsCopy: { QuestSlot } = {}
	for _, slot in s.slots do
		table.insert(slotsCopy, {
			id = slot.id,
			kind = slot.kind,
			target = slot.target,
			progress = slot.progress,
			claimed = slot.claimed,
			label = slot.label,
			cash = slot.cash,
			aura = slot.aura,
			bpXp = slot.bpXp,
		})
	end
	return { dayKey = s.dayKey, slots = slotsCopy }
end

--- Advance matching active quests. kind must match QuestKind.
function QuestService.Progress(player: Player, kind: string, amount: number?)
	if typeof(kind) ~= "string" then
		return
	end
	local add = amount or 1
	if typeof(add) ~= "number" or add <= 0 then
		return
	end
	local s = getState(player)
	local changed = false
	for _, slot in s.slots do
		if slot.kind == kind and not slot.claimed and slot.progress < slot.target then
			slot.progress = math.min(slot.target, slot.progress + add)
			changed = true
			if slot.progress >= slot.target then
				FeedbackService.Tell(player, "Quest ready: " .. slot.label, "success")
			end
		end
	end
	if changed then
		replicate(player, s)
	end
end

function QuestService.TryClaim(player: Player, slotIndex: number): (boolean, string?)
	if typeof(slotIndex) ~= "number" then
		return false, "Bad slot"
	end
	local idx = math.floor(slotIndex)
	local s = getState(player)
	local slot = s.slots[idx]
	if not slot then
		return false, "No quest"
	end
	if slot.claimed then
		return false, "Already claimed"
	end
	if slot.progress < slot.target then
		return false, "Not complete"
	end

	slot.claimed = true
	if slot.cash and slot.cash > 0 then
		EconomyService.AddCash(player, slot.cash, true) -- reward grant, not earn progress
	end
	if slot.aura and slot.aura > 0 then
		AuraService.AddAura(player, slot.aura)
	end
	if slot.bpXp and slot.bpXp > 0 then
		BattlePassService.AddXp(player, slot.bpXp, "Quest")
	end
	replicate(player, s)

	local bits = { slot.label }
	if slot.cash and slot.cash > 0 then
		table.insert(bits, "$" .. tostring(slot.cash))
	end
	if slot.aura and slot.aura > 0 then
		table.insert(bits, tostring(slot.aura) .. " aura")
	end
	if slot.bpXp and slot.bpXp > 0 then
		table.insert(bits, tostring(slot.bpXp) .. " BP XP")
	end
	FeedbackService.Tell(player, "Quest claimed — " .. table.concat(bits, " · "), "daily")
	return true, "Claimed"
end

--- Pool export for docs / tools.
function QuestService.GetPool(): { QuestDef }
	return table.clone(POOL)
end

Players.PlayerRemoving:Connect(function(player)
	states[player.UserId] = nil
end)

return QuestService
