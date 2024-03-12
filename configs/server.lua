return {
    payOut = { min = 10, max = 20 },                        -- Payout min/max
    payOutChance = { min = 70, max = 80 },                  -- Chance player receives cash
    policeJobs = {
        'police',
        'lspd'
    },

    addCash = function(src, amount)
        local player = getPlayer(src) -- Here's your player, use that as you want
        -- player.Functions.AddMoney('cash', amount)  -- qb/qbx

        return exports.ox_inventory:AddItem(src, 'money', amount)
    end
}