util.AddNetworkString( "GNCars:Data" )

local filename = "gncars/vehicles.json"
net.Receive( "GNCars:Data", function( len, ply )
    if not ply:IsSuperAdmin() then return end

    --  > check tbl
    local tbl = net.ReadTable()
    if not istable( tbl ) or table.Count( tbl ) <= 0 then return end

    --  > check first key
    local key = table.GetFirstKey( tbl )
    if not isstring( key ) then return end

    --  > dir
    file.CreateDir( "gncars" )

    --  > write
    local content = file.Read( filename )
    if not content then 
        file.Write( filename, util.TableToJSON( { [key] = tbl[key] } ) )
    else
        local content_tbl = util.JSONToTable( content )
        content_tbl[key] = tbl[key]

        file.Write( filename, util.TableToJSON( content_tbl ) )
    end

    ply:PrintChat( GNLib.Colors.Alizarin, "GNCars: ", color_white, "The data has been saved!" )

    --  > load
    GNCars.RegisterSavedVehicles()

    --  > sync
    GNCars.SyncVehicles()
end )

--  > fetch vehicles data
function GNCars.FetchVehicles()
    local time = os.clock()
    http.Post( "http://gnlib.mtxserv.com/gncars/vehicles/get.php", { json = util.TableToJSON( GNCars.GetCustomVehicleClasses( true ) ) }, function( raw )
        local vehicles = util.JSONToTable( raw )
        if not vehicles then return error( "GNCars: failed to fetch vehicles data" ) end

        --  > parse array positions to vectors
        GNCars.AddVehicle( GNCars.ParseVehicles( vehicles ) )

        print( ( "GNCars: success to fetch vehicles data in %ss" ):format( math.Round( os.clock() - time, 2 ) ) )
    end )

    --  > register saved vehicles
    GNCars.RegisterSavedVehicles()

    --  > send to players
    GNCars.SyncVehicles()
end
hook.Add( "InitPostEntity", "GNCars:FetchVehicles", GNCars.FetchVehicles )

--  > sync vehicles to client
function GNCars.SyncVehicles( ply )
    net.Start( "GNCars:Data" )
        net.WriteTable( GNCars.Vehicles )
    if ply then net.Send( ply ) else net.Broadcast() end
end
hook.Add( "PlayerInitialSpawn", "GNCars:Sync", GNCars.SyncVehicles )

function GNCars.GetSavedVehicles()
    local json = file.Read( filename )
    if not json then return {} end

    return util.JSONToTable( json )
end

function GNCars.RegisterSavedVehicles()
    GNCars.AddVehicle( GNCars.ParseVehicles( GNCars.GetSavedVehicles() ) )
end