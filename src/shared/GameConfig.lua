-- Game Configuration for Flush a Brainrot
-- Contains all game settings, values, and constants

local GameConfig = {}

-- Player Starting Values
GameConfig.STARTING_MONEY = 0
GameConfig.STARTING_STRENGTH = 0
GameConfig.STARTING_TOILETS = 4

-- Plot Configuration
GameConfig.PLOT_SIZE = Vector3.new(50, 1, 50) -- Size of each player plot
GameConfig.PLOT_SPACING = 10 -- Space between plots
GameConfig.PLOTS_PER_ROW = 5 -- How many plots per row

-- Toilet Types and Properties
GameConfig.TOILET_TYPES = {
	Basic = {
		Name = "Basic Toilet",
		Cost = 0,
		MoneyMultiplier = 1.0,
		StrengthMultiplier = 1.0,
		FlushTimeMultiplier = 1.0,
		Currency = "Money"
	},
	Golden = {
		Name = "Golden Toilet",
		Cost = 5000,
		MoneyMultiplier = 1.5,
		StrengthMultiplier = 1.5,
		FlushTimeMultiplier = 1.0,
		Currency = "Money"
	},
	Diamond = {
		Name = "Diamond Toilet",
		Cost = 50000,
		MoneyMultiplier = 2.5,
		StrengthMultiplier = 2.5,
		FlushTimeMultiplier = 1.0,
		Currency = "Money"
	},
	Void = {
		Name = "Void Toilet",
		Cost = 499, -- Robux price
		MoneyMultiplier = 6.0,
		StrengthMultiplier = 6.0,
		FlushTimeMultiplier = 3.0, -- 3x faster (divides flush time)
		Currency = "Robux"
	}
}

-- Brainrot Configuration (Using custom brainrot names)
GameConfig.BRAINROT_TYPES = {
	-- Basic Brainrots (progressive strength requirements)
	["Avocadorilla"] = {
		Name = "Avocadorilla",
		StrengthRequired = 0,
		MoneyPerSecond = 10,
		StrengthPerSecond = 5,
		FlushTime = 15,
		SpawnChance = 0.25,
		Type = "Basic"
	},
	["Bombardiro Crocodilo"] = {
		Name = "Bombardiro Crocodilo", 
		StrengthRequired = 100,
		MoneyPerSecond = 20,
		StrengthPerSecond = 10,
		FlushTime = 18,
		SpawnChance = 0.20,
		Type = "Basic"
	},
	["Brr Brr Patapim"] = {
		Name = "Brr Brr Patapim",
		StrengthRequired = 250,
		MoneyPerSecond = 35,
		StrengthPerSecond = 15,
		FlushTime = 20,
		SpawnChance = 0.18,
		Type = "Basic"
	},
	["Cappuccino Assassino"] = {
		Name = "Cappuccino Assassino",
		StrengthRequired = 500,
		MoneyPerSecond = 50,
		StrengthPerSecond = 25,
		FlushTime = 25,
		SpawnChance = 0.15,
		Type = "Basic"
	},
	["Chicleteira Bicicleteira"] = {
		Name = "Chicleteira Bicicleteira",
		StrengthRequired = 1000,
		MoneyPerSecond = 75,
		StrengthPerSecond = 40,
		FlushTime = 30,
		SpawnChance = 0.12,
		Type = "Basic"
	},
	["Chimpanzini Bananini"] = {
		Name = "Chimpanzini Bananini",
		StrengthRequired = 1500,
		MoneyPerSecond = 100,
		StrengthPerSecond = 50,
		FlushTime = 35,
		SpawnChance = 0.10,
		Type = "Basic"
	},
	["Chimpanzini Spiderini"] = {
		Name = "Chimpanzini Spiderini",
		StrengthRequired = 2000,
		MoneyPerSecond = 150,
		StrengthPerSecond = 75,
		FlushTime = 40,
		SpawnChance = 0.08,
		Type = "Basic"
	},
	["Cocofanto Elefanto"] = {
		Name = "Cocofanto Elefanto",
		StrengthRequired = 3000,
		MoneyPerSecond = 200,
		StrengthPerSecond = 100,
		FlushTime = 45,
		SpawnChance = 0.06,
		Type = "Basic"
	},
	
	-- Golden Brainrots (rare, high strength requirement)
	["Golden Avocadorilla"] = {
		Name = "Golden Avocadorilla",
		StrengthRequired = 5000,
		MoneyPerSecond = 400,
		StrengthPerSecond = 200,
		FlushTime = 50,
		SpawnChance = 0.04,
		Type = "Golden"
	},
	["Golden Bombardiro"] = {
		Name = "Golden Bombardiro",
		StrengthRequired = 7500,
		MoneyPerSecond = 600,
		StrengthPerSecond = 300,
		FlushTime = 60,
		SpawnChance = 0.02,
		Type = "Golden"
	}
}

-- Spawning Configuration
GameConfig.MAX_BRAINROTS_ON_MAP = 35
GameConfig.BRAINROT_SPAWN_INTERVAL = 3 -- seconds between spawns
GameConfig.BRAINROT_SPAWN_CLOUDS = 3 -- number of cloud spawn points

-- Map Configuration
GameConfig.MAP_CENTER = Vector3.new(0, 0, 0)
GameConfig.MAIN_PATH_WIDTH = 20
GameConfig.CLOUD_HEIGHT = 100
GameConfig.CLOUD_POSITIONS = {
	Vector3.new(-30, 100, 0),
	Vector3.new(0, 100, 0),
	Vector3.new(30, 100, 0)
}

-- Collector Configuration
GameConfig.COLLECTOR_TOUCH_RANGE = 5
GameConfig.COLLECTOR_COLLECTION_COOLDOWN = 1 -- seconds

-- Combat Configuration
GameConfig.SWORD_DAMAGE = 100
GameConfig.RESPAWN_TIME = 5
GameConfig.DROP_BRAINROT_ON_DEATH = true

-- Premium Features (Robux prices)
GameConfig.PREMIUM_PRICES = {
	FlushAll = 129,
	StealStrength = 59
}

-- Data Persistence
GameConfig.DATA_STORE_NAME = "FlushABrainrotData"
GameConfig.AUTO_SAVE_INTERVAL = 60 -- seconds

-- UI Configuration
GameConfig.CURRENCY_DISPLAY_FORMAT = {
	[1000] = "K",
	[1000000] = "M",
	[1000000000] = "B",
	[1000000000000] = "T"
}

-- Colors
GameConfig.COLORS = {
	Money = Color3.fromRGB(85, 170, 85),
	Strength = Color3.fromRGB(170, 85, 85),
	Basic = Color3.fromRGB(150, 150, 150),
	Golden = Color3.fromRGB(255, 215, 0),
	Diamond = Color3.fromRGB(185, 242, 255),
	Void = Color3.fromRGB(75, 0, 130)
}

-- Sound Effects
GameConfig.SOUNDS = {
	BrainrotPickup = "rbxasset://sounds/impact_generic_03.mp3",
	BrainrotDrop = "rbxasset://sounds/impact_generic_07.mp3",
	ToiletFlush = "rbxasset://sounds/water_splash.mp3",
	MoneyEarn = "rbxasset://sounds/pickup_generic_01.mp3",
	StrengthCollect = "rbxasset://sounds/ui_tap_variant_01.mp3",
	Purchase = "rbxasset://sounds/ui_tap_variant_02.mp3",
	SwordHit = "rbxasset://sounds/impact_sharp_01.mp3"
}

return GameConfig