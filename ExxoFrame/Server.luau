--!native
--!optimize 2

---# MODULES #---
local GoodSignal = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("GoodSignal"))

---# VARIABLES #---
local Started = false

local Types = require(script.Parent.Types)
local FastTime = os.clock()
local HalfTime = os.clock()
local SecondTime = os.clock()
local MinuteTime = os.clock()

local ExxoFrame = {
	GameVersion = game.PlaceVersion,

	Client = {},
	Server = {},

	FastLoop = GoodSignal.new(),
	HalfLoop = GoodSignal.new(),
	SecondLoop = GoodSignal.new(),
	MinuteLoop = GoodSignal.new(),

	ReferenceModules = {},
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
	ExxoFrame.Player = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("PlayerUtil"))
	ExxoFrame.Instance = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("InstanceUtil"))
	ExxoFrame.Frame = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("FrameUtil"))
	ExxoFrame.Number = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("NumberUtil"))
	ExxoFrame.Table = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("TableUtil"))
	ExxoFrame.CollisionGroups = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("CollisionGroups"))
	ExxoFrame.Colors = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("Colors"))
	ExxoFrame.GlobalSettings = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("GlobalSettings"))
	ExxoFrame.Output = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("Output"))
	ExxoFrame.Pets = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("PetsUtil"))
	ExxoFrame.ThreadHandler = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("ThreadHandler"))
	ExxoFrame.BridgeNet2 = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("BridgeNet2"))
	ExxoFrame.Promise = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Promise"))
	ExxoFrame.GoodSignal = GoodSignal
	ExxoFrame.Replica = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Replica"):WaitForChild("Server"))
	ExxoFrame.PlayersCache = require(game:GetService("ServerScriptService"):WaitForChild("Core"):WaitForChild("NewPlayer"):WaitForChild("PlayerCache"))
	ExxoFrame.Sound = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("SoundUtil"))
end

function ExxoFrame:Init()

	if Started then
		self.Output.Error("ExxoFrame Already Started!",1)
		return ExxoFrame.Promise.reject("ExxoFrame Already Started!")
	end

	Started = true
	ExxoFrame.StartTime = os.clock()
	
	LoadDependencies()

	for _,ReferenceModule in game:GetService("ReplicatedStorage"):WaitForChild("ReferenceModules"):GetChildren() do
		self.Output.ErrorAssert(not ReferenceModule:IsA("ModuleScript"),("%* is not a Module Script!"):format(ReferenceModule.Name))
		self.Output.ErrorAssert(self.ReferenceModules[ReferenceModule.Name],("This module already exists, %*"):format(ReferenceModule.Name))

		local ModuleScript = require(ReferenceModule)
		self.ReferenceModules[ReferenceModule.Name] = ModuleScript
		if ModuleScript and ModuleScript.Init then
			ModuleScript:Init()
		end
	end

	for _,CoreScript in game:GetService("ServerScriptService"):WaitForChild("Core"):GetChildren() do
		self.Output.ErrorAssert(not CoreScript:IsA("ModuleScript"),("%* is not a Module Script!"):format(CoreScript.Name))
		self.Output.ErrorAssert(self[CoreScript.Name],("This module already exists, %*"):format(CoreScript.Name))

		local ModuleScript = require(CoreScript)
		self[CoreScript.Name] = ModuleScript

		if ModuleScript and ModuleScript.Init then
			ModuleScript:Init()
		end
	end
	
	for _,Service in game:GetService("ServerScriptService"):WaitForChild("Services"):GetChildren() do
		self.Output.ErrorAssert(not Service:IsA("ModuleScript"),("%* is not a Module Script!"):format(Service.Name))
		self.Output.ErrorAssert(self.Services[Service.Name],("This module already exists, %*"):format(Service.Name))

		local ModuleScript = require(Service)
		self.Services[Service.Name] = ModuleScript

		if not ModuleScript.NoBridge then
			local RefBridge = ExxoFrame.BridgeNet2.ReferenceBridge(Service.Name)

			local FunctionNameID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionName")
			local FunctionContentID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionContent")
		
			RefBridge:Connect(function(Player, Content)
				ExxoFrame.Output.ErrorAssert(not Content[FunctionNameID],"Didn't got function name!")
				ExxoFrame.Output.ErrorAssert(not self.Services[Service.Name][Content[FunctionNameID]],("%* function doesn't exist inside %*!"):format(Content[FunctionNameID],Service.Name))
		
				if self.Services[Service.Name][Content[FunctionNameID]].Cooldown then
					if not self.Services[Service.Name][Content[FunctionNameID]].Debounces then
						self.Services[Service.Name][Content[FunctionNameID]].Debounces = {}
					end
		
					if self.Services[Service.Name][Content[FunctionNameID]].Debounces[Player.UserId] then return end
					self.Services[Service.Name][Content[FunctionNameID]].Debounces[Player.UserId] = true
		
					task.delay(self.Services[Service.Name][Content[FunctionNameID]].Cooldown, function()
						self.Services[Service.Name][Content[FunctionNameID]].Debounces[Player.UserId] = nil
					end)
				end

				local ExxoPlayer = ExxoFrame.NewPlayer:GetPlayer(Player)
		
				return ExxoFrame.Promise.try(function(resolve,reject)
					self.Services[Service.Name][Content[FunctionNameID]].Trigger(ExxoPlayer,table.unpack(Content[FunctionContentID]))
				end)
			end)
		end
		
		if ModuleScript and ModuleScript.Init then
			ModuleScript:Init()
		end
	end
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
game:GetService("RunService").PreSimulation:Connect(function()
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