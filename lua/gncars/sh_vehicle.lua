GNCars.Vehicles = GNCars.Vehicles or {}

--  > fetch vehicles data
http.Fetch( "https://raw.githubusercontent.com/Guthen/gncars/master/vehicles.json", function( raw )
    local vehicles = util.JSONToTable( raw )
    if not vehicles then return error( "GNCars: failed to fetch vehicles data" ) end

    --  > parse array positions to vectors
    for k, v in pairs( vehicles ) do
        for i, v in ipairs( v.seats ) do
            vehicles[k].seats[i] = { pos = Vector( v[1], v[2], v[3] ), ang = Angle( v[4], v[5], v[6] ) }
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