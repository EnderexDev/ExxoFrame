local ExxoFrame = {
	
	---# CURRENCIES #---
	Power = 0,
	Stars = 0,

	---# AUTO REJOIN #---
	FP2AutoClick = false,
	AutoClick = false,
	LastPosition = {},
	AutoSummon = false,
	
	---# STATS #---
	Level = 1,
	Rank = 0,
	Rebirth = 0,
	PlayerXP = 0,
	
	Map = "Mist Village",
	
	AvatarMult = false,
	AvatarSkin = false,

	EquippedPets = {},

	Following = {},

	Vaults = {},
	MobsKilled = {},

	SummonsOpen = {},
	SummonsPity = {},

	GachaPity = {},
	
	TotalStats = {
		["Date Joined"] = os.time(),
		["Total Power"] = 0,
		["Total Stars"] = 0,
		["Total Summons"] = 0,
		["Robux Spent"] = 0,
		["Play Time"] = 0,
		["Total Kills"] = 0,
		["Total Clicks"] = 0,
		["Total Player Exp"] = 0,
		["Total Orbs"] = 0,
	},
	
	Inventory = {
		["Accessories"] = {},
		["Artefacts"] = {},
		["Avatars"] = {},
		["Items"] = {},
		["Parchments"] = {},
		["Pets"] = {},
		["Potions"] = {},
		["Weapons"] = {},

		["Maps"] = {
			["Mist Village"] = {
				["Favorite"] = false,
			},
		},
	},
		
	Achievements = {},
	
	PetIndex = {},
	
	UsedPotions = {},

	PetAutoSell = {},
	
	PetAutoLock = {
		["Mythic"] = {
			Normal = true,
			Shiny = true,
		},
		["Secret"] = {
			Normal = true,
			Shiny = true,
		},
	},
	
	PetSummonMessages = {
		["Legendary"] = {
			Normal = true,
			Shiny = true,
		},
		["Mythic"] = {
			Normal = true,
			Shiny = true,
		},
		["Secret"] = {
			Normal = true,
			Shiny = true,
		},
	},
	
	Settings = {
		SFX = true,
		Music = true,
		["My Pets"] = true,
		["Other Pets"] = false,
		Gift = false,
		["Magnet Gamepass"] = true,
		["Low Mode"] = false,
		["Dynamic Environment Effects"] = true,
		["Disable Popups"] = false,
		["Always Run"] = false,
	},

	Gamepasses = {},
	Packs = {},
	Codes = {},
}

export type Profile = typeof(ExxoFrame)

return (ExxoFrame) :: Profile