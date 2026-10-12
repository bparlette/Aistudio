--!strict
-- Shared economy / ranch timing knobs (no magic numbers in services).

local EconomyConfig = {
	StarterCash = 50,
	StarterIncomeMult = 1,
	StarterMaxSlots = 3,

	-- Ranch vault lock (RequestLock / Lock after deposit)
	LockSecondsF2P = 45,
	LockSecondsVIP = 120,

	-- First-plot newbie soft lock
	NewbieLockSeconds = 45,

	-- Soft protect after being stolen from (StealService)
	SoftProtectSeconds = 15,
}

return EconomyConfig
