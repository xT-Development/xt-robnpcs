local config = require 'configs.client'
local target = GetResourceState('qb-target') == 'started' and 'qb' or 'ox'
local targetExport = (target == 'qb') and exports['qb-target'] or exports.ox_target

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
        if target == 'qb' then
            targetExport:RemoveTargetEntity(entity, 'Rob Citizen')
        else
            targetExport:removeLocalEntity(entity, 'rob_local')
        end
    end
end

-- Ped Chooses to Attack --
function attackingPed(entity)
    if IsPedFleeing(entity) then
        ClearPedTasksImmediately(entity)
    end

    SetPedFleeAttributes(entity, 0, 0)
    SetPedCombatAttributes(entity, 46, 1)       -- BF_CanFightArmedPedsWhenNotArmed
    SetPedCombatAttributes(entity, 17, 0)       -- BF_AlwaysFlee
    SetPedCombatAttributes(entity, 5, 1)        -- BF_AlwaysFight
    SetPedCombatAttributes(entity, 58, 1)       -- BF_DisableFleeFromCombat
    SetPedCombatRange(entity, 3)
    SetPedRelationshipGroupHash(entity, joaat('HATES_PLAYER'))
    TaskCombatHatedTargetsAroundPed(entity, 50, 0)

    local weaponChance = math.random(config.chancePedIsArmedWhileFighting.min, config.chancePedIsArmedWhileFighting.max)
    local randomChance2 = math.random(100)
    if randomChance2 <= weaponChance then
        local randomWeapon = math.random(#config.pedWeapons)
        GiveWeaponToPed(entity, config.pedWeapons[randomWeapon], false, false)
    end

    TaskCombatHatedTargetsAroundPed(entity, 50, 0)
    lib.notify({ title = 'Fight Back!', description = 'They didn\'t like that!', type = 'error' })
end

-- Ped Chooses to Flee --
function pedFlees(entity)
    SetBlockingOfNonTemporaryEvents(entity, false)
    TaskReactAndFleePed(entity, cache.ped)
    Wait(2000) -- Another little "buffer" so players cant just snap to the next ped instantly if they run away
    targetLocal = nil
    isRobbing = false
end

-- Ped Fights or Flees --
function fightOrFlee(entity)
    local fightChance = math.random(config.chancePedFights.min, config.chancePedFights.max)
    local fleeChance = math.random(config.chancePedFlees.min, config.chancePedFlees.max)
    local randomChance = math.random(100)

    SetBlockingOfNonTemporaryEvents(entity, true)

    if randomChance <= fightChance then
        attackingPed(entity)
        return true
    end

    if randomChance <= fleeChance then
        pedFlees(entity)
        lib.notify({ title = 'They ran away!', type = 'error'})
        return true
    end

    return false
end

function isAllowedWeapon(weapon)
    local callback = false

    for x = 1, #config.allowedWeapons do
        if weapon == joaat(config.allowedWeapons[x]) then
            callback = true
            break
        end
    end

    return callback
end