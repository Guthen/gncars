local vehicles = {
    ["ast_db5tdm"] = {
        seats = {
            Vector( -15, -6, 19 )
        }
    }
}

--  > add passenger seats
hook.Add( "OnEntityCreated", "guthcars", function( ent )
    if not ent:IsVehicle() then return end
    ent.Seats = {}

    timer.Simple( 0, function()
        local class = ent:GetVehicleClass()
        local vehicle = vehicles[class] 
        if not vehicle then return end
    
        for i, v in ipairs( vehicle.seats ) do
            local seat = GNLib.SpawnCar( "Seat_Jeep", ent:LocalToWorld( v ), ent:GetAngles() )
                seat:SetParent( ent )
                seat:SetNoDraw( true )

            ent.Seats[#ent.Seats + 1] = seat
        end
    end )
end )

--  > choose passenger seat
hook.Add( "guthcars:AttemptEnterVehicle", "guthcars", function( ply, veh )
    local pos = veh:GetPassengerSeatPoint( 1 )
    local seats = { --[[ not IsValid( veh:GetDriver() ) and ]] pos }
    table.Add( seats, veh.Seats )

    --  > calc nearest seat
    local dist, seat = math.huge
    for k, v in ipairs( seats ) do
        local is_vector = isvector( v )
        if not is_vector and ( not IsValid( v ) or not v:IsVehicle() ) then continue end

        local v_dist = ( is_vector and v or v:GetPos() ):DistToSqr( ply:GetPos() )
        if v_dist < dist then
            dist = v_dist
            seat = v
        end
    end

    --  > attempt to enter seat
    print( "Attempt", seat )
    timer.Simple( .1, function()
        if isvector( seat ) then
            veh.ForceEnter = true
            ply:EnterVehicle( veh )
            veh.ForceEnter = nil
            return
        else
            ply:EnterVehicle( seat )
        end
    end )
end )

--  > override default one (else it exits you from the vehicle)
hook.Add( "CanPlayerEnterVehicle", "guthcars", function( ply, veh ) 
    print( "hi", veh )
    if vehicles[veh:GetVehicleClass()] and not veh.ForceEnter then
        print( veh.ForceEnter )
        return false
    end
end )

--  > handle attempt to enter in a vehicle
hook.Add( "KeyPress", "guthcars", function( ply, key )
    if key == IN_USE then
        if ply:InVehicle() then return end

        local target = ply:GetEyeTrace().Entity

        if not IsValid( target ) or not target:IsVehicle() then return end
        if target:GetPos():Distance( ply:GetPos() ) > 128 then return end

        hook.Run( "guthcars:AttemptEnterVehicle", ply, target )
    end
end )
