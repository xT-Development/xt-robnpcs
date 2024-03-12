local config = require 'configs.client'

-- Forces Ped Into Surrended Animation --
function forceSurrenderAnimation(entity)
    CreateThread(function()
        lib.requestAnimDict('random@shop_robbery')
        while isRobbing do
            if not IsEntityPlayingAnim(entity, 'random@shop_robbery', 'kneel_loop_p', 3) then
                TaskPlayAnim(entity, 'random@shop_robbery', 'kneel_loop_p', 50.0, 8.0, -1, 1, 1.0, false, false, false)
            end
            Wait(200)
        end
    end)
end

-- Distance Between Player & Ped --
function getDistance(entity)
    local pCoords = GetEntityCoords(cache.ped, true)
    local tCoords = GetEntityCoords(entity, true)
    local dist = #(tCoords - pCoords)

    return dist
end

-- Chance Police are Called --
function notifyPolice(coords)
    local copsChance = math.random(config.copsChance.min, config.copsChance.max)
    local randomChance = math.random(100)
    if randomChance <= copsChance then
        config.dispatch(coords)
    end
end

-- Remove Interactions --
function removeInteraction(entity)
    if config.useInteract then
        local netId = NetworkGetNetworkIdFromEntity(entity)
        exports.interact:RemoveEntityInteraction(netId, 'robLocal')
    else
        exports['qb-target']:RemoveTargetEntity(entity, 'Rob Citizen')
    end

end