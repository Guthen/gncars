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
            GNCars.EnterVehicle( ply, veh )
            return
        else
            ply:EnterVehicle( seat )
        end
    end )
end

local function get_car( ply )
    if not ply:InVehicle() then return end

    local car = ply:GetVehicle()
    if not IsValid( car ) then error( "Invalid car" ) return end -- Check if current vehicle is valid

    if GNCars.IsSeat( car ) then -- If it's a seat, get the vehicle
        car = car:GetParent()
    end

    if not IsValid( car ) or GNCars.IsSeat( car ) then error( "Invalid car or seat" ) return end -- Check if the vehicle is valid

    return car
end

local function switch_lights( car, ply, switch, back_light )
    back_light = back_light or false

    if IsValid( car ) and car:GetDriver() == ply then
        for k, v in ipairs( car.Lights ) do
            if ( back_light and not v.IsBackLight ) or ( not back_light and v.IsBackLight ) then continue end
            v:Switch( switch == nil and not v:GetOn() or switch )
            v:UpdateLight()
        end
    end
end

util.AddNetworkString( "GNCars:BindTransmit" )
net.Receive( "GNCars:BindTransmit", function( _, ply )
    local bind = net.ReadString()

    if bind == "+use" then
        --  > enter a vehicle seat
        if ply:InVehicle() then return end

        local trace = ply:GetEyeTrace()
        local target = trace.Entity

        if not IsValid( target ) or not target:IsVehicle() then return end
        if target:GetPos():Distance( ply:GetPos() ) > 128 then return end

        choose_vehicle_seat( ply, target, trace )
    elseif bind:StartWith( "slot" ) then
        --  > change siege role
        local id = tonumber( bind:Replace( "slot", "" ) )
        id = id == 0 and 10 or id

        local car = get_car( ply )

        if not IsValid( car ) then return end
        local seat = car.Seats[ id - 1 ]

        if id == 1 then
            GNCars.EnterVehicle( ply, car )

        elseif IsValid( seat ) then
            GNCars.EnterVehicle( ply, seat )

        end
    elseif bind == "+reload" then
        --  > coink coink
        local car = get_car( ply )

        if IsValid( car ) and car:GetDriver() == ply then
            car:EmitSound( "ambient/alarms/klaxon1.wav" )
        end
    elseif bind == "impulse 100" then
        --  > front lights
        local car = get_car( ply )
        
        switch_lights( car, ply, nil, false )
    elseif bind == "+back" or bind == "+jump" then
        --  > switch on back lights
        local car = get_car( ply )
        
        switch_lights( car, ply, true, true )
    else
        --  > switch off back lights
        local car = get_car( ply )

        timer.Simple( .5, function()
            switch_lights( car, ply, false, true )
        end )
    end
end )