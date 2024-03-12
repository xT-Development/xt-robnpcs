return {
    useInteract = false,                                    -- Use interact or ox/qb target (https://github.com/darktrovx/interact)
    targetDistance = 20,                                    -- Max distance ped reacts to you aiming at them
    blacklistedJobs = {                                     -- Jobs not allowed to rob locals
        'police',
        'ambulance'
    },
    robLength = 5,                                          -- Length to rob local (seconds)
    chancePedFlees = {                                      -- Chance ped runs away rather than surrendering
        min = 5,
        max = 25
    },
    chancePedFights = {                                     -- Chance ped beats your ass before or after being robbed
        min = 5,
        max = 15
    },
    chancePedIsArmedWhileFighting = {                       -- Chance ped has a melee weapon to fight player
        min = 80,
        max = 90
    },
    pedWeapons = {                                          -- Weapons ped might have
        'WEAPON_KINFE',
        'WEAPON_BAT'
    },
    copsChance = {                                          -- Chance police are called
        min = 80,
        max = 90
    },

    dispatch = function(coords)
        local PoliceJobs = { 'police' }

        -- Add your own dispatch event / exports
        exports["ps-dispatch"]:CustomAlert({
            coords = coords,
            job = PoliceJobs,
            message = 'Citizen Robbery',
            dispatchCode = '10-??',
            firstStreet = coords,
            description = 'Citizen Robbery',
            radius = 0,
            sprite = 58,
            color = 1,
            scale = 1.0,
            length = 3,
        })
    end
}