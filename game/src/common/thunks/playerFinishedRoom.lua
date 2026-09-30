local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Modules = ReplicatedStorage:WaitForChild('Modules')
local logger = require(Modules.src.utils.Logger)

local addPlayerFinishToRoom = require(Modules.src.actions.rooms.addPlayerFinishToRoom)
local clientFinishGame = require(Modules.src.actions.toClient.clientFinishGame)
local clientPipNativeFinishCelebration = require(Modules.src.actions.toClient.clientPipNativeFinishCelebration)
local clientSendNotification = require(Modules.src.actions.toClient.clientSendNotification)
local M = require(Modules.M)
local assets = require(Modules.src.assets)
local Transporter = require(Modules.src.Transporter)
local Leaderboards = require(Modules.src.Leaderboards)
local GameDatastore = require(Modules.src.GameDatastore)

local InventoryObjects = require(Modules.src.objects.InventoryObjects)
local RoomObjects = InventoryObjects.RoomObjects

local PIP_NATIVE_FINISH_REWARD_ID = '20004'

local function unlockPipNativeFinishReward(player)
	local rewardItem = InventoryObjects.PetObjects[PIP_NATIVE_FINISH_REWARD_ID]
	if not rewardItem then
		logger:w('Pip native finish reward item missing: ' .. PIP_NATIVE_FINISH_REWARD_ID)
		return nil
	end

	local inventory = GameDatastore:getInventory(player)
	if M.include(inventory, PIP_NATIVE_FINISH_REWARD_ID) then
		return nil
	end

	GameDatastore:setInventoryItem(player, PIP_NATIVE_FINISH_REWARD_ID)
	return rewardItem
end

local function calulatePrize(prizeCoins, playersPlaying)
	local function isPlayerFinished(player)
		return player.finishTime ~= nil
	end

	local playersFinished = M.select(playersPlaying, isPlayerFinished)

	local count = M.count(playersFinished)

	logger:d('Players finished', count, playersPlaying)

	if count == 0 and M.count(playersPlaying) == 1 then
		-- solo run gives always half
		return prizeCoins / 2
	elseif count == 0 then
		return prizeCoins
	end

	local newPrize = prizeCoins / (count + 1) * (count * 1.75)
	return math.floor(newPrize / 10) * 10
end

local function playerFinishedRoom(player, roomId)
	return function(store)
		local room = store:getState().rooms[roomId]

		local roomObject = RoomObjects[roomId]
		local config = roomObject.config

		local playerObj = room.playersPlaying[player.UserId]
		if playerObj and playerObj.finishTime then
			logger:d('Player  already finished room:' .. player.Name)
		else
			local coins = calulatePrize(config.prizeCoins, room.playersPlaying)
			logger:d(
				'Player finished room: ' .. player.Name .. '. Transport to lobby. Give money: ' .. coins .. ' coins.'
			)

			Transporter:placePlayersToHomeSpawn({ player })

			local finishTime = os.time()
			store:dispatch(addPlayerFinishToRoom(player, roomId, finishTime, coins))
			store:dispatch(clientFinishGame(player, roomId, finishTime, coins))

			GameDatastore:incrementCoins(player, coins)
			store:dispatch(
				clientSendNotification(
					player,
					'You won ' .. coins .. ' coins',
					assets.money['coins-pile']
				)
			)
			Leaderboards:updateMostPlayed(player)
			Leaderboards:updateMostPlayed(player, roomId)

			local pipRewardItem = unlockPipNativeFinishReward(player)
			if pipRewardItem then
				store:dispatch(
					clientSendNotification(
						player,
						'Pip unlocked ' .. pipRewardItem.name .. ' in your Inventory!',
						assets.brand['logo-icon']
					)
				)
			end

			store:dispatch(
				clientPipNativeFinishCelebration(player, roomId, finishTime, coins)
			)
		end
	end
end

return playerFinishedRoom