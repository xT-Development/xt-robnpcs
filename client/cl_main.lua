local config = require 'configs.client'
local shared = require 'configs.shared'
local targetLocal = nil
local totalCops = 0

isRobbing = false

-- Ped Gets Up & Runs Away --
local function pedGetUp(entity)
    targetLocal = nil
    isRobbing = false

    removeInteraction(entity)

    if IsPedDeadOrDying(entity, true) then
        return
    end

    FreezeEntityPosition(entity, false)
    lib.requestAnimDict('random@shop_robbery')
    TaskPlayAnim(entity, 'random@shop_robbery', 'kneel_getup_p', 2.0, 2.0, 2500, 9, 0, false, false, false)
    Wait(2500)

    SetBlockingOfNonTemporaryEvents(entity, false)

    if not cache.ped then
        return
    end

    TaskReactAndFleePed(entity, cache.ped)
end

-- Handle Robbing Local --
local function robLocal(entity)
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

-- Adds Interaction to Ped --
local function addInteraction(entity)
    if config.useInteract then
        local netId = NetworkGetNetworkIdFromEntity(entity)

        exports.interact:AddEntityInteraction({
            netId = netId,
            id = 'robLocal',
            distance = 4.0,
            interactDst = 2.0,
            ignoreLos = false,
            options = {
                {
                    label = 'Rob Citizen',
                    action = function(_, coords, args)
                        robLocal(entity)
                    end,
                },
            }
        })
    else
        exports['qb-target']:AddTargetEntity(entity, {
            options = {
                {
                    type = "client",
                    icon = 'fas fa-gun',
                    label = 'Rob Citizen',
                    action = function(entity)
                        robLocal(entity)
                    end,
                }
            },
            distance = 2.0,
        })
    end
end

-- Local Plays Anim / Add Target --
local function handlePedInteraction(pedEntity)
    isRobbing = true
    targetLocal = pedEntity

    Wait(2000) -- Just a little "buffer" so they dont react instantly

    -- Chance ped does not surrender
    local runChance = math.random(config.chancePedRunsAway.min, config.chancePedRunsAway.max)
    local randomChance = math.random(100)
    if randomChance <= runChance then
        TaskReactAndFleePed(targetLocal, cache.ped)
        Entity(targetLocal).state:set('robbed', true, false)
        lib.notify({ title = 'They ran away!', type = 'error'})
        Wait(2000) -- Another little "buffer" so players cant just snap to the next ped instantly if they run away
        targetLocal = nil
        isRobbing = false
        return
    end

    local coords = GetEntityCoords(targetLocal)
    notifyPolice(coords)

    SetBlockingOfNonTemporaryEvents(targetLocal, true)
    TaskStandStill(targetLocal, 2000)
    TaskHandsUp(targetLocal, 2000)
    SetPedKeepTask(targetLocal, true)
    FreezeEntityPosition(targetLocal, true)
    Wait(2000)

    forceSurrenderAnimation(targetLocal)
    addInteraction(targetLocal)
end

local function aimAtPedsLoop(newWeapon)
    local sleep = 10
    while cache.weapon ~= nil do
        if totalCops >= shared.requiredCops then
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
                local missionEntity = (GetEntityPopulationType(entity) == 7)
                dist = getDistance(entity)

                if dist <= config.targetDistance and not entityState and not missionEntity and not isRobbing and IsPedHuman(entity) and not IsPedDeadOrDying(entity, true) and not IsPedInAnyVehicle(entity) then
                    handlePedInteraction(entity)
                end
            else
                sleep = 500
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

RegisterNetEvent('xt-robnpcs:client:setCopCount', function(copCount)
    totalCops = copCount
end)

AddEventHandler('xt-robnpcs:client:onUnload', function()
    if not targetLocal then return end
    pedGetUp(targetLocal)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if not targetLocal then return end
    pedGetUp(targetLocal)
end)
