--!nocheck

-- Da Dubious Dynasty

-- Note this module is not done yet.

local Style = {}
Style.__index = Style

-- // Requires
local Color = require(script.Parent:WaitForChild("Color"))
local UILibrary = script.UILibrary

local styles = {
	["Roblox"] = {
		["Buttons"] = {
			["Link"] = Color.fromHex("#335fff"),
			["Any"] = Color.getColor("Grey"),
		},
	},
}

return Style
