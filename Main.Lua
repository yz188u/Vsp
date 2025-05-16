local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ball = Workspace:WaitForChild("Football")
local gravity = Vector3.new(0, -Workspace.Gravity, 0)
local timeStep = 0.02
local totalSteps = 200
local friction = 0.991
local bounceDamping = 0.8
local curveStrength = 0.1
local distanceBetweenDots = 3

local folder = Instance.new("Folder", Workspace)
folder.Name = "FootballPrediction"

local ballSize = ball.Size.Magnitude
local dotSize = ballSize * 1.2
local dotColor = Color3.fromRGB(255, 0, 0) -- Merah

local function createDot(position, transparency)
	local dot = Instance.new("Part")
	dot.Anchored = true
	dot.CanCollide = false
	dot.Size = Vector3.new(dotSize, dotSize, dotSize)
	dot.Shape = Enum.PartType.Ball
	dot.Material = Enum.Material.SmoothPlastic
	dot.Color = dotColor
	dot.Transparency = transparency
	dot.Position = position
	dot.Parent = folder
end

local function reflect(velocity, normal)
	return velocity - 2 * velocity:Dot(normal) * normal
end

local function isValidHit(hit)
	return hit and hit.CanCollide and hit.Transparency < 0.9
end

RunService.RenderStepped:Connect(function()
	if not _G.Predicting then return end
	folder:ClearAllChildren()

	local pos = ball.Position
	local vel = ball.AssemblyLinearVelocity
	local spin = ball.AssemblyAngularVelocity

	local lastDotPos = pos
	createDot(pos, 0.15)

	for i = 1, totalSteps do
		local newVel = vel + gravity * timeStep
		newVel *= friction

		local sideForce = spin:Cross(Vector3.new(0, 1, 0)) * curveStrength
		newVel += sideForce

		local move = newVel * timeStep
		local ray = Workspace:Raycast(pos, move, RaycastParams.new())

		if ray and isValidHit(ray.Instance) then
			pos = ray.Position + ray.Normal * 0.1
			vel = reflect(newVel, ray.Normal) * bounceDamping
		else
			pos += move
			vel = newVel
		end

		if (pos - lastDotPos).Magnitude >= distanceBetweenDots then
			local alpha = math.clamp(0.15 + (i / totalSteps), 0.15, 0.7)
			createDot(pos, alpha)
			lastDotPos = pos
		end

		if vel.Magnitude < 0.5 then
			createDot(pos, 0.7)
			break
		end
	end
end)
