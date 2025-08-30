--!strict
--!native
--!optimize 2

---# EXXOFRAME #---
local ExxoFrame = require(script.Parent.Parent)

---# SERVICES #---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

---# MODULES #---
local PlayerConstructor = require(script.PlayerConstructor)

---# VARIABLES #---
local Countries = {}

local RankTable = {
	["2"] = "Tester",
	["3"] = "Content Creator",
	["199"] = "Admin",
	["200"] = "StarX Team",
	["251"] = "Developer",
	["252"] = "Lead Developer",
	["253"] = "Co Owner",
	["254"] = "Owner",
	["255"] = "Owner",
}

local RankColors = {
	["2"] = Color3.fromRGB(110, 255, 110),
	["3"] = Color3.fromRGB(255, 65, 65),
	["199"] = Color3.fromRGB(247, 0, 255),
	["200"] = Color3.fromRGB(119, 212, 255),
	["251"] = Color3.fromRGB(114, 116, 255),
	["252"] = Color3.fromRGB(255, 161, 67),
	["253"] = Color3.fromRGB(255, 0, 0),
	["254"] = Color3.fromRGB(140, 0, 255),
	["255"] = Color3.fromRGB(140, 0, 255),
}

---# SCRIPT #---
local module = {}

local function CharacterAdded(NewPlayer)
	local Char = NewPlayer:GetCharacter()

	local StartTime = os.time()
	local Timeout = 10
	while not Char do
		Char = NewPlayer:GetCharacter()

		if (os.time() - StartTime) >= Timeout then
			break
		end

		task.wait(0.1)
	end

	ExxoFrame.Output.ErrorAssert(not Char,("[ExxoFrame] Not able to load %s's character!"):format(NewPlayer.Player.Name))

	local PlayerHUD = Char.HumanoidRootPart:FindFirstChild("HUD")
	if not PlayerHUD then
		PlayerHUD = ReplicatedStorage.Assets.Others.HUD:Clone()

		PlayerHUD.Parent = Char.HumanoidRootPart
	end

	PlayerHUD.Frame.Title.Text = NewPlayer.Player.Name
	PlayerHUD.Frame.TitleBG.Text = NewPlayer.Player.Name

	if RankTable[tostring(NewPlayer:GetRank(33910482))] then
		if NewPlayer.Player.UserId == 87918968 then
			PlayerHUD.Rank.Title.Text = RankTable["255"]
			PlayerHUD.Rank.TitleBG.Text = RankTable["255"]
			PlayerHUD.Rank.Title.TextColor3 = RankColors["255"]
			PlayerHUD.Rank.Visible = true
		else
			PlayerHUD.Rank.Title.Text = RankTable[tostring(NewPlayer:GetRank(33910482))]
			PlayerHUD.Rank.TitleBG.Text = RankTable[tostring(NewPlayer:GetRank(33910482))]
			PlayerHUD.Rank.Title.TextColor3 = RankColors[tostring(NewPlayer:GetRank(33910482))]
			PlayerHUD.Rank.Visible = true
		end
	end

	local GroupRole = NewPlayer:GetRole(33910482)
	NewPlayer.Player:SetAttribute("GroupRole",GroupRole)

	if NewPlayer.Data.Gamepasses["VIP"] then
		NewPlayer.Player:SetAttribute("VIP",true)
	end

	local Location = Char:GetAttribute("Location")
	if Location then
		Char:SetAttribute("Location", nil)
		Char:PivotTo(Location)
	end

	ExxoFrame.CollisionGroups:AddToCollisionGroup(Char,"Players")

	Char.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
end

function StartPlayer(Player : Player)
	local NewPlayer = PlayerConstructor(Player)
	ExxoFrame.PlayersCache[Player] = NewPlayer
	
	task.defer(function()
		pcall(function()
			local GamepassModule = require(ServerScriptService.ExxoFrame.Systems.Marketplace.Gamepasses)

			for GamepassName,GamepassData in GamepassModule do
				local GamepassID = GamepassData.ID
				ExxoFrame.Output.ErrorAssert(not GamepassID,("[ExxoFrame] No ID found for %s gamepass!"):format(GamepassName))

				if MarketplaceService:UserOwnsGamePassAsync(Player.UserId,GamepassID) then
					if not NewPlayer.Data.Gamepasses[GamepassName] then
						local GamepassInfo = ExxoFrame.ReferenceModules.Gamepasses[GamepassName]

						if GamepassInfo then
							NewPlayer.Data.Gamepasses[GamepassName] = true
							NewPlayer.Data.TotalStats["Robux Spent"] += tonumber(GamepassInfo.Price)
						end
					end
				end
			end
		end)
	end)

	NewPlayer:AddBadge(1299253214951952)

	if NewPlayer.Player.Character then
		CharacterAdded(NewPlayer)
	end

	NewPlayer.Player.CharacterAdded:Connect(function()
		CharacterAdded(NewPlayer)
	end)

	local success, code = pcall(LocalizationService.GetCountryRegionForPlayerAsync, LocalizationService, NewPlayer.Player)
	if success and code then
		NewPlayer.Player:SetAttribute("Country",Countries[code])
	end

	ExxoFrame.Server:FireSelf("Teleport","TeleportPlayer",NewPlayer,NewPlayer.Data.Map)

	ExxoFrame.PetsReplica:Set({"Pets",tostring(Player.UserId)},NewPlayer.Data.EquippedPets)
end

function EndPlayer(Player : Player)
	ExxoFrame.PlayersCache[Player] = nil
	ExxoFrame.PetsReplica:Set({"Pets",tostring(Player.UserId)},nil)
end

function module:GetPlayer(Player : Player)
	ExxoFrame.Output.ErrorAssert(not Player or typeof(Player) ~= "Instance" or not Player:IsA("Player"),("[ExxoFrame] Player type received : %s"):format(typeof(Player)))

	local ExxoPlayer = ExxoFrame.PlayersCache[Player]
	ExxoFrame.Output.ErrorAssert(not ExxoPlayer,("[ExxoFrame] Player doesn't exist, %s"):format(Player.Name))

	return ExxoPlayer
end

function module:GetAllPlayers()
	return ExxoFrame.PlayersCache
end

function module:Init()
	ExxoFrame.CollisionGroups:CreateCollisionGroup("Players")
	ExxoFrame.CollisionGroups:DisableCollisions("Players","Players")
end

---# CONNECTIONS #---
Players.PlayerAdded:Connect(function(Player)
	StartPlayer(Player)
end)

Players.PlayerRemoving:Connect(function(Player)
	EndPlayer(Player)
end)

return (module) :: typeof(module)
