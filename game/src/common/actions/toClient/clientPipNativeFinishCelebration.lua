local function clientPipNativeFinishCelebration(player, roomId, finishTime, coins)
	return {
		type = script.Name,
		playerId = tostring(player.UserId),
		roomId = roomId,
		coins = coins,
		finishTime = finishTime,
		replicateTo = tostring(player.UserId),
	}
end

return clientPipNativeFinishCelebration
