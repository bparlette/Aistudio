--!strict
-- Server ModuleScript: season clock + Trend Week banner replication
-- Writes CloutState.TrendTitle (StringValue) and TrendEndsAt (NumberValue, GetServerTimeNow).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SEASON_ID = 1
local SEASON_NAME = "Launch Glow"

local SeasonService = {}

local trendDropService: any = nil
local titleVal: StringValue? = nil
local endsVal: NumberValue? = nil
local lastTitle = ""
local lastEnds = -1

local function tryTrendDrop()
	if trendDropService then
		return trendDropService
	end
	local mod = script.Parent:FindFirstChild("TrendDropService")
	if mod then
		local ok, result = pcall(require, mod)
		if ok then
			trendDropService = result
		end
	end
	return trendDropService
end

function SeasonService.GetId(): number
	return SEASON_ID
end

function SeasonService.GetName(): string
	return SEASON_NAME
end

--- Active trend featured pet id (or nil).
function SeasonService.GetFeatured(): string?
	local td = tryTrendDrop()
	if td and td.GetFeaturedPetId then
		return td.GetFeaturedPetId()
	end
	return nil
end

function SeasonService.GetTrendTitle(): string
	local td = tryTrendDrop()
	if not td or not td.GetActive then
		return ""
	end
	local drop = td.GetActive()
	if not drop then
		return ""
	end
	if td.GetBannerTitle then
		return td.GetBannerTitle(drop)
	end
	return string.format("TREND WEEK · %s", drop.displayName)
end

function SeasonService.GetTrendEndsAt(): number
	local td = tryTrendDrop()
	if not td or not td.GetActive then
		return 0
	end
	local drop = td.GetActive()
	return if drop then drop.endsAt else 0
end

function SeasonService.IsLimitedActive(petId: string): boolean
	local featured = SeasonService.GetFeatured()
	return featured ~= nil and featured == petId
end

--- Bind replicated ValueObjects created by Bootstrap.
function SeasonService.BindCloutState(trendTitle: StringValue, trendEndsAt: NumberValue)
	titleVal = trendTitle
	endsVal = trendEndsAt
	SeasonService.SyncBanner()
end

local function ensureBound()
	if titleVal and endsVal then
		return
	end
	local state = ReplicatedStorage:FindFirstChild("CloutState")
	if not state then
		return
	end
	local t = state:FindFirstChild("TrendTitle")
	local e = state:FindFirstChild("TrendEndsAt")
	if t and t:IsA("StringValue") then
		titleVal = t
	end
	if e and e:IsA("NumberValue") then
		endsVal = e
	end
end

function SeasonService.SyncBanner()
	ensureBound()
	local title = SeasonService.GetTrendTitle()
	local endsAt = SeasonService.GetTrendEndsAt()
	if titleVal and title ~= lastTitle then
		lastTitle = title
		titleVal.Value = title
	end
	if endsVal and endsAt ~= lastEnds then
		lastEnds = endsAt
		endsVal.Value = endsAt
	end
end

function SeasonService.Tick(_dt: number?)
	local td = tryTrendDrop()
	if td and td.Tick then
		td.Tick(_dt)
	end
	SeasonService.SyncBanner()
end

return SeasonService
