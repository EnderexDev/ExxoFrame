--!strict
--!native
--!optimize 2
---# EXXOFRAME #---
local ExxoFrame = require(script.Parent.Parent)

---# VARIABLES #---
local BridgesToCreate = {
    "Notification",
}

local module = {}

function module:Init()
    for _,Bridge in BridgesToCreate do
        ExxoFrame.BridgeNet2.ReferenceBridge(Bridge)

        ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionName")
        ExxoFrame.BridgeNet2.ReferenceIdentifier("FunctionContent")
    end
end


return module