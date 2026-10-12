--!strict
-- Tiny tween / remotes helpers

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = {}

function Util.tween(
	inst: Instance,
	info: TweenInfo | number,
	props: { [string]: any },
	onDone: (() -> ())?
): Tween
	local ti: TweenInfo
	if typeof(info) == "number" then
		ti = TweenInfo.new(info :: number, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	else
		ti = info :: TweenInfo
	end
	local tw = TweenService:Create(inst, ti, props)
	if onDone then
		tw.Completed:Once(onDone)
	end
	tw:Play()
	return tw
end

function Util.waitRemotes(timeout: number?): Folder?
	return ReplicatedStorage:WaitForChild("Remotes", timeout or 30) :: Folder?
end

function Util.getRemoteEvent(remotes: Folder, name: string): RemoteEvent?
	local r = remotes:FindFirstChild(name) or remotes:WaitForChild(name, 3)
	if r and r:IsA("RemoteEvent") then
		return r
	end
	return nil
end

function Util.getRemoteFunction(remotes: Folder, name: string): RemoteFunction?
	local r = remotes:FindFirstChild(name) or remotes:WaitForChild(name, 3)
	if r and r:IsA("RemoteFunction") then
		return r
	end
	return nil
end

function Util.bindableOrRemote(parent: Instance, name: string): (RemoteEvent | BindableEvent)?
	local r = parent:FindFirstChild(name) or parent:WaitForChild(name, 2)
	if r and (r:IsA("RemoteEvent") or r:IsA("BindableEvent")) then
		return r :: any
	end
	return nil
end

--- Soft scale pulse for satisfying button feedback
function Util.pulse(button: GuiObject, scale: number?)
	local s = scale or 1.06
	local orig = button.Size
	Util.tween(button, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(orig.X.Scale, math.floor(orig.X.Offset * s), orig.Y.Scale, math.floor(orig.Y.Offset * s)),
	}, function()
		Util.tween(button, 0.12, { Size = orig })
	end)
end

return Util
