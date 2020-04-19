
function GNCars.IsSeat( ent )
    return ent:GetNWBool( "GNCars:Seat" )
end

function GNCars.EnterVehicle( ply, veh )
    if IsValid( veh:GetDriver() ) then return end

    local third_person_mode = false
    
    if ply:InVehicle() then
        third_person_mode = ply:GetVehicle():GetThirdPersonMode()
        ply:ExitVehicle()
    end

    veh.ForceEnter = true
        veh:SetThirdPersonMode( third_person_mode )
        ply:EnterVehicle( veh )
        ply:SetEyeAngles( veh:GetAngles() )
    veh.ForceEnter = nil
end

local function spawn_light( ent, pos, ang )
    local light = ents.Create( "gmod_lamp" )
        light:SetPos( ent:LocalToWorld( pos ) )
        light:SetAngles( ent:LocalToWorldAngles( ang ) )
        light:SetModel( "models/props_junk/PopCan01a.mdl" )
        light:SetParent( ent )
        light:SetModelScale( 0 )
        light:Spawn()

        light:SetFlashlightTexture( "effects/flashlight/hard" )
        light:SetColor( color_white )
        light:SetLightFOV( 50 )
        light:SetDistance( 768 )
        light:SetBrightness( 0.2 )
        light:Switch( false )
        light:UpdateLight()

    return light
end

--  > add passenger seats
hook.Add( "OnEntityCreated", "gncars", function( ent )
    if not ent:IsVehicle() then return end
    ent.Seats = {}
    ent.Lights = {}

    timer.Simple( 0, function()
        local class = ent:GetVehicleClass()
        local vehicle = GNCars.Vehicles[class] 
        if not vehicle then return end
    
        --  > seats
        for i, v in ipairs( vehicle.seats ) do
            local seat = GNLib.SpawnCar( "Seat_Jeep", ent:LocalToWorld( v.pos ), ent:LocalToWorldAngles( v.ang ) )
                seat:SetParent( ent )
                seat:SetNoDraw( vehicle.nodraw )
                seat:SetNWBool( "GNCars:Seat", true )

            ent.Seats[#ent.Seats + 1] = seat
        end

        --  > lamps
        for i, v in ipairs( vehicle.lamps ) do
            local light = spawn_light( ent, v.pos, v.ang )
                light.IsBackLight = v.is_back_light or false

            if light.IsBackLight then
                light:SetColor( GNLib.Colors.Alizarin )
            end

            ent.Lights[#ent.Lights + 1] = light
        end
    end )
end )

--  > override default one (else it exits you from the vehicle)
hook.Add( "CanPlayerEnterVehicle", "GNCars:CanForce", function( ply, veh ) 
    if GNCars.Vehicles[veh:GetVehicleClass()] and not veh.ForceEnter then
        return false
    end
end )

hook.Add( "EntityTakeDamage", "GNCars:PassengersDamages", function( car, dmg )
    if not car:IsVehicle() then return end
    if not car.Seats then return end

    for k, v in ipairs( car.Seats ) do
        local ply = v:GetDriver()

        if not IsValid( ply ) then return end

        ply:TakeDamage( dmg:GetDamage(), dmg:GetAttacker(), dmg:GetInflictor() )
    end
end )