--!strict
-- Simple Janitor/Maid — track tasks, connections, and instances; clean in LIFO order.
-- No external deps.

export type Maid = {
	Give: (self: Maid, task: any) -> any,
	GiveConnection: (self: Maid, conn: RBXScriptConnection) -> RBXScriptConnection,
	GiveInstance: (self: Maid, inst: Instance) -> Instance,
	DoCleaning: (self: Maid) -> (),
	Destroy: (self: Maid) -> (),
}

local Maid = {}
Maid.__index = Maid

local function cleanupOne(job: any)
	if job == nil then
		return
	end
	local t = typeof(job)
	if t == "RBXScriptConnection" then
		if (job :: RBXScriptConnection).Connected then
			(job :: RBXScriptConnection):Disconnect()
		end
	elseif t == "Instance" then
		(job :: Instance):Destroy()
	elseif t == "function" then
		(job :: () -> ())()
	elseif t == "thread" then
		local th = job :: thread
		if coroutine.status(th) ~= "dead" then
			pcall(task.cancel, th)
		end
	elseif t == "table" then
		local tab = job :: { [any]: any }
		if typeof(tab.Destroy) == "function" then
			tab:Destroy()
		elseif typeof(tab.Disconnect) == "function" then
			tab:Disconnect()
		elseif typeof(tab.DoCleaning) == "function" then
			tab:DoCleaning()
		end
	end
end

function Maid.new(): Maid
	local self = setmetatable({
		_tasks = {} :: { any },
		_cleaning = false,
	}, Maid)
	return (self :: any) :: Maid
end

function Maid.Give(self: Maid, task: any): any
	if task == nil then
		return nil
	end
	local raw = self :: any
	if raw._cleaning then
		cleanupOne(task)
		return task
	end
	table.insert(raw._tasks, task)
	return task
end

function Maid.GiveConnection(self: Maid, conn: RBXScriptConnection): RBXScriptConnection
	self:Give(conn)
	return conn
end

function Maid.GiveInstance(self: Maid, inst: Instance): Instance
	self:Give(inst)
	return inst
end

function Maid.DoCleaning(self: Maid)
	local raw = self :: any
	if raw._cleaning then
		return
	end
	raw._cleaning = true
	local tasks = raw._tasks
	for i = #tasks, 1, -1 do
		local ok, err = pcall(cleanupOne, tasks[i])
		if not ok then
			warn("[Maid] cleanup error:", err)
		end
		tasks[i] = nil
	end
	table.clear(tasks)
	raw._cleaning = false
end

function Maid.Destroy(self: Maid)
	self:DoCleaning()
end

return Maid
