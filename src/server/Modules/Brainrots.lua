-- Brainrots.script.lua
local Brainrots = {}

function Brainrots.spawnBrainrot(brainrotFolder, templateFolder, mainTrack, spawnCount)
	if not templateFolder or not mainTrack then
		warn("Brainrot template folder or main track not found!")
		return
	end

	local templates = {}
	for _, obj in templateFolder:GetChildren() do
		if obj:IsA("Model") or obj:IsA("Part") then
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

		local size = mainTrack.Size
		local pos = mainTrack.Position

		local randX = pos.X + math.random(-size.X / 2, size.X / 2)
		local randZ = pos.Z + math.random(-size.Z / 2, size.Z / 2)
		local y = pos.Y + size.Y / 2

		local spawnPos = Vector3.new(randX, y, randZ)
		local rotation = CFrame.Angles(0, math.rad(math.random(0, 359)), 0)

		clone:PivotTo(CFrame.new(spawnPos) * rotation)
	end
end

return Brainrots
