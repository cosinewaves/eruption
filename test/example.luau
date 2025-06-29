local eruption = require("../lib")

-- Declare which modules to load
eruption.declareDescendants(script, function(inst)
    return inst.Name:match("Service") -- only require modules with "Service" in name
end)

-- Load them and start lifecycles
eruption:erupt()
