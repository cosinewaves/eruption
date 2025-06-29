--!nonstrict

-- Requirements
local promise = require("@self/use/promise")

-- Types
export type article = { [any]: any }
export type argue<T> = (T) -> boolean
export type eruption = {
    declareChildren: (container: Instance) -> (),
    declareDescendants: (container: Instance, argue: argue<Instance>?) -> (),
    erupt: (self: eruption) -> (),
}
type internal = {
    declared: { article },
    erupted: boolean,
    safeRequire: (module: ModuleScript) -> (),
}

-- Public Metatable
local eruption = {} :: eruption
setmetatable(eruption, {__index = eruption})

-- Internal Metatable
local internal = {
     declared = {},
     erupted = false
} :: internal
setmetatable(internal, {__index = internal})

-- Functions

function internal.safeRequire(module: ModuleScript): ()
    return promise.new(function(resolve, reject)
        local success, result = pcall(require, module)
        if success then
            resolve(result)
        else
            reject(result)
        end
    end)
end


function eruption.declareChildren(container: Instance): ()
    
end

function eruption.declareDescendants(container: Instance, argue: argue<Instance>?): ()
    for _, descendant in container:GetDescendants() do

        if argue and not argue(descendant) then 
            continue 
        end

        if not descendant:IsA("ModuleScript") then
            continue
        end

	end
    return
end

function eruption:erupt(): ()
    
end

return eruption