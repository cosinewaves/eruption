--!strict

-- Requirements
local promise = require("@self/use/promise")

-- Types
export type article = { [any]: any }
export type argue<T> = (T) -> boolean
export type eruption = {
    declareChildren: (container: Instance) -> (),
    declareDescendants: (container: Instance) -> ()
}

-- Metatable
local eruption = {} :: eruption
setmetatable(eruption, {__index = eruption})

-- Internal
local declared: {article} = {}

-- Functions
function eruption.declareChildren(container: Instance): ()
    
end

function eruption.declareDescendants(container: Instance): ()
    
end

return eruption