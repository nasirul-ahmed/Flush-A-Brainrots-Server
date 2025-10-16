-- Main client entry point
print("=== CLIENT: LocalScript Loading ===")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Initialize ThrowInputHandler
local ThrowInputHandler = require(script.Parent.ThrowInputHandler)
ThrowInputHandler.Init()

-- Your existing client initialization code can go here
-- Example:
-- local StatsUI = require(script.Parent.StatsUI)
-- local ToiletShopUI = require(script.Parent.ToiletShopUI)

print("=== CLIENT: LocalScript Loaded ===")
