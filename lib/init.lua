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
}

export type article = { [any]: (any & lifecycles) }
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
            log.warn("eruption", "internal.safeRequire", `error requiring module {module:GetFullName()}: {result}`)
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
		log.warn("eruption", "erupt", `already erupted`)
		return
	end

	internal.erupted = true

	local promises = {}

	-- Require all declared modules
	for _, module in internal.declared do
		table.insert(promises, internal.safeRequire(module):andThen(function(loaded)
			return loaded
		end):catch(function(err)
			log.warn("eruption", "require", `failed to load module: {module.Name}: {err}`)
			return nil
		end))
	end

	-- After all modules are loaded
	promise.all(promises):andThen(function(results)
		log.print("eruption", "erupt", `successfully loaded {#results} modules.`)

		local articles = {}

		for _, result in results do
			if typeof(result) == "table" then
				table.insert(articles, result)
			end
		end

		-- Init lifecycle
		local initPromises = {}
		for _, article in articles do
			if type(article.init) == "function" then
				local ok, result = pcall(article.init)
				if ok and promise.is(result) then
					table.insert(initPromises, result)
				elseif not ok then
					log.warn("eruption", "init", `error in init: {result}`)
				end
			end
		end

		return promise.all(initPromises):andThen(function()
			-- onErupt
			for _, article in articles do
				if type(article.onErupt) == "function" then
					local ok, result = pcall(article.onErupt)
					if not ok then
						log.warn("eruption", "onErupt", `error: {result}`)
					end
				end
			end

			-- Connect lifecycles
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
            else
                log.print("eruption", "lifecycle", "skipped onRender: not available on server")
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

			log.print("eruption", "lifecycle", `lifecycles started for {#articles} article(s).`)
		end)
	end):catch(function(err)
		log.warn("eruption", "final", `one or more modules failed lifecycle init: {err}`)
	end)
end

return setmetatable(eruption, { __index = eruption })
