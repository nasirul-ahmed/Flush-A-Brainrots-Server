-- print("Flush a Brainrot client initialized!")

-- -- Welcome message
-- game:GetService("StarterGui"):SetCore("SendNotification", {
-- 	Title = "Welcome to Flush a Brainrot!",
-- 	Text = "Build your toilet empire! 🚽💩",
-- 	Duration = 5,
-- })

-- -- Load client systems after a short delay
-- wait(2)

-- -- Safely require client modules
-- spawn(function()
-- 	local success, err = pcall(function()
-- 		require(script.Parent:WaitForChild("ToiletShopUI"))
-- 	end)
-- 	if success then
-- 		print("ToiletShopUI loaded")
-- 	else
-- 		warn("Failed to load ToiletShopUI:", err)
-- 	end
-- end)

-- spawn(function()
-- 	local success, err = pcall(function()
-- 		require(script.Parent:WaitForChild("StatsUI"))
-- 	end)
-- 	if success then
-- 		print("StatsUI loaded")
-- 	else
-- 		warn("Failed to load StatsUI:", err)
-- 	end
-- end)
