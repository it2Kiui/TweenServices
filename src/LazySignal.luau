local Packages = script.Parent.Parent


local Signal = require(Packages.Signal)

return function(onFirstConnect, onLastDisconnect)
	local real = Signal.new()
	local count = 0

	local proxy = {}

	function proxy:Connect(fn)
		local conn = real:Connect(fn)
		count += 1
		if count == 1 and onFirstConnect then
			onFirstConnect()
		end

		return {
			Disconnect = function()
				conn:Disconnect()
				count -= 1
				if count == 0 and onLastDisconnect then
					onLastDisconnect()
				end
			end,
		}
	end

	function proxy:Fire(...)
		real:Fire(...)
	end

	function proxy:Destroy()
		real:Destroy()
	end

	return proxy
end