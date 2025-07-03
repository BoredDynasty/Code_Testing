--!strict
--[[
	Utility functions for Vector3 operations that might not be
	directly available or are commonly needed in vehicle physics.
]]

local VectorMath = {}

-- Projects a vector onto a plane defined by a normal.
function VectorMath.projectVectorOnPlane(vector: Vector3, planeNormal: Vector3): Vector3
	local normalizedPlaneNormal = planeNormal.Unit
	local dotProduct = vector:Dot(normalizedPlaneNormal)
	return vector - normalizedPlaneNormal * dotProduct
end

-- Clamps the magnitude of a vector to a maximum value.
-- If the vector's magnitude is less than or equal to maxMagnitude, it returns the original vector.
-- Otherwise, it returns a new vector with the same direction but magnitude clamped to maxMagnitude.
function VectorMath.clampMagnitude(vector: Vector3, maxMagnitude: number): Vector3
	if vector.Magnitude <= maxMagnitude then
		return vector
	else
		return vector.Unit * maxMagnitude
	end
end

-- Calculates the component of a vector along a given direction vector.
-- The direction vector does not need to be normalized beforehand.
function VectorMath.componentAlongVector(vector: Vector3, direction: Vector3): Vector3
	local normalizedDirection = direction.Unit
	local dotProduct = vector:Dot(normalizedDirection)
	return normalizedDirection * dotProduct
end

-- Returns the signed angle in radians between two vectors on a plane defined by an axis.
-- This is useful for determining steering direction, etc.
-- Assumes vectors are on the XZ plane if axis is Y, for example.
function VectorMath.signedAngle(fromVector: Vector3, toVector: Vector3, axis: Vector3): number
	local unsignedAngle = math.acos(math.clamp(fromVector.Unit:Dot(toVector.Unit), -1, 1))
	local crossProduct = fromVector:Cross(toVector)
	local sign = math.sign(crossProduct:Dot(axis))

	-- If sign is zero, vectors are collinear.
	-- If dot product of fromVector and toVector is close to -1, they are opposite, angle is pi.
	-- Otherwise, angle is 0.
	if sign == 0 then
		if fromVector.Unit:Dot(toVector.Unit) < -0.9999 then -- Check if vectors are opposing
			return math.pi
		else
			return 0 -- Vectors are collinear and in the same direction or one is zero vector
		end
	end

	return unsignedAngle * sign
end


-- Linearly interpolates between two vectors.
function VectorMath.lerp(v0: Vector3, v1: Vector3, t: number): Vector3
	return v0 + (v1 - v0) * t
end

-- Linearly interpolates between two CFrames
function VectorMath.lerpCF(cf0: CFrame, cf1: CFrame, t: number): CFrame
	return cf0:Lerp(cf1, t)
end

-- Rotates a Vector3 around an axis by a given angle (in radians).
-- Equivalent to CFrame.fromAxisAngle(axis, angle):VectorToWorldSpace(vector)
-- but can sometimes be more direct.
function VectorMath.rotateVectorAroundAxis(vector: Vector3, axis: Vector3, angle: number): Vector3
	local rotationCFrame = CFrame.fromAxisAngle(axis.Unit, angle)
	return rotationCFrame:VectorToWorldSpace(vector)
end


--[[
	Example Usage:

	local chassisUp = Vector3.new(0, 1, 0)
	local carVelocity = Vector3.new(10, 5, 5)

	-- Get velocity component on the ground plane
	local velocityOnGroundPlane = VectorMath.projectVectorOnPlane(carVelocity, chassisUp)
	print("Velocity on ground plane:", velocityOnGroundPlane) -- Expected: (10, 0, 5)

	local force = Vector3.new(100, 200, 50)
	local maxForceMagnitude = 150
	local clampedForce = VectorMath.clampMagnitude(force, maxForceMagnitude)
	print("Clamped force:", clampedForce) -- Expected: force vector with magnitude 150

	local direction = Vector3.new(1, 0, 0)
	local movement = Vector3.new(5, 3, 2)
	local movementAlongDirection = VectorMath.componentAlongVector(movement, direction)
	print("Movement along X-axis:", movementAlongDirection) -- Expected: (5, 0, 0)
]]

return table.freeze(VectorMath)
