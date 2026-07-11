local Packages = script.Parent.Parent

local Signal = require(Packages.Signal)

local bezier = {}

type options = {
    points: { [number]: Vector3 | CFrame },

    duration: number?,
    speed: number?,
}

function bezier.tween(options: options)
    
end

return bezier