--!strict
-- Clout Ranch — polished addiction HUD (LocalScript)
-- Modules live under HudModules/ (Rojo ModuleScripts)

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudModules = script.Parent:WaitForChild("HudModules")
local Theme = require(HudModules:WaitForChild("Theme"))
local Util = require(HudModules:WaitForChild("Util"))
local CashCounter = require(HudModules:WaitForChild("CashCounter"))
local CarpetShop = require(HudModules:WaitForChild("CarpetShop"))
local DailyClaim = require(HudModules:WaitForChild("DailyClaim"))
local AuraBanner = require(HudModules:WaitForChild("AuraBanner"))
local FeedbackToast = require(HudModules:WaitForChild("FeedbackToast"))
local TutorialTips = require(HudModules:WaitForChild("TutorialTips"))
local ActionBar = require(HudModules:WaitForChild("ActionBar"))
local JoinFunnel = require(HudModules:WaitForChild("JoinFunnel"))
local VfxService = require(HudModules:WaitForChild("VfxService"))
local Killfeed = require(HudModules:WaitForChild("Killfeed"))
local PartyPanel = require(HudModules:WaitForChild("PartyPanel"))
local QuestPanel = require(HudModules:WaitForChild("QuestPanel"))
local SoftOffer = require(HudModules:WaitForChild("SoftOffer"))
-- SoftFunnel retired: SoftOffer is sole SoftOffer remote listener (funnel-ui-1-notes)

local Maid = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Maid"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remotes folder (server creates); warn but keep UI alive for polish preview
local remotes = Util.waitRemotes(30)
if not remotes then
	warn("[CloutRanch] Remotes missing — HUD UI loads, actions will no-op until ServerBootstrap runs")
end

local gui = Instance.new("ScreenGui")
gui.Name = "CloutRanchHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 20
gui.Parent = playerGui

-- ScreenGui-lifetime Maid: all HUD connections / module handles clean on destroy
local hudMaid = Maid.new()
hudMaid:GiveConnection(gui.Destroying:Connect(function()
	hudMaid:DoCleaning()
end))

-- Full-screen root (safe area padding for mobile notch)
local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.BorderSizePixel = 0
root.Parent = gui

local inset = GuiService:GetGuiInset()
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, math.max(8, inset.Y))
pad.PaddingBottom = UDim.new(0, 8)
pad.PaddingLeft = UDim.new(0, 0)
pad.PaddingRight = UDim.new(0, 0)
pad.Parent = root

-- Subtle vignette for drip mood (non-blocking)
local vignette = Instance.new("Frame")
vignette.Name = "Vignette"
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = Theme.Colors.NightVoid
vignette.BackgroundTransparency = 0.92
vignette.BorderSizePixel = 0
vignette.ZIndex = 0
vignette.Parent = root

local feedback = FeedbackToast.mount(root, hudMaid)
hudMaid:Give(feedback)

local function toast(msg: string, kind: string?)
	feedback:Show(msg, kind)
end

hudMaid:Give(CashCounter.mount(root, hudMaid))

local shop = CarpetShop.mount(root, function(stockIndex: number)
	local folder = remotes or Util.waitRemotes(2)
	if not folder then
		toast("Remotes offline", "error")
		return
	end
	local buy = Util.getRemoteEvent(folder, "BuyCarpet")
	if not buy then
		toast("BuyCarpet missing", "error")
		return
	end
	buy:FireServer(stockIndex)
	toast("Buying slot " .. tostring(stockIndex) .. "…", "buy")
end, toast)
if shop and shop.Destroy then
	hudMaid:Give(shop)
end

hudMaid:Give(DailyClaim.mount(root, function(msg: string)
	toast(msg, "daily")
end, hudMaid))

hudMaid:Give(AuraBanner.mount(root, toast, hudMaid))
hudMaid:Give(TutorialTips.mount(root))
hudMaid:Give(ActionBar.mount(root, toast, hudMaid, function()
	if shop and shop.Open then
		shop:Open()
	end
end))
hudMaid:Give(JoinFunnel.mount(root, shop, toast, hudMaid))
hudMaid:Give(Killfeed.mount(root, hudMaid))
hudMaid:Give(PartyPanel.mount(root, toast))
hudMaid:Give(QuestPanel.mount(root, toast))
hudMaid:Give(SoftOffer.mount(root, toast, hudMaid))

-- Tiny brand chip (top-center under aura banner slot)
local brand = Instance.new("TextLabel")
brand.Name = "Brand"
brand.AnchorPoint = Vector2.new(0.5, 0)
brand.Position = UDim2.new(0.5, 0, 0, 88)
brand.Size = UDim2.fromOffset(160, 18)
brand.BackgroundTransparency = 1
brand.Font = Theme.Fonts.Body
brand.TextSize = 11
brand.TextColor3 = Theme.Colors.Muted
brand.TextTransparency = 0.35
brand.Text = "CLOUT RANCH"
brand.ZIndex = 5
brand.Parent = root

-- Juice remote → soft camera shake (kind intensity)
local SHAKE: { [string]: number } = {
	buy = 0.18,
	steal = 0.35,
	steal_trail = 0.35,
	deposit = 0.22,
	place_burst = 0.28,
	place = 0.28,
	rebirth = 0.45,
	daily = 0.25,
	lock = 0.12,
	slap = 0.4,
	miss = 0.1,
	clip = 0.38,
	flex_shock = 0.32,
	flex = 0.32,
	aura = 0.3,
	aura_beams = 0.28,
	vote_punch = 0.42,
}

local function cameraShake(kind: string)
	local mag = SHAKE[kind] or 0.2
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local start = os.clock()
	local dur = 0.22
	local conn: RBXScriptConnection? = nil
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		if t >= dur or not cam then
			if conn then
				conn:Disconnect()
			end
			return
		end
		local fall = 1 - (t / dur)
		local ox = (math.noise(t * 40, 0) - 0.5) * 2 * mag * fall
		local oy = (math.noise(0, t * 40) - 0.5) * 2 * mag * fall
		cam.CFrame = cam.CFrame * CFrame.new(ox, oy, 0)
	end)
	hudMaid:GiveConnection(conn)
end

task.spawn(function()
	local folder = remotes or Util.waitRemotes(30)
	if not folder then
		return
	end
	local juice = Util.getRemoteEvent(folder, "Juice")
	if not juice then
		juice = folder:WaitForChild("Juice", 8) :: RemoteEvent?
	end
	if juice and juice:IsA("RemoteEvent") then
		hudMaid:GiveConnection(juice.OnClientEvent:Connect(function(payload: any)
			local kind = "info"
			if typeof(payload) == "table" and typeof(payload.kind) == "string" then
				kind = payload.kind
			elseif typeof(payload) == "string" then
				kind = payload
			end
			cameraShake(kind)
		end))
	end
	-- OpenShop also bumps shop if CarpetShop missed the wire
	local openShop = Util.getRemoteEvent(folder, "OpenShop")
	if openShop then
		hudMaid:GiveConnection(openShop.OnClientEvent:Connect(function()
			if shop and shop.Open then
				shop:Open()
			end
		end))
	end
end)

task.spawn(function()
	VfxService.Start(hudMaid)
end)
-- SoundHooks.client.lua owns Juice/Feedback SFX (SoundService.Start is no-op; do not dual-listen).

print("[CloutRanch] Client HUD online (onboarding + juice + vfx; Maid-bound)")
