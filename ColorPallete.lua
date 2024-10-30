local ColorPallete = {}

local pallete = {
	["Roblox_Creator_Hub"] = {
		["Background"] = Color3.fromHex("#111216"),
		["Text"] = Color3.fromHex("#FFFFFF"),
		["DetailText"] = Color3.fromHex("#bbbcbe"),
		["Fonts"] = {
			"Builder Sans",
			"Builder Extended",
			"Builder Mono",
		},
		["ActiveButton"] = Color3.fromHex("#2c2e34"),
		["Divider"] = Color3.fromHex("#313339"),
		["Outline"] = Color3.fromHex("#313339"),
		["ButtonLink"] = Color3.fromHex("#2f5cff"),
		["ButtonLinkActive"] = Color3.fromHex("#1446ff"),
		["ButtonHover"] = Color3.fromHex("#1f2024"),
		["Markdown"] = Color3.fromHex("#11172e"),
		["LinkText"] = Color3.fromHex("#478bff"),
		["CodeBlock"] = Color3.fromHex("#1f2024"),
	},
}

function ColorPallete.get(scope)
	return pallete[scope]
end

return ColorPallete
