-- local TweenService = game:GetService("TweenService")
-- local RunService = game:GetService("RunService")
-- local TimerService = require(script.Parent.TimerService)
-- local BrainrotCarrying = require(script.Parent.BrainrotCarrying)
-- local CoreUtils = require(script.Parent:WaitForChild("Helper"))
-- local Brainrots = {}

-- function Brainrots.spawnBrainrot(brainrotFolder, templateFolder, clouds, spawnCount, mainTrack)
-- 	if not templateFolder or not clouds then
-- 		warn("Brainrot template folder or clouds not found!")
-- 		return
-- 	end

-- 	-- Collect templates
-- 	local templates = {}
-- 	for _, obj in templateFolder:GetChildren() do
-- 		if obj:IsA("Model") or obj:IsA("BasePart") then
-- 			table.insert(templates, obj)
-- 		end
-- 	end

-- 	if #templates == 0 then
-- 		warn("No brainrot templates found in folder!")
-- 		return
-- 	end

-- 	for i = 1, spawnCount do
-- 		local template = templates[math.random(1, #templates)]
-- 		local clone = template:Clone()
-- 		clone.Parent = brainrotFolder
-- 		local uniqueId = CoreUtils.generateUniqueId()
-- 		clone:SetAttribute("UniqueId", uniqueId)

-- 		-- print("Generated unique ID for brainrot:", uniqueId)

-- 		-- print("Spawning brainrot from template:", template.Name)

-- 		-- Pick random cloud
-- 		local cloudChildren = clouds:GetChildren()
-- 		if #cloudChildren == 0 then
-- 			warn("No clouds found!")
-- 			return
-- 		end
-- 		local randomCloud = cloudChildren[math.random(1, #cloudChildren)]

-- 		-- Find a part in the cloud
-- 		local cloudSize, cloudPos
-- 		if randomCloud:IsA("Model") then
-- 			local part = randomCloud:FindFirstChildWhichIsA("BasePart")
-- 			if part then
-- 				cloudSize = part.Size
-- 				cloudPos = part.Position
-- 				-- print("Using part '" .. part.Name .. "' from cloud: " .. randomCloud.Name)
-- 			else
-- 				warn("Cloud model has no BaseParts: " .. randomCloud.Name)
-- 				continue
-- 			end
-- 		elseif randomCloud:IsA("BasePart") then
-- 			cloudSize = randomCloud.Size
-- 			cloudPos = randomCloud.Position
-- 		else
-- 			warn("Cloud is not a Model or Part: " .. randomCloud.ClassName)
-- 			continue
-- 		end

-- 		-- Random spawn pos inside cloud bounds
-- 		local randX = cloudPos.X + math.random(-cloudSize.X / 2, cloudSize.X / 2)
-- 		local randZ = cloudPos.Z + math.random(-cloudSize.Z / 2, cloudSize.Z / 2)
-- 		local randY = cloudPos.Y + math.random(-cloudSize.Y / 2, cloudSize.Y / 2) -- cloudPos.Y - cloudSize.Y / 2 - 5 -- slightly below cloud

-- 		local spawnPos = Vector3.new(randX, randY, randZ)
-- 		local rotation = CFrame.Angles(0, math.rad(math.random(0, 359)), 0)

-- 		clone:PivotTo(CFrame.new(spawnPos) * rotation)

-- 		-- Ensure it has a PrimaryPart
-- 		if not clone.PrimaryPart then
-- 			local firstPart = clone:FindFirstChildWhichIsA("BasePart")
-- 			if firstPart then
-- 				clone.PrimaryPart = firstPart
-- 			end
-- 		end

-- 		-- Hover in place first
-- 		for _, part in clone:GetDescendants() do
-- 			if part:IsA("BasePart") then
-- 				part.Anchored = true
-- 				part.CanCollide = true
-- 			end
-- 		end

-- 		-- Fall after delay
-- 		local fallDelay = math.random(1, 5)
-- 		task.delay(fallDelay, function()
-- 			makeBrainrotFall(clone, mainTrack, spawnPos, rotation)

-- 			task.delay(fallDelay + 2, function()
-- 				startBrainrotLifetimeTimer(clone, mainTrack)

-- 				-- Set up carrying system for this brainrot after it has fallen and settled
-- 				BrainrotCarrying.SetupBrainrot(clone)
-- 			end)
-- 		end)
-- 	end
-- end

-- function makeBrainrotFall(brainrot, mainTrack, startPos, originalRotation)
-- 	if not brainrot or not brainrot.Parent then
-- 		return
-- 	end

-- 	-- print("Starting fall for:", brainrot.Name, "from position:", startPos)

-- 	-- Calculate landing position (simplified ground detection)
-- 	local groundY = findGroundLevel(startPos, mainTrack)
-- 	local landingPos = Vector3.new(startPos.X, groundY, startPos.Z)

-- 	-- print("Ground level found at Y:", groundY, "Landing at:", landingPos)

-- 	-- Start the falling animation immediately
-- 	simulateBounceFall(brainrot, startPos, landingPos, originalRotation)
-- end

-- function findGroundLevel(startPos, mainTrack)
-- 	-- Create raycast parameters
-- 	local raycastParams = RaycastParams.new()
-- 	raycastParams.FilterType = Enum.RaycastFilterType.Include
-- 	raycastParams.FilterDescendantsInstances = { mainTrack }

-- 	-- Cast ray from start position downward
-- 	local rayDirection = Vector3.new(0, -1000, 0) -- Cast 500 studs down
-- 	local rayResult = workspace:Raycast(startPos, rayDirection, raycastParams)

-- 	if rayResult then
-- 		-- print("Ray hit at Y:", rayResult.Position.Y)
-- 		return rayResult.Position.Y -- Add 1 stud above ground
-- 	else
-- 		-- Fallback: assume ground is 50 studs below start position
-- 		-- print("No ground found, using fallback")
-- 		return startPos.Y - 50
-- 	end
-- end

-- function simulateBounceFall(brainrot, startPos, landingPos, originalRotation)
-- 	-- print("Starting bounce simulation for:", brainrot.Name)

-- 	local startTime = tick()
-- 	local fallDuration = 3 -- Total time to fall and settle (seconds)
-- 	local bounceCount = 4 -- Number of bounces
-- 	local maxBounceHeight = math.abs(startPos.Y - landingPos.Y) * 0.1 -- First bounce height
-- 	local damping = 0.6 -- Energy reduction per bounce
-- 	local currentBounce = 0
-- 	local isSettled = false

-- 	local connection
-- 	connection = RunService.Heartbeat:Connect(function()
-- 		if not brainrot or not brainrot.Parent then
-- 			if connection then
-- 				connection:Disconnect()
-- 			end
-- 			return
-- 		end

-- 		if isSettled then
-- 			connection:Disconnect()
-- 			-- Final positioning
-- 			brainrot:PivotTo(CFrame.new(landingPos) * originalRotation)

-- 			-- Enable final state
-- 			for _, part in brainrot:GetDescendants() do
-- 				if part:IsA("BasePart") then
-- 					part.Anchored = true
-- 					part.CanCollide = false -- Allow walking through
-- 				end
-- 			end

-- 			-- print("Brainrot settled:", brainrot.Name, "at position:", landingPos)
-- 			return
-- 		end

-- 		local elapsedTime = tick() - startTime
-- 		local progress = math.min(elapsedTime / fallDuration, 1)

-- 		-- Calculate current Y position
-- 		local currentY

-- 		if currentBounce == 0 then
-- 			-- Initial fall - smooth acceleration
-- 			local fallProgress = math.min(elapsedTime / 2, 1) -- Take 2 seconds to fall
-- 			currentY = startPos.Y - (startPos.Y - landingPos.Y) * (fallProgress * fallProgress)

-- 			-- Check if we hit ground
-- 			if currentY <= landingPos.Y then
-- 				currentBounce = 1
-- 				startTime = tick() -- Reset timer for bounces
-- 				-- print("Hit ground, starting bounces")
-- 			end
-- 		else
-- 			-- Bouncing phase
-- 			local bounceTime = elapsedTime % 0.5 -- Each bounce takes 0.5 seconds
-- 			local bounceProgress = bounceTime / 0.5

-- 			-- Calculate bounce height (decreasing each bounce)
-- 			local currentBounceHeight = maxBounceHeight * math.pow(damping, currentBounce - 1)

-- 			-- Sine wave for smooth bounce
-- 			currentY = landingPos.Y + math.sin(bounceProgress * math.pi) * currentBounceHeight

-- 			-- Check if this bounce cycle is complete
-- 			if bounceTime <= 0.05 and elapsedTime > 0.1 then -- Small threshold for cycle detection
-- 				currentBounce = currentBounce + 1
-- 				-- print("Bounce", currentBounce, "height:", currentBounceHeight)

-- 				-- Check if we should stop bouncing
-- 				if currentBounce > bounceCount or currentBounceHeight < 0.5 then
-- 					isSettled = true
-- 					return
-- 				end
-- 			end
-- 		end

-- 		-- Update position while maintaining rotation and X/Z position
-- 		local newPosition = Vector3.new(landingPos.X, math.max(currentY, landingPos.Y), landingPos.Z)
-- 		brainrot:PivotTo(CFrame.new(newPosition) * originalRotation)
-- 	end)
-- end

-- function startBrainrotLifetimeTimer(brainrot, mainTrack)
-- 	if not brainrot or not brainrot.Parent then
-- 		return
-- 	end
-- 	TimerService:startTimer(brainrot, 30, function(br)
-- 		-- print("Timer started for:", br.Name)
-- 		createWormholeAndRemove(br, mainTrack)
-- 	end)

-- 	-- TimerService:pauseTimer(brainrot)
-- 	-- TimerService:resumeTimer(brainrot, function(id)
-- 	-- 	createWormholeAndRemove(id, mainTrack)
-- 	-- end)
-- end

-- function createWormholeAndRemove(brainrot, mainTrack)
-- 	if not brainrot or not brainrot.Parent then
-- 		return
-- 	end

-- 	-- Get the brainrot's position
-- 	local brainrotPosition = brainrot:GetPivot().Position
-- 	local groundY = -0.6

-- 	-- IMPORTANT: Position wormhole at a reasonable height above ground
-- 	local wormholeY = math.max(groundY + 2, brainrotPosition.Y - 2) -- At least 2 studs above ground, or 2 below brainrot
-- 	local wormholePosition = Vector3.new(brainrotPosition.X, wormholeY, brainrotPosition.Z)

-- 	-- print("Final wormhole position:", wormholePosition)

-- 	-- Calculate brainrot size

-- 	-- Create the wormhole effect
-- 	local wormhole = createWormholeEffect(wormholePosition)

-- 	-- print("Created wormhole for:", brainrot.Name, "at position:", wormholePosition, "ground at:", groundY)

-- 	-- Animate the brainrot going down into the wormhole
-- 	animateBrainrotIntoWormhole(brainrot, wormholePosition, function()
-- 		-- After animation completes, remove the brainrot and wormhole
-- 		if brainrot and brainrot.Parent then
-- 			-- Notify carrying system about brainrot timeout/destruction
-- 			BrainrotCarrying.OnBrainrotTimeout(brainrot)
-- 			brainrot:Destroy()
-- 		end

-- 		-- Remove wormhole after a short delay
-- 		if wormhole and wormhole.Parent then
-- 			-- Fade out the wormhole
-- 			fadeOutWormhole(wormhole)
-- 		end
-- 	end)
-- end

-- -- Custom function to create faded stroke colors
-- function createFadedColor(baseColor, fadeAmount)
-- 	-- fadeAmount: 0 = original color, 1 = completely black
-- 	local fadedR = baseColor.R * (1 - fadeAmount)
-- 	local fadedG = baseColor.G * (1 - fadeAmount)
-- 	local fadedB = baseColor.B * (1 - fadeAmount)

-- 	return Color3.new(fadedR, fadedG, fadedB)
-- end

-- -- Custom function to create a ring with faded color
-- function createWormholeRing(name, position, size, baseColor, fadeAmount, transparency, speed, direction)
-- 	local ring = Instance.new("Part")
-- 	ring.Name = name
-- 	ring.Size = size
-- 	ring.Position = position
-- 	ring.Anchored = true
-- 	ring.CanCollide = false
-- 	ring.Material = Enum.Material.Neon
-- 	ring.Shape = Enum.PartType.Cylinder
-- 	ring.Rotation = Vector3.new(0, 0, 90)
-- 	ring.Transparency = transparency
-- 	ring.Color = createFadedColor(baseColor, fadeAmount) -- Use our custom fade function

-- 	return {
-- 		part = ring,
-- 		speed = speed,
-- 		direction = direction,
-- 	}
-- end

-- function createWormholeEffect(position)
-- 	-- Create main container model
-- 	local wormholeContainer = Instance.new("Model")
-- 	wormholeContainer.Name = "WormholeEffect"
-- 	wormholeContainer.Parent = workspace

-- 	-- Base color for the wormhole
-- 	local baseColor = Color3.new(0, 0.8, 1) -- Bright cyan

-- 	-- Ring configuration: {diameter, fadeAmount, transparency, speed, direction}
-- 	local ringConfigs = {
-- 		{ 10, 0.0, 0.1, 2, 1 }, -- Outer ring: no fade
-- 		{ 8, 0.25, 0.2, 3, -1 }, -- Ring 2: 25% fade
-- 		{ 6, 0.5, 0.25, 4, 1 }, -- Ring 3: 50% fade
-- 		{ 4, 0.75, 0.3, 5, -1 }, -- Ring 4: 75% fade
-- 		{ 2, 0.9, 0.15, 8, 1 }, -- Center: 90% fade (almost black)
-- 	}

-- 	-- Store all rings for animation
-- 	local rings = {}

-- 	-- Create rings using our custom function
-- 	for i, config in ipairs(ringConfigs) do
-- 		local diameter, fadeAmount, transparency, speed, direction = table.unpack(config)

-- 		local ringPosition = Vector3.new(
-- 			position.X,
-- 			position.Y + (i - 1) * 0.02, -- Slight Y offset for each ring
-- 			position.Z
-- 		)

-- 		local ringData = createWormholeRing(
-- 			"Ring" .. i,
-- 			ringPosition,
-- 			Vector3.new(0.1 + (i - 1) * 0.02, diameter, diameter), -- Slightly thicker for inner rings
-- 			baseColor,
-- 			fadeAmount,
-- 			transparency,
-- 			speed,
-- 			direction
-- 		)

-- 		ringData.part.Parent = wormholeContainer
-- 		table.insert(rings, ringData)
-- 	end

-- 	-- Optimized animation
-- 	local lastUpdate = 0
-- 	local updateInterval = 1 / 30

-- 	local spinConnection
-- 	spinConnection = RunService.Heartbeat:Connect(function(deltaTime)
-- 		lastUpdate = lastUpdate + deltaTime

-- 		if lastUpdate >= updateInterval then
-- 			if wormholeContainer and wormholeContainer.Parent then
-- 				-- Animate each ring
-- 				for i, ringData in ipairs(rings) do
-- 					if ringData.part and ringData.part.Parent then
-- 						local currentRotation = ringData.part.Rotation
-- 						local newY = currentRotation.Y + (ringData.speed * ringData.direction * lastUpdate * 60)
-- 						ringData.part.Rotation = Vector3.new(0, newY, 90)
-- 					end
-- 				end

-- 				-- Add pulsing effect to outer ring only
-- 				if rings[1] and rings[1].part and rings[1].part.Parent then
-- 					local pulse = math.sin(tick() * 2) * 0.05
-- 					rings[1].part.Transparency = math.max(0.1 + pulse, 0.05)
-- 				end
-- 			else
-- 				spinConnection:Disconnect()
-- 			end

-- 			lastUpdate = 0
-- 		end
-- 	end)

-- 	-- Add particle effects to outer ring
-- 	if rings[1] and rings[1].part then
-- 		local particleAttachment = Instance.new("Attachment")
-- 		particleAttachment.Parent = rings[1].part

-- 		local particles = Instance.new("ParticleEmitter")
-- 		particles.Parent = particleAttachment
-- 		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
-- 		particles.Lifetime = NumberRange.new(1.5, 2.5)
-- 		particles.Rate = 20
-- 		particles.SpreadAngle = Vector2.new(360, 360)
-- 		particles.Speed = NumberRange.new(3, 6)
-- 		particles.Color = ColorSequence.new({
-- 			ColorSequenceKeypoint.new(0, baseColor), -- Use base color
-- 			ColorSequenceKeypoint.new(1, createFadedColor(baseColor, 0.4)), -- Faded version
-- 		})
-- 		particles.Size = NumberSequence.new({
-- 			NumberSequenceKeypoint.new(0, 0.2),
-- 			NumberSequenceKeypoint.new(1, 0.1),
-- 		})
-- 		particles.Transparency = NumberSequence.new({
-- 			NumberSequenceKeypoint.new(0, 0.6),
-- 			NumberSequenceKeypoint.new(1, 1),
-- 		})
-- 	end

-- 	-- print("Enhanced wormhole with custom faded colors created at", position)
-- 	return wormholeContainer
-- end

-- function animateBrainrotIntoWormhole(brainrot, wormholePosition, onComplete)
-- 	if not brainrot or not brainrot.Parent then
-- 		if onComplete then
-- 			onComplete()
-- 		end
-- 		return
-- 	end

-- 	local startPosition = brainrot:GetPivot().Position
-- 	local endPosition = Vector3.new(wormholePosition.X, wormholePosition.Y - 8, wormholePosition.Z)
-- 	local originalCFrame = brainrot:GetPivot() -- Store the complete original CFrame (position + rotation)
-- 	local originalRotation = originalCFrame - originalCFrame.Position -- Extract just the rotation part

-- 	-- Animation parameters
-- 	local animationDuration = 5 -- 5 seconds as requested
-- 	local startTime = tick()

-- 	-- print("Starting wormhole animation for:", brainrot.Name, "maintaining original rotation")

-- 	local connection
-- 	connection = RunService.Heartbeat:Connect(function()
-- 		if not brainrot or not brainrot.Parent then
-- 			connection:Disconnect()
-- 			if onComplete then
-- 				onComplete()
-- 			end
-- 			return
-- 		end

-- 		local elapsedTime = tick() - startTime
-- 		local progress = math.min(elapsedTime / animationDuration, 1)

-- 		-- Smooth easing (ease-in-out for more natural movement)
-- 		local easedProgress = progress * progress * (3 - 2 * progress)

-- 		-- Interpolate position vertically only
-- 		local currentPosition = startPosition:Lerp(endPosition, easedProgress)

-- 		-- Keep the original rotation - NO SPINNING of the brainrot
-- 		brainrot:PivotTo(CFrame.new(currentPosition) * originalRotation)

-- 		-- Make it gradually more transparent as it goes down
-- 		local transparency = easedProgress * 0.9 -- Up to 90% transparent
-- 		for _, part in brainrot:GetDescendants() do
-- 			if part:IsA("BasePart") then
-- 				local originalTransparency = part:GetAttribute("OriginalTransparency") or part.Transparency
-- 				if not part:GetAttribute("OriginalTransparency") then
-- 					part:SetAttribute("OriginalTransparency", part.Transparency)
-- 				end
-- 				part.Transparency = math.min(originalTransparency + transparency, 1)
-- 			end
-- 		end

-- 		-- Animation complete
-- 		if progress >= 1 then
-- 			connection:Disconnect()
-- 			-- print("Wormhole animation completed for:", brainrot.Name)
-- 			if onComplete then
-- 				onComplete()
-- 			end
-- 		end
-- 	end)
-- end

-- function fadeOutWormhole(wormhole)
-- 	if not wormhole or not wormhole.Parent then
-- 		return
-- 	end

-- 	-- Fade out all parts in the wormhole model
-- 	local rings = {}
-- 	for _, part in pairs(wormhole:GetChildren()) do
-- 		if part:IsA("BasePart") then
-- 			table.insert(rings, part)
-- 		end
-- 	end

-- 	-- Create fade animation for each ring
-- 	for i, ring in ipairs(rings) do
-- 		local fadeDelay = i * 0.1 -- Stagger the fade for each ring

-- 		task.delay(fadeDelay, function()
-- 			if ring and ring.Parent then
-- 				local fadeInfo = TweenInfo.new(
-- 					1.5, -- 1.5 seconds to fade each ring
-- 					Enum.EasingStyle.Quad,
-- 					Enum.EasingDirection.Out
-- 				)

-- 				local fadeTween = TweenService:Create(ring, fadeInfo, {
-- 					Transparency = 1,
-- 					Size = ring.Size * 0.1, -- Shrink to 10% of original size
-- 				})

-- 				fadeTween:Play()
-- 			end
-- 		end)
-- 	end

-- 	-- Destroy the entire model after all rings fade
-- 	task.delay(3, function()
-- 		if wormhole and wormhole.Parent then
-- 			wormhole:Destroy()
-- 		end
-- 		-- print("Wormhole completely removed")
-- 	end)
-- end

-- return Brainrots