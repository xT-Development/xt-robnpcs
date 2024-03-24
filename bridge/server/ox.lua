if GetResourceState('ox_core') ~= 'started' then return end

local file = ('imports/%s.lua'):format(IsDuplicityVersion() and 'server' or 'client')
local import = LoadResourceFile('ox_core', file)
local chunk = assert(load(import, ('@@ox_core/%s'):format(file)))
chunk()

function getPlayer(id)
    return Ox.GetPlayer(id)
end

function getPlayerJob(src)
    local player = getPlayer(src)
    return player and player.getGroup() or nil
end