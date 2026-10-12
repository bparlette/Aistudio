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
	end
	return r :: RemoteEvent
end

local BuyCarpet = ensureRemote("BuyCarpet")
local StealPet = ensureRemote("StealPet")
local DepositPet = ensureRemote("DepositPet")
local SlapThief = ensureRemote("SlapThief")
local VoteAura = ensureRemote("VoteAura")
local DoRebirth = ensureRemote("DoRebirth")
local RequestLock = ensureRemote("RequestLock")

RanchService.BootstrapFromWorkspace()
CarpetService.Rotate()

Players.PlayerAdded:Connect(function(player)
	EconomyService.InitPlayer(player)
	local ranch = RanchService.AssignPlot(player)
	if not ranch then
		warn("[CloutRanch] No free plot for", player.Name)
	end
end)

BuyCarpet.OnServerEvent:Connect(function(player, stockIndex: number)
	if typeof(stockIndex) ~= "number" then
		return
	end
	CarpetService.TryBuy(player, stockIndex)
end)

StealPet.OnServerEvent:Connect(function(player, plotName: string, slotIndex: number)
	if typeof(plotName) ~= "string" or typeof(slotIndex) ~= "number" then
		return
	end
	StealService.TrySteal(player, plotName, slotIndex)
end)

DepositPet.OnServerEvent:Connect(function(player)
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
	RebirthService.TryRebirth(player)
end)

RequestLock.OnServerEvent:Connect(function(player)
	RanchService.Lock(player, Monetization.IsVIP(player))
end)

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	CarpetService.Tick()
	AuraService.Tick()
	if acc >= 0.25 then
		RanchService.TickIncome(acc)
		acc = 0
	end
end)

print("[CloutRanch] MVP server boot OK")
