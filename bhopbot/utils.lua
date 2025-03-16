local utils = {}

function utils.error(condition, error_message)
    if (condition) then
        local err_output = string.format("[BHopBot] ERROR: %s", error_message)
        local time_to_close_seconds = 5
        notification.AddLegacy(err_output, NOTIFY_ERROR, time_to_close_seconds)
        surface.PlaySound("buttons/button8.wav")

        return
    end
end

function utils.save(filename, positions, connections)
    local payload = {
        version = bhopbot.version, -- ensure format compatibility
        positions = {},
        connections = {}
    }
    
    for position_index, position in ipairs(positions) do
        payload.positions[position_index] = {position.x, position.y, position.z}
    end

    for connection_index, connection in pairs(connections) do
        payload.connections[connection_index] = connection
    end

    payload = util.tableToJSON(payload)
    file.Write(filename, payload)
end

function utils.load(filename)
    local json_file = file.Read(filename)
    
    local err_no_json = ("\"%s\": bhopbot data not found or invalid!"):format(filename)
    utils.error(not json_file, err_no_json)

    local dat = util.JSONToTable(json_file)

    local err_version_mismatch = ("mismatched version \"%s\" does not match the newest release \"%s\""):format(dat.version, bhopbot.version)
    utils.error(not dat.version or dat.version ~= bhopbot.version, err_version_mismatch)

    return {positions = positions, connections = connections}
end

return utils
