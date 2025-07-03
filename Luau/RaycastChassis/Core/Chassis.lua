--!strict
--[[
	Main class for the vehicle chassis.
	Handles the overall vehicle simulation, including updating wheels,
	applying forces, and managing vehicle state.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Assuming Wheel and Config modules will be in Luau/RaycastChassis/Modules/
local Wheel = require(script.Parent.Parent.Modules.Wheel)
local DefaultConfig = require(script.Parent.Parent.Modules.Config)

export type ChassisConfig = {
	DebugEnabled: boolean,
	RaycastParams: RaycastParams,
	Suspension: {
		SpringStiffness: number,
		SpringDamping: number,
		MaxForce: number,
		RestLength: number, -- Or calculated dynamically
	},
	Tire: {
		FrictionCoefficient: number, -- General friction
		LateralStiffness: number, -- Resistance to sideways slip
		LongitudinalStiffness: number, -- Resistance to forward/backward slip
	},
	Engine: {
		MaxTorque: number,
		TorqueCurve: AnimationCurve?, -- Optional: For more realistic acceleration
		MaxRPM: number,
		MinRPM: number,
		IdleRPM: number,
	},
	Brakes: {
		MaxBrakeForce: number,
	},
	Steering: {
		MaxSteerAngle: number, -- In degrees
		SteerSpeed: number, -- How fast wheels turn
		AckermannPercentage: number, -- 0 for no Ackermann, 1 for perfect Ackermann
		SpeedSensitiveSteering: { -- Table of speed (studs/s) to steering angle multiplier
			{0, 1},
			{50, 0.7},
			{100, 0.4},
		}?,
	},
	AntiRollBar: {
		Enabled: boolean,
		Stiffness: number,
	}?,
	Optimization: {
		AdaptiveRaycastFrequency: {
			Enabled: boolean,
			MinSpeed: number, -- Speed below which raycast frequency might be reduced
			MaxSpeed: number, -- Speed above which raycast frequency is at max
			MinFrequency: number, -- Updates per second
			MaxFrequency: number, -- Updates per second
		},
		SelectiveRaycasting: {
			Enabled: boolean,
			AirborneTimeThreshold: number, -- Time in air before reducing raycasts
		},
	},
	-- Reference to the main body of the vehicle
	Body: BasePart,
	-- Table of Wheel instances, keyed by a name (e.g., "WheelFL")
	Wheels: {[string]: Wheel.Wheel},
}

export type ChassisInputs = {
	Throttle: number, -- -1 to 1 (for reverse and forward)
	Steer: number, -- -1 to 1 (left to right)
	Brake: number, -- 0 to 1
	Handbrake: number, -- 0 to 1
}

local Chassis = {}
Chassis.__index = Chassis

-- Constructor
function Chassis.new(vehicleModel: Model, customConfig: Partial<ChassisConfig>?)
	local self = setmetatable({}, Chassis)

	self.VehicleModel = vehicleModel
	self.Config = table.clone(DefaultConfig) -- Start with defaults
	if customConfig then
		-- Deep merge customConfig into self.Config (simplified here, might need a utility for deep merge)
		for key, value in pairs(customConfig) do
			if typeof(value) == "table" and typeof(self.Config[key]) == "table" then
				-- This is a shallow merge for nested tables, a proper deep merge is more complex
				for k, v in pairs(value) do
					(self.Config[key] :: any)[k] = v
				end
			else
				(self.Config :: any)[key] = value
			end
		end
	end

	assert(self.Config.Body, "ChassisConfig must include a 'Body' BasePart.")

	self.Body = self.Config.Body
	self.Wheels = {} -- Table to store Wheel objects
	self.Inputs = { Throttle = 0, Steer = 0, Brake = 0, Handbrake = 0 }

	self._lastRaycastTime = {} -- For Adaptive Raycasting Frequency, per wheel
	self._timeSinceLastGroundContact = {} -- For Selective Raycasting, per wheel

	-- Initialize Wheels
	-- The user is expected to pass a 'Wheels' table in customConfig where each entry
	-- has an instance and wheel-specific overrides.
	-- For now, we assume the user will populate self.Config.Wheels with Wheel objects directly
	-- or provide enough info in customConfig for us to create them.
	-- This part needs refinement based on how Wheel.new() is structured.
	if self.Config.Wheels then
		for wheelName, wheelInstance in pairs(self.Config.Wheels) do
			if typeof(wheelInstance) == "Instance" then -- If only the part is provided
				-- We'd need more info here, like wheel specific config or assume it from DefaultConfig
				-- This is a placeholder, actual wheel init will depend on Wheel module
				-- self.Wheels[wheelName] = Wheel.new(wheelInstance :: BasePart, self.Config)
				warn("Direct Instance for wheel in config is not fully supported yet for Chassis.new. Please provide pre-constructed Wheel objects or more detailed config.")
			elseif typeof(wheelInstance) == "table" and (wheelInstance :: any).ClassName == "Wheel" then
				self.Wheels[wheelName] = wheelInstance :: Wheel.Wheel
				self._lastRaycastTime[wheelName] = 0
				self._timeSinceLastGroundContact[wheelName] = 0
			else
				error("Invalid wheel configuration for " .. wheelName)
			end
		end
	end

	self._connections = {}

	return self
end

function Chassis:SetInputs(inputs: ChassisInputs)
	self.Inputs.Throttle = math.clamp(inputs.Throttle or 0, -1, 1)
	self.Inputs.Steer = math.clamp(inputs.Steer or 0, -1, 1)
	self.Inputs.Brake = math.clamp(inputs.Brake or 0, 0, 1)
	self.Inputs.Handbrake = math.clamp(inputs.Handbrake or 0, 0, 1)
end

function Chassis:_calculateAdaptiveFrequency(wheelName: string): number
	local optConfig = self.Config.Optimization.AdaptiveRaycastFrequency
	if not optConfig.Enabled then
		return optConfig.MaxFrequency
	end

	local speed = self.Body.AssemblyLinearVelocity.Magnitude -- Current speed of the vehicle body
	local minSpeed = optConfig.MinSpeed
	local maxSpeed = optConfig.MaxSpeed

	if speed <= minSpeed then
		return optConfig.MinFrequency
	elseif speed >= maxSpeed then
		return optConfig.MaxFrequency
	else
		local alpha = (speed - minSpeed) / (maxSpeed - minSpeed)
		return optConfig.MinFrequency + alpha * (optConfig.MaxFrequency - optConfig.MinFrequency)
	end
end

function Chassis:_shouldRaycast(wheel: Wheel.Wheel, wheelName: string, dt: number): boolean
	local selectiveConfig = self.Config.Optimization.SelectiveRaycasting
	if not selectiveConfig.Enabled then
		return true -- Always raycast if not enabled
	end

	if wheel:IsOnGround() then -- Assuming Wheel module has a way to check this
		self._timeSinceLastGroundContact[wheelName] = 0
		return true
	else
		self._timeSinceLastGroundContact[wheelName] = (self._timeSinceLastGroundContact[wheelName] or 0) + dt
		if self._timeSinceLastGroundContact[wheelName] > selectiveConfig.AirborneTimeThreshold then
			if self.Config.DebugEnabled then
				print(`Skipping raycast for {wheelName} (airborne too long)`)
			end
			return false -- Skip raycast if airborne for too long
		end
		return true
	end
end

-- Placeholder methods
function Chassis:_updateSteering(dt: number)
	local targetSteerAngle = self.Config.Steering.MaxSteerAngle * self.Inputs.Steer

	-- Optional: Speed sensitive steering
	if self.Config.Steering.SpeedSensitiveSteering then
		local currentSpeed = self.Body.AssemblyLinearVelocity.Magnitude
		local multiplier = 1
		for _, point in ipairs(self.Config.Steering.SpeedSensitiveSteering) do
			if currentSpeed >= point[1] then
				multiplier = point[2]
			else
				break -- Assuming sorted by speed
			end
		end
		targetSteerAngle *= multiplier
	end

	for _, wheel in pairs(self.Wheels) do
		if wheel.Config.IsSteeringWheel then
			-- Simplified steering, direct set. Real implementation might involve lerping to SteerSpeed.
			wheel:SetSteerAngle(targetSteerAngle)
			-- TODO: Implement Ackermann steering if self.Config.Steering.AckermannPercentage > 0
		end
	end
end

function Chassis:_updateSuspensionAndTraction(wheel: Wheel.Wheel, wheelName: string, dt: number)
	local adaptiveFreq = self._calculateAdaptiveFrequency(wheelName)
	local timeNow = os.clock()

	if timeNow - (self._lastRaycastTime[wheelName] or 0) < (1 / adaptiveFreq) then
		-- Not enough time passed for this wheel based on adaptive frequency
		-- Still need to apply existing forces or cached results if any
		wheel:ApplyCachedForces(dt) -- Wheel should handle this
		return
	end

	if not self:_shouldRaycast(wheel, wheelName, dt) then
		-- Based on selective raycasting, this wheel shouldn't raycast now
		wheel:ApplyCachedForces(dt) -- Apply any decay or residual forces
		return
	end

	self._lastRaycastTime[wheelName] = timeNow

	-- Raycast from wheel's attachment point downwards
	local origin = wheel:GetRaycastOrigin() -- Method on Wheel to get this
	local direction = wheel:GetRaycastDirection() -- Method on Wheel for this (e.g., -wheel.Attachment.WorldCFrame.UpVector)
	local raycastResult = workspace:Raycast(origin, direction * self.Config.Suspension.RestLength, self.Config.RaycastParams)

	local onGround = false
	local suspensionForce = Vector3.zero
	local hitPoint = Vector3.zero
	local hitNormal = Vector3.up
	local hitPart = nil

	if raycastResult then
		onGround = true
		hitPoint = raycastResult.Position
		hitNormal = raycastResult.Normal
		hitPart = raycastResult.Instance

		local compression = self.Config.Suspension.RestLength - (origin - hitPoint).Magnitude
		local springVelocity = wheel:GetSpringVelocity(hitPoint, dt) -- Wheel needs to calculate this based on previous position

		local stiffness = self.Config.Suspension.SpringStiffness
		local damping = self.Config.Suspension.SpringDamping

		-- Calculate spring force: F = -kx - bv
		local forceMagnitude = (stiffness * compression) + (damping * springVelocity)
		forceMagnitude = math.min(forceMagnitude, self.Config.Suspension.MaxForce) -- Clamp max force

		suspensionForce = hitNormal * forceMagnitude

		-- Apply suspension force at the wheel's contact point (or attachment point for simplicity)
		-- This should ideally be applied to self.Body relative to wheel's position
		-- For now, let wheel handle applying its calculated forces to the chassis body
		-- self.Body:ApplyForceAtPosition(suspensionForce, wheel:GetAttachmentPoint())

	end

	wheel:UpdateSuspensionData(onGround, suspensionForce, hitPoint, hitNormal, hitPart, dt)

	-- Update Traction based on suspension results
	if onGround then
		self:_updateTireForces(wheel, dt)
	else
		wheel:ResetTireForces()
	end
end

function Chassis:_updateThrottleAndBrakes(wheel: Wheel.Wheel, dt: number)
	if not wheel:IsOnGround() then return end

	local driveForce = 0
	if wheel.Config.IsDrivenWheel and self.Inputs.Throttle ~= 0 then
		driveForce = self.Config.Engine.MaxTorque * self.Inputs.Throttle
		-- TODO: Implement torque curve, RPM, gearing later
	end

	local brakeForce = 0
	if self.Inputs.Brake > 0 then
		brakeForce += self.Config.Brakes.MaxBrakeForce * self.Inputs.Brake
	end
	if self.Inputs.Handbrake > 0 and wheel.Config.IsHandbrakeWheel then
		brakeForce += self.Config.Brakes.MaxBrakeForce * self.Inputs.Handbrake -- Or a different value for handbrake
	end

	wheel:ApplyDriveAndBrake(driveForce, brakeForce, dt)
end


function Chassis:_updateTireForces(wheel: Wheel.Wheel, dt: number)
	-- This is a complex part of vehicle physics. Simplified for now.
	-- Needs wheel velocity, slip angles, slip ratios.

	-- Lateral (Steering) Force - simplified Pacejka-like model
	local lateralForce = wheel:CalculateLateralForce(self.Config.Tire.LateralStiffness, dt)

	-- Longitudinal (Drive/Brake) Force - already partially handled by _updateThrottleAndBrakes
	-- but friction also plays a role here.
	-- This force is what wheel:ApplyDriveAndBrake would generate.
	-- Here we'd combine it with friction limits.

	-- For now, assume wheel.ApplyDriveAndBrake and wheel.CalculateLateralForce
	-- directly apply their forces or store them to be applied by wheel:ApplyAccumulatedForces
end

function Chassis:_applyAntiRollBars(dt: number)
	if not self.Config.AntiRollBar or not self.Config.AntiRollBar.Enabled then return end

	-- Iterate over pairs of wheels (e.g., front pair, rear pair)
	-- This needs a way to define wheel pairs (e.g., "FL" and "FR")
	-- For simplicity, let's assume we have defined pairs in config or can infer them
	-- Example: { {"WheelFL", "WheelFR"}, {"WheelRL", "WheelRR"} }

	-- For each pair:
	--   Get compression of left wheel (dl) and right wheel (dr)
	--   Calculate anti-roll force: F_arb = (dl - dr) * Stiffness
	--   Apply -F_arb to left wheel and F_arb to right wheel along suspension direction
	-- This logic would go into the wheel and be called from here.
end

-- Main update loop
function Chassis:Update(dt: number)
	self:_updateSteering(dt)

	for wheelName, wheel in pairs(self.Wheels) do
		self:_updateSuspensionAndTraction(wheel, wheelName, dt)
		self:_updateThrottleAndBrakes(wheel, dt)
	end

	self:_applyAntiRollBars(dt)

	-- After all individual wheel forces are calculated for this frame,
	-- the Wheel objects should apply their accumulated forces to the Chassis.Body
	for _, wheel in pairs(self.Wheels) do
		wheel:ApplyAccumulatedForcesToBody(self.Body, dt)
	end

	if self.Config.DebugEnabled then
		self:_debugDraw()
	end
end

function Chassis:_debugDraw()
	-- Draw raycasts, forces, etc.
	-- This would typically use HandleAdornments or other visual debugging tools.
	for wheelName, wheel in pairs(self.Wheels) do
		if wheel:IsOnGround() then
			-- Example: Draw a line for the suspension force
			-- This needs a proper debug drawing utility
		end
	end
end

function Chassis:Destroy()
	for _, conn in pairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)

	for _, wheel in pairs(self.Wheels) do
		wheel:Destroy() -- If Wheel has its own cleanup
	end
	table.clear(self.Wheels)

	-- Other cleanup as needed
	setmetatable(self, nil)
end

return Chassis

-- Example of how Partial type might be defined if not available globally
-- (Roblox's Luau type system might handle this implicitly with table.clone and careful merging)
--[[
	type Partial<T> = {[K in keyof T]?: T[K]}
]]
