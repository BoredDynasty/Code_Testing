local Curvy = {}
Curvy.__index = Curvy

-- Da Dubious Dynasty

-- This is unfinished

local TweenService = game:GetService("TweenService")

local self = nil

local function addCurve(destination: any)
	table.insert(self.Curves, destination)
	return destination, self.Curves
end

local function addObject(objects: {})
	for i, object in objects do
		table.insert(objects.Objects, object)
	end
	return self.Objects, self
end

local function newTweenInfo(seconds, style, direction, repeatCount, reverses, delayTime): TweenInfo
	return TweenInfo.new(
		seconds,
		Enum.EasingStyle[style],
		Enum.EasingDirection[direction],
		repeatCount,
		reverses,
		delayTime
	)
end

local function createCurve(object, info, property, target): Tween
	return TweenService:Create(object, info, { property = target })
end

function Curvy:Tween(object, info, property, target)
	local tween = createCurve(object, info, property, target)
	tween:Play()
	return tween
end

function Curvy.TweenInfo(seconds, style, direction, repeatCount, reverses, delayTime)
	return newTweenInfo(seconds, style, direction, repeatCount, reverses, delayTime)
end

return Curvy
