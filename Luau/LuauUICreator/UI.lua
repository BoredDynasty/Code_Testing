--[=[
    @class UIManager
--]=]
local UIManager = {}
UIManager.__index = UIManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local self

type tuples = {
	player: Player,
	options: {},
}

export type UI = {
	self: {},
}

local function createConstructor(player): { GuiObject? }
	self.playerUI = player:FindFirstChild("PlayerGui")

	self.screenUI = Instance.new("ScreenGui", self.playerUI)
	self.canvas = Instance.new("CanvasGroup", self.screenUI)

	self.frame = Instance.new("Frame", self.canvas)
	self.frame.AnchorPoint = Vector2.new(0.5, 0.5)
	self.frame.Position = UDim2.new(0, 0.5, 0, 0.5)
	self.frame.BackgroundColor3 = self.frameColor or Color3.fromHex("#111216")
	self.frame.Visible = true

	self.title = Instance.new("TextLabel")
	self.title.Parent = script.Parent
	self.title.Text = self.prompts["Title"]
	self.title.Size = UDim2.new(1, 0, 0.1, 1)
	self.title.Position = UDim2.new(0, 0, 0.1, 0)
	self.title.TextColor3 = Color3.fromHex("#FFFFFF")
	self.title.BackgroundTransparency = 1
	self.title.BorderSizePixel = 0

	self.description = Instance.new("TextLabel")
	self.description.Parent = script.Parent
	self.description.Text = self.prompts["Description"]
	self.description.Size = UDim2.new(1, 0, 0.3, 1)
	self.description.Position = UDim2.new(0, 0, 0.1, 0)
	self.description.TextColor3 = Color3.fromHex("#FFFFFF")
	self.description.BackgroundTransparency = 1
	self.description.BorderSizePixel = 0

	self.screenUI.Name = self.title.Text
	self.screenUI:SetAttribute(script.Name, true)

	self.canvas.Size = UDim2.fromScale(1, 1)
	self.canvas.Position = UDim2.fromScale(0.5, 0.5)
	self.canvas.AnchorPoint = Vector2.new(0.5, 0.5)

	self.description.Parent, self.title.Parent, self.description.Parent = self.playerUI, self.playerUI, self.playerUI

	return { self.frame, self.title, self.description }
end
--[=[
    @function Create
        @param options table
        @param player Player
		@return table, any?
--]=]
function UIManager.Create(options: {}, player): UI
	self = setmetatable({}, UIManager)

	local constructors: {} = createConstructor(player)

	self.frameColor = options["Color"] or Color3.fromHex("#111216")
	self.frame = constructors[1] :: Frame
	self.title = constructors[2] :: TextLabel
	self.description = constructors[3] :: TextLabel
	self.prompts = options["Prompts"] or {
		["Title"] = "Attention!",
		["Description"] = nil,
	}
	self.actions = options["Actions"] or {
		"Continue",
		"Reject",
	}
	self.functionsToBind = options["Func"]

	for _, value in self.actions do
		local templateButton = self.frame.Interactions:FindFirstChild("Template")
		local newButton = templateButton:Clone() :: TextButton
		newButton.Text = value
		newButton.Visible = true
		newButton.Name = value
		for _, bind in self.functionsToBind do
			newButton.MouseButton1Click:Once(bind)
			next(self.functionsToBind, bind)
		end
	end

	return self, constructors
end

return UIManager
