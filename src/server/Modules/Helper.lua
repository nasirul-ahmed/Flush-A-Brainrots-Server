local HttpService = game:GetService("HttpService")

local CoreUtils = {}

function CoreUtils.generateUniqueId()
    return HttpService:GenerateGUID(false)
end

return CoreUtils