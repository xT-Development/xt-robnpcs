if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports["es_extended"]:getSharedObject()

function isBlacklistedJob(jobs)
    local Player = ESX.GetPlayerData()
    if type(jobs) == 'table' then
        for x = 1, #jobs do
            if jobs[x] == Player.job then
                return true
            end
        end
    else
        return (Player.job == jobs)
    end
end

AddEventHandler('esx:onPlayerLogout', function()
    TriggerEvent('xt-robnpcs:client:onUnload')
end)