--!strict
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
	LocalPlayer = game.Players.LocalPlayer,

	Client = {},
	Server = {},

	FastLoop = GoodSignal.new(),
	HalfLoop = GoodSignal.new(),
	SecondLoop = GoodSignal.new(),
	MinuteLoop = GoodSignal.new(),

	CharacterAdded = GoodSignal.new(),
	CharacterRemoved = GoodSignal.new(),

	ReferenceModules = {},
	PetsByMap = {},
	Components = {},
	UserFrames = {},
	Animations = {},
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
	ExxoFrame.Player = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("PlayerUtil"))
	ExxoFrame.Instance = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("InstanceUtil"))
	ExxoFrame.Frame = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("FrameUtil"))
	ExxoFrame.Number = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("NumberUtil"))
	ExxoFrame.Table = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("TableUtil"))
	ExxoFrame.CollisionGroups = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("CollisionGroups"))
	ExxoFrame.Colors = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("Colors"))
	ExxoFrame.GlobalSettings = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("GlobalSettings"))
	ExxoFrame.Sound = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("SoundUtil"))
	ExxoFrame.Effects = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("EffectsUtil"))
	ExxoFrame.Output = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("Output"))
	ExxoFrame.Pets = require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("PetsUtil"))
	ExxoFrame.ThreadHandler = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("ThreadHandler"))
	ExxoFrame.Promise = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Promise"))
	ExxoFrame.BridgeNet2 = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("BridgeNet2"))
	ExxoFrame.WindShake = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("WindShake"))
	ExxoFrame.WindLines = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("WindLines"))
	ExxoFrame.TopbarPlus = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("TopbarPlus"))
	ExxoFrame.GoodSignal = GoodSignal
	ExxoFrame.Replica = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Replica"):WaitForChild("Client"))
	ExxoFrame.SmoothShiftLock = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("SmoothShiftLock"))
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
	game:GetService("Workspace"):GetAttribute("ServerLoaded") == true

	self.StartTime = os.clock()
	
	LoadDependencies()
	
	self.Replica.OnNew("PlayerData", function(Replica)
		
		self.Data = Replica.Data
		self.PlayerReplica = Replica
	end)

	self.Replica.OnNew("ExistingStuff", function(Replica)
		self.ExistingData = Replica.Data
		self.ExistingReplica = Replica

		
		-- ExxoFrame.ExistingReplica:OnChange(function(Action, ChangedPath, NewValue, OldValue)
		-- 	print(Action,ChangedPath,NewValue,OldValue)
		-- end)
	end)
	
	self.Replica.RequestData()

	repeat 
		task.wait() 
	until 
		self.Data ~= nil

	self.PlayerGui = self.LocalPlayer:WaitForChild("PlayerGui")
	self.MainUI = self.PlayerGui:WaitForChild("MainUI")
	self.MainFrames = self.MainUI:WaitForChild("MainFrames")
	self.Inset = self.PlayerGui:WaitForChild("Inset")
	self.HUD = self.PlayerGui:WaitForChild("HUD")

	for _,ReferenceModule in game:GetService("ReplicatedStorage"):WaitForChild("ReferenceModules"):GetChildren() do
		self.Output.ErrorAssert(not ReferenceModule:IsA("ModuleScript"),("%* is not a Module Script!"):format(ReferenceModule.Name))
		self.Output.ErrorAssert(self.ReferenceModules[ReferenceModule.Name],("This module already exists, %*"):format(ReferenceModule.Name))

		local ModuleScript = require(ReferenceModule)
		self.ReferenceModules[ReferenceModule.Name] = ModuleScript

		if ModuleScript.Init then
			ModuleScript:Init()
		end
	end

	for _,CoreScript in game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Cores"):GetChildren() do
		self.Output.ErrorAssert(not CoreScript:IsA("ModuleScript"),("%* is not a Module Script!"):format(CoreScript.Name))
		self.Output.ErrorAssert(self[CoreScript.Name],("This module already exists, %*"):format(CoreScript.Name))
		
		local ModuleScript = require(CoreScript)
		self[CoreScript.Name] = ModuleScript

		if ModuleScript.Init then
			ModuleScript:Init()
		end
	end

	-- self.Replica.OnChange(self.PlayerReplica,function(Action, ChangedPath, _, _)
	-- 	if Action == "Set" then
	-- 		ExxoFrame.RefreshHandler:DataChanged(ChangedPath)
	-- 	end
	-- end)

	for _,Component in game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Components"):GetChildren() do
		self.Output.ErrorAssert(not Component:IsA("ModuleScript"),("%* is not a Module Script!"):format(Component.Name))
		self.Output.ErrorAssert(self.Components[Component.Name],("This module already exists, %*"):format(Component.Name))

		local ModuleScript = require(Component)
		self.Components[Component.Name] = ModuleScript

		if not ModuleScript.NoBridge then
			local RefBridge = ExxoFrame.BridgeNet2.ReferenceBridge(Component.Name)

			local FunctionNameID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionName")
			local FunctionContentID = ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionContent")
		
			RefBridge:Connect(function(Content)
				ExxoFrame.Output.ErrorAssert(not Content[FunctionNameID],"Didn't got function name!")
				ExxoFrame.Output.ErrorAssert(not self.Components[Component.Name][Content[FunctionNameID]],("%* function doesn't exist inside %*!"):format(Content[FunctionNameID],Component.Name))
		
				return ExxoFrame.Promise.try(function()
					self.Components[Component.Name][Content[FunctionNameID]](table.unpack(Content[FunctionContentID]))
				end)
			end)
		end

		if ModuleScript.Init then
			ModuleScript:Init()
		end
	end

	self.WindShake:Init({})

	self.WindLines:Init({
		Lifetime = 2,
		Speed = 8,
		SpawnRate = 18
	})

end

function ExxoFrame.Client:FireSelf(ModuleName : string, FunctionName : string, ...: any?)
	ExxoFrame.Output.ErrorAssert(not ModuleName,"No module name given!")
	ExxoFrame.Output.ErrorAssert(not FunctionName,"No module name given!")

	ExxoFrame.Output.ErrorAssert(typeof(ModuleName) ~= "string","The given module name is not a string.")
	ExxoFrame.Output.ErrorAssert(typeof(FunctionName) ~= "string","The given function name is not a string.")

	local ModuleScript = ExxoFrame.Components[ModuleName]
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

	if game:GetService("UserInputService").GamepadEnabled then
		Device = 'CONSOLE'
	elseif game:GetService("UserInputService").KeyboardEnabled then
		Device = 'PC'
	elseif game:GetService("UserInputService").TouchEnabled then
		Device = 'MOBILE'
	end

	return Device
end

function ExxoFrame:GetMouse()
	return game:GetService("Players").LocalPlayer:GetMouse()
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

game:GetService("RunService").PreRender:Connect(function()
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