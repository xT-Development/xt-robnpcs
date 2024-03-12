local config = require 'configs.client'
local isRobbing = false
local targetLocal = nil

-- Distance Between Player & Ped --
local function getDistance(entity)
    local pCoords = GetEntityCoords(cache.ped, true)
    local tCoords = GetEntityCoords(entity, true)
    local dist = #(tCoords - pCoords)

    return dist
end

-- Chance Police are Called --
local function notifyPolice(coords)
    local copsChance = math.random(config.copsChance.min, config.copsChance.max)
    local randomChance = math.random(100)
    if randomChance <= copsChance then
        config.dispatch(coords)
    end
end

-- Ped Gets Up & Runs Away --
local function pedGetUp(entity)
    targetLocal = nil
    isRobbing = false

    if IsPedDeadOrDying(entity, true) then return end

    FreezeEntityPosition(entity, false)
    lib.requestAnimDict('random@shop_robbery')
    TaskPlayAnim(entity, 'random@shop_robbery', 'kneel_getup_p', 2.0, 2.0, 2500, 9, 0, false, false, false)
    Wait(2500)
    if not cache.ped then return end

    TaskReactAndFleePed(entity, cache.ped)
end

-- Handle Robbing Local --
local function robLocal(entity)
    local coords = GetEntityCoords(entity)

    notifyPolice(coords)

    if lib.progressCircle({
        label = 'Running Pockets...',
        duration = (config.robLength * 1000),
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true },
        anim = { dict = 'random@shop_robbery', clip = 'robbery_action_b' },
    }) then
        local netID = NetworkGetNetworkIdFromEntity(entity)
        local robbed = lib.callback.await('xt-robnpcs:server:robNPC', false, netID)
        if robbed then
            pedGetUp(entity)
        end
    end
end

-- Local Plays Anim / Add Target --
local function handlePedInteraction(entity)
    isRobbing = true
    targetLocal = entity

    Wait(2000)  --- Just a little "buffer" so they dont react instantly

    -- Chance ped does not surrender
    local runChance = math.random(config.chancePedRunsAway.min, config.chancePedRunsAway.max)
    local randomChance = math.random(100)
    if randomChance <= runChance then
        Entity(entity).state:set('robbed', true, false)
        lib.notify({ title = 'They ran away!', type = 'error'})
        Wait(2000)  -- Another little "buffer" so players cant just snap to the next ped instantly if they run away
        targetLocal = nil
        isRobbing = false
        return
    end

    lib.requestAnimDict('random@arrests@busted')

    TaskStandStill(entity, 2000)
    TaskHandsUp(entity, 2000, -1)
    Wait(2000)
    TaskPlayAnim(entity, 'random@shop_robbery', 'kneel_loop_p', 2.0, 2.0, -1, 9, 0, false, false, false)
    FreezeEntityPosition(entity, true)

    exports.ox_target:addLocalEntity(entity, {
        {
            label = 'Rob Citizen',
            icon = 'fas fa-gun',
            onSelect = function()
                robLocal(entity)
            end
        }
    })
end

local function aimAtPedsLoop(newWeapon)
    local sleep = 10
    while cache.weapon ~= nil do
        local dist

        -- Ped gets up and runs away if you're too far away
        if targetLocal ~= nil then
            dist = getDistance(targetLocal)
            if dist > config.targetDistance then
                pedGetUp(targetLocal)
            end
        end

        if IsPlayerFreeAiming(cache.playerId) then
            sleep = 10

            local isAiming, entity = GetEntityPlayerIsFreeAimingAt(cache.playerId)
            local entityState = Entity(entity)?.state?.robbed
            dist = getDistance(entity)

            if dist <= config.targetDistance and not entityState and not isRobbing and IsPedHuman(entity) and not IsPedDeadOrDying(entity, true) then
                handlePedInteraction(entity)
            end
        else
            sleep = 500
        end
        Wait(sleep)
    end
end

-- Handlers --
lib.onCache('weapon', function(newWeapon)
    if not newWeapon or isBlacklistedJob(config.blacklistedJobs) then return end

    aimAtPedsLoop(newWeapon)
end)

AddEventHandler('xt-robnpcs:client:onUnload', function()
    if targetLocal ~= nil then
        pedGetUp(targetLocal)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if targetLocal ~= nil then
        pedGetUp(targetLocal)
    end
end)
