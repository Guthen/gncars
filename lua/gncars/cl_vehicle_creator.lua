local jeep_seat_model = "models/nova/jeep_seat.mdl"
local lamp_model = "models/maxofs2d/lamp_flashlight.mdl"

local function notify( ... )
    chat.AddText( GNLib.Colors.Alizarin, "GNCars: ", GNLib.Colors.Clouds, ... )
end

local function create_config_entity( model, part, pos, ang )
    local ent = ClientsideModel( model )
        ent:SetNoDraw( true )
        ent:SetPos( pos or Vector() )
        ent:SetAngles( ang or Angle() )
        ent.PartType = part
        ent.config = {}

    return ent
end

local function get_tbl( form )
    local vehicle = {}

    --  > create config
    for i, v in ipairs( form.entities ) do
        local name = v.PartType .. "s"
        if not vehicle[name] then vehicle[name] = {} end

        local obj = {
            pos = { v:GetPos():Unpack() },
            ang = { v:GetAngles():Unpack() },
            --is_back_light = v.IsBackLight,
            --brightness = v.Brightness,
        }

        for k, v in pairs( v.config ) do
            obj[k] = v
        end

        vehicle[name][#vehicle[name] + 1] = obj
    end
    if table.Count( vehicle ) <= 0 then return notify( "Please finish the config before trying to export it." ) end

    return { [form.vehicle:GetVehicleClass()] = vehicle }
end

local function get_json( form, prettify, should_print )
    --  > json
    local json = util.TableToJSON( get_tbl( form ), prettify == nil and true or prettify )
    if should_print then print( json ) end

    return json
end

local elements = {
    "Options",
    {
        type = "Toggle",
        text = "Wireframe",
        action = function( form, toggle )
            form.wireframe = toggle
        end,
    },
    "Actions",
    {
        type = "Button",
        text = "Export JSON",
        color = GNLib.Colors.PeterRiver,
        action = get_json,
    },
    {
        type = "Button",
        text = "Save Vehicle",
        color = GNLib.Colors.PeterRiver,
        action = function( form )
            if not LocalPlayer():IsSuperAdmin() then notify( "You must be an admin to save custom vehicles on the server." ) end

            local tbl = get_tbl( form, false )
            if not tbl then return end

            GNLib.DermaMessage( "GNCars - Save", "This option save the vehicle in your data folder and overwrite the global vehicle configuration (if exists). Are you sure to save this vehicle?", "Yes", function( affirmative )
                if not affirmative then return end

                net.Start( "GNCars:Data" )
                    net.WriteTable( tbl )
                net.SendToServer()
            end, "No" )
        end,
    },
    {
        type = "Button",
        text = "Suggest Vehicle",
        color = GNLib.Colors.Amethyst,
        action = function( form, modelpanel )
            local json = get_json( form, false )
            if not json then return end

            GNLib.DermaMessage( "GNCars - Suggestion", "We are going to take a screenshot of your vehicle configuration, please be sure that you have a good view of the vehicle and its elements (seats, lamps, etc.). Are you sure about that?", "Yes", function( affirmative )
                if not affirmative then return end

                local x, y, w, h = GNLib.GetPanelAbsoluteBounds( modelpanel )
                local wireframe = form.wireframe
                form.wireframe = true

                hook.Add( "PostRender", "GNCars:Screenshot", function() 
                    local data = render.Capture( {
                        format = "jpeg",
                        quality = 70,
                        x = x,
                        y = y,
                        w = w,
                        h = h,
                    } )

                    http.Post( "http://gnlib.wizzarheberg.fr/gncars/vehicles/add.php", { json = json, img = util.Base64Encode( data ), owner = LocalPlayer():SteamID() }, function( body, len, headers, code )
                        notify( ( "Response (HTTP/%d): %s" ):format( code, body ) )
                    end )

                    form.wireframe = wireframe
                    hook.Remove( "PostRender", "GNCars:Screenshot" )
                end )
            end, "No" )
        end
    },
} 

local function add_ent_elements( name, model, angles, new_elements )
    local els = {
        "-",
        name:sub( 1, 1 ):upper() .. name:sub( 2, #name ) .. "s",
        {
            type = "Button",
            text = "Add " .. name,
            color = GNLib.Colors.PeterRiver,
            action = function( form, modelpanel )
                local ent = create_config_entity( model, name, nil, modelpanel.Entity:GetAngles() )

                --  > combobox
                local combobox = form.elements[name .. "_combo_box"]

                --  > set pos to the selected choice
                local last_ent = combobox:GetSelected() and combobox:GetSelected().data
                if IsValid( last_ent ) then
                    ent:SetPos( last_ent:GetPos() )
                    ent:SetAngles( last_ent:GetAngles() )
                end

                --  > combobox choice
                combobox:AddChoice( name:sub( 1, 1 ):upper() .. name:sub( 2, #name ) .. " #" .. #combobox.choices + 1, ent, true )
                combobox:CloseMenu()

                local choice = combobox.choices[#combobox.choices]
                combobox:OnSelect( #combobox.choices, choice.value, choice.data )

                --  > add to entities
                form.entities[#form.entities + 1] = ent
            end
        },
        {
            type = "Button",
            text = "Remove " .. name,
            color = GNLib.Colors.Alizarin,
            action = function( form, modelpanel )
                if not form[name] then return end
                form[name]:Remove()

                --  > combobox
                local combobox = form.elements[name .. "_combo_box"]
                combobox.choices[combobox.selected] = nil
                combobox:CloseMenu()
            end
        },
        {
            type = "ComboBox",
            id = name .. "_combo_box",
            text = "Current " .. name,
            action = function( form, value, data )
                form[name] = data

                --  > position
                local sliders = form.elements[name .. "_vector"]
                local pos = form[name]:GetPos()

                sliders.x:SetValue( pos.x )
                sliders.y:SetValue( pos.y )
                sliders.z:SetValue( pos.z )

                --  > angle
                if angles then
                    local sliders = form.elements[name .. "_angle"]
                    local ang = form[name]:GetAngles()

                    sliders.p:SetValue( ang.p )
                    sliders.y:SetValue( ang.y )
                    sliders.r:SetValue( ang.r )
                end

                --  > custom
                if name == "lamp" then
                    form.elements.toggle_secondary_light:SetToggle( form[name].config.IsSecondaryLight )
                    form.elements.toggle_back_light:SetToggle( form[name].config.IsBackLight )
                    --form.elements.brightness_lamp:SetValue( form[name].Brightness or form[name].IsBackLight and .1 or .2 )
                    form.elements.toggle_blinker_left:SetToggle( form[name].config.BlinkerType == "left" )
                    form.elements.toggle_blinker_right:SetToggle( form[name].config.BlinkerType == "right" )
                end
            end,
        },
        {
            type = "Vector",
            id = name .. "_vector",
            text = "Position",
            action = function( form, vector )
                if not form[name] then return end

                form[name]:SetPos( vector )
            end,
        },
        angles and {
            type = "Angle",
            id = name .. "_angle",
            text = "Angles",
            action = function( form, angles )
                if not form[name] then return end

                form[name]:SetAngles( angles )
            end,
        },
    }

    table.Add( elements, els )
    if new_elements then table.Add( elements, new_elements( name ) ) end
end
add_ent_elements( "seat", jeep_seat_model, true )
add_ent_elements( "lamp", lamp_model, true, function( name ) return {
        {
            type = "Toggle",
            id = "toggle_secondary_light",
            text = "Secondary light",
            action = function( form, toggle )
                if not form[name] then return end

                form[name].config.IsSecondaryLight = toggle or nil

                --  > turn off other settings
                if toggle then
                    form.elements.toggle_back_light:SetToggle( false )
                    form.elements.toggle_blinker_left:SetToggle( false )
                    form.elements.toggle_blinker_right:SetToggle( false )
                end
            end,
        },
        {
            type = "Toggle",
            id = "toggle_back_light",
            text = "Back light",
            action = function( form, toggle )
                if not form[name] then return end

                form[name].config.IsBackLight = toggle or nil

                --  > turn off other settings
                if toggle then
                    form.elements.toggle_secondary_light:SetToggle( false )
                    form.elements.toggle_blinker_left:SetToggle( false )
                    form.elements.toggle_blinker_right:SetToggle( false )
                end
            end,
        },
        {
            type = "Toggle",
            id = "toggle_blinker_right",
            text = "Blinker Right",
            action = function( form, toggle )
                if not form[name] then return end

                --  > set type
                form[name].config.BlinkerType = toggle and "right" or nil

                --  > turn off the other if activated
                local other_toggle = form.elements.toggle_blinker_left
                if toggle and other_toggle then
                    other_toggle:SetToggle( false )
                elseif toggle then
                    other_toggle:SetToggle( true )
                end

                --  > turn off other settings
                if toggle then
                    form.elements.toggle_secondary_light:SetToggle( false )
                    form.elements.toggle_back_light:SetToggle( false )
                end
            end,
        },
        {
            type = "Toggle",
            id = "toggle_blinker_left",
            text = "Blinker Left",
            action = function( form, toggle )
                if not form[name] then return end

                --  > set type
                form[name].config.BlinkerType = toggle and "left" or nil
                
                --  > turn off the other if activated
                local other_toggle = form.elements.toggle_blinker_right
                if toggle and other_toggle then
                    other_toggle:SetToggle( false )
                elseif toggle then
                    other_toggle:SetToggle( true )
                end

                --  > turn off back light
                if toggle then
                    form.elements.toggle_secondary_light:SetToggle( false )
                    form.elements.toggle_back_light:SetToggle( false )
                end
            end,
        },
        --[[ {
            type = "Int",
            id = "brightness_lamp",
            text = "Brightness",
            bounds = { 0, .2 },
            value = .2,
            action = function( form, value )
                if not form[name] then return end

                form[name].Brightness = value
            end
        }, ]]
    }
end )

function GNCars.OpenCreatorMenu()
    local form = { elements = {}, entities = {}, wireframe = false }

    --  > frame
    local frame = GNLib.CreateFrame( "GNCars - Creator Menu", ScrW() * .4, ScrH() * .5 )
        frame.OnRemove = function()
            for i, v in ipairs( form.entities ) do v:Remove() end
        end
    form.elements.frame = frame

    --  > vehicle
    local vehicle = LocalPlayer():GetVehicle()
    if IsValid( vehicle ) and IsValid( vehicle:GetParent() ) then vehicle = vehicle:GetParent() end
    if not IsValid( vehicle ) then 
        frame:Remove()

        notify( "Please go in a vehicle before opening this panel." )
        return 
    end
    form.vehicle = vehicle

    --  > elements
    local modelpanel = frame:Add( "DAdjustableModelPanel" )
        modelpanel:Dock( LEFT )
        modelpanel:DockMargin( 5, 5, 5, 5 )
        modelpanel:InvalidateParent( true )
        modelpanel:SetWide( modelpanel:GetTall() )
        modelpanel:SetModel( vehicle:GetModel() )
        modelpanel:SetFirstPerson( true )
        modelpanel:SetCamPos( modelpanel:GetCamPos() + Vector( 100, 100, 25 ) )
        modelpanel.LayoutEntity = function( self, ent )
            if form.wireframe then 
                ent:SetMaterial( "models/wireframe" )
            else
                ent:SetMaterial( "" )
            end
        end
        modelpanel.PreDrawModel = function( self, ent )
            for i, v in ipairs( form.entities ) do
                if not IsValid( v ) then v:Remove() table.remove( form.entities, i ) continue end
                v:DrawModel()
            end
        end

    local optionlist = frame:Add( "DScrollPanel" )
        optionlist:Dock( LEFT )
        optionlist:SetWide( frame:GetWide() - modelpanel:GetWide() )
        optionlist.Paint = function( self, w, h )
            draw.RoundedBox( 0, 0, h * .01, 1, h - h * .01 * 2, frame.header.color )
        end
        optionlist:GetVBar():SetWide( 0 )

    local function add_label( text, parent )
        local label = ( parent or optionlist ):Add( "DLabel" )
            label:Dock( TOP )
            label:DockMargin( 10, 5, 0, 0 )
            label:SetText( text )
            label:SetFont( "GNLFontB15" )
            label:SetColor( GNLib.Colors.Clouds )
            label:SizeToContents()

        return label
    end

    --  > get bounds for pos sliders
    local max_slider_value = 100
    do 
        local min_bounds, max_bounds = vehicle:GetModelBounds()
        for i, v in ipairs( { unpack( { min_bounds:Unpack() } ), unpack( { max_bounds:Unpack() } ) } ) do
            if max_slider_value < math.abs( v ) then max_slider_value = math.abs( v ) end
        end
    end

    --  > show elements
    for i, v in ipairs( elements ) do
        if isstring( v ) then
            if v == "-" then
                local separator = optionlist:Add( "DPanel" )
                    separator:Dock( TOP )
                    separator:DockMargin( 5, 12, 15, 2 )
                    separator:SetTall( 1 )
                    separator.Paint = function( self, w, h )
                        draw.RoundedBox( 0, 0, 0, w, h, frame.header.color )
                    end
            else
                add_label( v ) 
            end
        else
            local element
            if v.type == "Button" then
                local button = optionlist:Add( "GNButton" )
                    button:Dock( TOP )
                    button:DockMargin( 15, 2, 20, 0 )
                    button:SetText( v.text )
                    button:SetTextColor( GNLib.Colors.Clouds )
                    button:SetHoveredTextColor( GNLib.Colors.Silver )
                    button.DoClick = function()
                        if v.action then v.action( form, modelpanel, optionlist ) end
                    end

                    if v.color then 
                        button:SetColor( v.color ) 
                        button:SetHoveredColor( ColorAlpha( v.color, 160 ) )
                    end

                element = button
            elseif v.type == "ComboBox" then
                local combobox = optionlist:Add( "GNComboBox" )
                    combobox:Dock( TOP )
                    combobox:DockMargin( 15, 10, 20, 5 )
                    combobox:SetValue( v.text )
                    combobox.OnSelect = function( self, id, value, data )
                        v.action( form, value, data )
                    end

                element = combobox
            elseif v.type == "Toggle" then
                local container = optionlist:Add( "DPanel" )
                    container:Dock( TOP )
                    container:DockMargin( 15, 2, 20, 2 )
                    container.Paint = function() end

                local label = add_label( v.text, container )
                    label:Dock( LEFT )
                    label:DockMargin( 0, 0, 0, 0 )
                    label:SetFont( "GNLFont12" )

                local toggle = container:Add( "GNToggleButton" )      
                    toggle:Dock( LEFT )
                    toggle.OnToggle = function( self, toggle )
                        v.action( form, toggle )
                    end
                    
                element = toggle
            elseif v.type == "Vector" then
                element = {}

                if v.text then
                    add_label( v.text ):SetFont( "GNLFontB13" )
                end

                local vector = Vector()
                for i = 1, 3 do
                    local axis = i == 1 and "x" or i == 2 and "y" or "z"

                    local numslider = optionlist:Add( "DNumSlider" )
                        numslider:Dock( TOP )
                        numslider:DockMargin( 15, 0, 5, 0 )
                        numslider:SetMinMax( -max_slider_value, max_slider_value )
                        numslider:SetValue( 0 )
                        numslider:SetText( axis )
                        numslider.Label:SetFont( "GNLFont12" )
                        numslider.OnValueChanged = function( self, value )
                            vector[axis] = value
                            v.action( form, vector )
                        end

                    element[axis] = numslider
                end
            elseif v.type == "Angle" then
                element = {}

                if v.text then
                    add_label( v.text ):SetFont( "GNLFontB13" )
                end

                local angle = Angle()
                for i = 1, 3 do
                    local axis = i == 1 and "p" or i == 2 and "y" or "r"

                    local numslider = optionlist:Add( "DNumSlider" )
                        numslider:Dock( TOP )
                        numslider:DockMargin( 15, 0, 5, 0 )
                        numslider:SetMinMax( -360, 360 )
                        numslider:SetValue( 0 )
                        numslider:SetText( axis )
                        numslider.Label:SetFont( "GNLFont12" )
                        numslider.OnValueChanged = function( self, value )
                            angle[axis] = value
                            v.action( form, angle )
                        end

                    element[axis] = numslider
                end
            elseif v.type == "Int" then
                local numslider = optionlist:Add( "DNumSlider" )
                    numslider:Dock( TOP )
                    numslider:DockMargin( 15, 0, 5, 0 )
                    numslider:SetMinMax( -v.bounds[1], v.bounds[2] )
                    numslider:SetValue( v.value or 0 )
                    numslider:SetText( v.text )
                    numslider.Label:SetFont( "GNLFont12" )
                    numslider.OnValueChanged = function( self, value )
                        v.action( form, value )
                    end

                element = numslider
            end

            if element and v.id then
                form.elements[v.id] = element 
            end
        end
    end

    --  > load
    local config = GNCars.Vehicles[vehicle:GetVehicleClass()]
    if config then
        for k, conf in pairs( config ) do
            if not istable( conf ) then continue end

            local vehicles_ents = {}

            for i, v in ipairs( conf ) do
                local part = k:sub( 1, #k - 1 )

                --  > create entity
                local ent = create_config_entity( part == "lamp" and lamp_model or jeep_seat_model, part, v.pos, v.ang )
                
                --  > set config keys
                for key, value in pairs( v ) do
                    if key == "pos" or key == "ang" then continue end
                    ent.config[key] = value
                end

                form.elements[ent.PartType .. "_combo_box"]:AddChoice( k:sub( 1, 1 ):upper() .. k:sub( 2 ) .. " #" .. i, ent )
                vehicles_ents[i] = ent
            end
    
            table.Add( form.entities, vehicles_ents ) 
        end
    end
end
concommand.Add( "gncars_creatormenu", GNCars.OpenCreatorMenu )