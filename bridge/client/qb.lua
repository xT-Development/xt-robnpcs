if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()

function isBlacklistedJob(jobs)
    local Player = QBCore.Functions.GetPlayerData()
    if type(jobs) == 'table' then
        for x = 1, #jobs do
            if jobs[x] == Player.job.name then
                return true
            end
        end
    else
        return (Player.job.name == jobs)
    end
end

AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    TriggerEvent('xt-robnpcs:client:onUnload')
end)