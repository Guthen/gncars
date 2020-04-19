GNCars.Vehicles = GNCars.Vehicles or {}

function GNCars.GetCustomVehicleClasses( ignore_saved )
    --  > get all vehicles
    local tbl = table.GetKeys( list.Get( "Vehicles" ) )

    --  > ignore table
    local ignore = {
        ["Seat_Jalopy"] = true,
        ["Seat_Airboat"] = true,
        ["Seat_Jeep"] = true,
        ["Chair_Wood"] = true,
        ["Chair_Plastic"] = true,
        ["Chair_Office1"] = true,
        ["Chair_Office2"] = true,
        ["Pod"] = true,
        ["Jeep"] = true,
        ["Airboat"] = true,
        ["phx_seat"] = true,
        ["phx_seat2"] = true,
        ["phx_seat3"] = true,
    }

    --  > add saved vehicles to ignore
    if ignore_saved then
        local vehicles = GNCars.GetSavedVehicles()
        for k, v in pairs( vehicles ) do
            ignore[k] = true
        end
    end

    --  > remove vehicles to ignore
    for k, v in ipairs( tbl ) do
        if ignore[v] then table.remove( tbl, k ) end
    end

    return tbl
end

function GNCars.ParseVehicles( vehicles )
    for class, veh in pairs( vehicles ) do
        for key, v in pairs( veh ) do
            if not istable( v ) then continue end
            vehicles[class][key] = GNCars.ParseVehicleEntities( v )
        end

        veh.nodraw = veh.nodraw == nil and true or veh.nodraw
    end

    return vehicles
end

function GNCars.ParseVehicleEntities( veh )
    local veh_ents = {}

    for i, ent in ipairs( veh ) do
        veh_ents[i] = { pos = Vector( unpack( ent.pos ) ), ang = Angle( unpack( ent.ang ) ) }

        local values = table.Copy( ent )
        values.pos = nil
        values.ang = nil

        table.Merge( veh_ents[i], values )
    end

    return veh_ents
end

function GNCars.AddVehicle( vehicle_class, tbl )
    if istable( vehicle_class ) then
        for k, v in pairs( vehicle_class ) do
            GNCars.AddVehicle( k, v )
        end
    else
        if not list.Get( "Vehicles" )[vehicle_class] then return end

        GNCars.Vehicles[vehicle_class] = { seats = tbl.seats or {}, lamps = tbl.lamps or {}, nodraw = tbl.nodraw == nil and true or tbl.nodraw }
    end
end
--[[ GNCars.AddVehicle( "m1tdm", { Vector( 18, -0, 8 ) } ) ]]