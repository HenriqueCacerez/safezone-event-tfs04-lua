--[[
    Evento originalmente criado por LuanLuciano93 e Movie (Movie#4361)
    Adaptado para TFS 0.4 por Imperius.
--]]

function onStepIn(cid, item, position, lastPosition, fromPosition, toPosition, actor)

    -- Verifica se o jogador possui o level minimo para participar do evento.
    if getPlayerLevel(cid) < SAFEZONE_CONFIG.levelMin then
        doPlayerSendCancel(cid, SAFEZONE_CONFIG.broadcast.prefix.." Voce precisa ser level "..SAFEZONE_CONFIG.levelMin.." ou maior para entrar no evento.")
        doTeleportThing(cid, fromPosition, true)
        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_POFF)
        return true
    end

    -- Verifica se o limite máximo de jogadores foi ultrapassado.
    if totalPlayersInSafeZone() == SAFEZONE_CONFIG.maxPlayers then
        doPlayerSendCancel(cid, SAFEZONE_CONFIG.broadcast.prefix.." o evento alcancou o limite maximo de jogadores.")
        doTeleportThing(cid, fromPosition, true)
        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_POFF)
        return true
    end

    -- Se o jogador estiver usando "stealth ring" não poderá entrar no evento.
    local ring = getPlayerSlotItem(cid, CONST_SLOT_RING)
    if ring and ring.itemid == 2202 then
      doPlayerSendCancel(cid, SAFEZONE_CONFIG.broadcast.prefix.." Voce nao pode entrar com um stealth ring no evento.")
      doTeleportThing(cid, fromPosition, true)
      doSendMagicEffect(getCreaturePosition(cid), CONST_ME_POFF)
      return true
  end

    doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, SAFEZONE_CONFIG.broadcast.prefix.." Voce entrou no evento. Boa sorte!")
    doTeleportThing(cid, SAFEZONE_CONFIG.position.arenaCenter, true)
    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_TELEPORT)
    insertPlayerInSafeZone(cid)

  return true
end