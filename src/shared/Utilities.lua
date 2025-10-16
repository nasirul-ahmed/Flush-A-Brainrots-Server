-- -- Utility Functions Module
-- -- Common utility functions used throughout the game

-- local Utilities = {}

-- -- Player Validation
-- function Utilities.IsValidPlayer(player)
-- 	return player and player.Parent and player:IsA("Player")
-- end

-- function Utilities.IsValidInstance(instance)
-- 	return instance and instance.Parent
-- end

-- -- Math Utilities
-- function Utilities.Round(number, decimals)
-- 	local mult = 10^(decimals or 0)
-- 	return math.floor(number * mult + 0.5) / mult
-- end

-- function Utilities.Lerp(a, b, t)
-- 	return a + (b - a) * t
-- end

-- function Utilities.Clamp(value, min, max)
-- 	return math.max(min, math.min(max, value))
-- end

-- function Utilities.RandomFloat(min, max)
-- 	return min + math.random() * (max - min)
-- end

-- -- String/Number Formatting
-- function Utilities.FormatNumber(number)
-- 	if number >= 1000000000000 then
-- 		return string.format("%.1fT", number / 1000000000000)
-- 	elseif number >= 1000000000 then
-- 		return string.format("%.1fB", number / 1000000000)
-- 	elseif number >= 1000000 then
-- 		return string.format("%.1fM", number / 1000000)
-- 	elseif number >= 1000 then
-- 		return string.format("%.1fK", number / 1000)
-- 	else
-- 		return tostring(math.floor(number))
-- 	end
-- end

-- function Utilities.AddCommas(number)
-- 	local formatted = tostring(number)
-- 	while true do
-- 		local k
-- 		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
-- 		if k == 0 then
-- 			break
-- 		end
-- 	end
-- 	return formatted
-- end

-- -- Table Utilities
-- function Utilities.DeepCopy(original)
-- 	local copy
-- 	if type(original) == 'table' then
-- 		copy = {}
-- 		for key, value in next, original, nil do
-- 			copy[Utilities.DeepCopy(key)] = Utilities.DeepCopy(value)
-- 		end
-- 		setmetatable(copy, Utilities.DeepCopy(getmetatable(original)))
-- 	else
-- 		copy = original
-- 	end
-- 	return copy
-- end

-- function Utilities.TableLength(t)
-- 	local count = 0
-- 	for _ in pairs(t) do
-- 		count = count + 1
-- 	end
-- 	return count
-- end

-- -- Time Utilities
-- function Utilities.FormatTime(seconds)
-- 	local hours = math.floor(seconds / 3600)
-- 	local minutes = math.floor((seconds % 3600) / 60)
-- 	local secs = seconds % 60
	
-- 	if hours > 0 then
-- 		return string.format("%d:%02d:%02d", hours, minutes, secs)
-- 	else
-- 		return string.format("%d:%02d", minutes, secs)
-- 	end
-- end

-- function Utilities.GetTimeStamp()
-- 	return os.time()
-- end

-- -- Distance and Position Utilities
-- function Utilities.GetDistance(pos1, pos2)
-- 	return (pos1 - pos2).Magnitude
-- end

-- function Utilities.GetDistanceXZ(pos1, pos2)
-- 	local diff = pos1 - pos2
-- 	return Vector2.new(diff.X, diff.Z).Magnitude
-- end

-- function Utilities.IsWithinRange(pos1, pos2, range)
-- 	return Utilities.GetDistance(pos1, pos2) <= range
-- end

-- -- Random Utilities
-- function Utilities.WeightedRandom(weights)
-- 	local totalWeight = 0
-- 	for _, weight in pairs(weights) do
-- 		totalWeight = totalWeight + weight
-- 	end
	
-- 	local random = math.random() * totalWeight
-- 	local currentWeight = 0
	
-- 	for option, weight in pairs(weights) do
-- 		currentWeight = currentWeight + weight
-- 		if random <= currentWeight then
-- 			return option
-- 		end
-- 	end
	
-- 	-- Fallback - return first option
-- 	for option, _ in pairs(weights) do
-- 		return option
-- 	end
	
-- 	-- If no options exist, return nil
-- 	return nil
-- end

-- -- Array/List Utilities
-- function Utilities.Shuffle(array)
-- 	local result = Utilities.DeepCopy(array)
-- 	for i = #result, 2, -1 do
-- 		local j = math.random(i)
-- 		result[i], result[j] = result[j], result[i]
-- 	end
-- 	return result
-- end

-- function Utilities.GetRandomFromArray(array)
-- 	if #array == 0 then return nil end
-- 	return array[math.random(#array)]
-- end

-- -- Cooldown System
-- local cooldowns = {}

-- function Utilities.SetCooldown(key, duration)
-- 	cooldowns[key] = tick() + duration
-- end

-- function Utilities.IsOnCooldown(key)
-- 	local endTime = cooldowns[key]
-- 	if not endTime then return false end
	
-- 	if tick() >= endTime then
-- 		cooldowns[key] = nil
-- 		return false
-- 	end
	
-- 	return true
-- end

-- function Utilities.GetCooldownRemaining(key)
-- 	local endTime = cooldowns[key]
-- 	if not endTime then return 0 end
	
-- 	return math.max(0, endTime - tick())
-- end

-- return Utilities