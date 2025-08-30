--!strict
--!native
--!optimize 2

---# MODULES #---
local Signal = require(script.Parent.Parent:WaitForChild("Signal"))
local BridgeNet2 = require(script.Parent.Parent:WaitForChild("BridgeNet2"))
local Replica = require(script.Parent.Parent:WaitForChild("Replica"))
local Promise = require(script.Parent.Parent:WaitForChild("Promise"))
local ClassConstructor = require(script.Parent.Shared:WaitForChild("ClassConstructor"))
local ThreadHandler = require(script.Parent.Shared:WaitForChild("ThreadHandler"))
local Output = require(script.Parent.Shared:WaitForChild("Output"))
local CollisionGroups = require(script.Parent.Shared:WaitForChild("CollisionGroups"))

---# SERVICES #---
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

---# VARIABLES #---
local Started = false

local Types = require(script.Parent.Types)
local FastTime = os.clock()
local HalfTime = os.clock()
local SecondTime = os.clock()
local MinuteTime = os.clock()

local PackagesToIgnore = {
	"ExxoFrame"
}

local ExxoFrame = {
	GameVersion = game.PlaceVersion,
	LocalPlayer = Players.LocalPlayer,

	Client = {},
	Server = {},

	Signal = Signal,
	BridgeNet2 = BridgeNet2,
	Replica = Replica,
	Promise = Promise,
	ClassConstructor = ClassConstructor,
	ThreadHandler = ThreadHandler,
	Output = Output,
	CollisionGroups = CollisionGroups,

	FastLoop = Signal.new(),
	HalfLoop = Signal.new(),
	SecondLoop = Signal.new(),
	MinuteLoop = Signal.new(),

	CharacterAdded = Signal.new(),
	CharacterRemoved = Signal.new(),

	Shared = {},
	PetsByMap = {},
	Services = {},
	UserFrames = {},
	Animations = {},
	Utils = {},
	Data = nil,

	ServerShutdown = false,

	Cache = {
		Pets = {},
		Mobs = {},
		Drops = {},
	}
}

---# SCRIPT #---
local function LoadDependencies()
	print("Loading Dependencies")

	local UtilsFolder = ReplicatedStorage:FindFirstChild("Utils")
	ExxoFrame.Output.WarnAssert(not UtilsFolder,("Couldn't find Utils folder, did you forget to create it?"))

	if UtilsFolder then
		for _,Utility in UtilsFolder:GetChildren() do
			if Utility:IsA("ModuleScript") then
				local UtilityScript = require(Utility)
				ExxoFrame.Utils[Utility.Name] = UtilityScript
			end
		end
	end

	local PackagesFolder = ReplicatedStorage:FindFirstChild("Packages")
	ExxoFrame.Output.WarnAssert(not PackagesFolder,("Couldn't find Packages folder, did you forget to create it?"))

	if PackagesFolder then
		for _,Package in PackagesFolder:GetChildren() do
			if Package:IsA("ModuleScript") and not table.find(PackagesToIgnore, Package.Name) then
				local PackageScript = require(Package)
				ExxoFrame[Package.Name] = PackageScript

				if PackageScript.Init then
					PackageScript:Init()
				end
			end
		end	
	end

	-- ExxoFrame.SmoothShiftLock = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("SmoothShiftLock"))
end

local function LoadShared()
	local SharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	ExxoFrame.Output.WarnAssert(not SharedFolder,("Couldn't find Shared folder, did you forget to create it?"))

	if not SharedFolder then return end
	for _,SharedModule in SharedFolder:GetChildren() do
		ExxoFrame.Output.ErrorAssert(not SharedModule:IsA("ModuleScript"),("%* is not a Module Script!"):format(SharedModule.Name))
		ExxoFrame.Output.ErrorAssert(ExxoFrame.Shared[SharedModule.Name],("This module already exists, %*"):format(SharedModule.Name))

		if SharedModule:IsA("ModuleScript") then
			local ModuleScript = require(SharedModule)
			ExxoFrame.Shared[SharedModule.Name] = ModuleScript
			if ModuleScript and ModuleScript.Init then
				ModuleScript:Init()
			end
		end
	end
end

local function LoadServices()

	local ServicesFolder = StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("Services")
	ExxoFrame.Output.WarnAssert(not ServicesFolder,("Couldn't find Services folder, did you forget to create it?"))

	if not ServicesFolder then return end
	for _,Services in StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("Services"):GetChildren() do
		ExxoFrame.Output.ErrorAssert(not Services:IsA("ModuleScript"),("%* is not a Module Script!"):format(Services.Name))
		ExxoFrame.Output.ErrorAssert(ExxoFrame.Services[Services.Name],("This module already exists, %*"):format(Services.Name))

		local ModuleScript = require(Services)
		ExxoFrame.Services[Services.Name] = ModuleScript

		if not ModuleScript.NoBridge then
			local RefBridge = ExxoFrame.BridgeNet2.ReferenceBridge(Services.Name)

			local FunctionNameID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionName")
			local FunctionContentID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionContent")
		
			RefBridge:Connect(function(Content)
				ExxoFrame.Output.ErrorAssert(not Content[FunctionNameID],"Didn't got function name!")
				ExxoFrame.Output.ErrorAssert(not ExxoFrame.Services[Services.Name][Content[FunctionNameID]],("%* function doesn't exist inside %*!"):format(Content[FunctionNameID],Services.Name))
		
				return ExxoFrame.Promise.try(function()
					ExxoFrame.Services[Services.Name][Content[FunctionNameID]](table.unpack(Content[FunctionContentID]))
				end)
			end)
		end

		if ModuleScript.Init then
			ModuleScript:Init()
		end
	end
end

function ExxoFrame:Init()
	if Started then
		self.Output.Error("ExxoFrame Already Started!")
		return self.Promise.reject("ExxoFrame Already Started!")
	end
	
	Started = true
	
	repeat
		task.wait(0.1)
	until
	Workspace:GetAttribute("ServerLoaded") == true

	self.StartTime = os.clock()
	
	self.Replica.OnNew("PlayerData", function(NewReplica)
		
		self.Data = NewReplica.Data
		self.PlayerReplica = NewReplica
	end)

	self.Replica.OnNew("ExistingStuff", function(NewReplica)

		self.ExistingData = NewReplica.Data
		self.ExistingReplica = NewReplica
	end)
	
	self.Replica.RequestData()

	repeat 
		task.wait() 
	until 
		self.Data ~= nil

	LoadDependencies()
	LoadShared()
	LoadServices()

	self.PlayerGui = self.LocalPlayer:WaitForChild("PlayerGui")
	self.MainUI = self.PlayerGui:WaitForChild("MainUI")
	self.MainFrames = self.MainUI:WaitForChild("MainFrames")
	self.Inset = self.PlayerGui:WaitForChild("Inset")
	self.HUD = self.PlayerGui:WaitForChild("HUD")

	for _,CoreScript in StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("Cores"):GetChildren() do
		self.Output.ErrorAssert(not CoreScript:IsA("ModuleScript"),("%* is not a Module Script!"):format(CoreScript.Name))
		self.Output.ErrorAssert(self[CoreScript.Name],("This module already exists, %*"):format(CoreScript.Name))
		
		local ModuleScript = require(CoreScript)
		self[CoreScript.Name] = ModuleScript

		if ModuleScript.Init then
			ModuleScript:Init()
		end
	end
end

function ExxoFrame.Client:FireSelf(ModuleName : string, FunctionName : string, ...: any?)
	ExxoFrame.Output.ErrorAssert(not ModuleName,"No module name given!")
	ExxoFrame.Output.ErrorAssert(not FunctionName,"No module name given!")

	ExxoFrame.Output.ErrorAssert(typeof(ModuleName) ~= "string","The given module name is not a string.")
	ExxoFrame.Output.ErrorAssert(typeof(FunctionName) ~= "string","The given function name is not a string.")

	local ModuleScript = ExxoFrame.Services[ModuleName]
	ExxoFrame.Output.ErrorAssert(not ModuleScript,("The %* Module Script was not found!"):format(ModuleName))

	local FunctionTable = ModuleScript[FunctionName]
	ExxoFrame.Output.ErrorAssert(not FunctionTable,("Couldn't find this %* function inside %* module script!"):format(FunctionName,ModuleName))
	ExxoFrame.Output.ErrorAssert(not FunctionTable,("Couldn't find this %* function inside %* module script!"):format(FunctionName,ModuleName))
	
	ExxoFrame.ThreadHandler(FunctionTable,...)
end

function ExxoFrame.Server:Fire(ModuleName : string, FunctionName : string, ...: any?)
	local RefBridge = ExxoFrame.BridgeNet2.ReferenceBridge(ModuleName)

	local FunctionNameID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionName")
	local FunctionContentID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionContent")

	local ContentPacked = table.pack(...)

	RefBridge:Fire({
		[FunctionNameID] = FunctionName,
		[FunctionContentID] = ContentPacked,
	})

	RefBridge = nil
	FunctionNameID = nil
	FunctionContentID = nil
end


---# UTILITIES #---
function ExxoFrame:GetDevice()
	local Device = nil

	if UserInputService.GamepadEnabled then
		Device = 'CONSOLE'
	elseif UserInputService.KeyboardEnabled then
		Device = 'PC'
	elseif UserInputService.TouchEnabled then
		Device = 'MOBILE'
	end

	return Device
end

function ExxoFrame:GetMouse()
	return self.LocalPlayer:GetMouse()
end

function ExxoFrame:GetCharacter()
	return self.LocalPlayer.Character or self.LocalPlayer.CharacterAdded:Wait()
end

function ExxoFrame:IsPremium()
	if self.LocalPlayer.MembershipType == Enum.MembershipType.Premium then
		return true
	else
		return false
	end
end

function ExxoFrame:LoadAnimations()
	local Character = self:GetCharacter()

	local StartTime = os.time()
	local Timeout = 10
	while not Character do
		Character = self:GetCharacter()

		if (os.time() - StartTime) >= Timeout then
			break
		end

		task.wait(0.1)
	end

	if not Character then
		warn("No character")
		return
	end

	local Humanoid = Character:WaitForChild("Humanoid")

	if not Humanoid:FindFirstChild("Animator") then
		local Animator = Instance.new("Animator")
		Animator.Parent = Humanoid
	end
end



---# CONNECTIONS #---
ExxoFrame.LocalPlayer.CharacterAdded:Connect(function(Character)
	local Char = ExxoFrame:GetCharacter()

	local StartTime = os.time()
	local Timeout = 10
	while not Char do
		Char = ExxoFrame:GetCharacter()

		if (os.time() - StartTime) >= Timeout then
			break
		end

		task.wait(0.1)
	end

	if not Char then
		warn(("[ExxoFrame] Not able to load %s's character!"):format(ExxoFrame.LocalPlayer.Name)) 
		return
	end
	
	ExxoFrame:LoadAnimations()
	ExxoFrame.CharacterAdded:Fire(Character)
end)

---# LOOPS #---

RunService.PreRender:Connect(function()
	if (os.clock() - FastTime) >= task.wait() then
		FastTime = os.clock()
		ExxoFrame.FastLoop:Fire()
	end
	if (os.clock() - HalfTime) >= 0.5 then
		HalfTime = os.clock()
		ExxoFrame.HalfLoop:Fire()
	end
	if (os.clock() - SecondTime) >= 1 then
		SecondTime = os.clock()
		ExxoFrame.SecondLoop:Fire()
	end
	if (os.clock() - MinuteTime) >= 60 then
		MinuteTime = os.clock()
		ExxoFrame.MinuteLoop:Fire()
	end
end)

return (ExxoFrame :: {}) :: Types.ExxoFrame