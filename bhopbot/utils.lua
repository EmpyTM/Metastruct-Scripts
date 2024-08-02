local utils = {}

function utils.error(condition, error_message)
    if condition then
        local err_out = string.format("[BHopBot] ERROR: %s", error_message)
        notification.AddLegacy(err_out, NOTIFY_ERROR, 4)
        surface.PlaySound("buttons/button8.wav")

        return
    end
end

function utils.save(filename, positions, connections)
    local payload = {}
    payload.version = bhopbot.version -- ensure format compatibility
    payload.positions = {}
    payload.connections = {}

    for position_index, position in ipairs(positions) do
        payload.positions[position_index] = {position.x, position.y, position.z}
    end

    for connection_index, connection in pairs(connections) do
        payload.connections[connection_index] = connection
    end

    file.Write(filename, util.tableToJSON(payload))
end

function utils.load(filename)
    local json_file = file.Read(filename)
    utils.error(not json_file, ("\"%s\": bhopbot data not found or invalid!"):format(filename))

    local dat = util.JSONToTable(json_file)
    utils.error(not dat.version or dat.version ~= bhopbot.version, ("mismatched version \"%s\" does not match the newest release \"%s\""):format(dat.version, bhopbot.version))

    return {positions = positions, connections = connections}
end

return utils
