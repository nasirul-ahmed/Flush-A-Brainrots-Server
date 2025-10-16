local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TimerService = require(script.Parent.TimerService)
local BrainrotCarrying = {}

-- Constants and configuration
local PICKUP_KEY = Enum.KeyCode.F
local THROW_KEY = Enum.KeyCode.Q -- Key for throwing
local ARM_RAISE_DEGREES = 110 -- Degrees to raise arms when carrying

-- Throwing system configuration
local MAX_THROW_POWER = 100 -- Maximum throw power (studs/second)
local MIN_THROW_POWER = 20 -- Minimum throw power
local CHARGE_TIME = 3 -- Seconds to reach max power
local THROW_ANGLE = 30 -- Launch angle in degrees

-- Hand positioning for different character types
local HAND_HEIGHT_R6 = 2.0
local HAND_HEIGHT_R15 = 5
local CARRY_FORWARD_OFFSET = -2.5

-- Internal state tracking
local originalShoulderC0 = {}
local carriedBrainrots = {}
local connections = {}
local throwingStates = {} -- [player] = {charging = bool, startTime = number, connection = RBXScriptConnection}
local initialized = false

-- Add these NEW functions after your existing validateShoulderJoints function
-- Function to hide all carry prompts for a specific player
local function hideCarryPromptsForPlayer(player)
	-- Find all brainrots in workspace
	local activeTrainrots = workspace:FindFirstChild("ActiveBrainrots")
	if not activeTrainrots then
		return
	end

	for _, brainrot in pairs(activeTrainrots:GetChildren()) do
		if brainrot:IsA("Model") then
			local primaryPart = brainrot.PrimaryPart or brainrot:FindFirstChildOfClass("BasePart")
			if primaryPart then
				local carryPrompt = primaryPart:FindFirstChild("ProximityCarry")
				if carryPrompt then
					-- Store original visibility state if not already stored
					if not carryPrompt:GetAttribute("OriginalEnabled_" .. player.Name) then
						carryPrompt:SetAttribute("OriginalEnabled_" .. player.Name, carryPrompt.Enabled)
					end

					-- Hide the prompt for this player
					carryPrompt.Enabled = false
					print("Hid carry prompt for", brainrot.Name, "from player", player.Name)
				end
			end
		end
	end
end

-- Function to show all carry prompts for a specific player
local function showCarryPromptsForPlayer(player)
	-- Find all brainrots in workspace
	local activeTrainrots = workspace:FindFirstChild("ActiveBrainrots")
	if not activeTrainrots then
		return
	end

	for _, brainrot in pairs(activeTrainrots:GetChildren()) do
		if brainrot:IsA("Model") then
			local primaryPart = brainrot.PrimaryPart or brainrot:FindFirstChildOfClass("BasePart")
			if primaryPart then
				local carryPrompt = primaryPart:FindFirstChild("ProximityCarry")
				if carryPrompt then
					-- Restore original visibility state
					local originalEnabled = carryPrompt:GetAttribute("OriginalEnabled_" .. player.Name)
					if originalEnabled ~= nil then
						carryPrompt.Enabled = originalEnabled
						carryPrompt:SetAttribute("OriginalEnabled_" .. player.Name, nil) -- Clean up
					else
						carryPrompt.Enabled = true -- Default to enabled
					end

					print("Showed carry prompt for", brainrot.Name, "to player", player.Name)
				end
			end
		end
	end
end

-- Calculate throw power based on charge time
local function calculateThrowPower(chargeTime)
	local powerPercent = math.min(chargeTime / CHARGE_TIME, 1) -- 0 to 1
	return MIN_THROW_POWER + (MAX_THROW_POWER - MIN_THROW_POWER) * powerPercent
end

-- Handle brainrot landing
local function handleBrainrotLanding(brainrotModel, primaryPart)
	print("Brainrot has landed and settled:", brainrotModel.Name)

	local currentPos = primaryPart.Position

	-- Find ground level
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { brainrotModel }

	local rayResult = workspace:Raycast(currentPos, Vector3.new(0, -50, 0), raycastParams)
	local groundY = rayResult and rayResult.Position.Y or (currentPos.Y - 2)

	-- Position brainrot upright on ground
	local uprightPosition = Vector3.new(currentPos.X, groundY + 1, currentPos.Z)
	local uprightRotation = CFrame.Angles(0, math.rad(math.random(0, 359)), 0)

	brainrotModel:PivotTo(CFrame.new(uprightPosition) * uprightRotation)

	-- Anchor and make non-collidable after a brief delay
	task.wait(0.5)

	for _, part in pairs(brainrotModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	-- Re-setup for carrying
	BrainrotCarrying.SetupBrainrot(brainrotModel)

	print("Brainrot is now ready for pickup again:", brainrotModel.Name)
end

-- Create trajectory visualization
local function createTrajectoryVisualization(player, startPos, velocity, angle)
	local character = player.Character
	if not character then
		return nil
	end

	-- Remove existing trajectory
	local existingTrajectory = workspace:FindFirstChild("ThrowTrajectory_" .. player.Name)
	if existingTrajectory then
		existingTrajectory:Destroy()
	end

	-- Get the actual brainrot position (from the carried brainrot)
	local carryData = carriedBrainrots[player]
	local brainrotStartPos = startPos -- Default to player position

	if carryData and carryData.brainrot then
		-- Use the actual carried brainrot's position
		brainrotStartPos = carryData.brainrot.Position
		print("DEBUG: Using brainrot position for trajectory:", brainrotStartPos)
	else
		-- Fallback: estimate hand position
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local humanoid = character:FindFirstChild("Humanoid")
			local handHeight = HAND_HEIGHT_R6
			if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
				handHeight = HAND_HEIGHT_R15
			end
			brainrotStartPos = humanoidRootPart.Position + Vector3.new(0, handHeight, CARRY_FORWARD_OFFSET)
		end
	end

	-- Create trajectory points folder
	local trajectoryFolder = Instance.new("Folder")
	trajectoryFolder.Name = "ThrowTrajectory_" .. player.Name
	trajectoryFolder.Parent = workspace

	local g = workspace.Gravity
	local direction = character.HumanoidRootPart.CFrame.LookVector

	-- Physics calculations
	local vx = velocity * math.cos(math.rad(angle)) -- Horizontal velocity
	local vy = velocity * math.sin(math.rad(angle)) -- Initial vertical velocity

	-- Create trajectory points every 0.15 seconds for smoother arc
	local timeStep = 0.15
	local maxTime = 5 -- Maximum simulation time

	for t = 0, maxTime, timeStep do
		-- Calculate position at time t
		local x = brainrotStartPos.X + direction.X * vx * t
		local y = brainrotStartPos.Y + vy * t - 0.5 * g * t ^ 2 -- Projectile motion formula
		local z = brainrotStartPos.Z + direction.Z * vx * t

		-- Stop if we hit the ground
		if y < -0.6 then
			-- Add final ground point
			local groundTime = (vy + math.sqrt(vy ^ 2 + 2 * g * (brainrotStartPos.Y + 0.6))) / g
			local finalX = brainrotStartPos.X + direction.X * vx * groundTime
			local finalZ = brainrotStartPos.Z + direction.Z * vx * groundTime

			local groundPoint = Instance.new("Part")
			groundPoint.Name = "TrajectoryPoint"
			groundPoint.Size = Vector3.new(0.3, 0.3, 0.3)
			groundPoint.Position = Vector3.new(finalX, -0.6, finalZ)
			groundPoint.Anchored = true
			groundPoint.CanCollide = false
			groundPoint.Material = Enum.Material.Neon
			groundPoint.BrickColor = BrickColor.new("Bright red") -- Red for impact point
			groundPoint.Shape = Enum.PartType.Ball
			groundPoint.Transparency = 0.2
			groundPoint.Parent = trajectoryFolder

			break
		end

		-- Create trajectory point
		local point = Instance.new("Part")
		point.Name = "TrajectoryPoint"
		point.Size = Vector3.new(0.3, 0.3, 0.3)
		point.Position = Vector3.new(x, y, z)
		point.Anchored = true
		point.CanCollide = false
		point.Material = Enum.Material.Neon
		point.BrickColor = BrickColor.new("Bright green")
		point.Shape = Enum.PartType.Ball
		point.Transparency = 0.4
		point.Parent = trajectoryFolder
	end

	-- Create enhanced landing indicator
	local landingTime = (vy + math.sqrt(vy ^ 2 + 2 * g * (brainrotStartPos.Y + 0.6))) / g
	local landingX = brainrotStartPos.X + direction.X * vx * landingTime
	local landingZ = brainrotStartPos.Z + direction.Z * vx * landingTime

	local landingIndicator = Instance.new("Part")
	landingIndicator.Name = "LandingIndicator"
	landingIndicator.Size = Vector3.new(4, 0.1, 4)
	landingIndicator.Position = Vector3.new(landingX, -0.5, landingZ)
	landingIndicator.Anchored = true
	landingIndicator.CanCollide = false
	landingIndicator.Material = Enum.Material.Neon
	landingIndicator.BrickColor = BrickColor.new("Bright red")
	landingIndicator.Transparency = 0.6
	landingIndicator.Shape = Enum.PartType.Cylinder
	landingIndicator.Rotation = Vector3.new(0, 0, 90) -- Make it flat on ground
	landingIndicator.Parent = trajectoryFolder

	-- Add distance text above landing indicator
	local distanceFromStart = (Vector3.new(landingX, 0, landingZ) - Vector3.new(
		brainrotStartPos.X,
		0,
		brainrotStartPos.Z
	)).Magnitude

	local textPart = Instance.new("Part")
	textPart.Name = "DistanceText"
	textPart.Size = Vector3.new(0.1, 0.1, 0.1)
	textPart.Position = Vector3.new(landingX, 1, landingZ)
	textPart.Anchored = true
	textPart.CanCollide = false
	textPart.Transparency = 1
	textPart.Parent = trajectoryFolder

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 100, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.Parent = textPart

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = string.format("%.1f studs", distanceFromStart)
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = billboardGui

	print(
		"Created trajectory from brainrot position:",
		brainrotStartPos,
		"to landing:",
		Vector3.new(landingX, -0.6, landingZ)
	)
	return trajectoryFolder
end

-- Update trajectory during charging
local function updateTrajectoryVisualization(player)
	local throwState = throwingStates[player]
	if not throwState or not throwState.charging then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	-- Calculate current power based on charge time
	local chargeTime = tick() - throwState.startTime
	local currentPower = calculateThrowPower(chargeTime)

	-- Get current brainrot position for accurate trajectory
	local startPos = humanoidRootPart.Position
	local carryData = carriedBrainrots[player]
	if carryData and carryData.brainrot then
		startPos = carryData.brainrot.Position
	end

	-- Create new trajectory with current power
	throwState.trajectoryViz = createTrajectoryVisualization(player, startPos, currentPower, THROW_ANGLE)
end

-- Monitor brainrot landing and handle settling
local function monitorBrainrotLanding(brainrotModel, primaryPart)
	local startTime = tick()
	local lastPosition = primaryPart.Position
	local stillTime = 0
	local requiredStillTime = 1.0

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not brainrotModel or not brainrotModel.Parent or not primaryPart.Parent then
			connection:Disconnect()
			return
		end

		local currentPosition = primaryPart.Position
		local distanceMoved = (currentPosition - lastPosition).Magnitude

		if distanceMoved < 0.1 then
			stillTime = stillTime + RunService.Heartbeat:Wait()

			if stillTime >= requiredStillTime then
				connection:Disconnect()
				handleBrainrotLanding(brainrotModel, primaryPart)
			end
		else
			stillTime = 0
		end

		lastPosition = currentPosition

		if tick() - startTime > 10 then
			connection:Disconnect()
			handleBrainrotLanding(brainrotModel, primaryPart)
		end
	end)
end

-- Helper function to validate shoulder joints exist for arm manipulation
local function validateShoulderJoints(character)
	if not character then
		print("DEBUG: No character provided")
		return false
	end

	print("DEBUG: Validating joints for", character.Name)

	-- Check for R6 first
	local torso = character:FindFirstChild("Torso")
	if torso then
		print("DEBUG: Found R6 Torso")
		local leftShoulder = torso:FindFirstChild("Left Shoulder")
		local rightShoulder = torso:FindFirstChild("Right Shoulder")

		if leftShoulder and rightShoulder then
			print("DEBUG: Found both R6 shoulder joints")
			return true
		else
			print("DEBUG: Missing R6 shoulders. Left:", leftShoulder, "Right:", rightShoulder)
		end
	end

	-- Check for R15 - shoulders are in the arm parts!
	local leftUpperArm = character:FindFirstChild("LeftUpperArm")
	local rightUpperArm = character:FindFirstChild("RightUpperArm")

	if leftUpperArm and rightUpperArm then
		print("DEBUG: Found R15 arms")

		-- In R15, the shoulder joints are in the arm parts
		local leftShoulder = leftUpperArm:FindFirstChild("LeftShoulder")
		local rightShoulder = rightUpperArm:FindFirstChild("RightShoulder")

		if leftShoulder and rightShoulder then
			print("DEBUG: Found both R15 shoulder joints in arms")
			return true
		else
			print("DEBUG: Missing R15 shoulders in arms. Left:", leftShoulder, "Right:", rightShoulder)
		end
	else
		print("DEBUG: No R15 arms found. LeftUpperArm:", leftUpperArm, "RightUpperArm:", rightUpperArm)
	end

	print("DEBUG: No valid shoulder joints found")
	return false
end

-- Setup character for carrying system
local function setupCharacter(player, character)
	print("Setting up character for carrying:", player.Name)

	-- Add initial delay for character to spawn properly
	task.wait(1)

	-- Wait for essential parts
	local humanoid = character:WaitForChild("Humanoid", 10)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)

	if not (humanoid and humanoidRootPart) then
		warn("Failed to setup character for", player.Name, "- missing essential parts")
		return
	end

	-- For R15, wait for arm parts too
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		local leftUpperArm = character:WaitForChild("LeftUpperArm", 10)
		local rightUpperArm = character:WaitForChild("RightUpperArm", 10)

		if not (leftUpperArm and rightUpperArm) then
			warn("Failed to setup R15 character for", player.Name, "- missing arm parts")
			return
		end

		-- Wait for shoulder joints in arms
		task.wait(1)
	end

	-- Wait a bit more for joints to be created
	task.wait(1)

	-- Validate shoulder joints for arm manipulation
	if not validateShoulderJoints(character) then
		warn("Character", player.Name, "missing shoulder joints - arm raising disabled")
		return
	end

	print("Character setup complete for", player.Name)
end

-- Start charging throw power
local function startThrowCharge(player)
	print("DEBUG: startThrowCharge called for", player.Name)

	if not carriedBrainrots[player] then
		print("DEBUG: Player not carrying anything")
		return -- Not carrying anything
	end

	if throwingStates[player] and throwingStates[player].charging then
		print("DEBUG: Already charging")
		return -- Already charging
	end

	throwingStates[player] = {
		charging = true,
		startTime = tick(),
		trajectoryViz = nil,
	}

	print("Started throw charge for", player.Name)

	-- Show initial trajectory
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local startPos = humanoidRootPart.Position
			local initialPower = MIN_THROW_POWER

			throwingStates[player].trajectoryViz =
				createTrajectoryVisualization(player, startPos, initialPower, THROW_ANGLE)
			print("DEBUG: Created initial trajectory visualization")
		end
	end
end

-- Execute the throw
local function executeThrow(player)
	local throwState = throwingStates[player]
	if not throwState or not throwState.charging then
		return
	end

	local carryData = carriedBrainrots[player]
    -- carryData.brainrot.CanCollide = false

	if not carryData then
		return
	end

	-- Remove trajectory visualization
	if throwState.trajectoryViz then
		throwState.trajectoryViz:Destroy()
		throwState.trajectoryViz = nil
	end

	-- Also remove any trajectory in workspace
	local existingTrajectory = workspace:FindFirstChild("ThrowTrajectory_" .. player.Name)
	if existingTrajectory then
		existingTrajectory:Destroy()
	end

	-- Calculate throw power
	local chargeTime = tick() - throwState.startTime
	local throwPower = calculateThrowPower(chargeTime)

	print("Throwing with power:", throwPower, "after charging for", chargeTime, "seconds")

	-- Get throw direction
	local character = player.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local throwDirection = humanoidRootPart.CFrame.LookVector
	local throwAngleRadians = math.rad(THROW_ANGLE)
	local throwVelocity = throwDirection * throwPower + Vector3.new(0, throwPower * math.sin(throwAngleRadians), 0)

	local brainrotPart = carryData.brainrot
	local parentModel = carryData.parentModel

    if parentModel and parentModel:IsA("Model") then
        local primaryPart = parentModel.PrimaryPart or parentModel:FindFirstChildOfClass("BasePart")

		if primaryPart then
			-- Enable physics for all parts
			for _, part in pairs(parentModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
    else 
        if brainrotPart and brainrotPart.Parent then
            brainrotPart.CanCollide = false
        end
    end



	-- Drop the brainrot first
	BrainrotCarrying.DropBrainrot(player)

	-- Enable physics for throwing
	if parentModel and parentModel:IsA("Model") then
		local primaryPart = parentModel.PrimaryPart or parentModel:FindFirstChildOfClass("BasePart")

		if primaryPart then
			-- Enable physics for all parts
			for _, part in pairs(parentModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = true
				end
			end

			-- Apply velocity
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
			bodyVelocity.Velocity = throwVelocity
			bodyVelocity.Parent = primaryPart

			game:GetService("Debris"):AddItem(bodyVelocity, 0.8)

			-- Start monitoring for landing
			monitorBrainrotLanding(parentModel, primaryPart)
		end
	else
		if brainrotPart and brainrotPart.Parent then
			brainrotPart.Anchored = false
			brainrotPart.CanCollide = true

			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
			bodyVelocity.Velocity = throwVelocity
			bodyVelocity.Parent = brainrotPart

			game:GetService("Debris"):AddItem(bodyVelocity, 0.8)

			-- Start monitoring for landing
			monitorBrainrotLanding(brainrotPart, brainrotPart)
		end
	end

	print("Threw brainrot with velocity:", throwVelocity)
	throwingStates[player] = nil
end

-- Cancel throw charge
local function cancelThrowCharge(player)
	if throwingStates[player] then
		print("Cancelled throw charge for", player.Name)
		throwingStates[player] = nil
	end
end

-- Handle throw key input
local function setupThrowInput(player)
	local inputConnections = {}

	-- Connect to UserInputService on the client side through RemoteEvents
	-- For now, we'll handle it through chat commands for testing

	player.Chatted:Connect(function(message)
		local lowerMessage = message:lower()

		if lowerMessage == "/throw" or lowerMessage == "/t" then
			if carriedBrainrots[player] then
				-- Quick throw with medium power
				throwingStates[player] = {
					charging = true,
					startTime = tick() - (CHARGE_TIME * 0.5), -- 50% power
				}
				executeThrow(player)
			end
		elseif lowerMessage == "/throwmax" then
			if carriedBrainrots[player] then
				-- Max power throw
				throwingStates[player] = {
					charging = true,
					startTime = tick() - CHARGE_TIME, -- Max power
				}
				executeThrow(player)
			end
		elseif lowerMessage == "/throwmin" then
			if carriedBrainrots[player] then
				-- Min power throw
				throwingStates[player] = {
					charging = true,
					startTime = tick(), -- Min power
				}
				executeThrow(player)
			end
		end
	end)
end

-- Setup player (called when player joins)
function BrainrotCarrying.SetupPlayer(player)
	print("Setting up BrainrotCarrying for player:", player.Name)
	-- Initialize player-specific data
	carriedBrainrots[player] = nil
	throwingStates[player] = nil

	-- Show all carry prompts for new player
	task.delay(2, function() -- Small delay to ensure brainrots are loaded
		showCarryPromptsForPlayer(player)
	end)

	-- Setup throw input
	setupThrowInput(player)
end

-- Clean up when player leaves
function BrainrotCarrying.CleanupPlayer(player)
	print("Cleaning up BrainrotCarrying for player:", player.Name)

	-- Cancel any active throw charge
	cancelThrowCharge(player)

	-- Drop any carried brainrot
	if carriedBrainrots[player] then
		BrainrotCarrying.DropBrainrot(player)
	end

	-- Clean up proximity prompt attributes for this player
	local activeTrainrots = workspace:FindFirstChild("ActiveBrainrots")
	if activeTrainrots then
		for _, brainrot in pairs(activeTrainrots:GetChildren()) do
			if brainrot:IsA("Model") then
				local primaryPart = brainrot.PrimaryPart or brainrot:FindFirstChildOfClass("BasePart")
				if primaryPart then
					local carryPrompt = primaryPart:FindFirstChild("ProximityCarry")
					if carryPrompt then
						carryPrompt:SetAttribute("OriginalEnabled_" .. player.Name, nil)
					end
				end
			end
		end
	end

	-- Rest of cleanup...
	throwingStates[player] = nil
	carriedBrainrots[player] = nil
end

-- Raise player hands by specified degrees
function BrainrotCarrying.RaiseHands(player, degrees)
	local character = player.Character
	if not character then
		return false
	end

	-- Try R6 first
	local torso = character:FindFirstChild("Torso")
	if torso then
		local leftShoulder = torso:FindFirstChild("Left Shoulder")
		local rightShoulder = torso:FindFirstChild("Right Shoulder")

		if leftShoulder and rightShoulder then
			local angleRadians = math.rad(degrees)

            print("Raising R6 arms by", degrees, "degrees (", angleRadians, "radians ) for", player.Name)

			-- Store originals in our table (not as properties)
			if not originalShoulderC0[leftShoulder] then
				originalShoulderC0[leftShoulder] = leftShoulder.C0
			end
			if not originalShoulderC0[rightShoulder] then
				originalShoulderC0[rightShoulder] = rightShoulder.C0
			end

			-- R6: Z-axis rotation for upward movement
			leftShoulder.C0 = originalShoulderC0[leftShoulder] * CFrame.Angles(0, 0, angleRadians)
			rightShoulder.C0 = originalShoulderC0[rightShoulder] * CFrame.Angles(0, 0, -angleRadians)

			print("Raised R6 arms upward for", player.Name)
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

-- Restore normal hand positions
function BrainrotCarrying.RestoreHands(player)
	local character = player.Character
	if not character then
		return
	end

	-- Try R6 first
	local torso = character:FindFirstChild("Torso")
	if torso then
		local leftShoulder = torso:FindFirstChild("Left Shoulder")
		local rightShoulder = torso:FindFirstChild("Right Shoulder")

		if leftShoulder and originalShoulderC0[leftShoulder] then
			leftShoulder.C0 = originalShoulderC0[leftShoulder]
			originalShoulderC0[leftShoulder] = nil -- Clean up
		end

		if rightShoulder and originalShoulderC0[rightShoulder] then
			rightShoulder.C0 = originalShoulderC0[rightShoulder]
			originalShoulderC0[rightShoulder] = nil -- Clean up
		end

		print("Restored R6 arms for", player.Name)
		return
	end

	-- Try R15 - shoulders are in the arm parts!
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

		print("Restored R15 arms for", player.Name)
	end
end

-- Attach brainrot to follow player
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

	-- Make sure brainrotPart is actually a BasePart
	if not brainrotPart:IsA("BasePart") then
		warn("BrainrotCarrying.AttachBrainrot: Expected BasePart, got", brainrotPart.ClassName)
		return false
	end

	-- Calculate proper height based on character type
	local handHeight = HAND_HEIGHT_R6
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		handHeight = HAND_HEIGHT_R15
	end

	-- Position: Above player at hand height, slightly in front
	local carryOffset = CFrame.new(0, handHeight, CARRY_FORWARD_OFFSET)

	-- Create Motor6D joint for smooth following
	local joint = Instance.new("Motor6D")
	joint.Name = "BrainrotJoint"
	joint.Part0 = humanoidRootPart -- Player's root part (stays on ground)
	joint.Part1 = brainrotPart -- Brainrot part (gets lifted)
	joint.C0 = carryOffset -- Offset from player's center to hand height
	joint.Parent = humanoidRootPart

	-- Get parent model for CanCollide and Anchored management
	local parentModel = brainrotPart.Parent
	local originalCanCollideStates = {}
	local originalAnchoredStates = {}

	-- Disable collision and anchoring for smooth carrying
	if parentModel and parentModel:IsA("Model") then
		for _, part in pairs(parentModel:GetDescendants()) do
			if part:IsA("BasePart") then
				-- Store original states
				originalCanCollideStates[part] = part.CanCollide
				originalAnchoredStates[part] = part.Anchored

				-- Disable for carrying
				part.CanCollide = false
				part.Anchored = false -- This is key! Unanchor for Motor6D to work properly
			end
		end
	else
		-- Store original states
		originalCanCollideStates[brainrotPart] = brainrotPart.CanCollide
		originalAnchoredStates[brainrotPart] = brainrotPart.Anchored

		-- Disable for carrying
		brainrotPart.CanCollide = false
		brainrotPart.Anchored = false -- This is key! Unanchor for Motor6D to work properly
	end

	-- Store all data for cleanup
	carriedBrainrots[player] = {
		brainrot = brainrotPart,
		joint = joint,
		parentModel = parentModel,
		originalCanCollideStates = originalCanCollideStates,
		originalAnchoredStates = originalAnchoredStates,
	}

	print("Brainrot attached at hand height (", handHeight, "studs ) for", player.Name)
	return true
end

-- Start carrying a brainrot
function BrainrotCarrying.CarryBrainrot(player, brainrotPart)
	if carriedBrainrots[player] then
		-- Already carrying something - don't allow picking up another
		print(player.Name, "is already carrying a brainrot")
		return false
	end

	-- Raise hands
	if BrainrotCarrying.RaiseHands(player, ARM_RAISE_DEGREES) then
		-- Attach brainrot
		if BrainrotCarrying.AttachBrainrot(player, brainrotPart) then
			print(player.Name, "is now carrying a brainrot")

			-- Get the parent model for timer management
			local parentModel = brainrotPart.Parent
			if parentModel and parentModel:IsA("Model") then
				-- Pause the brainrot's wormhole timer
				TimerService:pauseTimer(parentModel)
			else
				-- Single part brainrot
				TimerService:pauseTimer(brainrotPart)
			end

			-- Hide ALL carry prompts for this player (since they're now carrying something)
			hideCarryPromptsForPlayer(player)

			-- Create throw prompt on the carried brainrot
			local throwPrompt = Instance.new("ProximityPrompt")
			throwPrompt.Name = "ProximityThrow"
			throwPrompt.ActionText = "Throw Brainrot (Hold Q)"
			throwPrompt.KeyboardKeyCode = THROW_KEY
			throwPrompt.HoldDuration = 0
			throwPrompt.MaxActivationDistance = 10
			throwPrompt.Parent = brainrotPart

			throwPrompt.Triggered:Connect(function(p)
				if p == player then
					executeThrow(player)
				end
			end)

			return true
		else
			-- Failed to attach, restore hands
			BrainrotCarrying.RestoreHands(player)
		end
	end

	return false
end

-- Drop the carried brainrot
function BrainrotCarrying.DropBrainrot(player)
	local carryData = carriedBrainrots[player]
	if not carryData then
		return
	end

	print(player.Name, "is dropping their brainrot")

	-- Get the brainrot for timer management
	local brainrotPart = carryData.brainrot
	local parentModel = carryData.parentModel

	-- Resume the brainrot's wormhole timer
	if parentModel and parentModel:IsA("Model") then
		TimerService:resumeTimer(parentModel)
	else
		TimerService:resumeTimer(brainrotPart)
	end

	-- Remove Throw prompt
	if brainrotPart then
		local throwPrompt = brainrotPart:FindFirstChild("ProximityThrow")
		if throwPrompt then
			throwPrompt:Destroy()
		end
	end

	-- Restore original CanCollide and Anchored states
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

	-- Destroy the joint (this releases the brainrot)
	if carryData.joint then
		carryData.joint:Destroy()
	end

	-- Restore player arms to normal position
	BrainrotCarrying.RestoreHands(player)

	-- Clear the carried brainrot data
	carriedBrainrots[player] = nil

	-- Show ALL carry prompts for this player (since they're no longer carrying anything)
	showCarryPromptsForPlayer(player)
w
end

-- Set up a brainrot model for carrying
function BrainrotCarrying.SetupBrainrot(brainrot)
	print("DEBUG: Setting up brainrot:", brainrot.Name, brainrot.ClassName)

	if brainrot:IsA("Model") then
		print("DEBUG: It's a Model with PrimaryPart:", brainrot.PrimaryPart)
	end

	local partToAttachTo

	if brainrot:IsA("Model") then
		partToAttachTo = brainrot.PrimaryPart or brainrot:FindFirstChildOfClass("BasePart")
		if not partToAttachTo then
			warn("BrainrotCarrying.SetupBrainrot: Model has no PrimaryPart or BasePart")
			return false
		end
	elseif brainrot:IsA("BasePart") then
		partToAttachTo = brainrot
	else
		warn("BrainrotCarrying.SetupBrainrot: Expected Model or BasePart, got", brainrot.ClassName)
		return false
	end

	if partToAttachTo:FindFirstChild("ProximityCarry") then
		-- Already set up
		return true
	end

	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.Name = "ProximityCarry"
	proximityPrompt.ActionText = "Carry Brainrot"
	proximityPrompt.KeyboardKeyCode = PICKUP_KEY
	proximityPrompt.HoldDuration = 0.5
	proximityPrompt.MaxActivationDistance = 10
	proximityPrompt.Parent = partToAttachTo

	proximityPrompt.Triggered:Connect(function(player)
		-- Check if player is already carrying something
		if carriedBrainrots[player] then
			print(player.Name, "tried to pick up", brainrot.Name, "but is already carrying something")
			return -- Don't allow pickup
		end

		-- Try to carry this brainrot
		BrainrotCarrying.CarryBrainrot(player, partToAttachTo)
	end)

	print("Set up carrying for brainrot:", brainrot.Name)
	return true
end

-- Get whether a player is currently carrying something
function BrainrotCarrying.IsCarrying(player)
	return carriedBrainrots[player] ~= nil
end

-- Get the brainrot a player is carrying
function BrainrotCarrying.GetCarriedBrainrot(player)
	local carryData = carriedBrainrots[player]
	return carryData and carryData.brainrot or nil
end

-- Function to be called when a brainrot is timed out (cleanup)
function BrainrotCarrying.OnBrainrotTimeout(brainrot)
	-- Find any player carrying this brainrot and make them drop it
	for player, carryData in pairs(carriedBrainrots) do
		if carryData and carryData.brainrot == brainrot then
			BrainrotCarrying.DropBrainrot(player)
			break
		end
	end
end

-- Main initialization function
function BrainrotCarrying.Init()
	if initialized then
		warn("BrainrotCarrying already initialized!")
		return
	end
	initialized = true

	print("BrainrotCarrying system initialized!")

	-- Clean up existing connections
	for _, connection in pairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end
	connections = {}

	-- Create RemoteEvents folder
	local remoteEventsFolder = game.ReplicatedStorage:FindFirstChild("BrainrotEvents")
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = "BrainrotEvents"
		remoteEventsFolder.Parent = game.ReplicatedStorage
		print("Created BrainrotEvents folder")
	end

	-- Create ThrowStart event
	local throwStartEvent = remoteEventsFolder:FindFirstChild("ThrowStart")
	if not throwStartEvent then
		throwStartEvent = Instance.new("RemoteEvent")
		throwStartEvent.Name = "ThrowStart"
		throwStartEvent.Parent = remoteEventsFolder
		print("Created ThrowStart event")
	end

	-- Create ThrowRelease event
	local throwReleaseEvent = remoteEventsFolder:FindFirstChild("ThrowRelease")
	if not throwReleaseEvent then
		throwReleaseEvent = Instance.new("RemoteEvent")
		throwReleaseEvent.Name = "ThrowRelease"
		throwReleaseEvent.Parent = remoteEventsFolder
		print("Created ThrowRelease event")
	end

	-- Add this RIGHT AFTER creating ThrowRelease event in Init function
	local trajectoryUpdateEvent = remoteEventsFolder:FindFirstChild("TrajectoryUpdate")
	if not trajectoryUpdateEvent then
		trajectoryUpdateEvent = Instance.new("RemoteEvent")
		trajectoryUpdateEvent.Name = "TrajectoryUpdate"
		trajectoryUpdateEvent.Parent = remoteEventsFolder
		print("Created TrajectoryUpdate event")
	end

	-- Add this connection RIGHT AFTER the other throw event connections
	connections.trajectoryUpdate = trajectoryUpdateEvent.OnServerEvent:Connect(function(player)
		updateTrajectoryVisualization(player)
	end)

	-- IMPORTANT: Connect event handlers AFTER events are created
	print("Connecting throw event handlers...")

	connections.throwStart = throwStartEvent.OnServerEvent:Connect(function(player)
		print("🎯 SERVER: ThrowStart received from", player.Name)
		print("Player is carrying:", carriedBrainrots[player] ~= nil)
		startThrowCharge(player)
	end)

	connections.throwRelease = throwReleaseEvent.OnServerEvent:Connect(function(player)
		print("🎯 SERVER: ThrowRelease received from", player.Name)
		print("Player is carrying:", carriedBrainrots[player] ~= nil)
		executeThrow(player)
	end)

	print("Throw event handlers connected!")

	-- Set up player connections
	connections.playerAdded = Players.PlayerAdded:Connect(function(player)
		print("Player joined:", player.Name)
		BrainrotCarrying.SetupPlayer(player)

		connections[player.UserId] = player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character)
		end)
	end)

	-- Set up existing players
	for _, player in pairs(Players:GetPlayers()) do
		BrainrotCarrying.SetupPlayer(player)

		if player.Character then
			task.spawn(function()
				setupCharacter(player, player.Character)
			end)
		end

		connections[player.UserId] = player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character)
		end)
	end

	-- Clean up when players leave
	connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
		BrainrotCarrying.CleanupPlayer(player)
	end)

	-- Monitor carried brainrots
	connections.heartbeat = RunService.Heartbeat:Connect(function()
		for player, carryData in pairs(carriedBrainrots) do
			if carryData and carryData.brainrot then
				local brainrot = carryData.brainrot

				if not brainrot.Parent then
					print("Brainrot was destroyed, cleaning up for player:", player.Name)
					BrainrotCarrying.DropBrainrot(player)
				end
			end
		end
	end)

	print("BrainrotCarrying initialization complete!")
end

-- Return the module
return BrainrotCarrying
