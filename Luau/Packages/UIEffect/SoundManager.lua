--[=[
    @class Audio
--]=]
local Audio = {}

-- // Services

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

--[[
    Note to anyone,
    the sound param is the config table.
    If the script finds if the sound["type"] is a string,
    the script will go to the directory param
    and search for the sound there.
elseif
    If its a number, the script will guess it's a soundId,
    the script will load the sound and the rest is history.

else
    Just use ``UIEffectsClass.Sound(soundName)``
    It's that simple :skull:
]]

-- // Functions

--[=[
    @function Play
        @param sound table
        @param directory Instance?
--]=]
function Audio.Play(sound: { string | number }, directory: Instance?)
	if not directory then
		directory = SoundService -- FYI, ReplicatedStorage is kinda client side so, it'll play for the client.
	end
	local audio = nil
	if type(sound[1]) == "string" then
		local any: Sound = sound[directory]
		audio = any:Clone()
		audio.Parent = sound[directory] :: Instance
		audio:SetAttribute(script.Name, true)
		audio:Play()
		Debris:AddItem(audio, audio.TimeLength)
		return audio
	else
		audio = Instance.new("Sound")
		audio.SoundId = "rbxassetid://" .. sound[1]
		audio.Parent = SoundService
		audio:SetAttribute(script.Name, true)
		audio:Play()
		Debris:AddItem(audio, audio.TimeLength)
		return audio
	end
end
--[=[
    @function Music
        @param playlist table
        @param client boolean
--]=]
function Audio.Music(playlist: { Sound }, client: boolean)
	local currentlyPlaying = nil
	if client == true then
		for i, sound: Sound in playlist do
			local newSound = sound:Clone()
			newSound.Playing = true
			newSound.Volume = 1
			newSound.Parent = SoundService
			currentlyPlaying = newSound
			Debris:AddItem(newSound, newSound.TimeLength)
			task.wait(newSound.TimeLength + 5)
			next(playlist, sound)
		end
	end
	return currentlyPlaying
end

--[=[
    @function Stop
        @param sound string
        @param directory Instance?
--]=]
function Audio.Stop(sound: string, directory: Instance?)
	assert(directory)
	if table.find(directory:GetDescendants(), sound) then
		directory[sound]:Destroy()
		print(`Removing {sound.Name} sound from {directory.Name}.`)
	end
end

return Audio
