--[[
    Evento originalmente criado por LuanLuciano93 e Movie (Movie#4361)
    Adaptado para TFS 0.4 por Imperius.
--]]

SAFEZONE_CONFIG = {
    effectArea       = CONST_ME_SMALLPLANTS,
    tileActionId     = 69241,
    protectionTileId = {9562, 9563, 9564, 9565}, -- ID dos pisos que serão criados
    minPlayers       = 2,  -- Limite minimo de jogadores.
    maxPlayers       = 14, -- Limite maximo de jogadores.
    levelMin         = 1,  -- Level  minimo para participar.
    days = { -- Dias da semana e os horários em que o evento irá acontecer.
        ["Monday"]    = {"19:30"}, -- Segunda
		["Tuesday"]   = {"19:30"}, -- Terça
		["Wednesday"] = {"19:30"}, -- Quarta
		["Thursday"]  = {"19:30"}, -- Quinta
		["Friday"]    = {"19:30"}, -- Sexta
		["Saturday"]  = {"19:30"}, -- Sábado
		["Sunday"]    = {"19:30"}  -- Domingo
    },
    broadcast = {      -- NÃO ALTERE |totalParticipants|, |position|, |playerName| e |minutesToStart|.
        prefix         = "[SafeZone]",
        start          = "O evento ira comecar agora com |totalParticipants| participantes! Boa sorte!",
        noParticipants = "O evento nao foi iniciado por falta de participantes!",
        open           = "O evento foi aberto, voce tem |minutesToStart| minuto(s) para entrar no portal do evento que se encontra no templo!",
        finish         = "O evento foi finalizado e o ganhador foi |playerName|! Parabens!",
        winner         = "|playerName| terminou o evento em |position| lugar!"
    },
    reward = { -- Recompensas aos ganhadores.
    -- [colocacao] = {{itemID, quantidade}, etc...}
       [1] = {{2160, 80}, {2520, 1}},
       [2] = {{2160, 50}},
       [3] = {{2160, 25}}
    },
    position = {
        openTeleport   = {x = 32365, y = 32236, z = 7}, -- Posição onde o teleport será aberto para participar do evento.
        leaveEvent     = {x = 32369, y = 32241, z = 7}, -- Posição onde o jogador será teleportado ao perder / ganhar o evento.
        arenaCenter    = {x = 32337, y = 31934, z = 7}, -- Posição do centro da arena do evento.
        arenaLeftTop   = {x = 32332, y = 31930, z = 7}, -- Posição do canto superior esquerdo da arena.
        arenaRightDown = {x = 32342, y = 31939, z = 7}  -- Posição do canto inferior direito  da arena.
    },
    lifeColor = { -- cores do outfit
        [1] = 94, -- red
        [2] = 77, -- orange
        [3] = 79  -- yellow
    },
    timeInMinutes = {
        closeTP = 1 -- Tempo em que o TP fechará após o evento ser anunciado.
    }
}

-- Responsável por inserir o jogador como um participante do evento.
function insertPlayerInSafeZone(playerId)
    local query = db.query or db.executeQuery
    query("INSERT INTO safezone_participants (cid, life) VALUES ('"..playerId.."', 3) LIMIT 1")
end

-- Retorna a quantidade de jogadores que estão participando do evento.
function totalPlayersInSafeZone()
    local queryResult = db.storeQuery("SELECT COUNT(id) as total FROM safezone_participants")
    return result.getDataInt(queryResult, "total")
end

-- Retorna todos os "cid" dos jogadores que estão participando do evento.
function getPlayersIdInSafeZone() 
    local queryResult = db.storeQuery("SELECT cid FROM safezone_participants")
    local players = {}
    if not queryResult then
        return players
    else
        table.insert(players, result.getDataInt(queryResult, "cid"))
        while result.next(queryResult) do
          local result = result.getDataInt(queryResult, "cid")
          table.insert(players, result)
        end
        return players
    end
end