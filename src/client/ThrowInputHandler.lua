--print("=== DEBUG LOCALSCRIPT LOADED ===")

--local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local UserInputService = game:GetService("UserInputService")
--local RunService = game:GetService("RunService")

--local remoteEventsFolder = ReplicatedStorage:WaitForChild("BrainrotEvents", 10)
--if not remoteEventsFolder then
--	warn("BrainrotEvents folder not found!")
--	return
--end

--local throwStartEvent = remoteEventsFolder:WaitForChild("ThrowStart", 10)
--local throwReleaseEvent = remoteEventsFolder:WaitForChild("ThrowRelease", 10)
--local trajectoryUpdateEvent = remoteEventsFolder:WaitForChild("TrajectoryUpdate", 10)

--print("Found events:", throwStartEvent, throwReleaseEvent, trajectoryUpdateEvent)

--local throwCharging = false
--local trajectoryUpdateConnection

---- Test all input first
--UserInputService.InputBegan:Connect(function(input, gameProcessed)
--	print("Input detected:", input.KeyCode.Name, "GameProcessed:", gameProcessed)

--	-- Don't ignore gameProcessed for Q key - sometimes it's needed
--	if input.KeyCode == Enum.KeyCode.Q then
--		print("Q KEY DETECTED (raw)")

--		if not throwCharging then
--			throwCharging = true
--			print("Q PRESSED - Starting charge")
--			throwStartEvent:FireServer()

--			-- Start trajectory update loop
--			trajectoryUpdateConnection = task.spawn(function()
--				while throwCharging do
--					trajectoryUpdateEvent:FireServer()
--					task.wait(0.1)
--				end
--			end)
--		end
--	end
--end)

--UserInputService.InputEnded:Connect(function(input, gameProcessed)
--	if input.KeyCode == Enum.KeyCode.Q then
--		print("Q KEY RELEASED (raw)")

--		if throwCharging then
--			throwCharging = false
--			print("Q RELEASED - Executing throw")
--			throwReleaseEvent:FireServer()

--			-- Stop trajectory updates
--			if trajectoryUpdateConnection then
--				task.cancel(trajectoryUpdateConnection)
--				trajectoryUpdateConnection = nil
--			end
--		end
--	end
--end)

--print("=== DEBUG SETUP COMPLETE ===")
-- Client-side throw input handler
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Shared.BrainrotConfig)

local ThrowInputHandler = {}

local throwCharging = false
local trajectoryUpdateConnection = nil
local remoteEvents = {}

-- Initialize remote events
local function initializeRemoteEvents()
	local remoteEventsFolder = ReplicatedStorage:WaitForChild(Constants.REMOTE_FOLDER_NAME, 1)
	if not remoteEventsFolder then
		warn("BrainrotEvents folder not found!")
		return false
	end

	remoteEvents.throwStart = remoteEventsFolder:WaitForChild(Constants.THROW_START_EVENT, 1)
	remoteEvents.throwRelease = remoteEventsFolder:WaitForChild(Constants.THROW_RELEASE_EVENT, 1)
	remoteEvents.trajectoryUpdate = remoteEventsFolder:WaitForChild(Constants.TRAJECTORY_UPDATE_EVENT, 1)

	if not (remoteEvents.throwStart and remoteEvents.throwRelease and remoteEvents.trajectoryUpdate) then
		warn("Throw events not found!")
		return false
	end

	print("ThrowInputHandler: Found all throw events")
	return true
end

-- Handle input
local function handleInputBegan(input, gameProcessed)
	if input.KeyCode == Constants.THROW_KEY then
		if not throwCharging then
			throwCharging = true
			print("Q PRESSED - Starting throw charge")

			if remoteEvents.throwStart then
				remoteEvents.throwStart:FireServer()
			end

			-- Start trajectory update loop
			trajectoryUpdateConnection = task.spawn(function()
				while throwCharging do
					if remoteEvents.trajectoryUpdate then
						remoteEvents.trajectoryUpdate:FireServer()
					end
					task.wait(Constants.TRAJECTORY_UPDATE_RATE)
				end
			end)
		end
	end
end

local function handleInputEnded(input, gameProcessed)
	if input.KeyCode == Constants.THROW_KEY then
		if throwCharging then
			throwCharging = false
			print("Q RELEASED - Executing throw")

			if remoteEvents.throwRelease then
				remoteEvents.throwRelease:FireServer()
			end

			-- Stop trajectory updates
			if trajectoryUpdateConnection then
				task.cancel(trajectoryUpdateConnection)
				trajectoryUpdateConnection = nil
			end
		end
	end
end

-- Public API
function ThrowInputHandler.Init()
	print("ThrowInputHandler: Initializing...")

	if not initializeRemoteEvents() then
		warn("ThrowInputHandler: Failed to initialize remote events")
		return false
	end

	-- Connect input handlers
	UserInputService.InputBegan:Connect(handleInputBegan)
	UserInputService.InputEnded:Connect(handleInputEnded)

	print("ThrowInputHandler: Initialized successfully!")
	return true
end

return ThrowInputHandler
