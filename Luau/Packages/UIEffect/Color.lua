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

return Color
