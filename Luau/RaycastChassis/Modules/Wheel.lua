--!strict
--[[
	Class representing a single wheel on the vehicle.
	Handles raycasting for suspension, calculating tire forces,
	and applying forces to the vehicle body.
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Assuming Config module is available
-- For type reference from Chassis.lua
-- type ChassisConfig = Chassis.ChassisConfig
-- type DefaultWheelConfig = Config.DefaultWheelConfig

export type WheelConfig = {
	Name: string,
	Instance: BasePart, -- The visual wheel part
	AttachmentPointWorld: CFrame, -- Initial CFrame of where the suspension connects to the body, in world space
	                               -- This should be derived from an Attachment on the body or a Part position.
	RaycastOriginOffset: Vector3, -- Offset from AttachmentPointWorld.Position for ray starting point (in world space, or local to attachment CFrame)

	Radius: number,
	Width: number,
	Mass: number,
	VisualOffset: Vector3, -- Offset of the visual wheel part from its suspension point

	IsSteeringWheel: boolean,
	IsDrivenWheel: boolean,
	IsHandbrakeWheel: boolean,

	-- Suspension, Tire, etc. settings can be per-wheel or inherit from ChassisConfig
	SuspensionRestLength: number,
	SuspensionStiffness: number,
	SuspensionDamping: number,
	SuspensionMaxForce: number,

	TireFrictionCoefficient: number,
	TireLateralStiffness: number,
	TireLongitudinalStiffness: number,

	-- Reference to the main chassis config for other shared values
	ParentChassisConfig: any, -- TODO: type this with ChassisConfig once cycles are handled or via a forward declaration
}

local Wheel = {}
Wheel.__index = Wheel
Wheel.ClassName = "Wheel" -- For type checking if needed

function Wheel.new(wheelPart: BasePart, chassisBody: BasePart, wheelConfig: WheelConfig)
	local self = setmetatable({}, Wheel)

	assert(wheelPart, "Wheel.new requires a BasePart for the wheel instance.")
	assert(chassisBody, "Wheel.new requires a BasePart for the chassisBody.")
	assert(wheelConfig, "Wheel.new requires a wheelConfig table.")
	assert(wheelConfig.AttachmentPointWorld, "wheelConfig must include AttachmentPointWorld CFrame.")

	self.Instance = wheelPart
	self.Body = chassisBody -- Reference to the main vehicle body
	self.Config = wheelConfig

	self.CurrentSteerAngle = 0 -- Degrees
	self.TargetSteerAngle = 0 -- Degrees

	self.RaycastOrigin = Vector3.zero -- To be updated each frame
	self.RaycastDirection = Vector3.down -- Default, can be updated based on suspension geometry

	self._isOnGround = false
	self._lastRaycastResult = nil :: RaycastResult?
	self._lastCompression = 0
	self._lastHitPointWorld = Vector3.zero
	self._springVelocity = 0

	-- Accumulated forces to be applied to the chassis body at the end of the step
	self._accumulatedForce = Vector3.zero
	self._accumulatedTorque = Vector3.zero -- For forces not acting through CoM of body

	-- Store the local CFrame offset of the suspension attachment point from the chassis body's CFrame
	self.AttachmentOffsetCF_Local = self.Body.CFrame:ToObjectSpace(wheelConfig.AttachmentPointWorld)

	-- The suspension force will be applied at this point on the body, in world space (updated dynamically)
	self.SuspensionForceApplicationPointWorld = wheelConfig.AttachmentPointWorld.Position

	-- For calculating spring velocity & visual wheel spin
	local initialAttachmentWorldCF = self.Body.CFrame * self.AttachmentOffsetCF_Local
	self._prevFrameWheelHitPointWorld = initialAttachmentWorldCF.Position - (initialAttachmentWorldCF.UpVector * self.Config.SuspensionRestLength)
	self._prevFrameWheelHubPositionWorld = initialAttachmentWorldCF.Position - (initialAttachmentWorldCF.UpVector * self.Config.SuspensionRestLength) + (initialAttachmentWorldCF.UpVector * self.Config.Radius)


	if self.Config.IsSteeringWheel then
		-- Create a HingeConstraint or similar if we want to physically rotate the wheel part
		-- For now, we'll just CFrame it.
	end

	return self
end

function Wheel:SetSteerAngle(angle: number)
	self.TargetSteerAngle = math.clamp(angle, -self.Config.ParentChassisConfig.Steering.MaxSteerAngle, self.Config.ParentChassisConfig.Steering.MaxSteerAngle)
	-- Actual angle update can be smoothed/interpolated in an update method
end

function Wheel:_updateSteerVisual(dt: number)
	if not self.Config.IsSteeringWheel then
		self.CurrentSteerAngle = 0
		return
	end

	local steerSpeed = self.Config.ParentChassisConfig.Steering.SteerSpeed
	local diff = self.TargetSteerAngle - self.CurrentSteerAngle
	if math.abs(diff) < 0.1 then
		self.CurrentSteerAngle = self.TargetSteerAngle
	else
		self.CurrentSteerAngle += math.sign(diff) * math.min(math.abs(diff), steerSpeed * dt)
	end
end


function Wheel:GetRaycastOriginAndDirection() : (Vector3, Vector3)
	-- The ray starts from the suspension's top attachment point on the chassis body.
	-- This point moves with the chassis body.
	local attachmentCF = self.Body.CFrame * self.Config.AttachmentPointWorld:ToObjectSpace(self.Body.CFrame) -- This recalculates attachment point in world based on current body CFrame

	-- If AttachmentPointWorld was defined relative to body's CFrame initially, it's simpler:
	-- local attachmentCF_local = self.InitialBodyCFrame:ToObjectSpace(self.Config.AttachmentPointWorld)
	-- local attachmentCF_world = self.Body.CFrame * attachmentCF_local

	-- For simplicity, let's assume AttachmentPointWorld was the intended world CFrame at t=0
	-- And we have its offset from the body's CoM (or a known part of the body)
	-- The most robust way is to use an actual Attachment instance on the body.
	-- For now, let's assume AttachmentPointWorld is a CFrame that defines the suspension top point's local offset from Body.Position
	-- No, AttachmentPointWorld is defined in world space at init. We need its position relative to the body's CFrame.

	-- Let's assume self.Config.AttachmentPointLocal is a CFrame relative to self.Body.CFrame
	-- This should be calculated at init: self.AttachmentPointLocal = self.Body.CFrame:ToObjectSpace(self.Config.AttachmentPointWorld)
	-- Then, current world CFrame is: currentAttachmentWorldCF = self.Body.CFrame * self.AttachmentPointLocal

	-- For now, using the stored world position of the application point, which should be updated if it's based on an Attachment
	-- This part is crucial and needs to be robust.
	-- Use the stored local offset to find the current world CFrame of the attachment point
	local currentAttachmentWorldCF = self.Body.CFrame * self.AttachmentOffsetCF_Local

	local origin = currentAttachmentWorldCF.Position + currentAttachmentWorldCF:VectorToWorldSpace(self.Config.RaycastOriginOffset)
	local direction = currentAttachmentWorldCF.UpVector * -1 -- Downwards relative to the attachment's orientation

	self.RaycastOrigin = origin
	self.RaycastDirection = direction

	-- Update the world point for force application dynamically
	self.SuspensionForceApplicationPointWorld = currentAttachmentWorldCF.Position

	return origin, direction
end


function Wheel:UpdateSuspensionData(isOnGround: boolean, suspensionForce: Vector3, hitPoint: Vector3, hitNormal: Vector3, hitPart: BasePart?, dt: number)
	self._isOnGround = isOnGround

	if self._isOnGround then
		self._lastRaycastResult = { Position = hitPoint, Normal = hitNormal, Instance = hitPart } -- Simplified RaycastResult
		self._lastHitPointWorld = hitPoint

		-- Calculate current compression based on the distance from the dynamic raycast origin to the hit point
		local currentSuspensionLength = (self.RaycastOrigin - hitPoint).Magnitude
		local currentCompression = self.Config.SuspensionRestLength - currentSuspensionLength

		-- Calculate spring velocity (rate of change of compression)
		-- This can also be calculated using GetSpringVelocity method before applying forces.
		-- For simplicity here, using compression difference if GetSpringVelocity isn't called first by Chassis.
		if dt > 0 then
			self._springVelocity = (currentCompression - self._lastCompression) / dt
		else
			self._springVelocity = 0
		end
		self._lastCompression = currentCompression

		-- Add suspension force to be applied to body
		-- The force is applied at self.SuspensionForceApplicationPointWorld (top of the spring, updated dynamically)
		self:AddForceToBody(suspensionForce, self.SuspensionForceApplicationPointWorld)
	else
		self._lastRaycastResult = nil
		self._springVelocity = 0
		self._lastCompression = 0
		-- self._lastHitPointWorld remains the last known contact point or resets.
	end

	-- Update previous hit point for next frame's calculations (used in GetSpringVelocity and visual wheel spin)
	self._prevFrameWheelHitPointWorld = self._isOnGround and hitPoint or (self.RaycastOrigin + self.RaycastDirection * self.Config.SuspensionRestLength)
end

function Wheel:GetSpringVelocity(currentHitPointWorld: Vector3, dt: number): number
	-- This function calculates the velocity of the suspension spring's compression/extension.
	-- It's based on the relative velocities of the wheel's contact point on the ground
	-- and the suspension's attachment point on the chassis body, projected onto the suspension axis.

	local suspensionAxis = self.RaycastDirection * -1 -- The direction of suspension travel (e.g., world up vector of attachment)

	-- Velocity of the chassis body at the suspension attachment point, projected onto the suspension axis.
	local chassisAttachmentPointVelocity = self.Body:GetVelocityAtPosition(self.SuspensionForceApplicationPointWorld)
	local chassisComponentVelocity = chassisAttachmentPointVelocity:Dot(suspensionAxis)

	-- Velocity of the wheel's contact point on the ground, projected onto the suspension axis.
	local groundComponentVelocity = 0
	if self._isOnGround and self._lastRaycastResult and self._lastRaycastResult.Instance then
		-- If the ground is a moving part (e.g., a platform), get its velocity.
		local groundPart = self._lastRaycastResult.Instance
		if groundPart:IsA("BasePart") then
			local groundContactPointVelocity = groundPart:GetVelocityAtPosition(currentHitPointWorld)
			groundComponentVelocity = groundContactPointVelocity:Dot(suspensionAxis)
		end
	end

	-- The spring velocity is the difference between how fast the attachment point is moving
	-- along the suspension axis and how fast the contact point is moving along the same axis.
	return chassisComponentVelocity - groundComponentVelocity
end


function Wheel:ApplyCachedForces(dt: number)
	-- If not raycasting this frame, we might still want to apply some forces
	-- e.g., gravity on the wheel mass itself if it's significant, or decay existing forces.
	-- For now, this is a placeholder. The main chassis handles body gravity.
end

function Wheel:ResetTireForces()
	-- Reset any applied tire forces if the wheel is not on the ground
end

function Wheel:ApplyDriveAndBrake(driveForceMagnitude: number, brakeForceMagnitude: number, dt: number)
	if not self._isOnGround or not self._lastRaycastResult then return end

	local wheelForwardVector = self.Body.CFrame:VectorToWorldSpace(Vector3.new(0,0,-1)) -- Assuming Z- is forward for the chassis body
	-- This needs to be adjusted by steer angle if it's a front wheel
	if self.Config.IsSteeringWheel and self.CurrentSteerAngle ~= 0 then
		local steerRotation = CFrame.fromAxisAngle(self.Body.CFrame.UpVector, math.rad(self.CurrentSteerAngle))
		wheelForwardVector = steerRotation * wheelForwardVector
	end

	-- Project forward vector onto the ground plane
	local groundNormal = self._lastRaycastResult.Normal
	local tireForwardOnGround = (wheelForwardVector - groundNormal * wheelForwardVector:Dot(groundNormal)).Unit

	local totalForce = 0
	if driveForceMagnitude ~= 0 then
		-- Apply drive force. Consider available friction.
		-- Simplified: Max drive force is limited by friction * normal force (suspension upward reaction)
		-- This is where slip ratio calculation would go.
		totalForce += driveForceMagnitude
	end

	if brakeForceMagnitude > 0 then
		-- Apply brake force. Needs wheel's current velocity direction.
		local wheelVelocityAtContact = self.Body:GetVelocityAtPosition(self._lastHitPointWorld)
		local wheelSpeedAlongForward = wheelVelocityAtContact:Dot(tireForwardOnGround)

		local brakingDir = -math.sign(wheelSpeedAlongForward) -- Brake opposes current motion along tire's forward
		if wheelSpeedAlongForward == 0 then brakingDir = -math.sign(driveForceMagnitude) end -- If stationary, brake opposes potential drive

		totalForce += brakingDir * brakeForceMagnitude
	end

	-- Apply this longitudinal force
	-- Limit by tire friction: Max Longitudinal Force = NormalForce * FrictionCoefficient
	local normalForceMagnitude = self:GetLastSuspensionForceMagnitude() -- Assuming this is available
	local maxLongitudinalForce = normalForceMagnitude * self.Config.TireFrictionCoefficient

	local actualLongitudinalForce = math.clamp(totalForce, -maxLongitudinalForce, maxLongitudinalForce)

	local forceVector = tireForwardOnGround * actualLongitudinalForce
	self:AddForceToBody(forceVector, self._lastHitPointWorld)
end

function Wheel:CalculateLateralForce(lateralStiffnessFactor: number, dt: number): Vector3
	if not self._isOnGround or not self._lastRaycastResult then return Vector3.zero end

	local wheelRightVector = self.Body.CFrame:VectorToWorldSpace(Vector3.new(1,0,0)) -- Assuming X+ is right for the chassis body
	if self.Config.IsSteeringWheel and self.CurrentSteerAngle ~= 0 then
		local steerRotation = CFrame.fromAxisAngle(self.Body.CFrame.UpVector, math.rad(self.CurrentSteerAngle))
		wheelRightVector = steerRotation * wheelRightVector
	end

	local groundNormal = self._lastRaycastResult.Normal
	local tireRightOnGround = (wheelRightVector - groundNormal * wheelRightVector:Dot(groundNormal)).Unit

	-- Calculate slip angle
	-- Slip Angle = atan(lateral velocity / longitudinal velocity) at the tire contact patch
	local contactPointVelocity = self.Body:GetVelocityAtPosition(self._lastHitPointWorld)
	if self._lastRaycastResult.Instance then -- Account for moving ground if any
		contactPointVelocity -= self._lastRaycastResult.Instance:GetVelocityAtPosition(self._lastHitPointWorld)
	end

	local tireForwardOnGround = ( (self.Body.CFrame * CFrame.Angles(0,math.rad(self.CurrentSteerAngle),0)).LookVector - groundNormal * (self.Body.CFrame * CFrame.Angles(0,math.rad(self.CurrentSteerAngle),0)).LookVector:Dot(groundNormal) ).Unit

	local vLateral = contactPointVelocity:Dot(tireRightOnGround)
	local vLongitudinal = contactPointVelocity:Dot(tireForwardOnGround)

	local slipAngle = 0
	if math.abs(vLongitudinal) > 0.1 then -- Avoid division by zero, or very small longitudinal vel
		slipAngle = math.atan(vLateral / vLongitudinal)
	else
		slipAngle = math.pi/2 * math.sign(vLateral) -- Max slip if no forward speed but sideways speed
	end

	-- Simplified lateral force: F_lateral = -slipAngle * stiffness
	-- Note: Pacejka curves are more complex. This is linear.
	local lateralForceMagnitude = -slipAngle * lateralStiffnessFactor * self:GetLastSuspensionForceMagnitude() -- Scale by normal force

	-- Limit by tire friction
	local normalForceMagnitude = self:GetLastSuspensionForceMagnitude()
	local maxLateralForce = normalForceMagnitude * self.Config.TireFrictionCoefficient
	-- This maxLateralForce should consider combined slip (longitudinal and lateral) using a friction circle/ellipse.

	lateralForceMagnitude = math.clamp(lateralForceMagnitude, -maxLateralForce, maxLateralForce)

	local forceVector = tireRightOnGround * lateralForceMagnitude
	self:AddForceToBody(forceVector, self._lastHitPointWorld)
	return forceVector
end

function Wheel:GetLastSuspensionForceMagnitude(): number
	-- This needs to be the reaction force from the ground, i.e., the upward component of suspension force.
	-- If self._accumulatedForce contains the latest suspension force, we can use its magnitude.
	-- More accurately, it's the force calculated in UpdateSuspensionData.
	-- For now, let's assume it's related to compression and damping, projected onto ground normal.
	-- This needs to be more robust. The suspension force applied to the body is what we need.
	if self._isOnGround and self._lastRaycastResult then
		-- A rough estimate based on stiffness and compression, should be the actual applied force's magnitude
		return (self.Config.SuspensionStiffness * self._lastCompression + self.Config.SuspensionDamping * self._springVelocity)
	end
	return 0
end


function Wheel:AddForceToBody(force: Vector3, applicationPointWorld: Vector3)
	-- Forces are accumulated and applied once per frame by the Chassis class
	-- to avoid multiple calls to ApplyForce/ApplyImpulse on the same body part in one physics step.
	-- However, Roblox's physics engine handles this internally now.
	-- For direct application:
	-- self.Body:ApplyForceAtPosition(force, applicationPointWorld)

	-- Accumulate:
	self._accumulatedForce += force

	-- Calculate torque if force is not applied at center of mass
	local centerOfMassWorld = self.Body.AssemblyCenterOfMass
	local leverArm = applicationPointWorld - centerOfMassWorld
	self._accumulatedTorque += leverArm:Cross(force)
end

function Wheel:ApplyAccumulatedForcesToBody(body: BasePart, dt: number)
	if self._accumulatedForce.Magnitude > 0 then
		-- body:ApplyImpulse(self._accumulatedForce * dt) -- If forces are continuous over dt
		body:ApplyForce(self._accumulatedForce) -- If forces represent instantaneous change for this frame
	end
	if self._accumulatedTorque.Magnitude > 0 then
		-- body:ApplyAngularImpulse(self._accumulatedTorque * dt)
		body.AssemblyAngularVelocity += body.AssemblyInertia:Inverse() * self._accumulatedTorque * dt -- This is more direct for torque
		-- Or use VectorForce/Torque objects if preferred for continuous application.
		-- For direct physics manipulation, ApplyForce and manually adjusting AssemblyAngularVelocity is one way.
	end

	-- Reset for next frame
	self._accumulatedForce = Vector3.zero
	self._accumulatedTorque = Vector3.zero
end


function Wheel:UpdateVisuals(dt: number)
	self:_updateSteerVisual(dt)

	-- Position and orient the visual wheel part based on suspension and steering
	-- This is a key part for making it look right.
	-- The wheel is attached to the end of the suspension spring.

	-- 1. Get the current top attachment CFrame of the suspension on the body.
	-- 1. Get the current top attachment CFrame of the suspension on the body.
	local currentAttachmentWorldCF = self.Body.CFrame * self.AttachmentOffsetCF_Local

	local wheelHubPositionWorld: Vector3
	if self._isOnGround and self._lastRaycastResult then
		-- The visual wheel hub is the hit point offset by radius along hit normal
		wheelHubPositionWorld = self._lastHitPointWorld + self._lastRaycastResult.Normal * self.Config.Radius
	else
		-- Wheel in air: position it at full extension from the *current* attachment point's downward direction
		-- The raycast direction is currentAttachmentWorldCF.UpVector * -1
		wheelHubPositionWorld = currentAttachmentWorldCF.Position + (currentAttachmentWorldCF.UpVector * -1) * self.Config.SuspensionRestLength + (currentAttachmentWorldCF.UpVector * self.Config.Radius)
	end

	-- Orientation:
	-- UpVector for the wheel should be the ground normal if on ground, or attachment's up vector if in air.
	local wheelUpVector = currentAttachmentWorldCF.UpVector
	if self._isOnGround and self._lastRaycastResult then
		wheelUpVector = self._lastRaycastResult.Normal
	end

	-- LookVector for the wheel is derived from the body's look vector, rotated by steer angle, then made orthogonal to wheelUpVector.
	local bodySteeredLookVector = (self.Body.CFrame * CFrame.Angles(0, math.rad(self.CurrentSteerAngle), 0)).LookVector

	local wheelRightVector = bodySteeredLookVector:Cross(wheelUpVector)
	-- If bodySteeredLookVector is parallel to wheelUpVector (e.g. car on a vertical wall, looking up/down wall), Cross product is zero.
	if wheelRightVector.Magnitude < 0.001 then
		-- Fallback: use attachment's right vector or body's right vector
		wheelRightVector = (self.Body.CFrame * CFrame.Angles(0, math.rad(self.CurrentSteerAngle), 0)).RightVector
	else
		wheelRightVector = wheelRightVector.Unit
	end

	local wheelLookVector = wheelUpVector:Cross(wheelRightVector).Unit

	local targetCF = CFrame.fromMatrix(wheelHubPositionWorld, wheelRightVector, wheelUpVector, wheelLookVector)

	-- Add visual offset if any (e.g. if wheel part's origin is not its center relative to suspension point)
	targetCF = targetCF * CFrame.new(self.Config.VisualOffset)

	-- Apply CFrame
	self.Instance.CFrame = targetCF

	-- Visual wheel rotation (spin)
	if dt > 0 and self.Config.Radius > 0 then
		local linearVelocityMagnitude = (wheelHubPositionWorld - self._prevFrameWheelHubPositionWorld).Magnitude / dt
		self._prevFrameWheelHubPositionWorld = wheelHubPositionWorld -- Store for next frame

		-- Determine direction of movement relative to wheel's forward vector to correctly sign the rotation
		local movementDirection = (wheelHubPositionWorld - self._prevFrameWheelHubPositionWorld)
		local forwardSpeed = movementDirection:Dot(wheelLookVector) / dt -- speed along wheel's current forward

		local wheelCircumference = 2 * math.pi * self.Config.Radius
		local rotationThisFrame = (forwardSpeed / wheelCircumference) * (2 * math.pi) -- radians for this frame

		-- Apply rotation around the wheel's right vector (axle)
		-- In Roblox CFrame.Angles(rx, ry, rz), rx is rotation about X-axis.
		-- If wheelRightVector is X-axis, then this is correct.
		self.Instance.CFrame = self.Instance.CFrame * CFrame.Angles(rotationThisFrame, 0, 0)
	else
		self._prevFrameWheelHubPositionWorld = wheelHubPositionWorld -- Still update if dt is 0
	end
end

function Wheel:IsOnGround(): boolean
	return self._isOnGround
end

function Wheel:Destroy()
	-- Disconnect any connections, remove any created instances (like constraints if used)
	-- For now, nothing complex to clean up besides what GC handles.
end

return Wheel
