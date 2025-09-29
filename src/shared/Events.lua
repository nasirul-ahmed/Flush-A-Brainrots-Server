-- Events System for Client-Server Communication
-- Manages RemoteEvents and RemoteFunctions

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = {}

-- Create events folder in ReplicatedStorage
local eventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "RemoteEvents"
	eventsFolder.Parent = ReplicatedStorage
end

-- Remote Events List
local remoteEventNames = {
	"UpdatePlayerStats",
	"RequestPlayerStats", 
	"PlaySound",
	"ShowNotification",
	"OpenToiletShop",
	"PurchaseToilet",
	"PickupBrainrot",
	"DropBrainrot",
	"FlushToilet",
	"CollectStrength",
	"UpdateLeaderboard"
}

-- Remote Functions List  
local remoteFunctionNames = {
	"GetPlayerStats",
	"GetShopData",
	"CanPickupBrainrot",
	"GetToiletData"
}

-- Create RemoteEvents
Events.RemoteEvents = {}
for _, eventName in pairs(remoteEventNames) do
	local remoteEvent = eventsFolder:FindFirstChild(eventName)
	if not remoteEvent then
		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = eventName
		remoteEvent.Parent = eventsFolder
	end
	Events.RemoteEvents[eventName] = remoteEvent
end

-- Create RemoteFunctions
Events.RemoteFunctions = {}
for _, functionName in pairs(remoteFunctionNames) do
	local remoteFunction = eventsFolder:FindFirstChild(functionName)
	if not remoteFunction then
		remoteFunction = Instance.new("RemoteFunction")
		remoteFunction.Name = functionName
		remoteFunction.Parent = eventsFolder
	end
	Events.RemoteFunctions[functionName] = remoteFunction
end

-- Server-side helper functions
if game:GetService("RunService"):IsServer() then
	
	function Events.FireClient(player, eventName, ...)
		local event = Events.RemoteEvents[eventName]
		if event and player then
			event:FireClient(player, ...)
		else
			warn("Failed to fire client event: " .. tostring(eventName))
		end
	end
	
	function Events.FireAllClients(eventName, ...)
		local event = Events.RemoteEvents[eventName]
		if event then
			event:FireAllClients(...)
		else
			warn("Failed to fire all clients event: " .. tostring(eventName))
		end
	end
	
	function Events.SetRemoteFunction(functionName, callback)
		local func = Events.RemoteFunctions[functionName]
		if func then
			func.OnServerInvoke = callback
		else
			warn("Remote function not found: " .. tostring(functionName))
		end
	end

-- Client-side helper functions  
else
	
	function Events.FireServer(eventName, ...)
		local event = Events.RemoteEvents[eventName]
		if event then
			event:FireServer(...)
		else
			warn("Failed to fire server event: " .. tostring(eventName))
		end
	end
	
	function Events.InvokeServer(functionName, ...)
		local func = Events.RemoteFunctions[functionName]
		if func then
			return func:InvokeServer(...)
		else
			warn("Remote function not found: " .. tostring(functionName))
			return nil
		end
	end
	
	function Events.ConnectToServerEvent(eventName, callback)
		local event = Events.RemoteEvents[eventName]
		if event then
			return event.OnClientEvent:Connect(callback)
		else
			warn("Remote event not found: " .. tostring(eventName))
			return nil
		end
	end

end

print("Events system initialized with " .. #remoteEventNames .. " RemoteEvents and " .. #remoteFunctionNames .. " RemoteFunctions")

return Events