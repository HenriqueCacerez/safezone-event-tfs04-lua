
--[[
    Evento originalmente criado por LuanLuciano93 e Movie (Movie#4361)
    Adaptado para TFS 0.4 por Imperius.
--]]

function onThink(interval)

	local hrs = tostring(os.date("%X")):sub(1, 5)

	if SAFEZONE_CONFIG.days[os.date("%A")] and isInArray(SAFEZONE_CONFIG.days[os.date("%A")], hrs) then

		local from = SAFEZONE_CONFIG.position.arenaLeftTop
		local to   = SAFEZONE_CONFIG.position.arenaRightDown

		-- função para converter minutos em milissegundos
		function minutesToMillis(minutes)
			return minutes * 1000 * 60
		end

		-- responsável por atualizar o outfit do jogador de acordo com a quantidade vidas restantes.
		function changeOutfitLifeInSafeZone(playerId, qntLife)
			local color  = SAFEZONE_CONFIG.lifeColor[qntLife]
			local outfit = getPlayerSex(playerId) == 0 and 136 or 128
							  
			local conditionOutfitLife = createConditionObject(CONDITION_OUTFIT)
			setConditionParam(conditionOutfitLife, CONDITION_PARAM_TICKS, -1)
			addOutfitCondition(conditionOutfitLife, {lookType = outfit, lookHead = color, lookBody = color, lookLegs = color, lookFeet = color})
			doAddCondition(playerId, conditionOutfitLife)
		end

		
		-- Remove uma vida do jogador, se ele não tiver mais vidas, é removido do evento.
		function removeLifePlayerInSafeZone(playerId)
			local lifePlayer = getPlayerLifeInSafeZone(playerId) - 1
			if lifePlayer >= 1 then
				changeOutfitLifeInSafeZone(playerId, lifePlayer)
				db.executeQuery("UPDATE safezone_participants SET life = life - 1 WHERE cid = " ..playerId.. " LIMIT 1")
			else
				removePlayerInSafeZone(playerId)
			end
		end

		-- Retorna a quantidade de pisos que serão criados na rodada.
		function totalProtectionTileInSafeZone()
			local totalPlayers = totalPlayersInSafeZone()
			if totalPlayers >= 10 then
				return totalPlayers - 3
			else
				return totalPlayers - 1
			end
		end

		-- Remove um jogador do evento.
		function removePlayerInSafeZone(playerId) 
			if checkToRewardPlayerInSafeZone(playerId, totalPlayersInSafeZone()) then
				db.query("DELETE FROM safezone_participants WHERE cid = '"..playerId.."' LIMIT 1")
				doTeleportThing(playerId, SAFEZONE_CONFIG.position.leaveEvent, true)
				checkAndSetWinnerInSafeZone()
				doRemoveCondition(playerId, CONDITION_OUTFIT)
				return true
			end
		end

		-- Verifica se o jogador ficou em "primeiro", "segundo" ou "terceiro" lugar.
		-- Se sim, receberá as recompensas correspondentes a sua colocação.
		function checkToRewardPlayerInSafeZone(playerId, placement)
			if placement > 0 and placement <= 3 then

				if placement > 1 then
					local placementName = (placement == 2) and "segundo" or "terceiro"
		
					local broadcast = string.gsub(SAFEZONE_CONFIG.broadcast.winner, "|playerName|", getCreatureName(playerId))
					local broadcast = string.gsub(broadcast, "|position|", placementName)
					doBroadcastMessage(SAFEZONE_CONFIG.broadcast.prefix.." "..broadcast)
					insertWinnerInSafeZone(playerId, placement)
				end
		
				local bagReward = doCreateItemEx(1992)
				for _, reward in pairs(SAFEZONE_CONFIG.reward[placement]) do
					doAddContainerItemEx(bagReward, doCreateItemEx(reward[1], reward[2]))
				end
				doPlayerAddItemEx(playerId, bagReward)

			end
			return true
		end

		-- Responsável por verificar se o evento possui um vencedor do primeiro lugar.
		function checkAndSetWinnerInSafeZone()
			if totalPlayersInSafeZone() == 1 then
				local playerId = selectWinnerInSafeZone()
				doBroadcastMessage(SAFEZONE_CONFIG.broadcast.prefix.." "..string.gsub(SAFEZONE_CONFIG.broadcast.finish, "|playerName|", getCreatureName(playerId)))
				insertWinnerInSafeZone(playerId, 1)
				removePlayerInSafeZone(playerId)
			end
		end

		-- Responsável por inserir o jogador vencedor na tabela.
		function insertWinnerInSafeZone(playerId, placement)
			local date  = os.date("%Y-%m-%d %H:%M:%S")
			local query = db.query or db.executeQuery
			db.executeQuery("INSERT INTO safezone_winners (player_id, placement, date) VALUES ('"..getPlayerGUID(playerId).."', '"..tonumber(placement).."', '"..date.."') LIMIT 1")
			return true
		end

		-- Responsável por selecionar o jogador, vencedor do evento.
		function selectWinnerInSafeZone()
			local queryResult = db.storeQuery("SELECT cid FROM safezone_participants LIMIT 1")
			return result.getDataInt(queryResult, "cid")
		end

		-- Responsável por retornar a quantidade de vidas restantes de um jogador.
		function getPlayerLifeInSafeZone(playerId) 
			local queryResult = db.storeQuery("SELECT life FROM safezone_participants WHERE cid = '"..playerId.."' LIMIT 1")
			return (queryResult) and result.getDataInt(queryResult, "life") or 0
		end

		-- Remove todos os jogadores do evento.
		-- Utilizado em caso de não houver jogadores suficientes para começar o evento.
		function removeAllPlayersInSafeZone() 
			for _, playerId in pairs(getPlayersIdInSafeZone()) do
				doTeleportThing(playerId, SAFEZONE_CONFIG.position.leaveEvent, true)
			end
			db.query("DELETE FROM safezone_participants")
		end

		-- Atualiza os outfits de todos os participantes de acordo com a vida inicial "3".
		function changeOutfitStartInSafeZone()
			for _, playerId in pairs(getPlayersIdInSafeZone()) do
				changeOutfitLifeInSafeZone(playerId, 3)
			end
		end

		-- Responsável por verificar se o jogador está ou não pisando no protection tile.
		function moveToEventSafeTile(playerId, tileID)
			local tilePlayer = getTileItemById(getCreaturePosition(playerId), tileID)
			if tilePlayer.actionid ~= SAFEZONE_CONFIG.tileActionId then
			  removeLifePlayerInSafeZone(playerId)
			end
		end
		
		-- Responsável por criar o efeito em área somente aonde não tiver os protection tile.
		function createEffectAreaInSafeZone(playerId, tileID)
			for x = from.x, to.x do
			for y = from.y, to.y do
			for z = from.z, to.z do
				pos = {x = x, y = y, z = z, stackpos = 253}
				local effect = (getTileItemById(pos, tileID).actionid == SAFEZONE_CONFIG.tileActionId) and "" or doSendMagicEffect(pos, CONST_ME_SMALLPLANTS)
			end
			end
			end
			 moveToEventSafeTile(playerId, tileID)
		  end		

		-- Responsável por remover todos os protections tiles da arena.
		function removeProtectTilesInSafeZone(tileID, positionTile)
			local tile = getTileItemById(positionTile, tileID)
			if tile.uid > 0 then
				doRemoveItem(tile.uid, 1)
			end
		end

		-- Responsável por criar novos protections tiles em posições aleatorias da arena.
		function createProtectTileInSafeZone()
			local randomTileId = SAFEZONE_CONFIG.protectionTileId[math.random(1, #SAFEZONE_CONFIG.protectionTileId)]
			for i, playerId in pairs(getPlayersIdInSafeZone()) do
				local randomPositionTile = {x=math.random(from.x,to.x), y=math.random(from.y,to.y), z=math.random(from.z,to.z)}
				doItemSetAttribute(doCreateItem(randomTileId, 1, randomPositionTile), "aid", SAFEZONE_CONFIG.tileActionId)
				if i >= totalPlayersInSafeZone() then
					doRemoveItem(getTileItemById(randomPositionTile, randomTileId).uid)
				end
				addEvent(createEffectAreaInSafeZone, 8700, playerId, randomTileId)
				addEvent(removeProtectTilesInSafeZone, 9000, randomTileId, randomPositionTile)
			end
			addEvent(createProtectTileInSafeZone, 16000)
		end
			
		-- responsável por verificar se há ou não jogadores suficientes para começar.
		function checkToStartSafeZone()
			doRemoveItem(getTileItemById(SAFEZONE_CONFIG.position.openTeleport, 1387).uid)
			
			if totalPlayersInSafeZone() >= SAFEZONE_CONFIG.minPlayers then
				doBroadcastMessage(SAFEZONE_CONFIG.broadcast.prefix.." "..string.gsub(SAFEZONE_CONFIG.broadcast.start, "|totalParticipants|", totalPlayersInSafeZone()))
				changeOutfitStartInSafeZone()
				addEvent(createProtectTileInSafeZone, 10000)
			else
				removeAllPlayersInSafeZone()
				doBroadcastMessage(SAFEZONE_CONFIG.broadcast.prefix.." "..SAFEZONE_CONFIG.broadcast.noParticipants)
			end
		end

		-- abre o teleport do evento.
		function openTeleportInSafeZone()
			local openTeleport = doCreateItem(1387, 1, SAFEZONE_CONFIG.position.openTeleport)
			doItemSetAttribute(openTeleport, "aid", 6925)
			doBroadcastMessage(SAFEZONE_CONFIG.broadcast.prefix.." "..string.gsub(SAFEZONE_CONFIG.broadcast.open, "|minutesToStart|", SAFEZONE_CONFIG.timeInMinutes.closeTP))
			addEvent(checkToStartSafeZone, minutesToMillis(SAFEZONE_CONFIG.timeInMinutes.closeTP))
		end
		
		openTeleportInSafeZone()
	end
	return true
end