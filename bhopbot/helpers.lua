local helpers = {}

function helpers.get_players_sitting_on(target_player)
    local players = player.GetAll()
    local sitting_players = {}
    
    for player_index, player_entity in ipairs(players) do
        if (player_entity == target_player) then continue end
        
        local in_vehicle = player_entity:InVehicle()
        if (not in_vehicle) then continue end

        local veh = player_entity:GetVehicle()
        local veh_parent = veh:GetParent()
        if (veh_parent ~= target_player) then continue end
        
        table.insert(sitting_players, player_entity)
    end
    
    return sitting_players
end

function helpers.find_player_by_name(desired_name)
    local players = player.GetAll()
    local ply = nil
    local to_find_start_position = 1
    local use_patterns = false

    for player_index, player_entity in ipairs(players) do
        local player_name = player_entity:GetName()
        local found_start, found_end, matched = player_name:find(desired_name, to_find_start_position, use_patterns)
        
        if (found_start) then
            ply = player_entity
            break
        end
    end

    return ply
end

return helpers
