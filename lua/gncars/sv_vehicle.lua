GNCars.Vehicles = GNCars.Vehicles or {}

--  > fetch vehicles data
http.Fetch( "https://raw.githubusercontent.com/Guthen/gncars/master/vehicles.json", function( raw )
    local vehicles = util.JSONToTable( raw )
    if not vehicles then return error( "GNCars: failed to fetch vehicles data" ) end

    --  > parse array positions to vectors
    for k, v in pairs( vehicles ) do
        for i, v in ipairs( v.seats ) do
            vehicles[k].seats[i] = Vector( unpack( v ) )
        end
        v.nodraw = v.nodraw == nil and true or v.nodraw
        GNCars.AddVehicle( k, v.seats, v.nodraw )
    end

    print( "GNCars: success to fetch vehicles data" )
end )

function GNCars.AddVehicle( vehicle_class, seats, nodraw )
    if not list.Get( "Vehicles" )[vehicle_class] then return --[[ error( ( "GNCars: '%s' is not a valid vehicle class!" ):format( vehicle_class ), 2 ) ]] end

    GNCars.Vehicles[vehicle_class] = { seats = seats, nodraw = nodraw == nil and true or nodraw }
end
--[[ GNCars.AddVehicle( "m1tdm", { Vector( 18, -0, 8 ) } ) ]]

--  > add passenger seats
hook.Add( "OnEntityCreated", "gncars", function( ent )
    if not ent:IsVehicle() then return end
    ent.Seats = {}

    timer.Simple( 0, function()
        local class = ent:GetVehicleClass()
        local vehicle = GNCars.Vehicles[class] 
        if not vehicle then return end
    
        for i, v in ipairs( vehicle.seats ) do
            local seat = GNLib.SpawnCar( "Seat_Jeep", ent:LocalToWorld( v ), ent:GetAngles() )
                seat:SetParent( ent )
                seat:SetNoDraw( vehicle.nodraw )

            ent.Seats[#ent.Seats + 1] = seat
        end
    end )
end )

--  > choose passenger seat
local function choose_vehicle_seat( ply, veh, trace )
    local seats = { veh:GetPassengerSeatPoint( 1 ) }
    table.Add( seats, veh.Seats )

    --  > get nearest seat
    local pos = trace.HitPos
    local dist, seat = math.huge
    for k, v in ipairs( seats ) do
        local is_vector = isvector( v )
        if not is_vector and ( not IsValid( v ) or not v:IsVehicle() ) then continue end

        local v_dist = ( is_vector and v or v:GetPos() ):DistToSqr( pos )
        if v_dist < dist then
            dist = v_dist
            seat = v
        end
    end

    --  > attempt to enter seat
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
end

--  > override default one (else it exits you from the vehicle)
hook.Add( "CanPlayerEnterVehicle", "gncars", function( ply, veh ) 
    if GNCars.Vehicles[veh:GetVehicleClass()] and not veh.ForceEnter then
        return false
    end
end )

--  > handle attempt to enter in a vehicle
hook.Add( "KeyPress", "gncars", function( ply, key )
    if key == IN_USE then
        if ply:InVehicle() then return end

        local trace = ply:GetEyeTrace()
        local target = trace.Entity

        if not IsValid( target ) or not target:IsVehicle() then return end
        if target:GetPos():Distance( ply:GetPos() ) > 128 then return end

        choose_vehicle_seat( ply, target, trace )
    end
end )
