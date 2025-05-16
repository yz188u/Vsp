local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ball = Workspace:WaitForChild("Football")
local gravity = Vector3.new(0, -Workspace.Gravity, 0)
local timeStep = 0.02
local totalSteps = 150
local friction = 0.991
local bounceDamping = 0.8
local curveStrength = 0.1

local folder = Instance.new("Folder", Workspace)
folder.Name = "FootballPrediction"

-- Fungsi buat bikin garis persegi panjang dari titik A ke B
local function createLine(from, to)
	local distance = (to - from).Magnitude
	local midPoint = (from + to) / 2
	local direction = (to - from).Unit

	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(0.5, 0.5, distance)
	part.CFrame = CFrame.new(midPoint, to)
	part.Color = Color3.fromRGB(255, 255, 0)
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = 0.3
	part.Parent = folder
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

	local startPos = pos
	local lastPos = pos
	local segments = {}

	for i = 1, totalSteps do
		local newVel = vel + gravity * timeStep
		newVel *= friction

		local sideForce = spin:Cross(Vector3.new(0, 1, 0)) * curveStrength
		newVel += sideForce

		local move = newVel * timeStep
		local ray = Workspace:Raycast(pos, move, RaycastParams.new())

		if ray and isValidHit(ray.Instance) then
			local endPos = ray.Position
			table.insert(segments, {lastPos, endPos})
			pos = ray.Position + ray.Normal * 0.1
			vel = reflect(newVel, ray.Normal) * bounceDamping
			lastPos = pos
		else
			pos += move
		end

		if vel.Magnitude < 0.5 then
			table.insert(segments, {lastPos, pos})
			break
		end

		-- Batasi jumlah garis, biar ringan
		if #segments >= 5 then break end
	end

	-- Bikin garis dari semua segmen
	for _, seg in ipairs(segments) do
		createLine(seg[1], seg[2])
	end
end)
