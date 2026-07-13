local Types = require(script.Parent.Types)

type Point = Types.Point
type Object = Types.Object

local Utils = {}

function Utils.lerp(a: Point, b: Point, t: number): Point
	return a:Lerp(b, t)
end

function Utils.toVector3(point: Point): Vector3
	return if typeof(point) == "CFrame" then point.Position else point
end

function Utils.toCFrame(point: Point): CFrame
	return if typeof(point) == "Vector3" then CFrame.new(point) else point
end

function Utils.isObject(inst: Instance): boolean
	return inst:IsA("Model") or inst:IsA("BasePart")
end

function Utils.isVaildPoint(point: Point): boolean
	return typeof(point) == "Vector3" or typeof(point) == "CFrame"
end

function Utils.moveObject(object: Object, point: Point)
	if object:IsA("Model") then
		object:PivotTo(Utils.toCFrame(point))
		return
	end

	object.Position = Utils.toVector3(point)
end

return Utils