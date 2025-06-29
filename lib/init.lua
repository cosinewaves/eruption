-- Requirements
local log = require("@self/aid/log")
local promise = require("@self/use/promise")

-- Types
export type article = { [any]: any }
export type argue<T> = (T) -> boolean
export type eruption = {
    declareChildren: (container: Instance, argue: argue<Instance>?) -> (),
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


-- Internal Metatable
local internal = {
    declared = {},
    erupted = false,
} :: internal
setmetatable(internal, { __index = internal })

-- Functions

function internal.safeRequire(module: ModuleScript): ()
    return promise.new(function(resolve, reject)
        local success, result = pcall(require, module)
        if success then
            resolve(result)
        else
            reject()
            log.warn("internal", "safeRequire", `Error requiring module {module:GetFullName()}: {result}`)
        end
    end)
end

function eruption.declareChildren(container: Instance, argue: argue<Instance>?): ()
    for _, child in container:GetChildren() do
        if not child:IsA("ModuleScript") then continue end
        if argue and not argue(child) then continue end

        table.insert(internal.declared, child)
    end
end

function eruption.declareDescendants(container: Instance, argue: argue<Instance>?): ()
    for _, descendant in container:GetDescendants() do
        if not descendant:IsA("ModuleScript") then continue end
        if argue and not argue(descendant) then continue end

        table.insert(internal.declared, descendant)
    end
end



function eruption:erupt(): ()
    if internal.erupted then
        warn("[eruption] Already erupted. Skipping.")
        return
    end

    internal.erupted = true

    -- Create list of promises to require each declared module
    local promises = {}

    for _, module in internal.declared do
        table.insert(promises, internal.safeRequire(module):catch(function(err)
            warn(`[eruption] Failed to load module: {module.Name}`, err)
        end))
    end

    promise.all(promises):andThen(function()
        print(`[eruption] Loaded {#internal.declared} modules successfully.`)
    end):catch(function(err)
        warn("[eruption] One or more modules failed to load:", err)
    end)

end
return setmetatable(eruption, { __index = eruption })
