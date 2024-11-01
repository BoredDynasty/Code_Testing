--!nocheck

-- Da Dubious Dynasty

--- @class UIEffect
---
--- A UIEffects Class for all your UI needs.

-- By the way, don't use this Module: https://devforum.roblox.com/t/uianimator-devlog-effects-ui-effect-manager-wip/3190172

local UIEffect = {}
UIEffect.__index = UIEffect

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")

local Style = require(script:WaitForChild("Style"))
local Color = require(script:WaitForChild("Color"))
local SoundManager = require(script:FindFirstChild("SoundManager"))
local Maid = require(script:FindFirstChild("Maid"))
local Curvy = require(script:FindFirstChild("Curvy"))

local Camera = game.Workspace:WaitForChild("Camera")
local Blur = Lighting:WaitForChild("Blur", 5)
if not Blur then
	Blur = Instance.new("BlurEffect", Lighting)
end

export type Color = {
	-- Custom Types of Colors
	["Green"]: Color3,
	["Red"]: Color3,
	["Light Blue"]: Color3,
	["Blue"]: Color3,
	["Yellow"]: Color3,
	["Orange"]: Color3,
	["Pink"]: Color3,
	["Brown"]: Color3,
	["Hot Pink"]: Color3,
}

export type UIEffects = {
	self: {},
}

local self -- nil

Maid.new()

-- Functions

--- @function
---
--- Table Constructor
function UIEffect.Constructor(): UIEffects
	self = setmetatable({}, UIEffect)

	print("Running UIEffectsClass | " .. script:GetAttribute("_VERSION"))

	return self
end

local function stripRichText(text)
	-- Function to strip out rich text tags and return the pure text
	return string.gsub(text, "<.->", "")
end

local function cameraAngle(value, angle, tweenStyle)
	local connection: RBXScriptConnection = nil :: RBXScriptConnection
	if value == true then
		Maid:GiveTask(connection)
		connection = RunService.RenderStepped:Connect(function(deltaTime): RBXScriptConnection
			TweenService:Create(Camera, tweenStyle, { CFrame = Camera.CFrame * CFrame.Angles(angle) })
		end)
	else
		if connection ~= nil then
			Maid:ClearTask(connection)
		end
	end
end

local function cleanupText(textlabel)
	local index = 0
	local text = " "

	if index >= #text then
		return
	end

	print(text:sub(index, index))
	index = index + 1
	textlabel.Text = text
	task.wait(0.05)
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

-- UIEffect Functions

--- @function
---
--- @param color string
--- Returns a Color from the inputted string.
function UIEffect.getColor(color: string): Color
	return Color.getColor(color)
end

--- @function
---
--- Makes a blur effect.
function UIEffect.BlurEffect(value)
	if value == true then
		Curvy:Tween(Blur, TweenInfo.new(0.5), "Size", 10)
	else
		Curvy:Tween(Blur, TweenInfo.new(0.5), "Size", 0)
	end

	return value
end

---@function
---
--- Zooms the Camera
function UIEffect:Zoom(value)
	if value == true then
		Curvy:Tween(Blur, TweenInfo.new(0.3), "Size", 60)
		SoundManager.Play({ "ZoomIn" }, script.UISounds)
	else
		Curvy:Tween(Blur, TweenInfo.new(0.3), "Size", 60)
		SoundManager.Play({ "ZoomOut" }, script.UISounds)
	end

	return value
end

--- @function
---
--- A function that automatically strips the rich text tags out of the inputted string, then does a typewriter effect.
function UIEffect.TypewriterEffect(DisplayedText: { string }, TextLabel, speed): ()
	local Text: string = stripRichText(DisplayedText) :: string -- Removes the rich text tags
	local currentTypedText = ""
	local typingSpeed = speed or 0.05
	TextLabel:SetAttribute("type_writer", true)

	self.translator = LocalizationService:GetTranslatorForPlayerAsync(Players.LocalPlayer)
	if not self.translator then
		self.translator = LocalizationService:GetTranslatorForLocaleAsync(self.sourceLocale)
	end

	assert(TextLabel)

	task.spawn(function()
		debug.profilebegin("UIEffects | Typewriter Effect")
		for index = 1, #Text do
			SoundManager.Play({ "DialogText" }, script.UISounds)
			local formattedText = ""
			local currentTag = ""
			local insideTag = false

			currentTypedText = string.sub(Text, 1, index)

			for indexed = 1, #DisplayedText do
				local char = string.sub(DisplayedText, indexed, indexed)

				if char == "<" then
					insideTag = true
					currentTag = char -- Start of tag
				elseif char == ">" then
					insideTag = false
					currentTag = currentTag .. char -- End of tag
					formattedText = formattedText .. currentTag -- Append complete tag
					currentTag = "" -- Reset tag
				elseif insideTag then
					currentTag = currentTag .. char -- Continue building tag
				elseif #formattedText < #currentTypedText then
					formattedText = formattedText .. char -- Append visible characters gradually
				end
			end

			TextLabel.Text = formattedText
			task.wait(typingSpeed)
		end

		if #DisplayedText >= DisplayedText then
			TextLabel:SetAttribute("type_writer", nil)
			cleanupText(TextLabel)
			SoundManager.Play({ "DialogText" }, script.UISounds)
			debug.profileend("UIEffects | Typewriter Effect")
		end
	end)
end

--- @function
---
--- Plays a sound within a folder in ReplicatedStorage or just ReplicatedStorage.
function UIEffect.Sound(soundType, cleanup)
	SoundManager.Play({ soundType }, script.UISounds)
end

--- @function
---
--- Changes a UI Elements Color
function UIEffect.changeColor(color, frame): ()
	color = Color.getColor(color)

	task.wait(1)
	if frame:IsA("Frame") then
		Curvy:Tween(Blur, TweenInfo.new(0.1), "BackgroundColor3", color)
	elseif frame:IsA("ImageLabel") then
		Curvy:Tween(Blur, TweenInfo.new(0.5), "ImageColor3", color)
	end
end

--- @function
---
--- Similar to GitHub markdown, except using GitHubs markdown inside a string, it converts it into Rich Text which can be later put into a TextLabel with Rich Text enabled.
function UIEffect:markdownToRichText(input): string?
	-- Convert Bold: **text** → <b>text</b>
	input = string.gsub(input, "%*%*(.-)%*%*", "<b>%1</b>")
	-- Convert Italic: *text* → <i>text</i>
	input = string.gsub(input, "%*(.-)%*", "<i>%1</i>")
	-- Convert Underline: __text__ → <u>text</u>
	input = string.gsub(input, "__([^_]-)__", "<u>%1</u>")
	-- Convert Color: {#hexcolor|text} → <font color="hexcolor">text</font>
	input = string.gsub(input, "{#([%x]+)%|(.-)}", '<font color="#%1">%2</font>')

	return input
end

--- @function
---
--- Does a Custom UI Animation from the inputted string.
function UIEffect:CustomAnimation(effect, object: GuiObject, value)
	local objectSize = object.Size
	local objectPosition = object.Position

	task.spawn(function()
		if effect == "Hover" and value == true then
			TweenService:Create(object, newTweenInfo(0.5, "Back", "InOut", 0, false, 0), {
				Size = UDim2.new(
					object.Size.X.Scale * 0.9,
					object.Size.Y.Offset,
					object.Size.Y.Scale * 0.9,
					object.Size.Y.Offset
				),
			}):Play()
		elseif value == false then
			TweenService
				:Create(object, newTweenInfo(0.5, "Back", "InOut", 0, false, 0), {
					Size = UDim2.new(
						object.Size.X.Scale,
						object.Size.X.Offset,
						object.Size.Y.Scale,
						object.Size.Y.Offset
					),
				})
				:Play()
		elseif effect == "Click" then
			TweenService:Create(
				object,
				newTweenInfo(0.2, "Back", "InOut", 0, false, 0)({
					Size = UDim2.new(
						object.Size.X.Scale * 0.9,
						object.Size.Y.Offset,
						object.Size.Y.Scale * 0.9,
						object.Size.Y.Offset
					),
				})
			)
			task.wait(0.2)
			TweenService:Create(
				object,
				newTweenInfo(0.2, "Back", "InOut", 0, false, 0)({
					Size = UDim2.new(
						object.Size.X.Scale,
						object.Size.X.Offset,
						object.Size.Y.Scale,
						object.Size.Y.Offset
					),
				})
			)
		end
	end)
end

function UIEffect:changeVisibility(canvas: CanvasGroup, value, frame: Frame?)
	assert(canvas)
	if value == true then
		canvas.Visible = true
		canvas.Position = UDim2.fromScale(0.5, 0.4)
		local Tween =
			TweenService:Create(canvas, newTweenInfo(0.5, "Sine", "Out", 0, false, 0), { GroupTransparency = 0 })
		Tween:Play()
		local Tween2 = TweenService:Create(
			canvas,
			newTweenInfo(0.5, "Sine", "Out", 0, false, 0),
			{ Position = UDim2.fromScale(0.5, 0.5) }
		)
		Tween2:Play()

		if frame then
			if frame.AnchorPoint ~= Vector2.new(0.5, 0.5) then
				return
			else
				frame.Position = UDim2.fromScale(0.5, 0.42)
				TweenService
					:Create(
						frame,
						newTweenInfo(0.5, "Sine", "Out", 0, false, 0),
						{ Position = UDim2.fromScale(0.5, 0.5) }
					)
					:Play()
			end
		end
	else
		canvas.Visible = true
		canvas.Position = UDim2.fromScale(0.5, 0.5)
		local Tween =
			TweenService:Create(canvas, newTweenInfo(0.5, "Sine", "Out", 0, false, 0), { GroupTransparency = 1 })
		Tween:Play()
		local Tween2 = TweenService:Create(
			canvas,
			newTweenInfo(0.5, "Sine", "Out", 0, false, 0),
			{ Position = UDim2.fromScale(0.5, 0.4) }
		)
		Tween2:Play()

		if frame then
			if frame.AnchorPoint ~= Vector2.new(0.5, 0.5) then
				return
			else
				frame.Position = UDim2.fromScale(0.5, 0.5)
				TweenService
					:Create(
						frame,
						newTweenInfo(0.5, "Sine", "Out", 0, false, 0),
						{ Position = UDim2.fromScale(0.5, 0.42) }
					)
					:Play()
				task.wait(0.6)
				frame.Position = UDim2.fromScale(0.5, 0.5) -- revert
			end
		end
	end
end
--[[
function UIEffect:smoothSwitch(components: {})
	local component = components[1]
	-- We want component 1 to dissapear so...
	if component:IsA("ImageButton") then
		component.Visible = true
		TweenService:Create(component, newTweenInfo(0.5, "Sine", "Out", 0, false, 0), { ImageTransparency = 1 }):Play()
	elseif component:IsA("Frame") then
		component.Visible = true
		TweenService:Create(component, newTweenInfo(0.5, "Sine", "Out", 0, false, 0), { BackgroundTransparency = 1 })
			:Play()
	elseif component:IsA("TextButton") then
		component.Visible = true
		TweenService:Create(component, newTweenInfo(0.5, "Sine", "Out", 0, false, 0), { BackgroundTransparency = 1 })
			:Play()
	elseif component:IsA("TextLabel") then
		component.Visible = true
		TweenService:Create(component, newTweenInfo(0.5, "Sine", "Out", 0, false, 0), { BackgroundTransparency = 1 })
			:Play()
	end
end

function UIEffect:styleButton(object, style) end
--]]
-- Thats for the future
return UIEffect
