local Curve = {}
Curve.__index = Curve

-- Float Curve Module
-- OfficialDynasty

local self

function Curve.Constructor(keys: { FloatCurveKey }, part: { any }, options: {})
	self = setmetatable({}, Curve)

	self.keys = keys
	self.floatCurve = Instance.new("FloatCurve")
	self.part = Instance.new("Part")

	for property, _ in self.part do
		part[property] = part[property]["Properties"]
	end

	for index, position in options["Positions"] do
	end

	self.part.Position = Vector3.new(options["Time"], self.floatCurve:GetValueAtTime(options["Time"]), options["ZAxis"])
	self.floatCurve:SetKeys(keys)

	return self
end

return Curve
