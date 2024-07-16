local utils = {}

do
    local err_fmt = "[BHopBot] ERROR: %s"
    local err_len = 4
    local snd = "buttons/button8.wav"

    function utils.error(condition, error_message)
        if (condition) then
            local err_out = string.format(err_fmt, error_message)
            notification.AddLegacy(err_out, NOTIFY_ERROR, err_len)
            surface.PlaySound(snd)

            return
        end
    end
end

function utils.save(filename, positions, connections)
    local payload = {}
    payload.version = bhopbot.version -- ensure format compatibility
    payload.positions = {}
    payload.connections = {}

    for position_index, position in ipairs(positions) do
        local t = {}
        t[1] = position.x
        t[2] = position.y
        t[3] = position.z
        payload.positions[position_index] = t
    end

    for connection_index, connection in pairs(connections) do
        payload.connections[connection_index] = connection
    end

    local to_json = util.tableToJSON(payload)
    file.Write(filename, to_json)
end

function utils.load(filename)
    local json_file = file.Read(filename)
    
    local json_file_err_out = string.format("\"%s\": bhopbot data not found or invalid!", filename)
    utils.error(not json_file, json_file_err_out)

    local dat = util.JSONToTable(json_file)

    local current_version = dat.version
    local version_err_out = string.format("mismatched version \"%s\" does not match the newest release \"%s\"",
        current_version, bhopbot.version)
    utils.error(not current_version or current_version ~= bhopbot.version, version_err_out)

    local ret = {}
    ret.positions = dat.positions
    ret.connections = dat.connections

    return ret
end

return utils
