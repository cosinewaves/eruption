# eruption

**eruption** is a lightweight Roblox module loader and lifecycle manager designed to load modular services (called _articles_), run their lifecycle methods safely with promise-based async handling, and connect them to Roblox `RunService` events for clean, scalable game architecture.

---

## Features

- Automatically require modules (articles) from a folder.
- Validate articles support lifecycle methods with default no-ops.
- Supports lifecycle hooks: `init`, `onErupt`, `onRender`, `onTick`, `onPhysics`.
- Safely connects lifecycle hooks to Roblox's `RunService` events.
- Handles async `init` with Promises.
- Logs errors and warnings cleanly.
- Works on both Server and Client (Render lifecycle only on Client).
- Designed for typed Luau usage with Intellisense-friendly types.

---

## Installation

Place the `eruption.lua` module in your project (e.g. `ReplicatedStorage/eruption`).

Require and use in a server script or local script like:

```lua
local eruption = require(game.ReplicatedStorage.eruption)
```

---

## Usage

### Declaring articles

Create service modules by extending the base article type from `eruption.article()`:

```lua
local eruption = require(game.ReplicatedStorage.eruption)

local MyService = eruption.article()

function MyService.init()
    print("Service initializing")
end

function MyService.onTick(dt)
    print("Tick event with dt:", dt)
end

return MyService
```

### Registering modules

Declare modules to be loaded by eruption via:

- `eruption.declareChildren(container)` — declare direct child ModuleScripts of a container.
- `eruption.declareDescendants(container)` — declare all descendant ModuleScripts recursively.

You can also pass an optional filter function to select modules.

```lua
eruption.declareChildren(game.ServerScriptService.MyServices)
```

### Starting eruption

Call `eruption:erupt()` to:

- Require all declared modules.
- Run their `init` lifecycle (async-safe).
- Run `onErupt` lifecycle.
- Connect their lifecycle hooks to Roblox RunService events (`RenderStepped`, `Stepped`, `Heartbeat`).

```lua
eruption:erupt()
```

---

## API Reference

### `eruption.article() -> article`

Returns a new article table prefilled with empty lifecycle methods:

- `init(): void | Promise<void>` — async or sync initialization.
- `onErupt(): void` — called once after all modules initialize.
- `onRender(dt: number): void` — called each frame on client only (`RenderStepped`).
- `onTick(dt: number): void` — called each frame (`Stepped`).
- `onPhysics(dt: number): void` — called each frame (`Heartbeat`).

You override these methods in your service modules.

---

### `eruption.declareChildren(container: Instance, filter?: (Instance) -> boolean): void`

Adds all **child** `ModuleScript`s of `container` to the list of modules to be loaded.

`filter` is an optional predicate to select specific modules.

---

### `eruption.declareDescendants(container: Instance, filter?: (Instance) -> boolean): void`

Adds all **descendant** `ModuleScript`s of `container` recursively to the load list.

`filter` is optional.

---

### `eruption:erupt(): void`

Starts the module loading and lifecycle execution process:

1. Requires all declared modules safely.
2. Validates and runs `init` lifecycle for each article, supports promises.
3. Calls `onErupt` on each article.
4. Connects lifecycle methods (`onRender`, `onTick`, `onPhysics`) to `RunService` events.
5. Logs errors/warnings during any phase.

**Note:** `onRender` is only connected on clients (`RunService:IsClient()`).

---

## Error Handling & Logging

- Uses an internal logging module to print warnings/errors with context.
- Lifecycle errors are caught and logged, preventing crashes.
- Failed module requires or lifecycle methods are logged and do not halt eruption.

---

## Example

```lua
local eruption = require(game.ReplicatedStorage.eruption)

-- Declare all services in a folder
eruption.declareDescendants(game.ServerScriptService.Services)

-- Start loading and lifecycle execution
eruption:erupt()
```
