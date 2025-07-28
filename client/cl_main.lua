local config = require 'configs.client'
local shared = require 'configs.shared'
local globalState = GlobalState
local target = GetResourceState('qb-target') == 'started' and 'qb' or 'ox'
local targetExport = (target == 'qb') and exports['qb-target'] or exports.ox_target

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

    if target == 'qb' then
        targetExport:RemoveTargetEntity(entity, 'Rob Citizen')
    else
        targetExport:removeLocalEntity(entity, 'rob_local')
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

        if target == 'qb' then
            targetExport:AddTargetEntity(entity, {
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
        else
            targetExport:addLocalEntity(entity, {
                {
                    label = 'Rob Citizen',
                    name = 'rob_local',
                    icon = 'fas fa-gun',
                    distance = 2.0,
                    onSelect = function(data)
                        robLocal(entity)
                    end,
                }
            })
        end
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

local function isAiming()
    return (IsPlayerTargettingAnything(cache.playerId) or IsPlayerFreeAiming(cache.playerId) or IsControlPressed(0, 25)) and true or false
end

-- raycast from gun muzzle for hit entities
-- rather than relying on dogshit aiming natives that rarely seem to work
local function raycastFromGun()
    local gun = GetCurrentPedWeaponEntityIndex(cache.ped)
    if not gun or gun == 0 then return end

    -- Get muzzle position
    local muzzleIndex = GetEntityBoneIndexByName(gun, "gun_muzzle")
    local gunCoords = GetWorldPositionOfEntityBone(gun, muzzleIndex)

    -- Get camera direction
    local camRot = GetGameplayCamRot(0)
    local pitch = math.rad(camRot.x)
    local yaw = math.rad(camRot.z)

    -- Convert rotation to a directional vector
    local forwardVector = {
        x = -math.sin(yaw) * math.cos(pitch),
        y = math.cos(yaw) * math.cos(pitch),
        z = math.sin(pitch)
    }

    -- Raycast endpoint
    local distance = config.targetDistance
    local finalCoords = {
        x = gunCoords.x + forwardVector.x * distance,
        y = gunCoords.y + forwardVector.y * distance,
        z = gunCoords.z + forwardVector.z * distance
    }

    local hit, entity = lib.raycast.fromCoords(gunCoords, finalCoords, 4, 4)

    return hit, entity
end

local function aimAtPedsLoop(newWeapon)
    while cache.weapon ~= newWeapon do
        Wait(1)
    end

    local sleep = 10
    while cache.weapon == newWeapon do
        if globalState?.copCount >= shared.requiredCops and not cache.vehicle and not isRobbing then
            local dist

            -- Ped gets up and runs away if you're too far away
            if targetLocal ~= nil then
                dist = getDistance(targetLocal)
                if dist > config.targetDistance then
                    pedGetUp(targetLocal)
                end
            end

            local aiming = isAiming()
            local hit, entity
            if aiming then
                hit, entity = raycastFromGun()
            end

            sleep = (aiming and not isRobbing) and 10 or 500

            if aiming and hit and entity then
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
    if not newWeapon or (newWeapon == `WEAPON_UNARMED`) or not isAllowedWeapon(newWeapon) or isBlacklistedJob(config.blacklistedJobs) or cache.vehicle then return end

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
