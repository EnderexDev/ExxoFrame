--!strict
--!native
--!optimize 2

---# EXXOFRAME #---
local ExxoFrame = require(script.Parent:WaitForChild("ExxoFrame"))

---# SERVICES #---
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local LocalizationService = game:GetService("LocalizationService")

---# MODULES #---
local ClassConstructor = require(ExxoFrame.ClassConstructor)
local ProfilesStorage = require(ServerStorage:WaitForChild("ProfilesStorage"))

---# VARIABLES #---
local Countries = {}
local ReplicaToken = ExxoFrame.Replica.Token("PlayerData")
local DropsReplicaToken = ExxoFrame.Replica.Token("Drops")
local PlayerExtensions = ServerScriptService:FindFirstChild("PlayerExtensions")


---# SCRIPT #---
local PlayerConstructor = ClassConstructor.class{}
PlayerConstructor.__index = PlayerConstructor

local function CheckDependencies()
	ExxoFrame.Output.WarnAssert(not PlayerExtensions,"Could't find PlayerExtensions, did you forget to create it?")
end

local function WaitData(Player : Player)
	local PlayerData

	while not PlayerData do
		PlayerData = ProfilesStorage[Player]

		task.wait(.1)
	end

	return PlayerData
end

task.defer(function()
	local success, result = pcall(function()
		return HttpService:GetAsync("http://country.io/names.json")
	end)

	if success and result then
		Countries = HttpService:JSONDecode(result)
	end
end)

function PlayerConstructor:__init(PlayerInstance)
	if not PlayerInstance or typeof(PlayerInstance) ~= 'Instance' or not PlayerInstance:IsA('Player') then 
		warn('Invalid argument: ' .. typeof(PlayerInstance)) 
		return 
	end
	
	local Profile = WaitData(PlayerInstance)
	if not Profile then 
		PlayerInstance:Kick("[ExxoFrame] Could't retrieve your data. Please rejoin!") 
		return 
	end
	
	self.Player = PlayerInstance
	self.Profile = Profile
	
	local success, code = pcall(LocalizationService.GetCountryRegionForPlayerAsync, LocalizationService, self.Player)
	if success and code then
		self.Player:SetAttribute("Country",Countries[code])
		self.Country = Countries[code]
	end

	local DataReplica = ExxoFrame.Replica.New({
		Token = ReplicaToken,
		Data = Profile.Data,
	})

	local DropsReplica = ExxoFrame.Replica.New({
		Token = DropsReplicaToken,
		Data = {Drops = {}},
	})
	
	self.Cache = {
		Drops = {},
	}
	
	self.Replica = DataReplica
	self.Data = DataReplica.Data
	self.DropsReplica = DropsReplica
	
	repeat
		task.wait()
	until
		ExxoFrame.Replica.ReadyPlayers[PlayerInstance]

	DropsReplica:Subscribe(PlayerInstance)
	DataReplica:Subscribe(PlayerInstance)

	task.defer(function()
		while task.wait(1) do
			if not ExxoFrame.PlayersCache[PlayerInstance] or not self then break end
			self.Replica:Set({"TotalStats","Play Time"},self.Data.TotalStats["Play Time"] + 1)
		end
	end)

	local LeaderstatsFolder = ExxoFrame.Instance:NewFolder("leaderstats",PlayerInstance)
	ExxoFrame.Instance:NewValue("PPC","string",ExxoFrame.Number:Abbreviate(0),LeaderstatsFolder)
	ExxoFrame.Instance:NewValue("Power","string",ExxoFrame.Number:Abbreviate(0),LeaderstatsFolder)
	ExxoFrame.Instance:NewValue("Stars","string",ExxoFrame.Number:Abbreviate(0),LeaderstatsFolder)

	ExxoFrame.Instance:NewFolder(tostring(PlayerInstance.UserId),SoundService.Debris,true)
	ExxoFrame.Instance:NewFolder(tostring(PlayerInstance.UserId),Workspace.Client.Debris.Drops, true)

	if PlayerExtensions then
		for _,Module in PlayerExtensions:GetChildren() do
			local ModuleScript = require(Module)
			
			if ModuleScript and ModuleScript.Init then
				ModuleScript:Init(self)
			end

			for Index,Func in ModuleScript do
				if Index == "Init" then continue end
				ExxoFrame.Output.ErrorAssert(self[Index],("This function already exists, %*"):format(Index))
				self[Index] = Func
			end
		end
	end

end

function PlayerConstructor:Notification(NotificationType : "Item" | "Text" , Param1 : "Text" | "Item Name" | string, Param2 : "Time" | "Item Quantity" | number,Param3 : Color3 | nil)

	ExxoFrame.Output.ErrorAssert(not NotificationType,"Didn't got any Notification Type")
	ExxoFrame.Output.ErrorAssert(not Param1,"Didn't got any Text or Item Name")
	ExxoFrame.Output.ErrorAssert(not Param2,"Didn't got any Time or Item Quantity")

	ExxoFrame.Output.ErrorAssert(typeof(NotificationType) ~= "string",("Notification Type is not a string, %s type of %s"):format(NotificationType, typeof(NotificationType)))
	ExxoFrame.Output.ErrorAssert(typeof(Param1) ~= "string",("Param1 is not a string, %s type of %s"):format(Param1, typeof(Param1)))
	ExxoFrame.Output.ErrorAssert(typeof(Param2) ~= "number",("Param2 is not a number, %s type of %s"):format(Param2, typeof(Param2)))

	self:Client("Notification","New",NotificationType,Param1,Param2,Param3)
end

function PlayerConstructor:IsInGroup(GroupID : number)
	ExxoFrame.Output.ErrorAssert(not GroupID,"No group id reveived!")

	return self.Player:IsInGroup(GroupID)
end

function PlayerConstructor:GetRole(GroupID : number)
	ExxoFrame.Output.ErrorAssert(not GroupID,"No group id reveived!")

	return self.Player:GetRoleInGroup(GroupID)
end

function PlayerConstructor:GetRank(GroupID : number)
	ExxoFrame.Output.ErrorAssert(not GroupID,"No group id reveived!")

	return self.Player:GetRankInGroup(GroupID)
end

function PlayerConstructor:FriendWith(UserID : number)
	ExxoFrame.Output.ErrorAssert(not UserID,"No user id reveived!")

	return self.Player:IsFriendWith(tonumber(UserID))
end

function PlayerConstructor:IsPremium()
	local Premium = self.Player.MembershipType

	if Premium == Enum.MembershipType.Premium  then
		return true
	else
		return false
	end
end

function PlayerConstructor:GetCharacter()
	local Char = self.Player.Character or self.Player.CharacterAdded:Wait()

	return Char
end

CheckDependencies()

return (PlayerConstructor) :: typeof(PlayerConstructor)