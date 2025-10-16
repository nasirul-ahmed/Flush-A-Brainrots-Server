local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.BrainrotConfig)
local TimerService = require(script.Parent.Parent.TimerService)
local BrainrotCarrying = require(script.Parent.BrainrotCarrying)
local BrainrotWormhole = require(script.Parent.BrainrotWormhole)
local CoreUtils = require(script.Parent.Parent.Helper)

local Brainrots = {}

function Brainrots.spawnBrainrot(brainrotFolder, templateFolder, clouds, spawnCount, mainTrack)
	if not templateFolder or not clouds then
		warn("Brainrot template folder or clouds not found!")
		return
	end

	-- Collect templates
	local templates = {}
	for _, obj in templateFolder:GetChildren() do
		if obj:IsA("Model") or obj:IsA("BasePart") then
			table.insert(templates, obj)
		end
	end

	if #templates == 0 then
		warn("No brainrot templates found in folder!")
		return
	end

	for i = 1, spawnCount do
		local template = templates[math.random(1, #templates)]
		local clone = template:Clone()
		clone.Parent = brainrotFolder
		local uniqueId = CoreUtils.generateUniqueId()
		clone:SetAttribute("UniqueId", uniqueId)

		-- Pick random cloud
		local cloudChildren = clouds:GetChildren()
		if #cloudChildren == 0 then
			warn("No clouds found!")
			return
		end
		local randomCloud = cloudChildren[math.random(1, #cloudChildren)]

		-- Find a part in the cloud
		local cloudSize, cloudPos
		if randomCloud:IsA("Model") then
			local part = randomCloud:FindFirstChildWhichIsA("BasePart")
			if part then
				cloudSize = part.Size
				cloudPos = part.Position
			else
				warn("Cloud model has no BaseParts: " .. randomCloud.Name)
				continue
			end
		elseif randomCloud:IsA("BasePart") then
			cloudSize = randomCloud.Size
			cloudPos = randomCloud.Position
		else
			warn("Cloud is not a Model or Part: " .. randomCloud.ClassName)
			continue
		end

		-- Random spawn pos inside cloud bounds
		local randX = cloudPos.X + math.random(-cloudSize.X / 2, cloudSize.X / 2)
		local randZ = cloudPos.Z + math.random(-cloudSize.Z / 2, cloudSize.Z / 2)
		local randY = cloudPos.Y + math.random(-cloudSize.Y / 2, cloudSize.Y / 2)

		local spawnPos = Vector3.new(randX, randY, randZ)
		local rotation = CFrame.Angles(0, math.rad(math.random(0, 359)), 0)

		clone:PivotTo(CFrame.new(spawnPos) * rotation)

		-- Ensure it has a PrimaryPart
		if not clone.PrimaryPart then
			local firstPart = clone:FindFirstChildWhichIsA("BasePart")
			if firstPart then
				clone.PrimaryPart = firstPart
			end
		end

		-- Hover in place first
		for _, part in clone:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = true
			end
		end

		-- Fall after delay
		local fallDelay = math.random(1, 5)
		task.delay(fallDelay, function()
			makeBrainrotFall(clone, mainTrack, spawnPos, rotation)

			task.delay(fallDelay + 2, function()
				startBrainrotLifetimeTimer(clone, mainTrack)

				-- Set up carrying system for this brainrot after it has fallen and settled
				BrainrotCarrying.SetupBrainrot(clone)
			end)
		end)
	end
end

function makeBrainrotFall(brainrot, mainTrack, startPos, originalRotation)
	if not brainrot or not brainrot.Parent then
		return
	end

	local groundY = findGroundLevel(startPos, mainTrack)
	local landingPos = Vector3.new(startPos.X, groundY, startPos.Z)

	simulateBounceFall(brainrot, startPos, landingPos, originalRotation)
end

function findGroundLevel(startPos, mainTrack)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { mainTrack }

	local rayDirection = Vector3.new(0, -1000, 0)
	local rayResult = workspace:Raycast(startPos, rayDirection, raycastParams)

	if rayResult then
		return rayResult.Position.Y
	else
		return startPos.Y - 50
	end
end

function simulateBounceFall(brainrot, startPos, landingPos, originalRotation)
	local startTime = tick()
	local fallDuration = 3
	local bounceCount = 4
	local maxBounceHeight = math.abs(startPos.Y - landingPos.Y) * 0.1
	local damping = 0.6
	local currentBounce = 0
	local isSettled = false

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not brainrot or not brainrot.Parent then
			if connection then
				connection:Disconnect()
			end
			return
		end

		if isSettled then
			connection:Disconnect()
			brainrot:PivotTo(CFrame.new(landingPos) * originalRotation)

			for _, part in brainrot:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = false
				end
			end

			return
		end

		local elapsedTime = tick() - startTime
		local progress = math.min(elapsedTime / fallDuration, 1)

		local currentY

		if currentBounce == 0 then
			local fallProgress = math.min(elapsedTime / 2, 1)
			currentY = startPos.Y - (startPos.Y - landingPos.Y) * (fallProgress * fallProgress)

			if currentY <= landingPos.Y then
				currentBounce = 1
				startTime = tick()
			end
		else
			local bounceTime = elapsedTime % 0.5
			local bounceProgress = bounceTime / 0.5

			local currentBounceHeight = maxBounceHeight * math.pow(damping, currentBounce - 1)

			currentY = landingPos.Y + math.sin(bounceProgress * math.pi) * currentBounceHeight

			if bounceTime <= 0.05 and elapsedTime > 0.1 then
				currentBounce = currentBounce + 1

				if currentBounce > bounceCount or currentBounceHeight < 0.5 then
					isSettled = true
					return
				end
			end
		end

		local newPosition = Vector3.new(landingPos.X, math.max(currentY, landingPos.Y), landingPos.Z)
		brainrot:PivotTo(CFrame.new(newPosition) * originalRotation)
	end)
end

function startBrainrotLifetimeTimer(brainrot, mainTrack)
	if not brainrot or not brainrot.Parent then
		return
	end

	TimerService:startTimer(brainrot, 30, function(br)
		BrainrotWormhole.createAndRemove(br, mainTrack)
	end)
end

-- Export wormhole function for other modules
Brainrots.createWormholeAndRemove = function(brainrot, mainTrack)
	BrainrotWormhole.createAndRemove(brainrot, mainTrack)
end

return Brainrots
