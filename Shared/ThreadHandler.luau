--!strict
--!native
--!optimize 2
local FreeThread = false

local function AcquireThread(TaskFunction, ...)
	local Thread: (thread | false)? = FreeThread
	FreeThread = nil

	TaskFunction(...)

	FreeThread = Thread
end

local function CreateThreadTask(...)
	AcquireThread(...)

	while true do
		AcquireThread(coroutine.yield())
	end
end

local function NewTask(TaskFunction, ...)
	if not FreeThread then
		FreeThread = coroutine.create(CreateThreadTask)
	end

	task.spawn(FreeThread, TaskFunction, ...)
end

return NewTask