return {
    targetDistance = 20,                                    -- Max distance ped reacts to you aiming at them
    blacklistedJobs = {                                     -- Jobs not allowed to rob locals
        'police',
        'ambulance'
    },
    robLength = 5,                                          -- Length to rob local (seconds)
    chancePedRunsAway = { min = 5, max = 10 },              -- Chance ped runs away rather than surrendering
    copsChance = { min = 0, max = 10 },                     -- Chance police are called

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