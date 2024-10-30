--[=[
    @class Dialog
--]=]
local Dialog = {}
Dialog.__index = Dialog

-- Does not support Rich Text.
-- OfficialDynasty

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

export type Dialog = {
	self: { any? },
}

local self

local function typeWriterEffect(textLabel: TextLabel, text: string)
	for i = 1, #text do
		textLabel.Text = textLabel.Text .. text:sub(i, i)
		task.wait(0.05)
	end
end

local function startCamera(camera: Camera, cameraSettings: {})
	self.connection = RunService.RenderStepped:Connect(function()
		camera.CFrame.LookVector = cameraSettings["PlayerPostionVector"] :: Vector3
		camera.CFrame.Position = camera.CFrame.Position
		camera.DiagonalFieldOfView = cameraSettings["DiagonalFieldOfView"] :: number
	end)
end

local function stopCamera()
	if self.connection ~= nil then
		self.connection:Disconnect()
	end
end

local function dialog(text, dialogSettings, dialogUI): {}
	if not table.find(text) then
		table.insert(self.debounce, text)
		typeWriterEffect(dialogUI, text)
		dialogSettings["Camera"]["PlayerPostionVector"] = self.player.Character.HumanoidRootPart.Position

		if dialogSettings["Camera"]["PlayerLock"] == true then
			startCamera(self.camera, dialogSettings)
		end

		local tweenIn = TweenService:Create(dialogUI, TweenInfo.new(0.5), { Position = dialogSettings["Positions"][1] })
		local tweenOut =
			TweenService:Create(dialogUI, TweenInfo.new(0.5), { Position = dialogSettings["Positions"][2] })

		coroutine.wrap(function()
			tweenIn:Play()
			task.wait(5)
			tweenOut:Play()
			task.wait(0.5)
			dialogUI.Text = ""
			stopCamera()
			table.remove(self.debounce, 1)
		end)()
	end
	return { self.debounce, dialogSettings }
end

--[=[
    @function Construtor
        @param player Player
		@return any
--]=]
function Dialog.Constructor(player): Dialog
	self = setmetatable({}, Dialog)

	self.player = player
	self.camera = workspace.CurrentCamera
	self.connection = nil
	self.debounce = {}

	return self
end

--[=[
    @function newDialog
        @param text table
        @param dialogUI TextLabel?
		@param dialogSettings table
--]=]
function Dialog.newDialog(text: {}, dialogUI: TextLabel?, dialogSettings: {})
	local any = nil
	for key, value in text do
		local _, variant = next(text, key)
		repeat
			task.wait(0.5)
		until not table.find(self.debounce, variant)

		any = dialog(variant, dialogSettings, dialogUI)
	end
	return any
end

--[=[
    @function Cleanup
--]=]
function Dialog:Cleanup()
	self.connection:Disconnect()
	self.connection = nil
	self.player = nil

	script:Destroy()
end

return Dialog
