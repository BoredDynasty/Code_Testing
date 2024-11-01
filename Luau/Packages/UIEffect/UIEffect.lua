--!nocheck

-- Da Dubious Dynasty

--- @class UIEffect
---
--- A UIEffects Class for all your UI needs.

-- By the way, don't use this Module: https://devforum.roblox.com/t/uianimator-devlog-effects-ui-effect-manager-wip/3190172

local UIEffect = {}
UIEffect.__index = UIEffect

-- // Services
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- // Requires
local Style = require(script:FindFirstChild("Style"))
local Color = require(script:FindFirstChild("Color"))
local SoundManager = require(script:FindFirstChild("SoundManager"))
local Maid = require(script:FindFirstChild("Maid"))
local Curvy = require(script:FindFirstChild("Curvy"))
local Text = require(script:FindFirstChild("Text"))

local Camera = game.Workspace.CurrentCamera
local Blur = Lighting:WaitForChild("Blur", 5)
if not Blur then
	Blur = Instance.new("BlurEffect", Lighting)
end

export type UIEffects = {
	self: {},
}

local self -- nil

Maid.new()

local function cameraAngle(value, angle, tweenStyle)
	local connection: RBXScriptConnection = nil :: RBXScriptConnection
	if value == true then
		Maid:GiveTask(connection)
		connection = RunService.RenderStepped:Connect(function(deltaTime): RBXScriptConnection
			local target = Camera.CFrame * CFrame.Angles(angle)
			Curvy:Curve(Camera, tweenStyle, "CFrame", target)
		end)
	else
		if connection ~= nil then
			Maid:ClearTask(connection)
		end
	end
end

-- // UIEffect

--[=[
	@function getColor
		@within UIEffect
		@param color string
		@return Color3? | BrickColor?
--]=]
function UIEffect.getColor(color: string)
	return Color.getColor(color)
end

--[=[
	@function BlurEffect
		@within UIEffect
		@param value boolean
		@return boolean?
--]=]
function UIEffect.BlurEffect(value)
	if value == true then
		Curvy:Tween(Blur, TweenInfo.new(0.5), "Size", 10)
	else
		Curvy:Tween(Blur, TweenInfo.new(0.5), "Size", 0)
	end
	return value
end

--[=[
	@function Zoom
		@wihin UIEffect
		@param value boolean
		@return boolean?
--]=]
function UIEffect:Zoom(value)
	if value == true then
		Curvy:Curve(Blur, TweenInfo.new(0.3), "Size", 60)
		SoundManager.Play({ "ZoomIn" }, script.UISounds)
	else
		Curvy:Curve(Blur, TweenInfo.new(0.3), "Size", 60)
		SoundManager.Play({ "ZoomOut" }, script.UISounds)
	end

	return value
end

--[=[
	@function TypewriterEffect
		@within UIEffect
		@param DisplayText table string
		@param textlabel TextLabel | TextButton
		@param speed number
--]=]
function UIEffect.TypewriterEffect(DisplayedText: { string }, textlabel, speed): ()
	return Text.TypewriterEffect(DisplayedText, textlabel, speed)
end

--[=[
	@function Sound
		@within UIEffect
		@param soundType string | number
--]=]
function UIEffect.Sound(soundType)
	SoundManager.Play({ soundType }, script.UISounds)
end

--[=[
	@function changeColor
		@within UIEffect
		@param color string
		@param frame Frame
--]=]
function UIEffect.changeColor(color, frame): ()
	color = Color.getColor(color)

	task.wait(1)
	if frame:IsA("Frame") then
		Curvy:Tween(Blur, TweenInfo.new(0.1), "BackgroundColor3", color)
	elseif frame:IsA("ImageLabel") then
		Curvy:Tween(Blur, TweenInfo.new(0.5), "ImageColor3", color)
	end
end

--[=[
	@function markdownToRichText
		@within UIEffect
		@param input string
		@return string?
--]=]
function UIEffect:markdownToRichText(input): string?
	return Text:MD_ToRichText(input)
end

--[=[
	@function CustomAnimation
		@within UIEffect
		@param effect any
		@param object GuiObbject
		@param value boolean
--]=]
function UIEffect:CustomAnimation(effect, object: GuiObject, value)
	local objectSize = object.Size
	local objectPosition = object.Position

	task.spawn(function()
		if effect == "Hover" and value == true then
			local target = UDim2.new(
				object.Size.X.Scale * 0.9,
				object.Size.Y.Offset,
				object.Size.Y.Scale * 0.9,
				object.Size.Y.Offset
			)
			Curvy:Curve(object, Curvy.TweenInfo(0.5, "Back", "InOut", 0, false, 0), "Size", target)
		elseif value == false then
			local target =
				UDim2.new(object.Size.X.Scale, object.Size.X.Offset, object.Size.Y.Scale, object.Size.Y.Offset)
			Curvy:Curve(object, Curvy.TweenInfo(0.5, "Back", "InOut", 0, false, 0), "Size", target)
		elseif effect == "Click" then
			local target = UDim2.new(
				object.Size.X.Scale * 0.9,
				object.Size.Y.Offset,
				object.Size.Y.Scale * 0.9,
				object.Size.Y.Offset
			)
			Curvy:Curve(object, Curvy.TweenInfo(0.2, "Back", "InOut", 0, false, 0), "Size", target)
			task.wait(0.2)
			local newTarget =
				UDim2.new(object.Size.X.Scale, object.Size.X.Offset, object.Size.Y.Scale, object.Size.Y.Offset)
			Curvy:Create(object, Curvy.TweenInfo(0.2, "Back", "InOut", 0, false, 0), "Size", target)
		end
	end)
end
--[=[
	@function changeVisibility
		@within UIEffect
		@param canvas CanvasGroup
		@param value boolean
		@param frame Frame?
--]=]
function UIEffect:changeVisibility(canvas: CanvasGroup, value, frame: Frame?)
	assert(canvas)
	if value == true then
		canvas.Visible = true
		canvas.Position = UDim2.fromScale(0.5, 0.4)
		Curvy:Curve(canvas, Curvy.TweenInfo(0.5, "Sine", "Out", 0, false, 0), "GroupTransparency", 0)
		local target = UDim2.fromScale(0.5, 0.5)
		Curvy:Curve(canvas, Curvy.TweenInfo(0.5, "Sine", "Out", 0, false, 0), "Position", target)

		if frame then
			if frame.AnchorPoint ~= Vector2.new(0.5, 0.5) then
				return
			else
				frame.Position = UDim2.fromScale(0.5, 0.42)
				Curvy:Curve(
					frame,
					Curvy.TweenInfo(0.5, "Sine", "Out", 0, false, 0),
					"Position",
					UDim2.fromScale(0.5, 0.5)
				)
			end
		end
	else
		canvas.Visible = true
		canvas.Position = UDim2.fromScale(0.5, 0.5)
		Curvy:Curve(canvas, Curvy.TweenInfo(0.5, "Sine", "Out", 0, false, 0), "GroupTransparency", 0)
		Curvy:Curve(canvas, Curvy.TweenInfo(0.5, "Sine", "Out", 0, false, 0), "Position", UDim2.fromScale(0.5, 0.4))

		if frame then
			if frame.AnchorPoint ~= Vector2.new(0.5, 0.5) then
				return
			else
				frame.Position = UDim2.fromScale(0.5, 0.5)
				Curvy
					:Curve(
						frame,
						Curvy.TweenInfo(0.5, "Sine", "Out", 0, false, 0),
						"Position",
						UDim2.fromScale(0.5, 0.42)
					)
					:Play()
				task.wait(0.6)
				frame.Position = UDim2.fromScale(0.5, 0.5) -- revert
			end
		end
	end
end

return UIEffect
