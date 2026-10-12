--!strict
-- Clout Ranch HUD theme — Art one-pager palette + HUD helpers
-- Tokens match docs/ART_DIRECTION.md + ReplicatedStorage RarityColors.Brand()

local Theme = {}

Theme.Colors = {
	Gold = Color3.fromRGB(245, 200, 75),
	GoldDim = Color3.fromRGB(201, 160, 58),
	DeepPurple = Color3.fromRGB(91, 42, 158),
	Lilac = Color3.fromRGB(201, 166, 255),
	Cream = Color3.fromRGB(255, 246, 224),
	NightVoid = Color3.fromRGB(26, 18, 40),
	HeatPink = Color3.fromRGB(255, 77, 184),
	Panel = Color3.fromRGB(26, 18, 40),
	PanelAlt = Color3.fromRGB(91, 42, 158),
	Mint = Color3.fromRGB(125, 255, 179),
	Pink = Color3.fromRGB(255, 77, 184),
	Purple = Color3.fromRGB(91, 42, 158),
	PurpleHot = Color3.fromRGB(201, 166, 255),
	White = Color3.fromRGB(255, 246, 224),
	Shadow = Color3.fromRGB(10, 6, 20),
	Danger = Color3.fromRGB(255, 92, 122),
	Stroke = Color3.fromRGB(201, 166, 255),
	Muted = Color3.fromRGB(168, 148, 196),
	-- Aliases used by older HUD modules
	BgDeep = Color3.fromRGB(26, 18, 40),
	BgPanel = Color3.fromRGB(36, 24, 50),
	BgCard = Color3.fromRGB(46, 32, 68),
	BgCardHover = Color3.fromRGB(58, 42, 88),
}

Theme.Rarity = {
	Common = Color3.fromRGB(255, 246, 224),
	Uncommon = Color3.fromRGB(201, 166, 255),
	Rare = Color3.fromRGB(245, 200, 75),
	Epic = Color3.fromRGB(245, 200, 75),
	Legendary = Color3.fromRGB(255, 77, 184),
	Secret = Color3.fromRGB(255, 77, 184),
	Mythic = Color3.fromRGB(255, 77, 184),
}

Theme.Fonts = {
	Title = Enum.Font.GothamBold,
	Body = Enum.Font.GothamMedium,
	Mono = Enum.Font.Code,
}

function Theme.corner(parent: Instance, px: number?): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px or 12)
	c.Parent = parent
	return c
end

function Theme.stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Colors.Stroke
	s.Thickness = thickness or 1.5
	s.Transparency = transparency or 0.25
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

function Theme.padding(parent: Instance, px: number): UIPadding
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = parent
	return p
end

function Theme.gradient(parent: GuiObject, c0: Color3, c1: Color3, rotation: number?): UIGradient
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c0),
		ColorSequenceKeypoint.new(1, c1),
	})
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

function Theme.formatCash(n: number): string
	local v = math.floor(n + 0.5)
	if v >= 1_000_000_000 then
		return string.format("$%.2fB", v / 1_000_000_000)
	elseif v >= 1_000_000 then
		return string.format("$%.2fM", v / 1_000_000)
	elseif v >= 10_000 then
		return string.format("$%.1fK", v / 1_000)
	end
	local s = tostring(v)
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return "$" .. formatted
end

function Theme.rarityColor(rarity: string): Color3
	return Theme.Rarity[rarity] or Theme.Colors.Muted
end

return Theme
