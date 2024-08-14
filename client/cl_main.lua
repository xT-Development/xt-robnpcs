local config = require 'configs.client'
local shared = require 'configs.shared'
local globalState = GlobalState

targetLocal = nil
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

    if not cache.ped then
        return
    end

    local fightChance = math.random(config.chancePedFights.min, config.chancePedFights.max)
    local randomChance = math.random(100)
    if randomChance <= fightChance then
        attackingPed(entity)
    else
        pedFlees(entity)
    end
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

    local coords = GetEntityCoords(targetLocal)
    notifyPolice(coords)

    TaskStandStill(targetLocal, 2000)

    -- Chance ped does not surrender
    if fightOrFlee(targetLocal) then
        isRobbing = false
        targetLocal = nil
        Entity(pedEntity).state:set('robbed', true, false)
        return
    end

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
        if globalState?.copCount >= shared.requiredCops and not cache.vehicle then
            local dist

            -- Ped gets up and runs away if you're too far away
            if targetLocal ~= nil then
                dist = getDistance(targetLocal)
                if dist > config.targetDistance then
                    pedGetUp(targetLocal)
                end
            end

            local entity

            if IsPlayerTargettingAnything(cache.playerId) then
                _, entity = GetPlayerTargetEntity(cache.playerId)
                sleep = 10
            elseif IsPlayerFreeAiming(cache.playerId) then
                _, entity = GetEntityPlayerIsFreeAimingAt(cache.playerId)
                sleep = 10
            else
                sleep = 500
            end

            if entity ~= nil then
                local entityState = Entity(entity)?.state?.robbed
                local missionEntity = (GetEntityPopulationType(entity) == 7)
                dist = getDistance(entity)

                if dist <= config.targetDistance and not entityState and not missionEntity and not isRobbing and IsPedHuman(entity) and not IsPedAPlayer(entity) and not IsPedDeadOrDying(entity, true) and not IsPedInAnyVehicle(entity) then
                    handlePedInteraction(entity)
                end
            end
        else
            sleep = 500
        end
        Wait(sleep)
    end
end

-- Handlers --
lib.onCache('weapon', function(newWeapon)
    if not newWeapon or not isAllowedWeapon(newWeapon) or isBlacklistedJob(config.blacklistedJobs) then return end

    aimAtPedsLoop(newWeapon)
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
