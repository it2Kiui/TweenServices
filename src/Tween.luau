local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Packages = script.Parent.Parent
local Types = require(script.Parent.Types)
local Signal = require(Packages.Signal)
local Utils = require(script.Parent.Utils)
local LazySignal = require(script.Parent.LazySignal)

type Point = Types.Point
type Object = Types.Object

type options = {
	tweenInfo: TweenInfo,
	object: Object,
	finalPoint: Point
}

local Networker = require(script.Parent.Networker)

local function getObjectCFrame(object: Object): CFrame
	if object:IsA("Model") then
		return object:GetPivot()
	else
		return object.CFrame
	end
end

local function setObjectCFrame(object: Object, cframe: CFrame)
	if object:IsA("Model") then
		object:PivotTo(cframe)
	else
		object.CFrame = cframe
	end
end

local function toCFrame(point: Point, referenceCFrame: CFrame): CFrame
	if typeof(point) == "CFrame" then
		return point
	else
		return CFrame.new(point) * (referenceCFrame - referenceCFrame.Position)
	end
end

local function localTween(options: options, shouldMoveObject: boolean)
	local tweenInfo = options.tweenInfo
	local object = options.object

	local startCFrame = getObjectCFrame(object)
	local targetCFrame = toCFrame(options.finalPoint, startCFrame)

    local updated = nil

	local elapsed = 0
	local delayElapsed = 0
	local reversing = false
	local repeatsLeft = tweenInfo.RepeatCount

	local heartbeatConn: RBXScriptConnection?

	local function step(dt: number)
		if delayElapsed < tweenInfo.DelayTime then
			delayElapsed += dt
			return
		end

		elapsed += dt
		local alpha = math.clamp(elapsed / tweenInfo.Time, 0, 1)
		local easedAlpha = TweenService:GetValue(alpha, tweenInfo.EasingStyle, tweenInfo.EasingDirection)

		if reversing then
			easedAlpha = 1 - easedAlpha
		end

		local currentCFrame = startCFrame:Lerp(targetCFrame, easedAlpha)

		if shouldMoveObject then
			setObjectCFrame(object, currentCFrame)
		end

		updated:Fire(currentCFrame, alpha)

		if elapsed >= tweenInfo.Time then
			if tweenInfo.Reverses and not reversing then
				reversing = true
				elapsed = 0
			elseif repeatsLeft ~= 0 then
				if repeatsLeft > 0 then
					repeatsLeft -= 1
				end
				reversing = false
				elapsed = 0
			else
				if heartbeatConn then
					heartbeatConn:Disconnect()
					heartbeatConn = nil
				end
			end
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

	if shouldMoveObject then
		startLoop()
	end

	updated = LazySignal(
		if shouldMoveObject then nil else startLoop,
		if shouldMoveObject then nil else stopLoop
	)

	local completed = Signal.new()
	local totalTime = tweenInfo.DelayTime + tweenInfo.Time

	local completedThread = task.delay(totalTime, function()
		completed:Fire()
		updated:Destroy()
		completed:Destroy()
		stopLoop()

        Utils.moveObject(options.object, options.finalPoint)
	end)

	return {
		Updated = updated,
		Completed = completed,
		Cancel = function()
			stopLoop()
			task.cancel(completedThread)
			updated:Destroy()
			completed:Destroy()
		end,
	}
end

Networker.Register("tween", function(options: options)
	localTween(options, true)
end)

return function(options: options)
	local isServer = RunService:IsServer()

	assert(Utils.isVaildPoint(options.finalPoint), `Invalid point, expected a Vector3 or CFrame got: {typeof(options.finalPoint)}`)
	assert(Utils.isObject(options.object), `Invalid Object, expected a Model or BasePart got: {typeof(options.object)}`)

	if isServer then
		Networker.FireAllClients("tween", options)

		return localTween(options, false)
	else
		return localTween(options, true)
	end
end