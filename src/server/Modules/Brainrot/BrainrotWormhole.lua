local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.BrainrotConfig)
local BrainrotCarrying = require(script.Parent.BrainrotCarrying)

local BrainrotWormhole = {}

-- Helper Functions
local function createFadedColor(baseColor, fadeAmount)
	local fadedR = baseColor.R * (1 - fadeAmount)
	local fadedG = baseColor.G * (1 - fadeAmount)
	local fadedB = baseColor.B * (1 - fadeAmount)
	return Color3.new(fadedR, fadedG, fadedB)
end

local function createWormholeRing(name, position, size, baseColor, fadeAmount, transparency, speed, direction)
	local ring = Instance.new("Part")
	ring.Name = name
	ring.Size = size
	ring.Position = position
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Shape = Enum.PartType.Cylinder
	ring.Rotation = Vector3.new(0, 0, 90)
	ring.Transparency = transparency
	ring.Color = createFadedColor(baseColor, fadeAmount)

	return {
		part = ring,
		speed = speed,
		direction = direction,
	}
end

local function createWormholeEffect(position)
	local wormholeContainer = Instance.new("Model")
	wormholeContainer.Name = "WormholeEffect"
	wormholeContainer.Parent = workspace

	local baseColor = Config.WORMHOLE_BASE_COLOR

	-- Ring configuration: {diameter, fadeAmount, transparency, speed, direction}
	local ringConfigs = {
		{ 10, 0.0, 0.1, 2, 1 }, -- Outer ring: no fade
		{ 8, 0.25, 0.2, 3, -1 }, -- Ring 2: 25% fade
		{ 6, 0.5, 0.25, 4, 1 }, -- Ring 3: 50% fade
		{ 4, 0.75, 0.3, 5, -1 }, -- Ring 4: 75% fade
		{ 2, 0.9, 0.15, 8, 1 }, -- Center: 90% fade (almost black)
	}

	local rings = {}

	for i, config in ipairs(ringConfigs) do
		local diameter, fadeAmount, transparency, speed, direction = table.unpack(config)

		local ringPosition = Vector3.new(position.X, position.Y + (i - 1) * 0.02, position.Z)

		local ringData = createWormholeRing(
			"Ring" .. i,
			ringPosition,
			Vector3.new(0.1 + (i - 1) * 0.02, diameter, diameter),
			baseColor,
			fadeAmount,
			transparency,
			speed,
			direction
		)

		ringData.part.Parent = wormholeContainer
		table.insert(rings, ringData)
	end

	-- Animation
	local lastUpdate = 0
	local updateInterval = 1 / 30

	local spinConnection
	spinConnection = RunService.Heartbeat:Connect(function(deltaTime)
		lastUpdate = lastUpdate + deltaTime

		if lastUpdate >= updateInterval then
			if wormholeContainer and wormholeContainer.Parent then
				for i, ringData in ipairs(rings) do
					if ringData.part and ringData.part.Parent then
						local currentRotation = ringData.part.Rotation
						local newY = currentRotation.Y + (ringData.speed * ringData.direction * lastUpdate * 60)
						ringData.part.Rotation = Vector3.new(0, newY, 90)
					end
				end

				if rings[1] and rings[1].part and rings[1].part.Parent then
					local pulse = math.sin(tick() * 2) * 0.05
					rings[1].part.Transparency = math.max(0.1 + pulse, 0.05)
				end
			else
				spinConnection:Disconnect()
			end

			lastUpdate = 0
		end
	end)

	-- Particle effects
	if rings[1] and rings[1].part then
		local particleAttachment = Instance.new("Attachment")
		particleAttachment.Parent = rings[1].part

		local particles = Instance.new("ParticleEmitter")
		particles.Parent = particleAttachment
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Lifetime = NumberRange.new(1.5, 2.5)
		particles.Rate = 20
		particles.SpreadAngle = Vector2.new(360, 360)
		particles.Speed = NumberRange.new(3, 6)
		particles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, baseColor),
			ColorSequenceKeypoint.new(1, createFadedColor(baseColor, 0.4)),
		})
		particles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 0.1),
		})
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		})
	end

	return wormholeContainer
end

local function animateBrainrotIntoWormhole(brainrot, wormholePosition, onComplete)
	if not brainrot or not brainrot.Parent then
		if onComplete then
			onComplete()
		end
		return
	end

	local startPosition = brainrot:GetPivot().Position
	local endPosition = Vector3.new(wormholePosition.X, wormholePosition.Y - 8, wormholePosition.Z)
	local originalCFrame = brainrot:GetPivot()
	local originalRotation = originalCFrame - originalCFrame.Position

	local animationDuration = Config.WORMHOLE_ANIMATION_DURATION
	local startTime = tick()

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not brainrot or not brainrot.Parent then
			connection:Disconnect()
			if onComplete then
				onComplete()
			end
			return
		end

		local elapsedTime = tick() - startTime
		local progress = math.min(elapsedTime / animationDuration, 1)

		-- Smooth easing
		local easedProgress = progress * progress * (3 - 2 * progress)

		-- Interpolate position
		local currentPosition = startPosition:Lerp(endPosition, easedProgress)

		brainrot:PivotTo(CFrame.new(currentPosition) * originalRotation)

		-- Fade transparency
		local transparency = easedProgress * 0.9
		for _, part in brainrot:GetDescendants() do
			if part:IsA("BasePart") then
				local originalTransparency = part:GetAttribute("OriginalTransparency") or part.Transparency
				if not part:GetAttribute("OriginalTransparency") then
					part:SetAttribute("OriginalTransparency", part.Transparency)
				end
				part.Transparency = math.min(originalTransparency + transparency, 1)
			end
		end

		if progress >= 1 then
			connection:Disconnect()
			if onComplete then
				onComplete()
			end
		end
	end)
end

local function fadeOutWormhole(wormhole)
	if not wormhole or not wormhole.Parent then
		return
	end

	local rings = {}
	for _, part in pairs(wormhole:GetChildren()) do
		if part:IsA("BasePart") then
			table.insert(rings, part)
		end
	end

	for i, ring in ipairs(rings) do
		local fadeDelay = i * 0.1

		task.delay(fadeDelay, function()
			if ring and ring.Parent then
				local fadeInfo =
					TweenInfo.new(Config.WORMHOLE_FADE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

				local fadeTween = TweenService:Create(ring, fadeInfo, {
					Transparency = 1,
					Size = ring.Size * 0.1,
				})

				fadeTween:Play()
			end
		end)
	end

	task.delay(3, function()
		if wormhole and wormhole.Parent then
			wormhole:Destroy()
		end
	end)
end

-- Public API
function BrainrotWormhole.createAndRemove(brainrot, mainTrack)
	if not brainrot or not brainrot.Parent then
		return
	end

	local brainrotPosition = brainrot:GetPivot().Position
	local groundY = Config.GROUND_LEVEL

	local wormholeY = math.max(groundY + 2, brainrotPosition.Y - 2)
	local wormholePosition = Vector3.new(brainrotPosition.X, wormholeY, brainrotPosition.Z)

	local wormhole = createWormholeEffect(wormholePosition)

	animateBrainrotIntoWormhole(brainrot, wormholePosition, function()
		if brainrot and brainrot.Parent then
			BrainrotCarrying.OnBrainrotTimeout(brainrot)
			brainrot:Destroy()
		end

		if wormhole and wormhole.Parent then
			fadeOutWormhole(wormhole)
		end
	end)
end

return BrainrotWormhole
