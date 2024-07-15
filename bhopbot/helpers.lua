local helpers = {}

function helpers.get_players_sitting_on( ply )	
	local players = player.GetAll()
	local sitting_players = {}
	
	for player_index, player_entity in ipairs(players) do
		if ( player_entity == ply ) then continue end
		if ( not v:InVehicle() ) then continue end
        local veh = player_entity:GetVehicle()
		if ( veh:GetParent() ~= ply ) then continue end
        
        table.insert(sitting_players, v)
	end
	
	return sitting_players
end

function helpers.find_player_by_name( desired_name )	
	local players = player.GetAll()
    local ply = nil

	for player_index, player_entity in ipairs(players) do
        local player_name = v:GetName()
		if ( string.find(player_name, desired_name) ) then
			ply = player_entity
            break
		end
	end

	return ply
end

return helpers
