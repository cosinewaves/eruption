local eruption = require("../../lib")

local PointsService = eruption.article()

-- Table to hold player points: [Player] = points
local playerPoints = {}

function PointsService.init()
	-- Connect PlayerAdded and PlayerRemoving events to manage points
	game:GetService("Players").PlayerAdded:Connect(function(player)
		playerPoints[player] = 0 -- start with 0 points
		print(`[PointsService]: Player {player.Name} joined, points initialized to 0`)
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		playerPoints[player] = nil -- clean up
		print(`[PointsService]: Player {player.Name} left, points cleaned up`)
	end)
end

function PointsService.onTick(dt)
	-- Example usage: increment each player's points every tick by 1 (could be anything)
	for player, points in pairs(playerPoints) do
		playerPoints[player] = points + 1
		-- Could fire events or update leaderstats here - i'm using log for example
        PointsService.useLog().print("PointsService", "onTick", "gave a point to every player")
	end
end

-- Public method to get points for a player
function PointsService.GetPoints(player)
	return playerPoints[player] or 0
end

-- Public method to add points to a player
function PointsService.AddPoints(player, amount)
	if playerPoints[player] then
		playerPoints[player] = playerPoints[player] + amount
        PointsService.useLog().print("PointsService", "AddPoints", "successfully added points")
	else
		playerPoints[player] = amount
	end
end

return PointsService