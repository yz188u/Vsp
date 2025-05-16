local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ball = Workspace:WaitForChild("Football")
local gravity = Vector3.new(0, -Workspace.Gravity, 0)
local timeStep = 0.02
local totalSteps = 300
local friction = 0.991
local bounceDamping = 0.8
local curveStrength = 0.1 -- makin besar makin belok

local folder = Instance.new("Folder", Workspace)
folder.Name = "FootballPrediction"

local ballSize = ball.Size.Magnitude
local dotSize = ballSize * 1.2
local distanceBetweenDots = 3 -- dalam stud

local function HSVtoRGB(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	local r, g, b
	if i % 6 == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	elseif i == 5 then r, g, b = v, p, q end
	return Color3.new(r, g, b)
end

local function createDot(position, t)
	local color = HSVtoRGB(t % 1, 1, 1) -- rainbow smooth
	local dot = Instance.new("Part")
	dot.Anchored = true
	dot.CanCollide = false
	dot.Size = Vector3.new(dotSize, dotSize, dotSize)
	dot.Shape = Enum.PartType.Ball
	dot.Material = Enum.Material.SmoothPlastic
	dot.Color = color

	-- Gradien transparansi (dari transparan ke solid)
	local transparency = math.clamp(0.7 - (t * 0.5), 0.15, 0.7)
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
	createDot(pos, 0)

	local colorProgress = 0

	for i = 1, totalSteps do
		local newVel = vel + gravity * timeStep
		newVel *= friction

		-- Tambahin efek belokan dari spin bola
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
			colorProgress += 0.025
			createDot(pos, colorProgress)
			lastDotPos = pos
		end

		if vel.Magnitude < 0.5 then
			createDot(pos, 1)
			break
		end
	end
end)
