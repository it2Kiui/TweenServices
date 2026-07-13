local RunService = game:GetService("RunService")

local Bezier = require(script.Bezier)
local Tween = require(script.Tween)

if RunService:IsServer() then
	local bootstrap = script.TweenInitilizer
	bootstrap.Parent = game.ReplicatedFirst
end

return {
	bezier = Bezier,
	tweenObject = Tween,
}
