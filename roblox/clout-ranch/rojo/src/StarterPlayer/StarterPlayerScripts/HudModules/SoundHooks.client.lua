--!strict
-- Boot LocalScript — PRIMARY Juice/Feedback SFX owner lives in SoundHooksApi.
-- SoundService.Start is a no-op — do not dual-listen Remotes.Juice.
-- docs/AUDIO_MIX_BIBLE.md

local SoundHooksApi = require(script.Parent:WaitForChild("SoundHooksApi"))
SoundHooksApi.Start()
