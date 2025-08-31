---# VARIABLES #---
local FrameworkName = "ExxoFrame"

---# SCRIPT #---
local module = {}

function module.Warn(Message : string)
	warn(debug.traceback(("[%*] %*"):format(FrameworkName,Message),1))
end

function module.WarnAssert(Condition : any, Message : string)
	if Condition then
		module.Warn(Message)
	end
end

function module.Error(Message : string,Level : number)
	error(("[%*] %*"):format(FrameworkName,Message),Level or 0)
end

function module.ErrorAssert(Condition : any, Message : string)
	if Condition then
		module.Error(Message,2)
	end
end

return (module) :: typeof(module)