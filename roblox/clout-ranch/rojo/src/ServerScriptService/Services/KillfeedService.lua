--!strict
-- Server ModuleScript: scrolling steal / slap / flex feed
-- Replicates via ReplicatedStorage.CloutFeed (StringValues) + Remotes.FeedEvent

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MAX_LINES = 12
local VERBS = { "yeeted", "yoinked", "snatched", "spirited", "clipped", "beamed" }

local KillfeedService = {}

local feedFolder: Folder? = nil
local feedEvent: RemoteEvent? = nil
local lineSeq = 0

local function ensureFolder(): Folder
	if feedFolder and feedFolder.Parent then
		return feedFolder
	end
	local existing = ReplicatedStorage:FindFirstChild("CloutFeed")
	if existing and existing:IsA("Folder") then
		feedFolder = existing
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "CloutFeed"
	folder.Parent = ReplicatedStorage
	feedFolder = folder
	return folder
end

function KillfeedService.BindRemote(ev: RemoteEvent)
	feedEvent = ev
end

local function prune(folder: Folder)
	local kids = folder:GetChildren()
	table.sort(kids, function(a, b)
		return a.Name < b.Name
	end)
	while #kids > MAX_LINES do
		local oldest = table.remove(kids, 1)
		if oldest then
			oldest:Destroy()
		end
	end
end

function KillfeedService.Push(line: string)
	if typeof(line) ~= "string" or #line == 0 then
		return
	end
	local trimmed = string.sub(line, 1, 120)
	local folder = ensureFolder()
	lineSeq += 1
	local sv = Instance.new("StringValue")
	sv.Name = string.format("%06d", lineSeq)
	sv.Value = trimmed
	sv.Parent = folder
	prune(folder)

	if feedEvent then
		feedEvent:FireAllClients(trimmed)
	end
end

local function pickVerb(): string
	return VERBS[math.random(1, #VERBS)]
end

function KillfeedService.AnnounceSteal(thief: Player, victimName: string, petName: string)
	local verb = pickVerb()
	KillfeedService.Push(string.format("%s %s %s's %s", thief.DisplayName, verb, victimName, petName))
end

function KillfeedService.AnnounceSlap(attacker: Player, thiefName: string, petName: string?)
	if petName then
		KillfeedService.Push(string.format("%s slapped %s — %s scampered home", attacker.DisplayName, thiefName, petName))
	else
		KillfeedService.Push(string.format("%s slapped %s mid-heist", attacker.DisplayName, thiefName))
	end
end

function KillfeedService.AnnounceDeposit(player: Player, petName: string)
	KillfeedService.Push(string.format("%s locked in %s 🔒", player.DisplayName, petName))
end

function KillfeedService.AnnounceAura(winners: { number })
	if #winners == 0 then
		return
	end
	local names = {}
	for i, uid in winners do
		local plr = Players:GetPlayerByUserId(uid)
		local label = if plr then plr.DisplayName else ("#" .. tostring(i))
		table.insert(names, label)
	end
	KillfeedService.Push("Aura Flex podium: " .. table.concat(names, " · "))
end

function KillfeedService.Bootstrap()
	ensureFolder()
end

return KillfeedService
