--!strict
--!native
--!optimize 2
---# EXXOFRAME #---
local ExxoFrame = require(script.Parent:WaitForChild("ExxoFrame"))

---# SERVICES #---
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---# MODULES #---
local DataTemplate = require(script:WaitForChild("DefaultData")) 
local ProfileStore = require(script:WaitForChild("ProfileStore"))
local Profiles = require(ServerStorage:WaitForChild("ProfilesStorage"))

---~# VARIABLES #---
local PlayersIssues = {}

local ProfileTemplate = DataTemplate

local PlayerStore = ProfileStore.New("ExxoFrameV1", ProfileTemplate)

---# SCRIPT #---
local function PlayerAdded(player)	
	local profile = PlayerStore:StartSessionAsync("P_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile ~= nil then
		profile:AddUserId(player.UserId)

		profile:Reconcile()

		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			player:Kick("[ExxoFrame] Profile session ended - Please rejoin")
		end)

		if player.Parent == Players then
			Profiles[player] = profile
		else
			profile:EndSession()
		end

		profile:MessageHandler(function(Message,Processed)
			if Message.Type == "Ban" then
				profile.Data.Banned = true

				local ExxoPlayer = ExxoFrame.PlayerConstructor:GetPlayer(player)

				if ExxoPlayer then
					ExxoPlayer:Notification("Text","[ExxoFrame] You got banned!",10,Color3.fromRGB(255, 0, 0))
				end
			elseif Message.Type == "Unban" then
				profile.Data.Banned = nil

				local ExxoPlayer = ExxoFrame.PlayerConstructor:GetPlayer(player)

				if ExxoPlayer then
					ExxoPlayer:Notification("Text","[ExxoFrame] You got unbanned!",10,Color3.fromRGB(0, 255, 225))
				end

			end

			Processed()
		end)
	else
		player:Kick()
	end
end

---# INITIALIZATION #---
for _, player in Players:GetPlayers() do
	ExxoFrame.ThreadHandler(PlayerAdded, player)
end

---# CONNECTIONS #---
Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end)

ProfileStore.OnError:Connect(function(ErrorMessage,_,ProfileKey)
	local PlayerID = string.gsub(ProfileKey,"P_","")
	if not PlayerID then return end

	local Player = Players:GetPlayerByUserId(PlayerID)
	if not Player then return end

	warn(("DataStore error - (PlayerUID:%*,Key:%*): %*"):format(PlayerID,ProfileKey,ErrorMessage))

	if not PlayersIssues[Player] then
		PlayersIssues[Player] = 1
	else
		if PlayersIssues[Player] >= 5 then
			Player:Kick("[ExxoFrame] Couldn't save your data multiple times. Rejoin please!")
		else
			PlayersIssues[Player] += 1
		end
	end
end)

ProfileStore.OnOverwrite:Connect(function(_,ProfileKey)
	local PlayerID = string.gsub(ProfileKey,"P_","")
	if not PlayerID then return end

	local Player = Players:GetPlayerByUserId(PlayerID)
	if not Player then return end

	warn(("DataStore Overwrite - (PlayerUID:%*,Key:%*)"):format(PlayerID,ProfileKey))

	if not PlayersIssues[Player] then
		PlayersIssues[Player] = 1
	else
		if PlayersIssues[Player] >= 5 then
			Player:Kick("[ExxoFrame] Couldn't save your data multiple times. Rejoin please!")
		else
			PlayersIssues[Player] += 1
		end
	end
end)

ProfileStore.OnCriticalToggle:Connect(function(IsCritical)
	if IsCritical then
		ReplicatedStorage:SetAttribute("IsCritical",true)
	else
		ReplicatedStorage:SetAttribute("IsCritical",nil)
	end

end)

return nil