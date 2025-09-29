local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Plots = Workspace.Plots

-- Assign Plots to players on join (randomly)
game.Players.PlayerAdded:Connect(function(player)
	print("Player joined: " .. player.Name)

	local character = player.Character or player.CharacterAdded:Wait()
	local HRP = character:WaitForChild("Humanoid")

	for _, plot in pairs(Plots:GetChildren()) do
		if plot:GetAttribute("Taken") then
			continue
		end

		plot:SetAttribute("Taken", true)
		plot:SetAttribute("Owner", player.UserId)

		HRP.CFrame = plot.CFrame + CFrame.new(0, 3, 0)

		print("Assigned plot " .. plot.Name .. " to player " .. player.Name)

		plot:FindFirstChild("PlotOwner").TextLabel.Text = player.Name .. "'s Base"
		break
	end
end)

-- when player leaves, free up their plot
game.Players.PlayerRemoving:Connect(function(player)
	for _, plot in Plots:GetChildren() do
		if not plot:GetAttribute("Taken") then
			continue
		end
		if plot:GetAttribute("Owner") ~= player.UserId then
			continue
		end

		plot:SetAttribute("Taken", nil)
		plot:SetAttribute("Owner", nil)

		plot:FindFirstChild("PlotOwner").TextLabel.Text = "Unclaimed Base"
		break
	end
end)

local brainrotsModule = require(script.Parent:WaitForChild("Modules"):WaitForChild("Brainrots"))

-- Settings
local SPAWN_INTERVAL = 10
local SPAWN_COUNT = 4
local SPAWN_THRESHOLD = 40

local templateFolder = Workspace:WaitForChild("Brainrots") -- your templates
local mainTrack = Workspace:WaitForChild("MainTrack") -- your main track

-- Create ActiveBrainrots folder if it doesn't exist
local activeFolder = Workspace:FindFirstChild("ActiveBrainrots")
if not activeFolder then
	activeFolder = Instance.new("Folder")
	activeFolder.Name = "ActiveBrainrots"
	activeFolder.Parent = Workspace
end

-- Spawn loop (non-blocking)
spawn(function()
	print("[Main] Spawn loop started. Templates:", #templateFolder:GetChildren())
	while true do
		local count = #activeFolder:GetChildren()
		if count < SPAWN_THRESHOLD then
			brainrotsModule.spawnBrainrot(activeFolder, templateFolder, mainTrack, SPAWN_COUNT)
		end
		task.wait(SPAWN_INTERVAL)
	end
end)

-- lets add the spawn meachnism here
-- local BrainRots = Workspace.Brainrots
-- local mainTrack = Workspace.MainTrack

-- local SPAWN_INTERVAL = 10
-- local SPAWN_COUNT = 4
-- local SPAWN_THRESHOLD = 40

-- local activeFolder = Instance.new("Folder")
-- activeFolder.Name = "ActiveBrainrots"
-- activeFolder.Parent = workspace

-- function spawnBrainrot()
-- 	if not BrainRots or not mainTrack then
-- 		warn("Brainrot folder or main track not found!")
-- 		return
-- 	end

-- 	local templates = {}
-- 	for _, obj in BrainRots:GetChildren() do
-- 		if obj:IsA("Model") or obj:IsA("Part") then
-- 			table.insert(templates, obj)
-- 		end
-- 	end

-- 	if #templates == 0 then
-- 		warn("No brainrot templates found in folder!")
-- 		return
-- 	end

-- 	for i = 1, SPAWN_COUNT do
-- 		local template = templates[math.random(1, #templates)]
-- 		local clone = template:Clone()
-- 		-- clone.Parent = Workspace
-- 		clone.Parent = activeFolder

-- 		local size = mainTrack.Size
-- 		local pos = mainTrack.Position

-- 		local randX = pos.X + math.random(-size.X / 2, size.X / 2)
-- 		local randZ = pos.Z + math.random(-size.Z / 2, size.Z / 2)
-- 		local y = pos.Y + size.Y / 2 -- top surface height

-- 		local spawnPos = Vector3.new(randX, y, randZ)

-- 		local brainrotRandDirection = CFrame.Angles(0, math.rad(math.random(0, 359)), 0)

-- 		clone:PivotTo(CFrame.new(spawnPos) * brainrotRandDirection)
-- 	end
-- end

-- while true do
-- 	if #activeFolder:GetChildren() < SPAWN_THRESHOLD then
-- 		spawnBrainrot()
-- 	end
-- 	task.wait(SPAWN_INTERVAL)
-- end
