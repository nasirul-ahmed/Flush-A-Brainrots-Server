-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local ServerStorage = game:GetService("ServerStorage")
-- local Players = game:GetService("Players")
-- local Workspace = game:GetService("Workspace")
-- local Plots = Workspace.Plots
-- -- local mainTrack = Workspace.MiddleRoad:GetFirstChild("MainTrack")

-- local templateFolder = Workspace.Brainrots -- your templates
-- local mainTrack = Workspace.MiddleRoad.MainTrack

-- -- Load modules
-- local BrainrotCarrying = require(script.Parent:WaitForChild("Modules"):WaitForChild("BrainrotCarrying"))

-- -- Landscape mode for mobile
-- game:GetService("StarterGui").ScreenOrientation = Enum.ScreenOrientation.LandscapeRight

-- -- Initialize brainrot carrying system
-- BrainrotCarrying.Init()

-- -- Assign Plots to players on join (randomly)
-- game.Players.PlayerAdded:Connect(function(player)
-- 	print("Player joined: " .. player.Name)
-- 	player.CharacterAdded:Connect(function(character)
-- 		local HRP = character:WaitForChild("HumanoidRootPart")

-- 		for _, plot in Plots:GetChildren() do
-- 			if plot:GetAttribute("Taken") then
-- 				continue
-- 			end

-- 			plot:SetAttribute("Taken", true)
-- 			plot:SetAttribute("Owner", player.UserId)

-- 			local baseCFrame = plot:IsA("Model") and plot.PrimaryPart and plot.PrimaryPart.CFrame or plot:GetPivot()

-- 			HRP.CFrame = baseCFrame * CFrame.new(0, 3, 0)

-- 			print("Assigned plot " .. plot.Name .. " to player " .. player.Name)

-- 			-- plot:FindFirstChild("PlotOwner").TextLabel.Text = player.Name .. "'s Base"
-- 			break
-- 		end
-- 	end)

-- 	if player.Character then
-- 		local character = player.Character
-- 		local HRP = character:FindFirstChild("HumanoidRootPart")
-- 		if HRP then
-- 			-- Find available plot
-- 			for _, plot in Plots:GetChildren() do
-- 				if plot:GetAttribute("Taken") then
-- 					continue
-- 				end

-- 				plot:SetAttribute("Taken", true)
-- 				plot:SetAttribute("Owner", player.UserId)

-- 				local baseCFrame = plot:IsA("Model") and plot.PrimaryPart and plot.PrimaryPart.CFrame or plot:GetPivot()
-- 				HRP.CFrame = baseCFrame * CFrame.new(0, 3, 0)

-- 				print("Assigned plot " .. plot.Name .. " to existing player " .. player.Name)
-- 				-- plot:FindFirstChild("PlotOwner").TextLabel.Text = player.Name .. "'s Base"
-- 				break
-- 			end
-- 		end
-- 	end
-- end)

-- game.Players.PlayerRemoving:Connect(function(player)
-- 	for _, plot in Plots:GetChildren() do
-- 		if not plot:GetAttribute("Taken") then
-- 			continue
-- 		end
-- 		if plot:GetAttribute("Owner") ~= player.UserId then
-- 			continue
-- 		end

-- 		plot:SetAttribute("Taken", nil)
-- 		plot:SetAttribute("Owner", nil)

-- 		plot:FindFirstChild("PlotOwner").TextLabel.Text = "Unclaimed Base"
-- 		break
-- 	end
-- end)

-- local brainrotsModule = require(script.Parent:WaitForChild("Modules"):WaitForChild("Brainrots"))
-- local clouds = Workspace:WaitForChild("Clouds")

-- -- Settings
-- local SPAWN_INTERVAL = 10
-- local SPAWN_COUNT = 4
-- local SPAWN_THRESHOLD = 20

-- -- Create ActiveBrainrots folder if it doesn't exist
-- local activeFolder = Workspace:FindFirstChild("ActiveBrainrots")
-- if not activeFolder then
-- 	activeFolder = Instance.new("Folder")
-- 	activeFolder.Name = "ActiveBrainrots"
-- 	activeFolder.Parent = Workspace
-- end

-- -- Spawn loop (non-blocking)
-- spawn(function()
-- 	print("[Main] Spawn loop started. Templates:", #templateFolder:GetChildren())
-- 	while true do
-- 		local count = #activeFolder:GetChildren()
-- 		if count < SPAWN_THRESHOLD then
-- 			brainrotsModule.spawnBrainrot(activeFolder, templateFolder, clouds, SPAWN_COUNT, mainTrack)
-- 		end
-- 		task.wait(SPAWN_INTERVAL)
-- 	end
-- end)

-- Main server entry point
print("=== SERVER: Main Script Starting ===")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Config = require(ReplicatedStorage.Shared.BrainrotConfig)

-- Load modules
local BrainrotSpawner = require(script.Parent.Modules.Brainrot.BrainrotSpawner)
local BrainrotCarrying = require(script.Parent.Modules.Brainrot.BrainrotCarrying)
local BrainrotThrowing = require(script.Parent.Modules.Brainrot.BrainrotThrowing)
local TimerService = require(script.Parent.Modules.TimerService)

local Workspace = game:GetService("Workspace")
local mainTrack = Workspace.MiddleRoad.MainTrack

-- Initialize systems
print("=== SERVER: Initializing Systems ===")

-- Initialize brainrot systems
BrainrotCarrying.Init()
BrainrotThrowing.Init()

-- Your existing initialization code
-- Example: Initialize other systems, spawn brainrots, etc.

-- Player management example
Players.PlayerAdded:Connect(function(player)
	print("Player joined:", player.Name)

	-- Your existing player setup code
	-- Example: Assign plot, setup stats, etc.
end)

-- Setup existing players
for _, player in pairs(Players:GetPlayers()) do
	print("Setting up existing player:", player.Name)
	-- Your existing player setup code
end

-- Example: Start brainrot spawning
task.spawn(function()
	task.wait(2) -- Wait for game to initialize

	local ActiveBrainrots = workspace:FindFirstChild("ActiveBrainrots")
	if not ActiveBrainrots then
		ActiveBrainrots = Instance.new("Folder")
		ActiveBrainrots.Name = "ActiveBrainrots"
		ActiveBrainrots.Parent = workspace
	end

	local templateFolder = workspace:FindFirstChild("Brainrots")
	local clouds = workspace:FindFirstChild("Clouds")
	-- local mainTrack = workspace:FindFirstChild("MainTrack")

	if templateFolder and clouds and mainTrack then
		print("[Main] Starting brainrot spawn loop")

		-- Spawn initial brainrots
		-- BrainrotSpawner.spawnBrainrot(brainrotFolder, templateFolder, clouds, 5, mainTrack)

		-- Continuous spawning (optional)
		-- while true do
		-- 	task.wait(30) -- Spawn every 30 seconds
		-- 	BrainrotSpawner.spawnBrainrot(brainrotFolder, templateFolder, clouds, 1, mainTrack)
		-- end

		while true do
			local count = #ActiveBrainrots:GetChildren()
			if count < Config.SPAWN_THRESHOLD then
				BrainrotSpawner.spawnBrainrot(ActiveBrainrots, templateFolder, clouds, 5, mainTrack)
			end
			task.wait(Config.SPAWN_INTERVAL)
		end
	else
		warn("Missing brainrot spawn requirements!")
	end
end)

print("=== SERVER: Main Script Loaded ===")
