local utils = {}

function utils.save( filename, positions, connections )
    local payload = {}
    payload.version = bhopbot.version -- ensure format compatibility
    payload.positions = {}
    payload.connections = {}

    for position_index, position in ipairs(positions) do
        payload.positions[position_index] = { position.x, position.y, position.z }
    end

    for connection_index, connection in pairs(connections) do
        payload.connections[connection_index] = connection
    end

    local to_json = util.tableToJSON(payload)
    file.Write(filename, to_json)
end

function utils.load( filename )
    local json_file = file.Read(filename)

    if ( not json_file ) then
        local formatted_error = string.format("ERROR: \"%s\": bhopbot data not found or invalid!", filename)
        error(formatted_error)
    end

    local dat = util.JSONToTable(json_file)

    if ( not dat.version or dat.version ~= bhopbot.version ) then
        local formatted_error = string.format("ERROR: mismatched version -- \"%s\" does not match the newest release \"%s\"", dat.version, bhopbot.version)
        error(formatted_error)
    end

    return { dat.positions, dat.connections }
end

return utils
