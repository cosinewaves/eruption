-- Requirements
local RunService = game:GetService("RunService")
local log = require("@self/aid/log")
local promise = require("@self/use/promise")

-- Types
export type lifecycles = {
    init: () -> ()?,
    onErupt: () -> ()?,
    onRender: (dt: number) -> ()?,
    onTick: (dt: number) -> ()?,
    onPhysics: (dt: number) -> ()?,
	useLog: () -> (log.log),
}

-- Article type: lifecycle methods plus any other keys
export type article = lifecycles & { [any]: any }

export type argue<T> = (T) -> boolean

export type eruption = {
    declareChildren: (container: Instance, argue: argue<Instance>?) -> (),
    declareDescendants: (container: Instance, argue: argue<Instance>?) -> (),
    erupt: (self: eruption) -> (),
    article: () -> article,
}

-- Internal state type
type internal = {
    declared: { ModuleScript },
    erupted: boolean,
    safeRequire: (module: ModuleScript) -> typeof(promise.new()),
}

-- Private unique marker to identify valid articles at runtime
local PRIVATE_MARKER = newproxy(true)

-- Internal state
local internal = {
    declared = {},
    erupted = false,
} :: internal

-- Helper function to check if a table is a valid article (has private marker)
local function isArticle(t: any): boolean
    return type(t) == "table" and rawget(t, PRIVATE_MARKER) == true
end

-- Safe require wrapped in a Promise
function internal.safeRequire(module: ModuleScript)
    return promise.new(function(resolve, reject)
        local success, result = pcall(require, module)
        if success then
            resolve(result)
        else
            reject()
            log.warn("eruption", "internal.safeRequire", `error requiring module {module:GetFullName()}: {result}`)
        end
    end)
end

local eruption = {} :: eruption

-- Declare immediate children ModuleScripts from a container
function eruption.declareChildren(container: Instance, argue: argue<Instance>?)
    for _, child in container:GetChildren() do
        if not child:IsA("ModuleScript") then continue end
        if argue and not argue(child) then continue end

        table.insert(internal.declared, child)
    end
end

-- Declare all descendants ModuleScripts from a container
function eruption.declareDescendants(container: Instance, argue: argue<Instance>?)
    for _, descendant in container:GetDescendants() do
        if not descendant:IsA("ModuleScript") then continue end
        if argue and not argue(descendant) then continue end

        table.insert(internal.declared, descendant)
    end
end

-- Article constructor: returns an article with default lifecycle methods and private marker
function eruption.article(): article
    local self = {
        init = function() end,
        onErupt = function() end,
        onRender = function(_dt: number) end,
        onTick = function(_dt: number) end,
        onPhysics = function(_dt: number) end,
    }
    -- Attach private marker so we can identify valid articles
    rawset(self, PRIVATE_MARKER, true)
    return self
end

function eruption:erupt()
    if internal.erupted then
        log.warn("eruption", "erupt", `already erupted`)
        return
    end

    internal.erupted = true

    local promises = {}

    -- Safe require all declared modules, get promises for each
    for _, module in internal.declared do
        table.insert(promises, internal.safeRequire(module):andThen(function(loaded)
            return loaded
        end):catch(function(err)
            log.warn("eruption", "require", `failed to load module: {module.Name}: {err}`)
            return nil
        end))
    end

    -- Wait for all modules to load
    promise.all(promises):andThen(function(results)
        log.print("eruption", "erupt", `successfully loaded {#results} modules.`)

        local articles = {}

        -- Filter valid articles only by private marker check
        for _, result in results do
            if isArticle(result) then
                table.insert(articles, result)
            else
                log.warn("eruption", "erupt", `ignored module because it is not a valid article`)
            end
        end

        -- Run init lifecycles collecting any promises returned
        local initPromises = {}
        for _, article in articles do
            if type(article.init) == "function" then
                local ok, result = pcall(article.init)
                if ok then
                    if promise.is(result) then
                        table.insert(initPromises, result)
                    end
                else
                    log.warn("eruption", "init", `error in init: {result}`)
                end
            end
        end

        return promise.all(initPromises):andThen(function()
            -- Call onErupt lifecycles
            for _, article in articles do
                if type(article.onErupt) == "function" then
                    local ok, result = pcall(article.onErupt)
                    if not ok then
                        log.warn("eruption", "onErupt", `error: {result}`)
                    end
                end
            end

            -- Connect RunService lifecycles only on client for RenderStepped
            if RunService:IsClient() then
                RunService.RenderStepped:Connect(function(dt)
                    for _, article in articles do
                        if type(article.onRender) == "function" then
                            local ok, err = pcall(article.onRender, dt)
                            if not ok then
                                log.warn("eruption", "onRender", `error: {err}`)
                            end
                        end
                    end
                end)
            end

            RunService.Heartbeat:Connect(function(dt)
                for _, article in articles do
                    if type(article.onPhysics) == "function" then
                        local ok, err = pcall(article.onPhysics, dt)
                        if not ok then
                            log.warn("eruption", "onPhysics", `error: {err}`)
                        end
                    end
                end
            end)

            RunService.Stepped:Connect(function(_, dt)
                for _, article in articles do
                    if type(article.onTick) == "function" then
                        local ok, err = pcall(article.onTick, dt)
                        if not ok then
                            log.warn("eruption", "onTick", `error: {err}`)
                        end
                    end
                end
            end)

			for _, article in articles do
				if type(article.useLog) == "function" then
					local success, result = pcall(article.useLog, log)
					if not success then
						-- optionally warn if useLog errors
						warn("Error calling useLog:", result)
					else
						-- You can return the log module or the result from useLog if needed
						return log
					end
				end
			end
			

            log.print("eruption", "lifecycle", `lifecycles started for {#articles} article(s).`)
        end)
    end):catch(function(err)
        log.warn("eruption", "final", `one or more modules failed lifecycle init: {err}`)
    end)
end

return setmetatable(eruption, { __index = eruption })
