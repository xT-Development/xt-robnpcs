if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()

function getPlayer(src)
    return QBCore.Functions.GetPlayer(src)
end

function getPlayerJob(src)
    local player = getPlayer(src)
    return player and player.PlayerData.job.name or nil
end