local RunService = game:GetService("RunService")

local Packages = script.Parent.Parent

local Networker = require(script.Parent.Networker)
local Types = require(script.Parent.Types)
local Signal = require(Packages.Signal)
local Utils = require(script.Parent.Utils)

local LazySignal = require(script.Parent.LazySignal)


local bezier = {}

type Point = Types.Point
type Object = Types.Object

type options = {
	points: { [number]: Point },
	object: Object,

	updateCallBack: (point: Point, time: number) -> ()?,
	completedCallBack: () -> ()?,

	duration: number?,
	speed: number?,
}

local function getPointAtT(points: { Point }, t: number): Point
	local working = points

	while #working > 1 do
		local nextLevel = {}
		for i = 1, #working - 1 do
			nextLevel[i] = Utils.lerp(working[i], working[i + 1], t)
		end
		working = nextLevel
	end

	return working[1]
end

local function calculateDuration(options: options)
	local duration = options.duration
	local points = options.points

	if not duration then
		local speed = options.speed or 10
		local length = 0
		local samples = 20
		local prevPos = Utils.toVector3(points[1])

		for i = 1, samples do
			local t = i / samples
			local currPos = Utils.toVector3(getPointAtT(points, t))
			length += (currPos - prevPos).Magnitude
			prevPos = currPos
		end

		duration = length / speed
	end

	return duration
end

local function localTween(options: options, shouldMoveObject: boolean)
	local points = options.points
	assert(points and #points >= 2, "BezierTween requires at least 2 points")

	local object = options.object
	local duration = calculateDuration(options)

	local elapsed = 0
	local heartbeatConn: RBXScriptConnection?

	local updated = nil
	local completed = Signal.new()

	local function step(dt: number)
		elapsed += dt
		local t = math.clamp(elapsed / duration, 0, 1)
		local point = getPointAtT(points, t)

		updated:Fire(point, t)
		if object and shouldMoveObject then
			Utils.moveObject(object, point)
		end

		if options.updateCallBack then
			options.updateCallBack(point, t)
		end

		if t >= 1 then
			if heartbeatConn then
				heartbeatConn:Disconnect()
				heartbeatConn = nil
			end

			completed:Fire()
			if options.completedCallBack then
				options.completedCallBack()
			end

			updated:Destroy()
			completed:Destroy()
		end
	end

	local function startLoop()
		if heartbeatConn then return end
		heartbeatConn = RunService.Heartbeat:Connect(step)
	end

	local function stopLoop()
		if heartbeatConn then
			heartbeatConn:Disconnect()
			heartbeatConn = nil
		end
	end

	local needsImmediateLoop = shouldMoveObject or options.updateCallBack ~= nil

	if needsImmediateLoop then
		updated = Signal.new()
		startLoop()
	else
		updated = LazySignal(startLoop, stopLoop)
	end

	return {
		Updated = updated,
		Completed = completed,
		Cancel = function()
			stopLoop()
			updated:Destroy()
			completed:Destroy()
		end,
	}
end

Networker.Register("bezier", function(options)
	localTween(options, true)
end)

return function(options: options)
	local isServer = RunService:IsServer()
	local duration = calculateDuration(options)

	if isServer then
		if options.object then
			Networker.FireAllClients("bezier", options)
		end

		task.delay(duration, function()
			Utils.moveObject(options.object, options.points[#options.points])
		end)

		return localTween(options, false)
	else
		return localTween(options, true)
	end
end
