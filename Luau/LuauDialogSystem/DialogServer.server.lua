local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local dialog = require("Dialog.lua") -- Use require(DialogModule)

local dialogGui = nil -- Replace with your dialog Textlabel

ReplicatedStorage.NewDialog.OnServerEvent:Connect(function(player, text: {}, dialogSettings: {}): any
	dialog.Constructor(player)
	dialog.newDialog(text, dialogGui, dialogSettings)

	return dialog
end)
