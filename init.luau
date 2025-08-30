--!strict
--!native
--!optimize 2
local RunService = game:GetService("RunService")

if RunService:IsRunning() and RunService:IsServer() then
	return require(script.Server)
else
	if script:FindFirstChild("Server") and RunService:IsRunning() then
		script.Server:Destroy()
		script.ServerCore:Destroy()
	end
	
	return require(script.Client)
end

