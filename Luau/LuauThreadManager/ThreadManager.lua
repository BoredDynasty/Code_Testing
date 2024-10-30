local ThreadManager = {}
ThreadManager.__index = ThreadManager

function ThreadManager.newThread(any: thread, threads: number)
	local self = setmetatable({}, ThreadManager)
	--
	self.runningThreads = {}
	table.insert(self.runningThreads, any)
	--
	task.desynchronize()
	--
	for count = 1, threads do
		for i, thread: thread in self.runningThreads do
			loadstring(thread)()
		end
	end
	--
	task.synchronize()
	return { self, self.runningThreads }
end

return ThreadManager
