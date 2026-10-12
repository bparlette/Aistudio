--!strict
-- Server ModuleScript: party DuoFlex cosmetic pose sync during Aura Flex
-- Fair flex: NO vote weight, NO aura power — vibe only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FlexEmoteService = {}

local duoBindable: BindableEvent? = nil
local duoRemote: RemoteEvent? = nil
local lastPhase: string = "idle"
local activeDuos: { [string]: boolean } = {} -- "uidA:uidB" sorted

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

local function pairKey(a: number, b: number): string
	if a < b then
		return tostring(a) .. ":" .. tostring(b)
	end
	return tostring(b) .. ":" .. tostring(a)
end

local function ensureBindable(): BindableEvent
	if duoBindable and duoBindable.Parent then
		return duoBindable
	end
	local folder = ReplicatedStorage:FindFirstChild("Social")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Social"
		folder.Parent = ReplicatedStorage
	end
	local existing = folder:FindFirstChild("DuoFlex")
	if existing and existing:IsA("BindableEvent") then
		duoBindable = existing
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local be = Instance.new("BindableEvent")
	be.Name = "DuoFlex"
	be.Parent = folder
	duoBindable = be
	return be
end

function FlexEmoteService.BindRemote(ev: RemoteEvent)
	duoRemote = ev
end

function FlexEmoteService.Bootstrap()
	ensureBindable()
end

--- Fire cosmetic duo pose for two party mates. Clients / VFX listen; zero combat effect.
function FlexEmoteService.TriggerDuo(a: Player, b: Player, reason: string?)
	local be = ensureBindable()
	local payload = {
		userIdA = a.UserId,
		userIdB = b.UserId,
		nameA = a.DisplayName,
		nameB = b.DisplayName,
		reason = reason or "party",
		cosmeticOnly = true, -- contract: never touch AuraService.Vote
	}
	be:Fire(payload)
	if duoRemote then
		duoRemote:FireAllClients(payload)
	end
end

local function scanDuos()
	local Party = tryParty()
	if not Party then
		return
	end
	local seen: { [string]: boolean } = {}
	for _, player in Players:GetPlayers() do
		local mates = Party.GetMembers(player.UserId)
		if #mates >= 2 then
			for _, mid in mates do
				if mid ~= player.UserId then
					local mate = Players:GetPlayerByUserId(mid)
					if mate and Party.AreNearby(player, mate) then
						local key = pairKey(player.UserId, mid)
						if not seen[key] then
							seen[key] = true
							if not activeDuos[key] then
								activeDuos[key] = true
								FlexEmoteService.TriggerDuo(player, mate, "flex_huddle")
							end
						end
					end
				end
			end
		end
	end
	-- clear pairs that drifted apart
	for key in activeDuos do
		if not seen[key] then
			activeDuos[key] = nil
		end
	end
end

function FlexEmoteService.OnPhase(phase: string)
	if phase == "flex" and lastPhase ~= "flex" then
		table.clear(activeDuos)
		scanDuos()
	elseif phase ~= "flex" then
		table.clear(activeDuos)
	end
	lastPhase = phase
end

function FlexEmoteService.Tick(phase: string)
	FlexEmoteService.OnPhase(phase)
	if phase == "flex" then
		scanDuos()
	end
end

-- Explicit: Aura votes stay 1:1. This module never calls AuraService.Vote.
function FlexEmoteService.DoesAffectVotes(): boolean
	return false
end

return FlexEmoteService
