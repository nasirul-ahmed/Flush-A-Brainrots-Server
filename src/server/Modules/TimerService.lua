local RunService = game:GetService("RunService")

local TimerService = {}
TimerService.__index = TimerService

local activeTimers = {}
local pausedTimers = {}

function TimerService:startTimer(id, duration, callback)
	if activeTimers[id] then
		self:cancelTimer(id)
	end

	activeTimers[id] = {
		startTime = tick(),
		duration = duration,
		callback = callback,
		connection = nil,
	}
	
	local timer = activeTimers[id]

	timer.connection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - timer.startTime
		if elapsed >= timer.duration then
			self:cancelTimer(id)
			if timer.callback then
				timer.callback(id)
			end
		end
	end)
end

function TimerService:pauseTimer(id)
	local timer = activeTimers[id]
	if not timer then return end

	pausedTimers[id] = {
		remaining = timer.duration - (tick() - timer.startTime),
		callback = timer.callback,
	}
	self:cancelTimer(id)
end

function TimerService:resumeTimer(id)
	local paused = pausedTimers[id]
	if not paused then return end

	self:startTimer(id, paused.remaining, paused.callback)
	pausedTimers[id] = nil
end

function TimerService:cancelTimer(id)
	local timer = activeTimers[id]
	if timer then
		if timer.connection then
			timer.connection:Disconnect()
		end
		activeTimers[id] = nil
	end
end

function TimerService:isActive(id)
	return activeTimers[id] ~= nil
end

function TimerService:isPaused(id)
	return pausedTimers[id] ~= nil
end

return TimerService
