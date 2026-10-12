--!strict
-- Soft tips driven by CloutStats.OnboardingStep (server OnboardingService) + timed fallbacks
-- pre-alpha-onboard-1: tips name BUY→STEAL→LOCK→DEPOSIT; carry forces DEPOSIT tip.

local Players = game:GetService("Players")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Util = require(script.Parent:WaitForChild("Util"))

local TutorialTips = {}

export type Handle = {
	Destroy: (self: Handle) -> (),
}

-- Mirrors OnboardingService steps 1..6 — verb-first copy
local ONBOARD_TIPS: { [number]: string } = {
	[1] = "🏡 Ranch claimed — NEXT: BUY on the glowing Red Carpet!",
	[2] = "✨ NEXT: BUY — open Red Carpet and grab your first pet.",
	[3] = "🥷 NEXT: STEAL — pink STEAL button or unlocked Slot (E).",
	[4] = "🔒 NEXT: LOCK your ranch (F) — or STEAL then DEPOSIT.",
	[5] = "🎁 Tap CLAIM DAILY for streak cash + luck.",
	[6] = "🔥 Loop live — BUY → STEAL → LOCK → DEPOSIT. Stack clout!",
}

local CARRY_TIP = "📦 NEXT: DEPOSIT — sprint to the mint pad at YOUR RANCH!"

local FALLBACK_TIPS = {
	{ t = 3, text = "✨ NEXT: BUY a pet on the Red Carpet — cash starts ticking." },
	{ t = 18, text = "🛒 BUY → then STEAL a demo pet → LOCK → DEPOSIT home." },
	{ t = 40, text = "🔒 LOCK your ranch after buying so thieves bounce." },
	{ t = 70, text = "🏃 STEAL from unlocked plots, then DEPOSIT at your ranch." },
	{ t = 100, text = "⚡ Aura Flex rounds hit often — vote for the biggest aura." },
	{ t = 130, text = "🎁 Claim Daily for streak cash + luck boosts." },
	{ t = 160, text = "♻️ Rebirth for permanent income mult + more pet slots." },
}

local SESSION_SECONDS = 180

local function isCarrying(player: Player): boolean
	local char = player.Character
	if not char then
		return false
	end
	for _, ch in char:GetChildren() do
		if typeof(ch.Name) == "string" and string.sub(ch.Name, 1, 9) == "CarryPet_" then
			return true
		end
	end
	return false
end

function TutorialTips.mount(root: Frame): Handle
	local player = Players.LocalPlayer

	local tip = Instance.new("Frame")
	tip.Name = "TutorialTip"
	tip.AnchorPoint = Vector2.new(0.5, 1)
	tip.Position = UDim2.new(0.5, 0, 1, -100)
	tip.Size = UDim2.new(0, 480, 0, 52)
	tip.BackgroundColor3 = Theme.Colors.BgDeep
	tip.BackgroundTransparency = 0.15
	tip.BorderSizePixel = 0
	tip.Visible = false
	tip.ZIndex = 30
	tip.Parent = root
	Theme.corner(tip, 12)
	Theme.stroke(tip, Theme.Colors.Gold, 1.5, 0.4)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, -8)
	label.Position = UDim2.fromOffset(10, 4)
	label.BackgroundTransparency = 1
	label.Font = Theme.Fonts.Body
	label.TextSize = 14
	label.TextColor3 = Theme.Colors.White
	label.TextWrapped = true
	label.Text = ""
	label.ZIndex = 31
	label.Parent = tip

	local start = os.clock()
	local idx = 0
	local alive = true
	local showing = false
	local lastOnboardStep = -1
	local onboardDriven = false
	local lastCarry = false
	local connections: { RBXScriptConnection } = {}

	local function hide()
		if not showing then
			return
		end
		showing = false
		Util.tween(tip, 0.3, { BackgroundTransparency = 1 }, function()
			if not showing then
				tip.Visible = false
				tip.BackgroundTransparency = 0.15
			end
		end)
		Util.tween(label, 0.3, { TextTransparency = 1 })
	end

	local function show(text: string)
		showing = true
		tip.Visible = true
		label.Text = text
		label.TextTransparency = 1
		tip.BackgroundTransparency = 0.4
		Util.tween(tip, 0.35, { BackgroundTransparency = 0.15 })
		Util.tween(label, 0.35, { TextTransparency = 0 })
		-- Sticky while onboarding incomplete; only auto-hide after step 6
		task.delay(14, function()
			if not alive or label.Text ~= text then
				return
			end
			if lastOnboardStep >= 0 and lastOnboardStep < 6 then
				return -- keep sticky
			end
			if isCarrying(player) then
				return
			end
			hide()
		end)
	end

	local function onStep(step: number)
		if isCarrying(player) then
			lastOnboardStep = step
			onboardDriven = true
			show(CARRY_TIP)
			return
		end
		if step == lastOnboardStep and not lastCarry then
			return
		end
		lastOnboardStep = step
		local text = ONBOARD_TIPS[step]
		if text then
			onboardDriven = true
			show(text)
		end
		if step >= 6 then
			task.delay(12, function()
				if alive and lastOnboardStep >= 6 and not isCarrying(player) then
					hide()
				end
			end)
		end
	end

	local function bindOnboarding(folder: Instance)
		local stepVal = folder:FindFirstChild("OnboardingStep")
		local function hook(v: Instance)
			if v:IsA("NumberValue") or v:IsA("IntValue") then
				onStep((v :: NumberValue).Value)
				table.insert(connections, v:GetPropertyChangedSignal("Value"):Connect(function()
					onStep((v :: NumberValue).Value)
				end))
			end
		end
		if stepVal then
			hook(stepVal)
		end
		table.insert(connections, folder.ChildAdded:Connect(function(ch)
			if ch.Name == "OnboardingStep" then
				hook(ch)
			end
		end))
	end

	-- Immediate first tip so solo Play sees guidance within 1s
	task.defer(function()
		if alive and not onboardDriven then
			show(ONBOARD_TIPS[2] or FALLBACK_TIPS[1].text)
		end
	end)

	local stats = player:FindFirstChild("CloutStats")
	if stats then
		bindOnboarding(stats)
	end
	table.insert(connections, player.ChildAdded:Connect(function(c)
		if c.Name == "CloutStats" then
			bindOnboarding(c)
		end
	end))

	-- Carry watch: force DEPOSIT tip when pet is on back
	task.spawn(function()
		while alive do
			local carrying = isCarrying(player)
			if carrying and not lastCarry then
				lastCarry = true
				onboardDriven = true
				show(CARRY_TIP)
			elseif not carrying and lastCarry then
				lastCarry = false
				if lastOnboardStep >= 0 then
					local step = lastOnboardStep
					lastOnboardStep = -1 -- force refresh
					onStep(step)
				end
			end
			task.wait(0.5)
		end
	end)

	-- Timed fallbacks only if onboarding hasn't taken over yet (or after done)
	task.spawn(function()
		while alive do
			local elapsed = os.clock() - start
			if elapsed > SESSION_SECONDS then
				if not onboardDriven or lastOnboardStep >= 6 then
					if not isCarrying(player) then
						hide()
					end
				end
				break
			end
			if (not onboardDriven or lastOnboardStep >= 6) and not isCarrying(player) then
				while idx < #FALLBACK_TIPS and FALLBACK_TIPS[idx + 1].t <= elapsed do
					idx += 1
					if lastOnboardStep < 0 or lastOnboardStep >= 6 then
						show(FALLBACK_TIPS[idx].text)
					end
				end
			end
			task.wait(0.5)
		end
	end)

	return {
		Destroy = function()
			alive = false
			for _, c in connections do
				c:Disconnect()
			end
			tip:Destroy()
		end,
	}
end

return TutorialTips
