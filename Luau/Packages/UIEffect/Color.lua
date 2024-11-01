--!nocheck

-- Da Dubious Dynasty

local Color = {}

local colors = {
	["Green"] = Color3.fromHex("#55ff7f"),
	["Red"] = Color3.fromHex("#ff4e41"),
	["Light Blue"] = Color3.fromHex("#136aeb"),
	["Blue"] = Color3.fromHex("#335fff"),
	["Yellow"] = Color3.fromHex("#ffff7f"),
	["Orange"] = Color3.fromHex("#ff8c3a"),
	["Pink"] = Color3.fromHex("#ff87ff"),
	["Brown"] = Color3.fromHex("#3f3025"),
	["Hot Pink"] = Color3.fromHex("#ff59d8"),
	["White"] = Color3.fromHex("#FFFFFF"),
	["Black"] = Color3.fromHex("#111216"),
	["Grey"] = Color3.fromHex("#9e9e9e"),
}

function Color.getColor(color)
	return colors[color]
end

function Color.fromHex(hex: string)
	return Color3.fromHex(hex)
end

function Color.fromHex_ToRGB(hex: string)
	hex = hex:gsub("#", "")
	local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
	return Color3.fromRGB(r, g, b)
end

return Color
