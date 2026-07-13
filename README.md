# TweenService

Utility library for tweening services.

---

Notes:
    - The most important thing about this package is that it runs on the server by sending the client to tween and it snaps in the server automatic after the player finishes the tween

    - its really effcient, and the server update signal loop doesnt run unless its connected, otherwise it will js fire the completed signal once its finished

### `TweenServies.bezier(options)`

```lua
local TweenServices = require(path.to.module)

--[[
    options = {
        points: { [number]: Point },
        object: Object,

        updateCallBack: (point: Point, time: number) -> ()?,
        completedCallBack: () -> ()?,

        duration: number?,
        speed: number?,
    }
]]


local actions = TweenServices.bezier({
    points = {
        Vector3.new(0, 0, 0),
        Vector3.new(25, 25, 0),
        Vector3.new(50, 0, 0),
    },

    duration = 6 -- or speed = 50 
    object = workspace.Part -- could be nil
})

actions.Updated:Connect(function(point: Vector3, t: number) -- t is the alpha thats between 0 - 1

end)

actions.Completed:Connect(function()
    
end)

actions.Cancel()
```

### `TweenServies.tweenObject(options)`

```lua
local TweenServices = require(path.to.module)

--[[
    options = {
        tweenInfo: TweenInfo,
        
        object: Object,
        finalPoint: Point
    }
]]


local actions = TweenServices.tweenObject({
    finalPoint = Vector3.new(10, 10, 10)

    tweenInfo = TweenInfo.new(10, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    object = workspace.Part
})

actions.Updated:Connect(function(point: Vector3, t: number)

end)

actions.Completed:Connect(function()
    
end)

actions.Cancel()
```