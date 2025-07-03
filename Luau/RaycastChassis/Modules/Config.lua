--!strict
--[[
	Default configuration values for a chassis.
	This module provides a baseline set of parameters that can be overridden
	by the user when creating a new Chassis instance.
]]

-- For type reference from Chassis.lua, though direct require isn't needed here.
-- type ChassisConfig = Chassis.ChassisConfig

local Config = {}

-- Default RaycastParameters
-- Note: FilterDescendantsInstances should be set by the chassis constructor
-- to include the vehicle model itself.
Config.RaycastParams = RaycastParams.new()
Config.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
Config.RaycastParams.IgnoreWater = true
-- Config.RaycastParams.CollisionGroup = "Default" -- Or specific group for ground

Config.DebugEnabled = false

Config.Suspension = {
	SpringStiffness = 15000, -- Force per unit of compression (e.g., N/m)
	SpringDamping = 1500,   -- Damping coefficient to reduce oscillation (e.g., Ns/m)
	MaxForce = 50000,       -- Maximum force the suspension can exert (N)
	RestLength = 1.0,       -- Target length of the suspension spring at rest (studs)
	-- ^ This might be better calculated dynamically based on wheel position relative to body attachment.
	-- For now, a fixed value. Wheel module will need an attachment point.
}

Config.Tire = {
	FrictionCoefficient = 1.2, -- General grip factor (mu)
	LateralStiffness = 25,     -- Affects how much force is generated per unit of slip angle (Pacejka 'B' factor like)
	LongitudinalStiffness = 5000, -- Affects how much force is generated per unit of slip ratio (for acceleration/braking)
	GripFalloffSpeed = 50,     -- Speed (studs/s) at which tire grip might start to reduce
}

Config.Engine = {
	MaxTorque = 2000,       -- Maximum torque output of the engine (Nm)
	TorqueCurve = nil,      -- Placeholder for AnimationCurve for more realistic torque delivery
	-- Example: Instance.new("AnimationCurve"), then add Keypoints
	MaxRPM = 7000,
	MinRPM = 800,
	IdleRPM = 1000,
	-- TODO: Add gearing ratios, differential settings
}

Config.Brakes = {
	MaxBrakeForce = 3000,   -- Max braking torque applied at the wheels (Nm)
	BrakeDistribution = 0.7, -- Percentage of brake force applied to front wheels (0 to 1)
}

Config.Steering = {
	MaxSteerAngle = 35,     -- Maximum angle wheels can turn (degrees)
	SteerSpeed = 150,       -- How fast wheels turn towards target angle (degrees/sec)
	AckermannPercentage = 0.8, -- 0 for no Ackermann, 1 for perfect. Affects inner/outer wheel angle difference.
	SpeedSensitiveSteering = { -- Table of {speed (studs/s), steeringAngleMultiplier}
		{Speed = 0, Multiplier = 1.0},
		{Speed = 30, Multiplier = 0.8},
		{Speed = 60, Multiplier = 0.6},
		{Speed = 100, Multiplier = 0.4},
	},
}

Config.AntiRollBar = {
	Enabled = true,
	Stiffness = 5000,       -- Stiffness of the anti-roll bar (Nm/rad or N/m depending on implementation)
	-- Assumes connection between pairs of wheels (e.g., front axle, rear axle)
}

Config.Optimization = {
	AdaptiveRaycastFrequency = {
		Enabled = true,
		MinSpeed = 5,       -- Speed (studs/s) below which raycast frequency is at MinFrequency
		MaxSpeed = 80,      -- Speed (studs/s) above which raycast frequency is at MaxFrequency
		MinFrequency = 10,  -- Minimum raycasts per second per wheel
		MaxFrequency = 60,  -- Maximum raycasts per second per wheel (aligned with Stepped if possible)
	},
	SelectiveRaycasting = {
		Enabled = true,
		AirborneTimeThreshold = 0.25, -- Time (seconds) a wheel needs to be airborne before raycasts might be skipped/reduced for it
	},
}

-- Body and Wheels are not part of the *default* config,
-- they must be provided by the user when creating a chassis.
-- However, we can define a structure for how individual wheel configs might look if overriding.
Config.DefaultWheelConfig = {
	Name = "UnnamedWheel",
	Instance = nil, -- The actual Part/MeshPart for the wheel, to be provided by user
	AttachmentPoint = nil, -- Optional: A specific Attachment object on the vehicle body for this wheel's suspension raycast origin
	                        -- If nil, Wheel module might calculate based on Instance position relative to Body.
	Radius = 0.7, -- Wheel radius (studs)
	Width = 0.3,  -- Wheel width (studs)
	Mass = 15,    -- Wheel mass (kg) - used for inertia if simulating wheel rotation independently
	IsSteeringWheel = false,
	IsDrivenWheel = false,
	IsHandbrakeWheel = false, -- For handbrake effect

	-- Specific overrides for this wheel, otherwise uses global Chassis config
	Suspension = {}, -- e.g. { RestLength = 0.9 }
	Tire = {},       -- e.g. { FrictionCoefficient = 1.1 }
}


-- The Chassis.new() constructor will take this Config table as a base,
-- and then merge any user-provided configuration table on top of it.

-- Ensure the module returns the Config table
return table.freeze(Config) -- Freeze to make it read-only, good practice for configs
