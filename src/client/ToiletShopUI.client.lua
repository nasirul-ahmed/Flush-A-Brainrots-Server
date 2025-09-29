-- -- Client-side Toilet Shop UI
-- -- Manages the toilet shop interface and interactions

-- local Players = game:GetService("Players")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local TweenService = game:GetService("TweenService")

-- local player = Players.LocalPlayer
-- local playerGui = player:WaitForChild("PlayerGui")

-- -- Wait for shared modules
-- local Shared = ReplicatedStorage:WaitForChild("Shared")
-- local GameConfig = Shared:WaitForChild("GameConfig")
-- local Utilities = Shared:WaitForChild("Utilities")
-- local Events = Shared:WaitForChild("Events")

-- local ToiletShopUI = {}

-- -- UI Elements
-- local shopGui = nil
-- local mainFrame = nil
-- local shopData = nil
-- local selectedToiletSlot = nil

-- -- Initialize shop UI system
-- function ToiletShopUI.Init()
-- 	print("Toilet Shop UI initialized!")
	
-- 	-- Set up event connections
-- 	ToiletShopUI.SetupEvents()
	
-- 	-- Create base GUI
-- 	ToiletShopUI.CreateBaseGui()
-- end

-- -- Set up event connections
-- function ToiletShopUI.SetupEvents()
-- 	-- Handle shop opening
-- 	Events.ConnectToServerEvent("OpenToiletShop", function(data)
-- 		ToiletShopUI.OpenShop(data)
-- 	end)
	
-- 	-- Handle notifications
-- 	Events.ConnectToServerEvent("ShowNotification", function(message, type)
-- 		ToiletShopUI.ShowNotification(message, type)
-- 	end)
-- end

-- -- Create base GUI elements
-- function ToiletShopUI.CreateBaseGui()
-- 	-- Main ScreenGui
-- 	shopGui = Instance.new("ScreenGui")
-- 	shopGui.Name = "ToiletShopGui"
-- 	shopGui.ResetOnSpawn = false
-- 	shopGui.Parent = playerGui
	
-- 	-- Main frame (initially hidden)
-- 	mainFrame = Instance.new("Frame")
-- 	mainFrame.Name = "ShopFrame"
-- 	mainFrame.Size = UDim2.new(0, 800, 0, 600)
-- 	mainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
-- 	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
-- 	mainFrame.BorderSizePixel = 0
-- 	mainFrame.Visible = false
-- 	mainFrame.Parent = shopGui
	
-- 	-- Corner rounding
-- 	local corner = Instance.new("UICorner")
-- 	corner.CornerRadius = UDim.new(0, 15)
-- 	corner.Parent = mainFrame
	
-- 	-- Background decoration
-- 	local titleBar = Instance.new("Frame")
-- 	titleBar.Name = "TitleBar"
-- 	titleBar.Size = UDim2.new(1, 0, 0, 60)
-- 	titleBar.Position = UDim2.new(0, 0, 0, 0)
-- 	titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
-- 	titleBar.BorderSizePixel = 0
-- 	titleBar.Parent = mainFrame
	
-- 	local titleCorner = Instance.new("UICorner")
-- 	titleCorner.CornerRadius = UDim.new(0, 15)
-- 	titleCorner.Parent = titleBar
	
-- 	-- Title text
-- 	local titleLabel = Instance.new("TextLabel")
-- 	titleLabel.Name = "Title"
-- 	titleLabel.Size = UDim2.new(1, -60, 1, 0)
-- 	titleLabel.Position = UDim2.new(0, 10, 0, 0)
-- 	titleLabel.BackgroundTransparency = 1
-- 	titleLabel.Text = "🚽 TOILET SHOP 🚽"
-- 	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
-- 	titleLabel.TextScaled = true
-- 	titleLabel.Font = Enum.Font.GothamBold
-- 	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
-- 	titleLabel.Parent = titleBar
	
-- 	-- Close button
-- 	local closeButton = Instance.new("TextButton")
-- 	closeButton.Name = "CloseButton"
-- 	closeButton.Size = UDim2.new(0, 40, 0, 40)
-- 	closeButton.Position = UDim2.new(1, -50, 0, 10)
-- 	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
-- 	closeButton.Text = "✕"
-- 	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
-- 	closeButton.TextScaled = true
-- 	closeButton.Font = Enum.Font.GothamBold
-- 	closeButton.BorderSizePixel = 0
-- 	closeButton.Parent = titleBar
	
-- 	local closeCorner = Instance.new("UICorner")
-- 	closeCorner.CornerRadius = UDim.new(0, 8)
-- 	closeCorner.Parent = closeButton
	
-- 	-- Close button connection
-- 	closeButton.MouseButton1Click:Connect(function()
-- 		ToiletShopUI.CloseShop()
-- 	end)
	
-- 	-- Money display
-- 	local moneyLabel = Instance.new("TextLabel")
-- 	moneyLabel.Name = "MoneyLabel"
-- 	moneyLabel.Size = UDim2.new(0, 200, 0, 30)
-- 	moneyLabel.Position = UDim2.new(0, 10, 0, 70)
-- 	moneyLabel.BackgroundTransparency = 1
-- 	moneyLabel.Text = "💰 Money: 0"
-- 	moneyLabel.TextColor3 = GameConfig.COLORS.Money
-- 	moneyLabel.TextScaled = true
-- 	moneyLabel.Font = Enum.Font.Gotham
-- 	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
-- 	moneyLabel.Parent = mainFrame
-- end

-- -- Open shop with data
-- function ToiletShopUI.OpenShop(data)
-- 	shopData = data
-- 	selectedToiletSlot = nil
	
-- 	-- Update money display
-- 	local moneyLabel = mainFrame:FindFirstChild("MoneyLabel")
-- 	if moneyLabel then
-- 		moneyLabel.Text = "💰 Money: " .. Utilities.FormatNumber(data.playerMoney)
-- 	end
	
-- 	-- Clear existing content
-- 	ToiletShopUI.ClearShopContent()
	
-- 	-- Create shop content
-- 	ToiletShopUI.CreateShopContent()
	
-- 	-- Show the shop
-- 	mainFrame.Visible = true
	
-- 	-- Animate entrance
-- 	mainFrame.Size = UDim2.new(0, 0, 0, 0)
-- 	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	
-- 	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
-- 		Size = UDim2.new(0, 800, 0, 600),
-- 		Position = UDim2.new(0.5, -400, 0.5, -300)
-- 	})
-- 	tween:Play()
-- end

-- -- Create shop content
-- function ToiletShopUI.CreateShopContent()
-- 	-- Current toilets section
-- 	local currentToiletsFrame = Instance.new("Frame")
-- 	currentToiletsFrame.Name = "CurrentToilets"
-- 	currentToiletsFrame.Size = UDim2.new(1, -20, 0, 120)
-- 	currentToiletsFrame.Position = UDim2.new(0, 10, 0, 110)
-- 	currentToiletsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
-- 	currentToiletsFrame.BorderSizePixel = 0
-- 	currentToiletsFrame.Parent = mainFrame
	
-- 	local currentCorner = Instance.new("UICorner")
-- 	currentCorner.CornerRadius = UDim.new(0, 8)
-- 	currentCorner.Parent = currentToiletsFrame
	
-- 	-- Current toilets title
-- 	local currentTitle = Instance.new("TextLabel")
-- 	currentTitle.Size = UDim2.new(1, -10, 0, 30)
-- 	currentTitle.Position = UDim2.new(0, 5, 0, 5)
-- 	currentTitle.BackgroundTransparency = 1
-- 	currentTitle.Text = "Your Current Toilets:"
-- 	currentTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
-- 	currentTitle.TextScaled = true
-- 	currentTitle.Font = Enum.Font.GothamBold
-- 	currentTitle.TextXAlignment = Enum.TextXAlignment.Left
-- 	currentTitle.Parent = currentToiletsFrame
	
-- 	-- Create toilet slots
-- 	for i = 1, GameConfig.STARTING_TOILETS do
-- 		ToiletShopUI.CreateToiletSlot(currentToiletsFrame, i)
-- 	end
	
-- 	-- Available toilets section
-- 	local availableFrame = Instance.new("Frame")
-- 	availableFrame.Name = "AvailableToilets"
-- 	availableFrame.Size = UDim2.new(1, -20, 1, -250)
-- 	availableFrame.Position = UDim2.new(0, 10, 0, 240)
-- 	availableFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
-- 	availableFrame.BorderSizePixel = 0
-- 	availableFrame.Parent = mainFrame
	
-- 	local availableCorner = Instance.new("UICorner")
-- 	availableCorner.CornerRadius = UDim.new(0, 8)
-- 	availableCorner.Parent = availableFrame
	
-- 	-- Available toilets title
-- 	local availableTitle = Instance.new("TextLabel")
-- 	availableTitle.Size = UDim2.new(1, -10, 0, 30)
-- 	availableTitle.Position = UDim2.new(0, 5, 0, 5)
-- 	availableTitle.BackgroundTransparency = 1
-- 	availableTitle.Text = "Available Toilet Upgrades:"
-- 	availableTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
-- 	availableTitle.TextScaled = true
-- 	availableTitle.Font = Enum.Font.GothamBold
-- 	availableTitle.TextXAlignment = Enum.TextXAlignment.Left
-- 	availableTitle.Parent = availableFrame
	
-- 	-- Scrolling frame for available toilets
-- 	local scrollFrame = Instance.new("ScrollingFrame")
-- 	scrollFrame.Size = UDim2.new(1, -10, 1, -40)
-- 	scrollFrame.Position = UDim2.new(0, 5, 0, 35)
-- 	scrollFrame.BackgroundTransparency = 1
-- 	scrollFrame.BorderSizePixel = 0
-- 	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
-- 	scrollFrame.ScrollBarThickness = 6
-- 	scrollFrame.Parent = availableFrame
	
-- 	-- Create available toilet items
-- 	ToiletShopUI.CreateAvailableToilets(scrollFrame)
-- end

-- -- Create toilet slot display
-- function ToiletShopUI.CreateToiletSlot(parent, slotIndex)
-- 	local toiletData = shopData.currentToilets[slotIndex]
-- 	if not toiletData then return end
	
-- 	local slot = Instance.new("TextButton")
-- 	slot.Name = "ToiletSlot" .. slotIndex
-- 	slot.Size = UDim2.new(0, 180, 0, 80)
-- 	slot.Position = UDim2.new(0, 10 + ((slotIndex - 1) * 190), 0, 35)
-- 	slot.BackgroundColor3 = toiletData.canUpgrade and Color3.fromRGB(60, 100, 60) or Color3.fromRGB(100, 60, 60)
-- 	slot.BorderSizePixel = 0
-- 	slot.Parent = parent
	
-- 	local slotCorner = Instance.new("UICorner")
-- 	slotCorner.CornerRadius = UDim.new(0, 6)
-- 	slotCorner.Parent = slot
	
-- 	-- Toilet type label
-- 	local typeLabel = Instance.new("TextLabel")
-- 	typeLabel.Size = UDim2.new(1, -10, 0.6, 0)
-- 	typeLabel.Position = UDim2.new(0, 5, 0, 5)
-- 	typeLabel.BackgroundTransparency = 1
-- 	typeLabel.Text = "🚽 " .. toiletData.type .. " Toilet"
-- 	typeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
-- 	typeLabel.TextScaled = true
-- 	typeLabel.Font = Enum.Font.GothamBold
-- 	typeLabel.Parent = slot
	
-- 	-- Status label
-- 	local statusLabel = Instance.new("TextLabel")
-- 	statusLabel.Size = UDim2.new(1, -10, 0.4, 0)
-- 	statusLabel.Position = UDim2.new(0, 5, 0.6, 0)
-- 	statusLabel.BackgroundTransparency = 1
-- 	statusLabel.Text = toiletData.isActive and "🔄 Flushing..." or (toiletData.canUpgrade and "✅ Ready" or "❌ Busy")
-- 	statusLabel.TextColor3 = toiletData.canUpgrade and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
-- 	statusLabel.TextScaled = true
-- 	statusLabel.Font = Enum.Font.Gotham
-- 	statusLabel.Parent = slot
	
-- 	-- Click handler
-- 	slot.MouseButton1Click:Connect(function()
-- 		if toiletData.canUpgrade then
-- 			ToiletShopUI.SelectToiletSlot(slotIndex)
-- 		end
-- 	end)
-- end

-- -- Create available toilet items
-- function ToiletShopUI.CreateAvailableToilets(parent)
-- 	local yOffset = 10
	
-- 	for toiletType, config in pairs(shopData.toiletTypes) do
-- 		ToiletShopUI.CreateToiletItem(parent, toiletType, config, yOffset)
-- 		yOffset = yOffset + 100
-- 	end
	
-- 	-- Update canvas size
-- 	parent.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)
-- end

-- -- Create individual toilet item
-- function ToiletShopUI.CreateToiletItem(parent, toiletType, config, yOffset)
-- 	local item = Instance.new("Frame")
-- 	item.Name = "ToiletItem_" .. toiletType
-- 	item.Size = UDim2.new(1, -20, 0, 90)
-- 	item.Position = UDim2.new(0, 10, 0, yOffset)
-- 	item.BackgroundColor3 = config.isAffordable and Color3.fromRGB(50, 70, 50) or Color3.fromRGB(70, 50, 50)
-- 	item.BorderSizePixel = 0
-- 	item.Parent = parent
	
-- 	local itemCorner = Instance.new("UICorner")
-- 	itemCorner.CornerRadius = UDim.new(0, 8)
-- 	itemCorner.Parent = item
	
-- 	-- Toilet name
-- 	local nameLabel = Instance.new("TextLabel")
-- 	nameLabel.Size = UDim2.new(0.4, 0, 0.4, 0)
-- 	nameLabel.Position = UDim2.new(0, 10, 0, 5)
-- 	nameLabel.BackgroundTransparency = 1
-- 	nameLabel.Text = config.name
-- 	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
-- 	nameLabel.TextScaled = true
-- 	nameLabel.Font = Enum.Font.GothamBold
-- 	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
-- 	nameLabel.Parent = item
	
-- 	-- Stats display
-- 	local statsLabel = Instance.new("TextLabel")
-- 	statsLabel.Size = UDim2.new(0.6, -20, 0.6, 0)
-- 	statsLabel.Position = UDim2.new(0, 10, 0.4, 0)
-- 	statsLabel.BackgroundTransparency = 1
-- 	statsLabel.Text = string.format("💰 %.1fx Money | 💪 %.1fx Strength | ⚡ %.1fx Speed", 
-- 		config.moneyMultiplier, config.strengthMultiplier, config.flushTimeMultiplier)
-- 	statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
-- 	statsLabel.TextScaled = true
-- 	statsLabel.Font = Enum.Font.Gotham
-- 	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
-- 	statsLabel.TextWrapped = true
-- 	statsLabel.Parent = item
	
-- 	-- Price and buy button
-- 	local buyButton = Instance.new("TextButton")
-- 	buyButton.Size = UDim2.new(0.25, -10, 1, -10)
-- 	buyButton.Position = UDim2.new(0.75, 0, 0, 5)
-- 	buyButton.BackgroundColor3 = config.isAffordable and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(100, 100, 100)
-- 	buyButton.BorderSizePixel = 0
-- 	buyButton.Parent = item
	
-- 	local buyCorner = Instance.new("UICorner")
-- 	buyCorner.CornerRadius = UDim.new(0, 6)
-- 	buyCorner.Parent = buyButton
	
-- 	-- Price text
-- 	local priceText = (config.currency == "Robux") and ("R$ " .. config.cost) or ("💰 " .. Utilities.FormatNumber(config.cost))
-- 	buyButton.Text = config.isAffordable and ("BUY\n" .. priceText) or ("NEED\n" .. priceText)
-- 	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
-- 	buyButton.TextScaled = true
-- 	buyButton.Font = Enum.Font.GothamBold
	
-- 	-- Buy button handler
-- 	buyButton.MouseButton1Click:Connect(function()
-- 		if selectedToiletSlot and config.isAffordable then
-- 			ToiletShopUI.PurchaseToilet(toiletType)
-- 		elseif not selectedToiletSlot then
-- 			ToiletShopUI.ShowNotification("Select a toilet slot first!", "Warning")
-- 		else
-- 			local currency = config.currency == "Robux" and "Robux" or "money"
-- 			ToiletShopUI.ShowNotification("Not enough " .. currency .. "!", "Error")
-- 		end
-- 	end)
	
-- 	return item
-- end

-- -- Select toilet slot
-- function ToiletShopUI.SelectToiletSlot(slotIndex)
-- 	selectedToiletSlot = slotIndex
	
-- 	-- Update visual feedback for all slots
-- 	local currentToiletsFrame = mainFrame:FindFirstChild("CurrentToilets")
-- 	if currentToiletsFrame then
-- 		for i = 1, GameConfig.STARTING_TOILETS do
-- 			local slot = currentToiletsFrame:FindFirstChild("ToiletSlot" .. i)
-- 			if slot then
-- 				if i == slotIndex then
-- 					slot.BackgroundColor3 = Color3.fromRGB(100, 150, 100) -- Selected
-- 				else
-- 					local toiletData = shopData.currentToilets[i]
-- 					slot.BackgroundColor3 = toiletData.canUpgrade and Color3.fromRGB(60, 100, 60) or Color3.fromRGB(100, 60, 60)
-- 				end
-- 			end
-- 		end
-- 	end
	
-- 	ToiletShopUI.ShowNotification("Selected toilet slot " .. slotIndex, "Info")
-- end

-- -- Purchase toilet
-- function ToiletShopUI.PurchaseToilet(toiletType)
-- 	if not selectedToiletSlot then
-- 		ToiletShopUI.ShowNotification("Select a toilet slot first!", "Warning")
-- 		return
-- 	end
	
-- 	-- Send purchase request to server
-- 	Events.FireServer("PurchaseToilet", toiletType, selectedToiletSlot)
-- end

-- -- Close shop
-- function ToiletShopUI.CloseShop()
-- 	if mainFrame then
-- 		local tween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
-- 			Size = UDim2.new(0, 0, 0, 0),
-- 			Position = UDim2.new(0.5, 0, 0.5, 0)
-- 		})
		
-- 		tween:Play()
-- 		tween.Completed:Connect(function()
-- 			mainFrame.Visible = false
-- 			selectedToiletSlot = nil
-- 		end)
-- 	end
-- end

-- -- Clear shop content
-- function ToiletShopUI.ClearShopContent()
-- 	for _, child in pairs(mainFrame:GetChildren()) do
-- 		if child.Name == "CurrentToilets" or child.Name == "AvailableToilets" then
-- 			child:Destroy()
-- 		end
-- 	end
-- end

-- -- Show notification
-- function ToiletShopUI.ShowNotification(message, notificationType)
-- 	-- Create notification
-- 	local notification = Instance.new("Frame")
-- 	notification.Size = UDim2.new(0, 300, 0, 60)
-- 	notification.Position = UDim2.new(1, -320, 0, 20)
-- 	notification.BackgroundColor3 = notificationType == "Success" and Color3.fromRGB(50, 150, 50) or
-- 		notificationType == "Error" and Color3.fromRGB(150, 50, 50) or
-- 		notificationType == "Warning" and Color3.fromRGB(150, 150, 50) or
-- 		Color3.fromRGB(50, 50, 150)
-- 	notification.BorderSizePixel = 0
-- 	notification.Parent = playerGui
	
-- 	local notifCorner = Instance.new("UICorner")
-- 	notifCorner.CornerRadius = UDim.new(0, 8)
-- 	notifCorner.Parent = notification
	
-- 	local notifLabel = Instance.new("TextLabel")
-- 	notifLabel.Size = UDim2.new(1, -10, 1, 0)
-- 	notifLabel.Position = UDim2.new(0, 5, 0, 0)
-- 	notifLabel.BackgroundTransparency = 1
-- 	notifLabel.Text = message
-- 	notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
-- 	notifLabel.TextScaled = true
-- 	notifLabel.Font = Enum.Font.Gotham
-- 	notifLabel.TextWrapped = true
-- 	notifLabel.Parent = notification
	
-- 	-- Animate in
-- 	local tween1 = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
-- 		Position = UDim2.new(1, -320, 0, 20)
-- 	})
-- 	tween1:Play()
	
-- 	-- Animate out after delay
-- 	wait(3)
-- 	local tween2 = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
-- 		Position = UDim2.new(1, 10, 0, 20)
-- 	})
-- 	tween2:Play()
	
-- 	tween2.Completed:Connect(function()
-- 		notification:Destroy()
-- 	end)
-- end

-- -- Initialize when script loads
-- ToiletShopUI.Init()

-- return ToiletShopUI