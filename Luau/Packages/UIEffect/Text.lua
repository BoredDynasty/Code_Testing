local Text = {}

-- // Requires
local SoundManager = require(script.Parent.SoundManager)

local function cleanupText(textlabel)
	local index = 0
	local text = " "

	if index >= #text then
		return text
	end

	print(text:sub(index, index))
	index = index + 1
	textlabel.Text = text
	task.wait(0.05)
end

local function stripRichText(text)
	-- Function to strip out rich text tags and return the pure text
	return string.gsub(text, "<.->", "")
end

local function markdownToRichText(input)
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

function Text.stripRichText(text)
	return stripRichText(Text)
end

function Text.clean(textlabel)
	return cleanupText(textlabel)
end

function Text.TypewriterEffect(DisplayedText: { string }, TextLabel, speed): ()
	local Text: string = stripRichText(DisplayedText) :: string
	local currentTypedText = ""
	local typingSpeed = speed or 0.05

	task.spawn(function()
		for index = 1, #Text do
			SoundManager.Play({ "DialogText" }, script.Parent.UISounds)

			-- // Rich Text Tags

			local formattedText = ""
			local currentTag = ""
			local insideTag = false

			currentTypedText = string.sub(Text, 1, index)

			-- // Rich Text Handler

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
			return
		end
	end)
end

function Text:MD_ToRichText(input): string
	return markdownToRichText(input)
end

return Text
