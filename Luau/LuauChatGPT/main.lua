--[=[
    @class AI
--]=]
local AI = {}

local HttpService = game:GetService("HttpService")

--[=[
    @function generate
        @param input string
		@tag You may want to filter the input here...
        @return string?
--]=]
function AI:generate(input: string): string?
	assert(input)

	local requestInput = HttpService:JSONEncode({
		message = input,
	})

	local success, response = xpcall(function()
		return HttpService:PostAsync(
			"https://internet.com:8000/messages",
			requestInput,
			Enum.HttpContentType.ApplicationJson
		)
	end, function(message)
		warn("Error generating reponse. " .. message)
	end)

	return success and HttpService:JSONDecode(response).answer
end

return AI
