--!strict
--[[
	Example script demonstrating how to set up and use the RaycastChassis.

	This script assumes you have a Vehicle Model in the workspace structured like this:

	VehicleModel (Model)
	├── Body (Part or MeshPart, this is the main chassis part)
	├── WheelFL (Part or MeshPart, for Front-Left wheel)
	├── WheelFR (Part or MeshPart, for Front-Right wheel)
	├── WheelRL (Part or MeshPart, for Rear-Left wheel)
	├── WheelRR (Part or MeshPart, for Rear-Right wheel)
	│
	├── BodyAttachments (Folder, optional but recommended)
	│   ├── WheelFL_Attachment (Attachment, at suspension top for FL wheel)
	│   ├── WheelFR_Attachment (Attachment, at suspension top for FR wheel)
	│   ├── WheelRL_Attachment (Attachment, at suspension top for RL wheel)
	│   ├── WheelRR_Attachment (Attachment, at suspension top for RR wheel)
	│
	├── DriveSeat (Seat or VehicleSeat) (Optional, for player input)

	Instructions:
	1. Place this script into ServerScriptService or StarterPlayerScripts (for client-side testing).
	2. Ensure your VehicleModel is in Workspace and named "VehicleModel" or update `vehicleModelPath`.
	3. Adjust wheel names and attachment point names if they differ in your model.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ChassisModule = require(ReplicatedStorage.Luau.RaycastChassis.Core.Chassis)
local WheelModule = require(ReplicatedStorage.Luau.RaycastChassis.Modules.Wheel)
local DefaultChassisConfig = require(ReplicatedStorage.Luau.RaycastChassis.Modules.Config)

-- Configuration
local vehicleModelPath = Workspace:WaitForChild("VehicleModel") :: Model
local chassisBodyPart = vehicleModelPath:WaitForChild("Body") :: BasePart

-- Wait for attachments folder and attachments if using them
local attachmentsFolder = vehicleModelPath:FindFirstChild("BodyAttachments") :: Folder?

-- Function to safely get an attachment's world CFrame or fallback
local function getAttachmentWorldCF(wheelName: string, fallbackPart: BasePart): CFrame
	if attachmentsFolder then
		local attachment = attachmentsFolder:FindFirstChild(wheelName .. "_Attachment") :: Attachment?
		if attachment then
			return attachment.WorldCFrame
		end
	end
	-- Fallback: position above the wheel part, aligned with chassis body's orientation
	local wheelPart = vehicleModelPath:FindFirstChild(wheelName) :: BasePart?
	local yOffset = DefaultChassisConfig.Suspension.RestLength or 1
	if wheelPart then
		return CFrame.new(wheelPart.Position + chassisBodyPart.CFrame.UpVector * yOffset) * (chassisBodyPart.CFrame - chassisBodyPart.CFrame.Position)
	else
		-- Absolute fallback relative to chassis body center
		return chassisBodyPart.CFrame * CFrame.new(0, yOffset, 0)
	end
end


-- Define Wheel Specific Configurations
-- These will use DefaultChassisConfig.DefaultWheelConfig as a base,
-- and then merge with ParentChassisConfig (which is DefaultChassisConfig initially)
-- and then merge with these specific settings.

local wheelInstanceFL = vehicleModelPath:WaitForChild("WheelFL") :: BasePart
local wheelInstanceFR = vehicleModelPath:WaitForChild("WheelFR") :: BasePart
local wheelInstanceRL = vehicleModelPath:WaitForChild("WheelRL") :: BasePart
local wheelInstanceRR = vehicleModelPath:WaitForChild("WheelRR") :: BasePart

-- Ensure visual wheel parts are not affected by normal physics simulation directly
for _, wheelInstance in pairs({wheelInstanceFL, wheelInstanceFR, wheelInstanceRL, wheelInstanceRR}) do
	wheelInstance.Anchored = false -- If true, CFrame updates won't work as expected unless also unanchored in Wheel.lua
	wheelInstance.CanCollide = false -- Visual only
	wheelInstance.Massless = true -- If unanchored
end
chassisBodyPart.Anchored = false -- The main body MUST be unanchored for physics forces to apply

-- Create Wheel Objects
-- The Wheel.new constructor needs a more detailed config table per wheel.
-- Let's prepare that based on DefaultChassisConfig.DefaultWheelConfig and our specific parts.

local function createWheel(
	name: string,
	instance: BasePart,
	isSteering: boolean,
	isDriven: boolean,
	isHandbrake: boolean,
	parentConfig: typeof(DefaultChassisConfig)
): typeof(WheelModule.Wheel)

	local wheelSpecificConfig: WheelModule.WheelConfig = {
		Name = name,
		Instance = instance,
		-- AttachmentPointWorld: This is tricky. The Wheel module expects the *initial* world CFrame.
		-- The chassis body's CFrame will change. The Wheel needs to know its attachment point's
		-- offset from the chassis body's CFrame.
		-- For now, providing the initial world CFrame of where the suspension *top* should be.
		AttachmentPointWorld = getAttachmentWorldCF(name, instance),
		RaycastOriginOffset = Vector3.zero, -- Can be adjusted if ray needs to start slightly offset from attachment point

		Radius = parentConfig.DefaultWheelConfig.Radius or 0.7,
		Width = parentConfig.DefaultWheelConfig.Width or 0.3,
		Mass = parentConfig.DefaultWheelConfig.Mass or 15,
		VisualOffset = Vector3.zero, -- Adjust if wheel mesh origin isn't its geometric center

		IsSteeringWheel = isSteering,
		IsDrivenWheel = isDriven,
		IsHandbrakeWheel = isHandbrake,

		SuspensionRestLength = parentConfig.Suspension.RestLength,
		SuspensionStiffness = parentConfig.Suspension.SpringStiffness,
		SuspensionDamping = parentConfig.Suspension.SpringDamping,
		SuspensionMaxForce = parentConfig.Suspension.MaxForce,

		TireFrictionCoefficient = parentConfig.Tire.FrictionCoefficient,
		TireLateralStiffness = parentConfig.Tire.LateralStiffness,
		TireLongitudinalStiffness = parentConfig.Tire.LongitudinalStiffness,

		ParentChassisConfig = parentConfig, -- Pass the whole chassis config
	}
	return WheelModule.new(instance, chassisBodyPart, wheelSpecificConfig)
end

-- Create a specific chassis configuration table
local myChassisConfigOverrides = {
	DebugEnabled = false, -- Enable for visual debugging if implemented in Chassis/Wheel
	Body = chassisBodyPart,
	RaycastParams = RaycastParams.new(), -- Create new one to customize

	-- Wheels table will be populated with Wheel objects
	Wheels = {},

	Suspension = {
		RestLength = 1.2, -- Tuned for this specific vehicle model
		SpringStiffness = 25000,
		SpringDamping = 2200,
	},
	Engine = {
		MaxTorque = 2500,
	},
	Steering = {
		MaxSteerAngle = 30,
	}
	-- Add other overrides as needed
}
myChassisConfigOverrides.RaycastParams.FilterDescendantsInstances = {vehicleModelPath}
myChassisConfigOverrides.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude


-- Instantiate Wheels and add to the config overrides
local wheels: {[string]: typeof(WheelModule.Wheel)} = {
	WheelFL = createWheel("WheelFL", wheelInstanceFL, true, true, false, DefaultChassisConfig),
	WheelFR = createWheel("WheelFR", wheelInstanceFR, true, true, false, DefaultChassisConfig),
	WheelRL = createWheel("WheelRL", wheelInstanceRL, false, true, true, DefaultChassisConfig),
	WheelRR = createWheel("WheelRR", wheelInstanceRR, false, true, true, DefaultChassisConfig),
}
myChassisConfigOverrides.Wheels = wheels


-- Create the Chassis instance
local VehicleChassis = ChassisModule.new(vehicleModelPath, myChassisConfigOverrides)

-- Input Handling (Example for client-side testing)
-- For server-side, you'd use RemoteEvents to get input from clients.
local currentInputs: ChassisModule.ChassisInputs = {
	Throttle = 0,
	Steer = 0,
	Brake = 0,
	Handbrake = 0,
}

if RunService:IsClient() then
	UserInputService.InputChanged:Connect(function(inputObject, gameProcessedEvent)
		if gameProcessedEvent then return end

		if inputObject.UserInputType == Enum.UserInputType.Keyboard then
			local isDown = inputObject.UserInputState == Enum.UserInputState.Begin

			if inputObject.KeyCode == Enum.KeyCode.W then
				currentInputs.Throttle = isDown and 1 or 0
			elseif inputObject.KeyCode == Enum.KeyCode.S then
				currentInputs.Throttle = isDown and -1 or 0
			end

			if inputObject.KeyCode == Enum.KeyCode.A then
				currentInputs.Steer = isDown and -1 or 0
			elseif inputObject.KeyCode == Enum.KeyCode.D then
				currentInputs.Steer = isDown and 1 or 0
			end

			if inputObject.KeyCode == Enum.KeyCode.Space then
				currentInputs.Handbrake = isDown and 1 or 0
			end

			-- If W/S or A/D released, and no other key for that action is pressed:
			if inputObject.UserInputState == Enum.UserInputState.End then
				if inputObject.KeyCode == Enum.KeyCode.W and UserInputService:IsKeyDown(Enum.KeyCode.S) then
					currentInputs.Throttle = -1
				elseif inputObject.KeyCode == Enum.KeyCode.S and UserInputService:IsKeyDown(Enum.KeyCode.W) then
					currentInputs.Throttle = 1
				elseif not UserInputService:IsKeyDown(Enum.KeyCode.W) and not UserInputService:IsKeyDown(Enum.KeyCode.S) then
					currentInputs.Throttle = 0
				end

				if inputObject.KeyCode == Enum.KeyCode.A and UserInputService:IsKeyDown(Enum.KeyCode.D) then
					currentInputs.Steer = 1
				elseif inputObject.KeyCode == Enum.KeyCode.D and UserInputService:IsKeyDown(Enum.KeyCode.A) then
					currentInputs.Steer = -1
				elseif not UserInputService:IsKeyDown(Enum.KeyCode.A) and not UserInputService:IsKeyDown(Enum.KeyCode.D) then
					currentInputs.Steer = 0
				end
			end
		end
	end)
else -- Server-side (Example using VehicleSeat)
	local seat = vehicleModelPath:FindFirstChildWhichIsA("VehicleSeat")
	if seat then
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if seat.Occupant then
				-- Player entered seat
			else
				-- Player exited seat, reset inputs
				currentInputs.Throttle = 0
				currentInputs.Steer = 0
				currentInputs.Brake = 0
				currentInputs.Handbrake = 0
				VehicleChassis:SetInputs(currentInputs)
			end
		end)

		-- In a server script, VehicleSeat throttle/steer are automatically handled by Roblox physics
		-- if the seat is correctly part of the assembly.
		-- For a custom chassis, we need to read these values.
		-- RunService.Stepped:Connect(function()
		--    if seat.Occupant then
		--        currentInputs.Throttle = seat.ThrottleFloat
		--        currentInputs.Steer = seat.SteerFloat
		--        currentInputs.Brake = (seat.ThrottleFloat < -0.1 and currentInputs.Throttle > 0) and 1 or 0 -- Basic brake logic
		--    end
		-- end)
		-- Note: The above Stepped connection for server seat input is better inside Heartbeat.
	else
		warn("No VehicleSeat found in model for server-side input example.")
	end
end


-- Main Update Loop
local function onUpdate(dt: number)
	-- Set inputs to the chassis
	VehicleChassis:SetInputs(currentInputs)

	-- Update the chassis physics
	VehicleChassis:Update(dt)

	-- Update visual representation of wheels (positioning, rotation)
	for _, wheel in pairs(VehicleChassis.Wheels) do
		wheel:UpdateVisuals(dt)
	end
end

-- Connect to RunService.Heartbeat for physics-related updates
-- Or RunService.Stepped if preferred for input/camera before physics.
-- Heartbeat is generally after physics simulation step. For applying forces *before* next step, Stepped is often used.
-- Since our Update applies forces, let's try Stepped.
RunService.Stepped:Connect(onUpdate)


-- Cleanup when the script stops or vehicle is destroyed
game:GetService("Players").PlayerRemoving:Connect(function(player)
	-- Handle cases if player leaves while driving, etc.
end)

-- If this script is destroyed (e.g. parented to a part that's destroyed)
script.Destroying:Connect(function()
	VehicleChassis:Destroy()
	-- Any other cleanup
end)

print("RaycastChassis BasicVehicle example loaded.")
print("Controls: W/S (Throttle), A/D (Steer), Space (Handbrake)")

-- Note: This example is quite detailed. The actual functionality depends heavily on the
-- correct implementation within Chassis.lua and Wheel.lua, especially regarding
-- CFrame calculations for attachments, force application points, and visual updates.
-- Debugging will likely be necessary to tune parameters and fix visual/physical behaviors.
-- The `AttachmentPointWorld` in `Wheel.new` is a critical piece that needs to be correctly
-- interpreted by the Wheel class (likely as an initial world CFrame from which a local offset is derived).
-- The current Wheel.lua expects AttachmentPointWorld to be the initial world CFrame.
-- The wheel's visual update and raycast origin logic will need to correctly use this,
-- probably by calculating a local offset from the chassis body at initialization.
--
-- For `Wheel:GetRaycastOriginAndDirection()` and `Wheel:UpdateVisuals()` to work correctly with a moving/rotating body,
-- they need to use a *local offset* from the body's CFrame to find the world CFrame of the suspension attachment points.
-- This local offset should be calculated once in `Wheel.new()`:
-- e.g., `self.AttachmentOffsetLocal = chassisBody.CFrame:ToObjectSpace(wheelConfig.AttachmentPointWorld)`
-- Then used like: `local currentAttachmentWorldCF = chassisBody.CFrame * self.AttachmentOffsetLocal`
-- This detail needs to be implemented in Wheel.lua based on this example's setup.
-- The example provides `AttachmentPointWorld` as the initial world space CFrame.
-- The Wheel module should internally convert this to a local offset from the main body part.
-- I've added comments in Wheel.lua about this, but the actual calculation using it needs to be firmed up there.
--
-- Specifically, in `Wheel.new`:
-- self.AttachmentOffsetCF_Local = self.Body.CFrame:ToObjectSpace(wheelConfig.AttachmentPointWorld)
--
-- And in `Wheel:GetRaycastOriginAndDirection`:
-- local currentAttachmentWorldCF = self.Body.CFrame * self.AttachmentOffsetCF_Local
-- local origin = currentAttachmentWorldCF.Position + currentAttachmentWorldCF:VectorToWorldSpace(self.Config.RaycastOriginOffset)
-- local direction = currentAttachmentWorldCF.UpVector * -1
--
-- Similar logic for `self.SuspensionForceApplicationPointWorld` update and in `UpdateVisuals`.
-- This example script is a guide; the Wheel and Chassis modules must correctly implement their parts of the contract.
-- The current Wheel.lua has placeholders for this, but the example highlights the need for robust CFrame management.
--
-- Making wheel instances `Anchored = false` and `Massless = true` with `CanCollide = false` is a common setup for
-- custom visual wheels that are CFramed. The main physics interaction is between the chassisBody and the world,
-- driven by raycast forces.
-- If wheels were to have their own physics (e.g. for more detailed collision or independent rotation physics),
-- they'd be unanchored, non-massless, and likely connected via Constraints, with the CFrame updates being more nuanced.
-- For this raycast chassis, fully CFramed visual wheels are typical.
-- The `wheelInstance.Anchored = false` is only if you want Roblox to "help" with rotation or something, but typically for fully custom CFrame, they might be Anchored=true in the model and the script unanchors if needed OR they are CANCollide=false and massless. The example sets Anchored=false, CanCollide=false, Massless=true. This is fine.
-- The chassisBodyPart MUST be Unanchored.
