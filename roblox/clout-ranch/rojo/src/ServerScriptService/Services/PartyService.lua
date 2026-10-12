--!strict
-- Server ModuleScript: 4-player parties, fuzzy invite, lock assist + cash huddle bonus
-- Remotes (wired in Bootstrap): PartyInvite, PartyAccept, PartyLeave, PartySync

local Players = game:GetService("Players")

local MAX_PARTY = 4
local NEARBY_STUDS = 42
local LOCK_ASSIST_SECONDS = 5
local CASH_BONUS_MULT = 1.1 -- when 2+ party mates huddle nearby
local INVITE_TTL = 45

export type Party = {
	id: string,
	leaderUserId: number,
	members: { number }, -- includes leader
}

local nextId = 0
local parties: { [string]: Party } = {}
local userParty: { [number]: string } = {} -- userId -> partyId
local pendingInvite: { [number]: { fromUserId: number, expires: number } } = {}

local PartyService = {}

local syncRemote: RemoteEvent? = nil
local feedbackTell: ((Player, string, string?) -> ())? = nil

function PartyService.BindRemotes(sync: RemoteEvent)
	syncRemote = sync
end

function PartyService.SetFeedback(fn: (Player, string, string?) -> ())
	feedbackTell = fn
end

local function tell(player: Player, msg: string, tone: string?)
	if feedbackTell then
		feedbackTell(player, msg, tone)
	end
end

local function newPartyId(): string
	nextId += 1
	return "p" .. tostring(nextId)
end

local function getRoot(player: Player): BasePart?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

function PartyService.AreNearby(a: Player, b: Player, range: number?): boolean
	local ra = getRoot(a)
	local rb = getRoot(b)
	if not ra or not rb then
		return false
	end
	return (ra.Position - rb.Position).Magnitude <= (range or NEARBY_STUDS)
end

function PartyService.GetParty(userId: number): Party?
	local pid = userParty[userId]
	return if pid then parties[pid] else nil
end

function PartyService.GetMembers(userId: number): { number }
	local p = PartyService.GetParty(userId)
	return if p then table.clone(p.members) else { userId }
end

function PartyService.IsPartyMate(aUserId: number, bUserId: number): boolean
	if aUserId == bUserId then
		return false
	end
	local pa = PartyService.GetParty(aUserId)
	local pb = PartyService.GetParty(bUserId)
	return pa ~= nil and pa == pb
end

local function partyPayload(party: Party?): { id: string?, leaderUserId: number?, members: { { userId: number, name: string } } }
	if not party then
		return { id = nil, leaderUserId = nil, members = {} }
	end
	local members = {}
	for _, uid in party.members do
		local plr = Players:GetPlayerByUserId(uid)
		table.insert(members, {
			userId = uid,
			name = if plr then plr.DisplayName else ("User" .. tostring(uid)),
		})
	end
	return {
		id = party.id,
		leaderUserId = party.leaderUserId,
		members = members,
	}
end

function PartyService.SyncPlayer(player: Player)
	if not syncRemote then
		return
	end
	local party = PartyService.GetParty(player.UserId)
	local invite = pendingInvite[player.UserId]
	local fromName: string? = nil
	if invite and workspace:GetServerTimeNow() < invite.expires then
		local from = Players:GetPlayerByUserId(invite.fromUserId)
		fromName = if from then from.DisplayName else nil
	else
		pendingInvite[player.UserId] = nil
	end
	syncRemote:FireClient(player, {
		party = partyPayload(party),
		pendingFrom = fromName,
		pendingFromUserId = if invite then invite.fromUserId else nil,
		cashBonusActive = PartyService.GetCashBonusMult(player) > 1,
		lockAssistStuds = NEARBY_STUDS,
	})
end

local function syncParty(party: Party)
	for _, uid in party.members do
		local plr = Players:GetPlayerByUserId(uid)
		if plr then
			PartyService.SyncPlayer(plr)
		end
	end
end

--- Fuzzy resolve: userId number, or username / displayName (exact → prefix → contains)
function PartyService.ResolveTarget(query: any): Player?
	if typeof(query) == "number" then
		return Players:GetPlayerByUserId(query)
	end
	if typeof(query) ~= "string" then
		return nil
	end
	local raw = string.gsub(query, "^%s+", "")
	raw = string.gsub(raw, "%s+$", "")
	if #raw == 0 then
		return nil
	end
	-- numeric string as userId
	local asNum = tonumber(raw)
	if asNum and math.floor(asNum) == asNum then
		local byId = Players:GetPlayerByUserId(asNum)
		if byId then
			return byId
		end
	end
	local q = string.lower(raw)
	local exact: Player? = nil
	local prefix: Player? = nil
	local contains: Player? = nil
	for _, plr in Players:GetPlayers() do
		local name = string.lower(plr.Name)
		local display = string.lower(plr.DisplayName)
		if name == q or display == q then
			exact = plr
			break
		end
		if not prefix and (string.sub(name, 1, #q) == q or string.sub(display, 1, #q) == q) then
			prefix = plr
		elseif not contains and (string.find(name, q, 1, true) or string.find(display, q, 1, true)) then
			contains = plr
		end
	end
	return exact or prefix or contains
end

local function ensureSoloParty(leader: Player): Party
	local existing = PartyService.GetParty(leader.UserId)
	if existing then
		return existing
	end
	local id = newPartyId()
	local party: Party = {
		id = id,
		leaderUserId = leader.UserId,
		members = { leader.UserId },
	}
	parties[id] = party
	userParty[leader.UserId] = id
	return party
end

function PartyService.Invite(from: Player, query: any): (boolean, string?)
	local target = PartyService.ResolveTarget(query)
	if not target then
		return false, "Nobody matches that name"
	end
	if target.UserId == from.UserId then
		return false, "Can't invite yourself"
	end
	local party = ensureSoloParty(from)
	if party.leaderUserId ~= from.UserId and not table.find(party.members, from.UserId) then
		return false, "Not in a party"
	end
	-- any member can invite
	if #party.members >= MAX_PARTY then
		return false, "Party full (max 4)"
	end
	local theirParty = PartyService.GetParty(target.UserId)
	if theirParty and theirParty.id == party.id then
		return false, "Already riding with you"
	end
	if theirParty and #theirParty.members > 1 then
		return false, "They're already in a crew"
	end
	pendingInvite[target.UserId] = {
		fromUserId = from.UserId,
		expires = workspace:GetServerTimeNow() + INVITE_TTL,
	}
	tell(target, from.DisplayName .. " invited you to their Clout Crew!", "clout")
	tell(from, "Invite sent to " .. target.DisplayName, "success")
	PartyService.SyncPlayer(target)
	PartyService.SyncPlayer(from)
	return true, nil
end

function PartyService.Accept(player: Player): (boolean, string?)
	local invite = pendingInvite[player.UserId]
	if not invite or workspace:GetServerTimeNow() >= invite.expires then
		pendingInvite[player.UserId] = nil
		return false, "No invite pending"
	end
	local from = Players:GetPlayerByUserId(invite.fromUserId)
	if not from then
		pendingInvite[player.UserId] = nil
		return false, "Inviter left"
	end
	pendingInvite[player.UserId] = nil

	-- leave old solo party if any
	local old = PartyService.GetParty(player.UserId)
	if old then
		PartyService.Leave(player, true)
	end

	local party = ensureSoloParty(from)
	if #party.members >= MAX_PARTY then
		return false, "Party filled up"
	end
	if table.find(party.members, player.UserId) then
		return true, nil
	end
	table.insert(party.members, player.UserId)
	userParty[player.UserId] = party.id
	tell(player, "Joined " .. from.DisplayName .. "'s crew!", "success")
	tell(from, player.DisplayName .. " hopped in the crew!", "clout")
	syncParty(party)
	return true, nil
end

function PartyService.Leave(player: Player, silent: boolean?): (boolean, string?)
	local party = PartyService.GetParty(player.UserId)
	if not party then
		return false, "Not in a party"
	end
	local uid = player.UserId
	local idx = table.find(party.members, uid)
	if idx then
		table.remove(party.members, idx)
	end
	userParty[uid] = nil

	if #party.members == 0 then
		parties[party.id] = nil
		PartyService.SyncPlayer(player)
		if not silent then
			tell(player, "Left the crew", "info")
		end
		return true, nil
	end

	if party.leaderUserId == uid then
		party.leaderUserId = party.members[1]
	end

	syncParty(party)
	PartyService.SyncPlayer(player)
	if not silent then
		tell(player, "Left the crew", "info")
	end
	return true, nil
end

--- +LOCK_ASSIST_SECONDS when any party mate is nearby
function PartyService.GetLockAssistSeconds(player: Player): number
	local party = PartyService.GetParty(player.UserId)
	if not party or #party.members < 2 then
		return 0
	end
	for _, uid in party.members do
		if uid ~= player.UserId then
			local mate = Players:GetPlayerByUserId(uid)
			if mate and PartyService.AreNearby(player, mate) then
				return LOCK_ASSIST_SECONDS
			end
		end
	end
	return 0
end

--- 1.1 when 2+ party members are together near this player
function PartyService.GetCashBonusMult(player: Player): number
	local party = PartyService.GetParty(player.UserId)
	if not party or #party.members < 2 then
		return 1
	end
	local nearbyCount = 1 -- self
	for _, uid in party.members do
		if uid ~= player.UserId then
			local mate = Players:GetPlayerByUserId(uid)
			if mate and PartyService.AreNearby(player, mate) then
				nearbyCount += 1
			end
		end
	end
	if nearbyCount >= 2 then
		return CASH_BONUS_MULT
	end
	return 1
end

function PartyService.CountNearbyMates(player: Player): number
	local party = PartyService.GetParty(player.UserId)
	if not party then
		return 0
	end
	local n = 0
	for _, uid in party.members do
		if uid ~= player.UserId then
			local mate = Players:GetPlayerByUserId(uid)
			if mate and PartyService.AreNearby(player, mate) then
				n += 1
			end
		end
	end
	return n
end

Players.PlayerRemoving:Connect(function(player)
	pendingInvite[player.UserId] = nil
	PartyService.Leave(player)
end)

Players.PlayerAdded:Connect(function(player)
	task.defer(function()
		PartyService.SyncPlayer(player)
	end)
end)

return PartyService
