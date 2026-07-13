local RunService = game:GetService("RunService")

local Networker = {}

local remote: RemoteEvent
if RunService:IsServer() then
	remote = Instance.new("RemoteEvent")
	remote.Name = "TweenServices"
	remote.Parent = script
else
	remote = script:WaitForChild("TweenServices", 10) :: RemoteEvent
end

local handlers: { [string]: (object: Instance, ...any) -> () } = {}

function Networker.FireAllClients(kind: string, options: any)
	if not RunService:IsServer() then
		return
	end
	remote:FireAllClients(kind, options)
end

function Networker.Register(kind: string, handler: (options: any) -> ())
	if not RunService:IsClient() then
		return
	end
	handlers[kind] = handler
end

if remote and RunService:IsClient() then
	remote.OnClientEvent:Connect(function(kind: string, options: any)
		local handler = handlers[kind]
		if handler then
			handler(options)
		else
			warn(("Networker: no handler registered for kind '%s'"):format(kind))
		end
	end)
end

return Networker