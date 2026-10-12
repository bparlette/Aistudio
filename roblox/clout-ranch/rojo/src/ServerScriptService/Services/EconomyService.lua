--!strict
-- Server ModuleScript: cash + multipliers (persisted via DataService)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local STARTER_CASH = 50
local STARTER_INCOME_MULT = 1
do
	local cfgFolder = ReplicatedStorage:FindFirstChild("Config")
	local mod = cfgFolder and cfgFolder:FindFirstChild("EconomyConfig")
	if mod and mod:IsA("ModuleScript") then
		local ok, cfg = pcall(require, mod)
		if ok and cfg then
			if typeof(cfg.StarterCash) == "number" then
				STARTER_CASH = cfg.StarterCash
			end
			if typeof(cfg.StarterIncomeMult) == "number" then
				STARTER_INCOME_MULT = cfg.StarterIncomeMult
			end
		end
	end
end

export type Wallet = {
	cash: number,
	incomeMult: number,
}

local wallets: { [number]: Wallet } = {}

local EconomyService = {}

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

local function ensureStats(player: Player, wallet: Wallet)
	local folder = player:FindFirstChild("CloutStats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "CloutStats"
		folder.Parent = player
	end
	local cash = folder:FindFirstChild("Cash")
	if not cash then
		cash = Instance.new("NumberValue")
		cash.Name = "Cash"
		cash.Parent = folder
	end
	(cash :: NumberValue).Value = wallet.cash
end

--- Default wallet only if missing — never clobber a DataService load.
function EconomyService.InitPlayer(player: Player)
	if wallets[player.UserId] then
		ensureStats(player, wallets[player.UserId])
		return
	end
	wallets[player.UserId] = { cash = STARTER_CASH, incomeMult = STARTER_INCOME_MULT }
	ensureStats(player, wallets[player.UserId])
end

--- Apply persisted cash/mult from DataService (after session lock).
function EconomyService.ApplyLoaded(player: Player, cash: number, incomeMult: number?)
	local c = if typeof(cash) == "number" then cash else STARTER_CASH
	local m = if typeof(incomeMult) == "number" then incomeMult else 1
	wallets[player.UserId] = { cash = c, incomeMult = m }
	ensureStats(player, wallets[player.UserId])
end

function EconomyService.Get(player: Player): Wallet
	local w = wallets[player.UserId]
	if not w then
		EconomyService.InitPlayer(player)
		w = wallets[player.UserId]
	end
	return w
end

--- Add cash. Pass skipQuest=true for refunds / non-earning grants that should not advance daily quests.
function EconomyService.AddCash(player: Player, amount: number, skipQuest: boolean?)
	local w = EconomyService.Get(player)
	w.cash += amount
	ensureStats(player, w)
	notifyDirty(player)
	-- Daily quest: earn_cash (skip refunds/micro crumbs under 1¢)
	if not skipQuest and amount >= 0.01 then
		local qs = script.Parent:FindFirstChild("QuestService")
		if qs then
			local ok, QuestService = pcall(require, qs)
			if ok and QuestService and QuestService.Progress then
				QuestService.Progress(player, "earn_cash", amount)
			end
		end
	end
end

function EconomyService.TrySpend(player: Player, amount: number): boolean
	local w = EconomyService.Get(player)
	if w.cash < amount then
		return false
	end
	w.cash -= amount
	ensureStats(player, w)
	notifyDirty(player)
	return true
end

function EconomyService.SetIncomeMult(player: Player, mult: number)
	EconomyService.Get(player).incomeMult = mult
	notifyDirty(player)
end

Players.PlayerAdded:Connect(EconomyService.InitPlayer)
Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	task.defer(function()
		if Players:GetPlayerByUserId(userId) then
			return
		end
		wallets[userId] = nil
	end)
end)

return EconomyService
