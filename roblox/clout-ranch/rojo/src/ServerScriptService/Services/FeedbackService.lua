--!strict
-- Server → client toasts. Payload matches HUD: { message, tone }

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FeedbackService = {}

local function getFeedbackRemote(): RemoteEvent?
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		return nil
	end
	local ev = remotes:FindFirstChild("Feedback")
	if ev and ev:IsA("RemoteEvent") then
		return ev
	end
	return nil
end

function FeedbackService.Tell(player: Player, message: string, tone: string?)
	local ev = getFeedbackRemote()
	if ev then
		ev:FireClient(player, {
			message = message,
			tone = tone or "info",
		})
	end
end

function FeedbackService.Notify(player: Player, kind: string, message: string)
	-- kind is tone; message is body (call sites use Notify(player, "daily", "…"))
	FeedbackService.Tell(player, message, kind)
end

function FeedbackService.Push(player: Player, kind: string, message: string)
	FeedbackService.Notify(player, kind, message)
end

function FeedbackService.Broadcast(message: string, tone: string?)
	local ev = getFeedbackRemote()
	if not ev then
		return
	end
	local payload = { message = message, tone = tone or "clout" }
	for _, player in game:GetService("Players"):GetPlayers() do
		ev:FireClient(player, payload)
	end
end

function FeedbackService.Submit(player: Player, text: any)
	if typeof(text) ~= "string" then
		return
	end
	local trimmed = string.sub(text, 1, 500)
	if #trimmed == 0 then
		return
	end
	print("[CloutRanch][Feedback]", player.Name, trimmed)
end

return FeedbackService
