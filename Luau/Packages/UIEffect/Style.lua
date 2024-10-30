--!nocheck

-- Da Dubious Dynasty

-- Note this module is not done yet.

local Style = {}
Style.__index = Style

local Color = require(script.Parent:WaitForChild("Color"))

local colorModes = {
	["Tonal"] = {
		["Transparency"] = 0.5,
		["TextTransparency"] = 0.2,
		["Outline"] = false,
	},
	["Full"] = {
		["Transparency"] = 1,
		["TextTransparency"] = 0,
		["Outline"] = false,
	},
}

local styles = {
	["Google"] = {
		["Corner"] = {
			["Base"] = UDim.new(1, 0),
			["Action"] = UDim.new(0, 8),
			["Swatch"] = UDim.new(1, 0),
		},
		["Font"] = Enum.Font.Monsterrat :: Font,
	},
	["CreatorHub"] = {
		["Corner"] = {
			["Base"] = UDim.new(0, 8),
			["Action"] = UDim.new(0.2, 0),
			["Swatch"] = UDim.new(1, 0),
		},
	},
}

local function appendStyle(colorMode, style, object: GuiObject)
	for colorMode_ in colorModes[colorMode] do
		object["BackgroundTransparency"] = colorMode_[1]
		if object:IsA("TextLabel") or object:IsA("TextButton") then
			object.TextTransparency = colorMode_[2]
		end
		if colorMode_[3] == true then
			local stroke = Instance.new("UIStroke")
			stroke.Color = Color.getColor("Black")
			stroke.Thickness = 1.5
		end
	end
end

function Style.appendStyle(colorMode, style, object: GuiObject)
	return appendStyle(colorMode, style, object)
end

return Style
