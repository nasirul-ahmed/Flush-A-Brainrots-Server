local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.BrainrotConfig)
local BrainrotCarrying = require(script.Parent.BrainrotCarrying)
local BrainrotThrowing = {}

-- Internal State
local throwingStates = {}
local connections = {}
local initialized = false

-- Helper Functions
local function calculateThrowPower(chargeTime)
	local powerPercent = math.min(chargeTime / Config.CHARGE_TIME, 1)
	return Config.MIN_THROW_POWER + (Config.MAX_THROW_POWER - Config.MIN_THROW_POWER) * powerPercent
end

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

	-- Get actual brainrot position
	local carryData = BrainrotCarrying.GetCarryData(player)
	local brainrotStartPos = startPos

	if carryData and carryData.brainrot then
		brainrotStartPos = carryData.brainrot.Position
	else
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local humanoid = character:FindFirstChild("Humanoid")
			local handHeight = Config.HAND_HEIGHT_R6
			if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
				handHeight = Config.HAND_HEIGHT_R15
			end
			brainrotStartPos = humanoidRootPart.Position + Vector3.new(0, handHeight, Config.CARRY_FORWARD_OFFSET)
		end
	end

	local trajectoryFolder = Instance.new("Folder")
	trajectoryFolder.Name = "ThrowTrajectory_" .. player.Name
	trajectoryFolder.Parent = workspace

	local g = workspace.Gravity
	local direction = character.HumanoidRootPart.CFrame.LookVector

	local vx = velocity * math.cos(math.rad(angle))
	local vy = velocity * math.sin(math.rad(angle))

	-- Create trajectory points
	for t = 0, Config.TRAJECTORY_MAX_TIME, Config.TRAJECTORY_TIMESTEP do
		local x = brainrotStartPos.X + direction.X * vx * t
		local y = brainrotStartPos.Y + vy * t - 0.5 * g * t ^ 2
		local z = brainrotStartPos.Z + direction.Z * vx * t

		if y < Config.GROUND_LEVEL then
			-- Add final ground point
			local groundTime = (vy + math.sqrt(vy ^ 2 + 2 * g * (brainrotStartPos.Y - Config.GROUND_LEVEL))) / g
			local finalX = brainrotStartPos.X + direction.X * vx * groundTime
			local finalZ = brainrotStartPos.Z + direction.Z * vx * groundTime

			local groundPoint = Instance.new("Part")
			groundPoint.Name = "TrajectoryPoint"
			groundPoint.Size = Vector3.new(0.3, 0.3, 0.3)
			groundPoint.Position = Vector3.new(finalX, Config.GROUND_LEVEL, finalZ)
			groundPoint.Anchored = true
			groundPoint.CanCollide = false
			groundPoint.Material = Enum.Material.Neon
			groundPoint.BrickColor = BrickColor.new("Bright red")
			groundPoint.Shape = Enum.PartType.Ball
			groundPoint.Transparency = 0.2
			groundPoint.Parent = trajectoryFolder
			break
		end

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

	-- Create landing indicator
	local landingTime = (vy + math.sqrt(vy ^ 2 + 2 * g * (brainrotStartPos.Y - Config.GROUND_LEVEL))) / g
	local landingX = brainrotStartPos.X + direction.X * vx * landingTime
	local landingZ = brainrotStartPos.Z + direction.Z * vx * landingTime

	local landingIndicator = Instance.new("Part")
	landingIndicator.Name = "LandingIndicator"
	landingIndicator.Size = Vector3.new(4, 0.1, 4)
	landingIndicator.Position = Vector3.new(landingX, Config.GROUND_LEVEL + 0.1, landingZ)
	landingIndicator.Anchored = true
	landingIndicator.CanCollide = false
	landingIndicator.Material = Enum.Material.Neon
	landingIndicator.BrickColor = BrickColor.new("Bright red")
	landingIndicator.Transparency = 0.6
	landingIndicator.Shape = Enum.PartType.Cylinder
	landingIndicator.Rotation = Vector3.new(0, 0, 90)
	landingIndicator.Parent = trajectoryFolder

	-- Distance text
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

	return trajectoryFolder
end

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

	local chargeTime = tick() - throwState.startTime
	local currentPower = calculateThrowPower(chargeTime)

	local startPos = humanoidRootPart.Position
	local carryData = BrainrotCarrying.GetCarryData(player)
	if carryData and carryData.brainrot then
		startPos = carryData.brainrot.Position
	end

	throwState.trajectoryViz = createTrajectoryVisualization(player, startPos, currentPower, Config.THROW_ANGLE)
end

local function monitorBrainrotLanding(brainrotModel, primaryPart)
	local startTime = tick()
	local lastPosition = primaryPart.Position
	local stillTime = 0

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not brainrotModel or not brainrotModel.Parent or not primaryPart.Parent then
			connection:Disconnect()
			return
		end

		local currentPosition = primaryPart.Position
		local distanceMoved = (currentPosition - lastPosition).Magnitude

		if distanceMoved < Config.LANDING_MOVEMENT_THRESHOLD then
			stillTime = stillTime + RunService.Heartbeat:Wait()

			if stillTime >= Config.LANDING_STILL_TIME then
				connection:Disconnect()
				BrainrotThrowing.HandleBrainrotLanding(brainrotModel, primaryPart)
			end
		else
			stillTime = 0
		end

		lastPosition = currentPosition

		if tick() - startTime > 10 then
			connection:Disconnect()
			BrainrotThrowing.HandleBrainrotLanding(brainrotModel, primaryPart)
		end
	end)
end

-- Public API
function BrainrotThrowing.HandleBrainrotLanding(brainrotModel, primaryPart)
	print("Brainrot has landed and settled:", brainrotModel.Name)

	local currentPos = primaryPart.Position

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { brainrotModel }

	local rayResult = workspace:Raycast(currentPos, Vector3.new(0, -50, 0), raycastParams)
	local groundY = rayResult and rayResult.Position.Y or (currentPos.Y - 2)

	local uprightPosition = Vector3.new(currentPos.X, groundY + 1, currentPos.Z)
	local uprightRotation = CFrame.Angles(0, math.rad(math.random(0, 359)), 0)

	brainrotModel:PivotTo(CFrame.new(uprightPosition) * uprightRotation)

	task.wait(0.5)

	for _, part in pairs(brainrotModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	BrainrotCarrying.SetupBrainrot(brainrotModel)

	print("Brainrot is now ready for pickup again:", brainrotModel.Name)
end

function BrainrotThrowing.StartThrowCharge(player)
	if not BrainrotCarrying.IsCarrying(player) then
		return
	end

	if throwingStates[player] and throwingStates[player].charging then
		return
	end

	throwingStates[player] = {
		charging = true,
		startTime = tick(),
		trajectoryViz = nil,
	}

	print("Started throw charge for", player.Name)

	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local startPos = humanoidRootPart.Position
			local initialPower = Config.MIN_THROW_POWER

			throwingStates[player].trajectoryViz =
				createTrajectoryVisualization(player, startPos, initialPower, Config.THROW_ANGLE)
		end
	end
end

function BrainrotThrowing.ExecuteThrow(player)
	local throwState = throwingStates[player]
	if not throwState or not throwState.charging then
		return
	end

	local carryData = BrainrotCarrying.GetCarryData(player)
	if not carryData then
		return
	end

	local brainrotPart = carryData.brainrot
	local parentModel = carryData.parentModel

	if parentModel and parentModel:IsA("Model") then
		local primaryPart = parentModel.PrimaryPart or parentModel:FindFirstChildOfClass("BasePart")

		if primaryPart then
			for _, part in pairs(parentModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = false
				end
			end
		end
	else
		if brainrotPart and brainrotPart.Parent then
			brainrotPart.Anchored = false
			brainrotPart.CanCollide = false
		end
	end

	-- Remove trajectory visualization
	if throwState.trajectoryViz then
		throwState.trajectoryViz:Destroy()
		throwState.trajectoryViz = nil
	end

	local existingTrajectory = workspace:FindFirstChild("ThrowTrajectory_" .. player.Name)
	if existingTrajectory then
		existingTrajectory:Destroy()
	end

	local chargeTime = tick() - throwState.startTime
	local throwPower = calculateThrowPower(chargeTime)

	print("Throwing with power:", throwPower, "after charging for", chargeTime, "seconds")

	local character = player.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local throwDirection = humanoidRootPart.CFrame.LookVector
	local throwAngleRadians = math.rad(Config.THROW_ANGLE)
	local throwVelocity = throwDirection * throwPower + Vector3.new(0, throwPower * math.sin(throwAngleRadians), 0)

	-- local brainrotPart = carryData.brainrot
	-- local parentModel = carryData.parentModel

	local newThrowVelocity = throwVelocity * 0.5

	BrainrotCarrying.DropBrainrot(player)

	if parentModel and parentModel:IsA("Model") then
		local primaryPart = parentModel.PrimaryPart or parentModel:FindFirstChildOfClass("BasePart")

		if primaryPart then
			for _, part in pairs(parentModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = true
				end
			end

			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
			bodyVelocity.Velocity = newThrowVelocity
			bodyVelocity.Parent = primaryPart

			game:GetService("Debris"):AddItem(bodyVelocity, 0.8)

			monitorBrainrotLanding(parentModel, primaryPart)
		end
	else
		if brainrotPart and brainrotPart.Parent then
			brainrotPart.Anchored = false
			brainrotPart.CanCollide = true

			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
			bodyVelocity.Velocity = newThrowVelocity
			bodyVelocity.Parent = brainrotPart

			game:GetService("Debris"):AddItem(bodyVelocity, 0.8)

			monitorBrainrotLanding(brainrotPart, brainrotPart)
		end
	end

	print("Threw brainrot with velocity:", newThrowVelocity)
	throwingStates[player] = nil
end

function BrainrotThrowing.UpdateTrajectory(player)
	updateTrajectoryVisualization(player)
end

function BrainrotThrowing.CleanupPlayer(player)
	if throwingStates[player] then
		if throwingStates[player].trajectoryViz then
			throwingStates[player].trajectoryViz:Destroy()
		end
		throwingStates[player] = nil
	end

	local existingTrajectory = workspace:FindFirstChild("ThrowTrajectory_" .. player.Name)
	if existingTrajectory then
		existingTrajectory:Destroy()
	end
end

function BrainrotThrowing.Init()
	if initialized then
		return
	end
	initialized = true

	print("BrainrotThrowing system initialized!")

	local remoteEventsFolder = ReplicatedStorage:FindFirstChild(Config.REMOTE_FOLDER_NAME)
	if not remoteEventsFolder then
		remoteEventsFolder = Instance.new("Folder")
		remoteEventsFolder.Name = Config.REMOTE_FOLDER_NAME
		remoteEventsFolder.Parent = ReplicatedStorage
	end

	local throwStartEvent = remoteEventsFolder:FindFirstChild(Config.THROW_START_EVENT)
	if not throwStartEvent then
		throwStartEvent = Instance.new("RemoteEvent")
		throwStartEvent.Name = Config.THROW_START_EVENT
		throwStartEvent.Parent = remoteEventsFolder
	end

	local throwReleaseEvent = remoteEventsFolder:FindFirstChild(Config.THROW_RELEASE_EVENT)
	if not throwReleaseEvent then
		throwReleaseEvent = Instance.new("RemoteEvent")
		throwReleaseEvent.Name = Config.THROW_RELEASE_EVENT
		throwReleaseEvent.Parent = remoteEventsFolder
	end

	local trajectoryUpdateEvent = remoteEventsFolder:FindFirstChild(Config.TRAJECTORY_UPDATE_EVENT)
	if not trajectoryUpdateEvent then
		trajectoryUpdateEvent = Instance.new("RemoteEvent")
		trajectoryUpdateEvent.Name = Config.TRAJECTORY_UPDATE_EVENT
		trajectoryUpdateEvent.Parent = remoteEventsFolder
	end

	connections.throwStart = throwStartEvent.OnServerEvent:Connect(function(player)
		BrainrotThrowing.StartThrowCharge(player)
	end)

	connections.throwRelease = throwReleaseEvent.OnServerEvent:Connect(function(player)
		BrainrotThrowing.ExecuteThrow(player)
	end)

	connections.trajectoryUpdate = trajectoryUpdateEvent.OnServerEvent:Connect(function(player)
		BrainrotThrowing.UpdateTrajectory(player)
	end)
end

return BrainrotThrowing
