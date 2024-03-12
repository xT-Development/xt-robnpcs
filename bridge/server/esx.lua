if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports['es_extended']:getSharedObject()

function getPlayer(src)
    return ESX.GetPlayerFromId(src)
end