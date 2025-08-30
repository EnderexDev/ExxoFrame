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
local PlayersCache = require(script.Parent.ServerCore:WaitForChild("NewPlayer"):WaitForChild("PlayerCache"))
local Output = require(script.Parent.Shared:WaitForChild("Output"))
local CollisionGroups = require(script.Parent.Shared:WaitForChild("CollisionGroups"))

---# SERVICES #---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

---# VARIABLES #---
local Started = false

local Types = require(script.Parent.Types)
local FastTime = os.clock()
local HalfTime = os.clock()
local SecondTime = os.clock()
local MinuteTime = os.clock()

local PackagesToIgnore = {
	"TopBarPlus",
	"WindLines",
	"WindShake",
	"ExxoFrame",
}

local ExxoFrame = {
	GameVersion = game.PlaceVersion,

	Client = {},
	Server = {},

	Signal = Signal,
	BridgeNet2 = BridgeNet2,
	Replica = Replica,
	Promise = Promise,
	ClassConstructor = ClassConstructor,
	ThreadHandler = ThreadHandler,
	PlayersCache = PlayersCache,
	Output = Output,
	CollisionGroups = CollisionGroups,

	FastLoop = Signal.new(),
	HalfLoop = Signal.new(),
	SecondLoop = Signal.new(),
	MinuteLoop = Signal.new(),

	Utils = {},
	Shared = {},
	PetsByMap = {},
	Services = {},
	Leaderboards = {},

	Cache = {
		Gift = {},
		Mobs = {},
		Drops = {},
	},

	Modes = {},
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
			end
		end	
	end
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

local function LoadCore()
	local CoreFolder = script.Parent:FindFirstChild("ServerCore")
	ExxoFrame.Output.WarnAssert(not CoreFolder,("Couldn't find ServerCore folder, did you forget to create it?"))

	if not CoreFolder then return end

	for _,CoreScript in script.Parent:WaitForChild("ServerCore"):GetChildren() do
		ExxoFrame.Output.ErrorAssert(not CoreScript:IsA("ModuleScript"),("%* is not a Module Script!"):format(CoreScript.Name))
		ExxoFrame.Output.ErrorAssert(ExxoFrame[CoreScript.Name],("This module already exists, %*"):format(CoreScript.Name))

		local ModuleScript = require(CoreScript)
		ExxoFrame[CoreScript.Name] = ModuleScript

		if ModuleScript and ModuleScript.Init then
			ModuleScript:Init()
		end
	end
end

local function LoadServices()
	local ServicesFolder = ServerScriptService:FindFirstChild("Services")
	ExxoFrame.Output.WarnAssert(not ServicesFolder,("Couldn't find Services folder, did you forget to create it?"))

	if not ServicesFolder then return end

	for _,Service in ServicesFolder:GetChildren() do
		ExxoFrame.Output.ErrorAssert(not Service:IsA("ModuleScript"),("%* is not a Module Script!"):format(Service.Name))
		ExxoFrame.Output.ErrorAssert(ExxoFrame.Services[Service.Name],("This module already exists, %*"):format(Service.Name))

		local ModuleScript = require(Service)
		ExxoFrame.Services[Service.Name] = ModuleScript

		if not ModuleScript.NoBridge then
			local RefBridge = ExxoFrame.BridgeNet2.ReferenceBridge(Service.Name)

			local FunctionNameID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionName")
			local FunctionContentID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionContent")
		
			RefBridge:Connect(function(Player, Content)
				ExxoFrame.Output.ErrorAssert(not Content[FunctionNameID],"Didn't got function name!")
				ExxoFrame.Output.ErrorAssert(not ExxoFrame.Services[Service.Name][Content[FunctionNameID]],("%* function doesn't exist inside %*!"):format(Content[FunctionNameID],Service.Name))
		
				if ExxoFrame.Services[Service.Name][Content[FunctionNameID]].Cooldown then
					if not ExxoFrame.Services[Service.Name][Content[FunctionNameID]].Debounces then
						ExxoFrame.Services[Service.Name][Content[FunctionNameID]].Debounces = {}
					end
		
					if ExxoFrame.Services[Service.Name][Content[FunctionNameID]].Debounces[Player.UserId] then return end
					ExxoFrame.Services[Service.Name][Content[FunctionNameID]].Debounces[Player.UserId] = true
		
					task.delay(ExxoFrame.Services[Service.Name][Content[FunctionNameID]].Cooldown, function()
						ExxoFrame.Services[Service.Name][Content[FunctionNameID]].Debounces[Player.UserId] = nil
					end)
				end

				local ExxoPlayer = ExxoFrame.NewPlayer:GetPlayer(Player)
		
				return ExxoFrame.Promise.try(function()
					ExxoFrame.Services[Service.Name][Content[FunctionNameID]].Trigger(ExxoPlayer,table.unpack(Content[FunctionContentID]))
				end)
			end)
		end

		if ModuleScript and ModuleScript.Init then
			ModuleScript:Init()
		end
	end
end

function ExxoFrame:Init()

	if Started then
		self.Output.Error("ExxoFrame Already Started!",1)
		return ExxoFrame.Promise.reject("ExxoFrame Already Started!")
	end

	Started = true
	ExxoFrame.StartTime = os.clock()
	
	LoadDependencies()

	LoadShared()

	LoadCore()
	
	LoadServices()
end

function ExxoFrame.Server:FireSelf(ModuleName : string, FunctionName : string, ...: any?)
	ExxoFrame.Output.ErrorAssert(not ModuleName,"No module name given!")
	ExxoFrame.Output.ErrorAssert(not FunctionName,"No module name given!")

	ExxoFrame.Output.ErrorAssert(typeof(ModuleName) ~= "string","The given module name is not a string.")
	ExxoFrame.Output.ErrorAssert(typeof(FunctionName) ~= "string","The given function name is not a string.")

	local ModuleScript = ExxoFrame.Services[ModuleName]
	ExxoFrame.Output.ErrorAssert(not ModuleScript,("The %* Module Script was not found!"):format(ModuleName))

	local FunctionTable = ModuleScript[FunctionName]
	ExxoFrame.Output.ErrorAssert(not FunctionTable,("Couldn't find this %* function inside %* module script!"):format(FunctionName,ModuleName))
	ExxoFrame.Output.ErrorAssert(not FunctionTable.Trigger,("Couldn't find this %* function inside %* module script!"):format(FunctionName,ModuleName))
	
	ExxoFrame.ThreadHandler(FunctionTable.Trigger,...)
end

function ExxoFrame.Client:Fire(Player : Player,ModuleName : string, FunctionName : string, ...: any?)
	local RefBridge = ExxoFrame.BridgeNet2.ReferenceBridge(ModuleName)

	local FunctionNameID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionName")
	local FunctionContentID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionContent")

	local ContentPacked = table.pack(...)

	RefBridge:Fire(Player,{
		[FunctionNameID] = FunctionName,
		[FunctionContentID] = ContentPacked,
	})

	RefBridge = nil
	FunctionNameID = nil
	FunctionContentID = nil
end

function ExxoFrame.Client:FireAll(ModuleName : string, FunctionName : string, ...: any?)
	local RefBridge = ExxoFrame.BridgeNet2.ReferenceBridge(ModuleName)

	local FunctionNameID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionName")
	local FunctionContentID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionContent")

	local ContentPacked = table.pack(...)

	RefBridge:Fire(
		ExxoFrame.BridgeNet2.AllPlayers(),
		{
			[FunctionNameID] = FunctionName,
			[FunctionContentID] = ContentPacked,
		}
	)

	RefBridge = nil
	FunctionNameID = nil
	FunctionContentID = nil
end

function ExxoFrame.Client:FireSpecific(PlayersToFire : {},ModuleName : string, FunctionName : string, ...: any?)
	local RefBridge = ExxoFrame.BridgeNet2.ReferenceBridge(ModuleName)

	local FunctionNameID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionName")
	local FunctionContentID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionContent")

	local ContentPacked = table.pack(...)

	RefBridge:Fire(
		ExxoFrame.BridgeNet2.Players(PlayersToFire),
		{
			[FunctionNameID] = FunctionName,
			[FunctionContentID] = ContentPacked,
		}
	)

	RefBridge = nil
	FunctionNameID = nil
	FunctionContentID = nil
end

function ExxoFrame.Client:FireExcept(PlayersToNotFire : {},ModuleName : string, FunctionName : string, ...: any?)
	local RefBridge = ExxoFrame.BridgeNet2.ReferenceBridge(ModuleName)

	local FunctionNameID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionName")
	local FunctionContentID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionContent")

	local ContentPacked = table.pack(...)

	RefBridge:Fire(
		ExxoFrame.BridgeNet2.PlayersExcept(PlayersToNotFire),
		{
			[FunctionNameID] = FunctionName,
			[FunctionContentID] = ContentPacked,
		}
	)

	RefBridge = nil
	FunctionNameID = nil
	FunctionContentID = nil
end

---# CONNECTIONS #---


---# LOOPS #---
RunService.PreSimulation:Connect(function()
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