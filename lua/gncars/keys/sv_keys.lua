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

local function switch_light( ent, switch )
    if IsValid( ent )  then
        ent:Switch( switch == nil and not ent:GetOn() or switch )
        ent:UpdateLight()
    end
end

local function switch_front_lights( car, switch )
    for i, v in ipairs( car.Lights ) do
        if v.IsBackLight or v.BlinkerType then continue end
        switch_light( v, switch )
    end
end

local function switch_back_lights( car, switch )
    local done = false

    for i, v in ipairs( car.Lights ) do
        if not v.IsBackLight or v.BlinkerType then continue end
        switch_light( v, switch )

        done = true
    end

    return done
end

local function switch_blinker_lights( car, switch, side )
    local done = false

    for i, v in ipairs( car.Lights ) do
        if v.IsBackLight or not v.BlinkerType then continue end
        if not ( v.BlinkerType == side ) then continue end
        switch_light( v, switch )

        done = true
    end

    return done
end

util.AddNetworkString( "GNCars:BindTransmit" )
net.Receive( "GNCars:BindTransmit", function( _, ply )
    local bind = net.ReadString()

    --  > enter a vehicle seat
    if bind == "+use" then
        if ply:InVehicle() then return end

        local trace = ply:GetEyeTrace()
        local target = trace.Entity

        if not IsValid( target ) or not target:IsVehicle() then return end
        if target:GetPos():Distance( ply:GetPos() ) > 128 then return end

        choose_vehicle_seat( ply, target, trace )
    --  > change siege role
    elseif bind:StartWith( "slot" ) then
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
    --  > coink coink
    elseif bind == "+reload" then
        local car = get_car( ply )

        if IsValid( car ) and car:GetDriver() == ply then
            car:EmitSound( "gncars/klaxon" .. math.random( 1, 2 ) .. ".wav" )
        end
    --  > front lights
    elseif bind == "impulse 100" then
        local car = get_car( ply )
        
        if IsValid( car ) and car:GetDriver() == ply then
            switch_front_lights( car, nil )
        end
    --  > back lights
    elseif bind == "+back" or bind == "+jump" then
        local car = get_car( ply )
        if not IsValid( car ) then return end

        --  > if car is stopped then do nothing
        local last_speed = math.abs( car:GetHLSpeed() )
        if last_speed <= .1 then return end

        --  > switch on lights
        if not IsValid( car ) or not ( car:GetDriver() == ply ) then return end
        if not switch_back_lights( car, true ) then return end

        --  > control lights
        local id = "GNCars:BackLights" .. car:EntIndex()
        timer.Create( id, .5, 0, function()
            --  > if car is fucked then stop
            if not IsValid( car ) then 
                timer.Remove( id )
                return 
            end
            
            --  > if car speed is greater than before or car is stop then stop
            local speed = car:GetHLSpeed()
            if math.abs( speed ) <= .3 or speed > last_speed then 
                switch_back_lights( car, false )
                timer.Remove( id )
            end

            --  > stock speed into last speed
            last_speed = speed
        end )
    elseif bind == "+attack" or bind == "+attack2" then
        --  > get car
        local car = get_car( ply )
        if not IsValid( car ) or not ( car:GetDriver() == ply ) then return end

        --  > get side and switch on desired side and off the other side
        local side = bind == "+attack2" and "right" or "left"
        local other_side = side == "right" and "left" or "right"

        if not switch_blinker_lights( car, nil, side ) then return end

        --  > get identifier and fuck off the other side
        local base_id = "GNCars:BlinkerLights"
        local id = base_id .. side .. car:EntIndex()
        if timer.Exists( id ) then 
            switch_blinker_lights( car, false, side )
            return timer.Remove( id ) 
        else 
            switch_blinker_lights( car, false, other_side )
            timer.Remove( base_id .. other_side .. car:EntIndex() ) 
        end
        
        --  > get to work the timer
        local toggled, last_ang_y = true, car:GetAngles().y
        timer.Create( id, .5, 0, function()
            --  > if car is fucked then stop
            if not IsValid( car ) then 
                timer.Remove( id )
                return 
            end

            --  > if you turn then stop
            local ang_y = car:GetAngles().y
            if math.abs( last_ang_y - ang_y ) > 80 then
                switch_blinker_lights( car, false, side )
                timer.Remove( id )
                return
            end

            --  > blink again
            switch_blinker_lights( car, nil, side )
            toggled = not toggled

            car:EmitSound( "gncars/blinker" .. ( toggled and "1" or "2" ) .. ".wav" )
        end )
    end
end )