--!strict
-- Server ModuleScript: cash + multipliers (wire to DataStore later)

local Players = game:GetService("Players")

export type Wallet = {
	cash: number,
	incomeMult: number,
}

local wallets: { [number]: Wallet } = {}

local EconomyService = {}

function EconomyService.InitPlayer(player: Player)
	wallets[player.UserId] = { cash = 50, incomeMult = 1 }
end

function EconomyService.Get(player: Player): Wallet
	local w = wallets[player.UserId]
	if not w then
		EconomyService.InitPlayer(player)
		w = wallets[player.UserId]
	end
	return w
end

function EconomyService.AddCash(player: Player, amount: number)
	local w = EconomyService.Get(player)
	w.cash += amount
end

function EconomyService.TrySpend(player: Player, amount: number): boolean
	local w = EconomyService.Get(player)
	if w.cash < amount then
		return false
	end
	w.cash -= amount
	return true
end

function EconomyService.SetIncomeMult(player: Player, mult: number)
	EconomyService.Get(player).incomeMult = mult
end

Players.PlayerAdded:Connect(EconomyService.InitPlayer)
Players.PlayerRemoving:Connect(function(player)
	wallets[player.UserId] = nil
end)

return EconomyService
