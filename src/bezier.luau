local RunService = game:GetService("RunService")

local Packages = script.Parent.Parent
local Signal = require(Packages.Signal)

local bezier = {}

type Point = Vector3 | CFrame
type Object = Model | BasePart

type options = {
	points: { [number]: Point },
	object: Object,

	updateCallBack: (point: Point, time: number) -> ()?,
    completedCallBack: () -> ()?,

	duration: number?,
	speed: number?,
}

local function lerp(a: Point, b: Point, t: number): Point
	return a:Lerp(b, t)
end

local function toVector3(point: Point): Vector3
	return if typeof(point) == "CFrame" then point.Position else point
end

local function toCFrame(point: Point): CFrame
	return if typeof(point) == "Vector3" then CFrame.new(point) else point
end

local function getPointAtT(points: { Point }, t: number): Point
	local working = points

	while #working > 1 do
		local nextLevel = {}
		for i = 1, #working - 1 do
			nextLevel[i] = lerp(working[i], working[i + 1], t)
		end
		working = nextLevel
	end

	return working[1]
end

function bezier.tween(options: options)
	local points = options.points
	assert(points and #points >= 2, "BezierTween requires at least 2 points")

	local object = options.object
	local duration = options.duration
	if not duration then
		local speed = options.speed or 10
		local length = 0
		local samples = 20
		local prevPos = toVector3(points[1])

		for i = 1, samples do
			local t = i / samples
			local currPos = toVector3(getPointAtT(points, t))
			length += (currPos - prevPos).Magnitude
			prevPos = currPos
		end

		duration = length / speed
	end

	local updated = Signal.new()
	local completed = Signal.new()

	local elapsed = 0
	local connection

	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local t = math.clamp(elapsed / duration, 0, 1)
		local point = getPointAtT(points, t)

		updated:Fire(point, t)
		if object then
			if object:IsA("Model") then
				object:PivotTo(toCFrame(point))
			else
				object.Position = toVector3(point)
			end
		end

		if options.updateCallBack then
			options.updateCallBack(point, t)
		end

		if t >= 1 then
			connection:Disconnect()
			completed:Fire()

            if options.completedCallBack then
                options.completedCallBack()
            end

			updated:Destroy()
            completed:Destroy()
		end
	end)

	return {
		Updated = updated,
		Completed = completed,
		Cancel = function()
			if connection then
				connection:Disconnect()
			end
            updated:Destroy()
            completed:Destroy()
		end,
	}
end

return bezier
