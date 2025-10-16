local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.BrainrotConfig)
local TimerService = require(script.Parent.Parent.TimerService)

local BrainrotCarrying = {}

-- Internal State
local originalShoulderC0 = {}
local carriedBrainrots = {}
local initialized = false

-- Helper Functions
local function validateShoulderJoints(character)
	if not character then
		return false
	end

	local torso = character:FindFirstChild("Torso")
	if torso then
		return torso:FindFirstChild("Left Shoulder") and torso:FindFirstChild("Right Shoulder")
	end

	local leftUpperArm = character:FindFirstChild("LeftUpperArm")
	local rightUpperArm = character:FindFirstChild("RightUpperArm")
	if leftUpperArm and rightUpperArm then
		return leftUpperArm:FindFirstChild("LeftShoulder") and rightUpperArm:FindFirstChild("RightShoulder")
	end

	return false
end

local function setupCharacter(player, character)
	task.wait(1)

	local humanoid = character:WaitForChild("Humanoid", 10)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)

	if not (humanoid and humanoidRootPart) then
		warn("Failed to setup character for", player.Name)
		return
	end

	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		character:WaitForChild("LeftUpperArm", 1)
		character:WaitForChild("RightUpperArm", 1)
		task.wait(1)
	end

	task.wait(1)

	if not validateShoulderJoints(character) then
		warn("Character", player.Name, "missing shoulder joints")
		return
	end

	print("Character setup complete for", player.Name)
end

-- Timer Management
local function pauseBrainrotTimer(brainrot)
	pcall(function()
		TimerService:pauseTimer(brainrot)
		print("Paused timer for brainrot:", brainrot.Name)
	end)
end

local function resumeBrainrotTimer(brainrot)
	pcall(function()
		TimerService:resumeTimer(brainrot, function(br)
			local BrainrotWormhole = require(script.Parent.BrainrotWormhole)
			if BrainrotWormhole.createAndRemove then
				BrainrotWormhole.createAndRemove(br, Workspace.MiddleRoad.MainTrack)
			end
		end)
		print("Resumed timer for brainrot:", brainrot.Name)
	end)
end

-- Proximity Prompt Management
local function hideCarryPromptsForPlayer(player)
	local activeBrainrots = workspace:FindFirstChild(Config.ACTIVE_BRAINROTS_FOLDER)
	if not activeBrainrots then
		return
	end

	for _, brainrot in pairs(activeBrainrots:GetChildren()) do
		if brainrot:IsA("Model") then
			local primaryPart = brainrot.PrimaryPart or brainrot:FindFirstChildOfClass("BasePart")
			if primaryPart then
				local carryPrompt = primaryPart:FindFirstChild("ProximityCarry")
				if carryPrompt then
					carryPrompt.Enabled = false
				end
			end
		end
	end
end

local function showCarryPromptsForPlayer(player)
	local activeBrainrots = workspace:FindFirstChild(Config.ACTIVE_BRAINROTS_FOLDER)
	if not activeBrainrots then
		return
	end

	for _, brainrot in pairs(activeBrainrots:GetChildren()) do
		if brainrot:IsA("Model") then
			local primaryPart = brainrot.PrimaryPart or brainrot:FindFirstChildOfClass("BasePart")
			if primaryPart then
				local carryPrompt = primaryPart:FindFirstChild("ProximityCarry")
				if carryPrompt then
					carryPrompt.Enabled = true
				end
			end
		end
	end
end

-- Arm Manipulation
function BrainrotCarrying.RaiseHands(player, degrees)
	local character = player.Character
	if not character then
		return false
	end

	-- local humanoid = character:FindFirstChild("Humanoid")

	-- -- For R15, skip arm raising to preserve animations
	-- if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
	-- 	return true
	-- end

	-- R6 arm raising
	local torso = character:FindFirstChild("Torso")
	if torso then
		local leftShoulder = torso:FindFirstChild("Left Shoulder")
		local rightShoulder = torso:FindFirstChild("Right Shoulder")

		if leftShoulder and rightShoulder then
			local angleRadians = math.rad(degrees)

			if not originalShoulderC0[leftShoulder] then
				originalShoulderC0[leftShoulder] = leftShoulder.C0
			end
			if not originalShoulderC0[rightShoulder] then
				originalShoulderC0[rightShoulder] = rightShoulder.C0
			end

			leftShoulder.C0 = originalShoulderC0[leftShoulder] * CFrame.Angles(0, 0, angleRadians)
			rightShoulder.C0 = originalShoulderC0[rightShoulder] * CFrame.Angles(0, 0, -angleRadians)

			return true
		end
	end
	-- Try R15 - shoulders are in the arm parts!
	local leftUpperArm = character:FindFirstChild("LeftUpperArm")
	local rightUpperArm = character:FindFirstChild("RightUpperArm")

	if leftUpperArm and rightUpperArm then
		local leftShoulder = leftUpperArm:FindFirstChild("LeftShoulder")
		local rightShoulder = rightUpperArm:FindFirstChild("RightShoulder")

		if leftShoulder and rightShoulder then
			local angleRadians = math.rad(degrees)
			print("Raising R15 arms by", degrees, "degrees (", angleRadians, "radians ) for", player.Name)

			-- Store originals in our table (not as properties)
			if not originalShoulderC0[leftShoulder] then
				originalShoulderC0[leftShoulder] = leftShoulder.C0
			end
			if not originalShoulderC0[rightShoulder] then
				originalShoulderC0[rightShoulder] = rightShoulder.C0
			end

			-- R15: X-axis rotation but POSITIVE direction for upward movement
			leftShoulder.C0 = originalShoulderC0[leftShoulder] * CFrame.Angles(angleRadians, 0, 0)
			rightShoulder.C0 = originalShoulderC0[rightShoulder] * CFrame.Angles(angleRadians, 0, 0)

			print("Raised R15 arms upward for", player.Name)
			return true
		end
	end

	return false
end

function BrainrotCarrying.RestoreHands(player)
	local character = player.Character
	if not character then
		return
	end

	-- local humanoid = character:FindFirstChild("Humanoid")

	-- if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
	-- 	return
	-- end

	local torso = character:FindFirstChild("Torso")
	if torso then
		local leftShoulder = torso:FindFirstChild("Left Shoulder")
		local rightShoulder = torso:FindFirstChild("Right Shoulder")

		if leftShoulder and originalShoulderC0[leftShoulder] then
			leftShoulder.C0 = originalShoulderC0[leftShoulder]
			originalShoulderC0[leftShoulder] = nil
		end

		if rightShoulder and originalShoulderC0[rightShoulder] then
			rightShoulder.C0 = originalShoulderC0[rightShoulder]
			originalShoulderC0[rightShoulder] = nil
		end
	end

	local leftUpperArm = character:FindFirstChild("LeftUpperArm")
	local rightUpperArm = character:FindFirstChild("RightUpperArm")

	if leftUpperArm and rightUpperArm then
		local leftShoulder = leftUpperArm:FindFirstChild("LeftShoulder")
		local rightShoulder = rightUpperArm:FindFirstChild("RightShoulder")

		if leftShoulder and originalShoulderC0[leftShoulder] then
			leftShoulder.C0 = originalShoulderC0[leftShoulder]
			originalShoulderC0[leftShoulder] = nil -- Clean up
		end

		if rightShoulder and originalShoulderC0[rightShoulder] then
			rightShoulder.C0 = originalShoulderC0[rightShoulder]
			originalShoulderC0[rightShoulder] = nil -- Clean up
		end
	end
end

-- Attachment System
function BrainrotCarrying.AttachBrainrot(player, brainrotPart)
	local character = player.Character
	if not character then
		return false
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")

	if not (humanoidRootPart and humanoid) then
		return false
	end
	if not brainrotPart:IsA("BasePart") then
		return false
	end

	local handHeight = Config.HAND_HEIGHT_R6
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		handHeight = Config.HAND_HEIGHT_R15
	end

	local carryOffset = CFrame.new(0, handHeight, Config.CARRY_FORWARD_OFFSET)

	local joint = Instance.new("Motor6D")
	joint.Name = "BrainrotJoint"
	joint.Part0 = humanoidRootPart
	joint.Part1 = brainrotPart
	joint.C0 = carryOffset
	joint.Parent = humanoidRootPart

	local parentModel = brainrotPart.Parent
	local originalCanCollideStates = {}
	local originalAnchoredStates = {}

	if parentModel and parentModel:IsA("Model") then
		for _, part in pairs(parentModel:GetDescendants()) do
			if part:IsA("BasePart") then
				originalCanCollideStates[part] = part.CanCollide
				originalAnchoredStates[part] = part.Anchored
				part.CanCollide = false
				part.Anchored = false
			end
		end
	else
		originalCanCollideStates[brainrotPart] = brainrotPart.CanCollide
		originalAnchoredStates[brainrotPart] = brainrotPart.Anchored
		brainrotPart.CanCollide = false
		brainrotPart.Anchored = false
	end

	carriedBrainrots[player] = {
		brainrot = brainrotPart,
		joint = joint,
		parentModel = parentModel,
		originalCanCollideStates = originalCanCollideStates,
		originalAnchoredStates = originalAnchoredStates,
	}

	return true
end

-- Public API
function BrainrotCarrying.CarryBrainrot(player, brainrotPart)
	if carriedBrainrots[player] then
		return false
	end

	if BrainrotCarrying.RaiseHands(player, Config.ARM_RAISE_DEGREES) then
		if BrainrotCarrying.AttachBrainrot(player, brainrotPart) then
			print(player.Name, "is now carrying a brainrot")

			local parentModel = brainrotPart.Parent
			if parentModel and parentModel:IsA("Model") then
				pauseBrainrotTimer(parentModel)
			else
				pauseBrainrotTimer(brainrotPart)
			end

			hideCarryPromptsForPlayer(player)

			-- -- Create throw prompt on the carried brainrot
			-- local throwPrompt = Instance.new("ProximityPrompt")
			-- throwPrompt.Name = "ProximityThrow"
			-- throwPrompt.ActionText = "Throw Brainrot (Hold Q)"
			-- throwPrompt.KeyboardKeyCode = Config.THROW_KEY
			-- throwPrompt.HoldDuration = 0
			-- throwPrompt.MaxActivationDistance = 10
			-- throwPrompt.Parent = brainrotPart

			-- throwPrompt.Triggered:Connect(function(p)
			-- 	if p == player then
			-- 		BrainrotThrowing.ExecuteThrow(player)
			-- 	end
			-- end)
			return true
		else
			BrainrotCarrying.RestoreHands(player)
		end
	end

	return false
end

function BrainrotCarrying.DropBrainrot(player)
	local carryData = carriedBrainrots[player]
	if not carryData then
		return
	end

	local brainrotPart = carryData.brainrot
	local parentModel = carryData.parentModel

	if parentModel and parentModel:IsA("Model") then
		resumeBrainrotTimer(parentModel)
	else
		resumeBrainrotTimer(brainrotPart)
	end

	if carryData.originalCanCollideStates then
		for part, originalState in pairs(carryData.originalCanCollideStates) do
			if part and part.Parent then
				part.CanCollide = originalState
			end
		end
	end

	if carryData.originalAnchoredStates then
		for part, originalState in pairs(carryData.originalAnchoredStates) do
			if part and part.Parent then
				part.Anchored = originalState
			end
		end
	end

	if carryData.joint then
		carryData.joint:Destroy()
	end

	BrainrotCarrying.RestoreHands(player)
	carriedBrainrots[player] = nil
	showCarryPromptsForPlayer(player)
end

function BrainrotCarrying.SetupBrainrot(brainrot)
	local partToAttachTo

	if brainrot:IsA("Model") then
		partToAttachTo = brainrot.PrimaryPart or brainrot:FindFirstChildOfClass("BasePart")
		if not partToAttachTo then
			return false
		end
	elseif brainrot:IsA("BasePart") then
		partToAttachTo = brainrot
	else
		return false
	end

	if partToAttachTo:FindFirstChild("ProximityCarry") then
		return true
	end

	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.Name = "ProximityCarry"
	proximityPrompt.ActionText = "Pick Up"
	proximityPrompt.KeyboardKeyCode = Config.PICKUP_KEY
	proximityPrompt.HoldDuration = 0.5
	proximityPrompt.MaxActivationDistance = 10
	proximityPrompt.Parent = partToAttachTo

	proximityPrompt.Triggered:Connect(function(player)
		if carriedBrainrots[player] then
			return
		end
		BrainrotCarrying.CarryBrainrot(player, partToAttachTo)
	end)

	return true
end

function BrainrotCarrying.IsCarrying(player)
	return carriedBrainrots[player] ~= nil
end

function BrainrotCarrying.GetCarriedBrainrot(player)
	local carryData = carriedBrainrots[player]
	return carryData and carryData.brainrot or nil
end

function BrainrotCarrying.GetCarryData(player)
	return carriedBrainrots[player]
end

function BrainrotCarrying.OnBrainrotTimeout(brainrot)
	for player, carryData in pairs(carriedBrainrots) do
		if carryData and carryData.brainrot == brainrot then
			BrainrotCarrying.DropBrainrot(player)
			break
		end
	end
end

function BrainrotCarrying.SetupPlayer(player)
	print("Setting up BrainrotCarrying for player:", player.Name)
	carriedBrainrots[player] = nil

	task.delay(0.5, function()
		showCarryPromptsForPlayer(player)
	end)
end

function BrainrotCarrying.CleanupPlayer(player)
	print("Cleaning up BrainrotCarrying for player:", player.Name)

	if carriedBrainrots[player] then
		BrainrotCarrying.DropBrainrot(player)
	end

	carriedBrainrots[player] = nil
end

function BrainrotCarrying.Init()
	if initialized then
		return
	end
	initialized = true

	print("BrainrotCarrying system initialized!")

	Players.PlayerAdded:Connect(function(player)
		BrainrotCarrying.SetupPlayer(player)
		player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character)
		end)
	end)

	for _, player in pairs(Players:GetPlayers()) do
		BrainrotCarrying.SetupPlayer(player)
		if player.Character then
			task.spawn(function()
				setupCharacter(player, player.Character)
			end)
		end
		player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character)
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		BrainrotCarrying.CleanupPlayer(player)
	end)
end

return BrainrotCarrying
