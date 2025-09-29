-- ReplicatedStorage/BrainrotConfig.lua
-- Central config for all brainrot types

local BrainrotConfig = {
    ["Avocadorilla"] = {
        StrengthRequired = 0,
        FlushTime = 15, -- seconds
        MoneyPerSecond = 10,
        StrengthPerSecond = 5,
        Rarity = "Basic",
    },

    ["Bombardiro Crocodilo"] = {
        StrengthRequired = 100,
        FlushTime = 18,
        MoneyPerSecond = 20,
        StrengthPerSecond = 10,
        Rarity = "Basic",
    },

    ["Brr Brr Patapim"] = {
        StrengthRequired = 250,
        FlushTime = 20,
        MoneyPerSecond = 35,
        StrengthPerSecond = 15,
        Rarity = "Basic",
    },

    ["Cappuccino Assassino"] = {
        StrengthRequired = 500,
        FlushTime = 25,
        MoneyPerSecond = 50,
        StrengthPerSecond = 25,
        Rarity = "Basic",
    },

    ["Chicleteira Bicicleteira"] = {
        StrengthRequired = 1000,
        FlushTime = 30,
        MoneyPerSecond = 75,
        StrengthPerSecond = 40,
        Rarity = "Basic",
    },

    ["Chimpanzini Bananini"] = {
        StrengthRequired = 1500,
        FlushTime = 35,
        MoneyPerSecond = 100,
        StrengthPerSecond = 50,
        Rarity = "Basic",
    },

    ["Chimpanzini Spiderini"] = {
        StrengthRequired = 2000,
        FlushTime = 40,
        MoneyPerSecond = 150,
        StrengthPerSecond = 75,
        Rarity = "Basic",
    },

    ["Cocofanto Elefanto"] = {
        StrengthRequired = 3000,
        FlushTime = 45,
        MoneyPerSecond = 200,
        StrengthPerSecond = 100,
        Rarity = "Basic",
    },

    -- Example Golden brainrots
    ["Golden Avocadorilla"] = {
        StrengthRequired = 5000,
        FlushTime = 50,
        MoneyPerSecond = 400,
        StrengthPerSecond = 200,
        Rarity = "Golden",
    },

    ["Golden Bombardiro"] = {
        StrengthRequired = 7500,
        FlushTime = 60,
        MoneyPerSecond = 600,
        StrengthPerSecond = 300,
        Rarity = "Golden",
    },
}

return BrainrotConfig
