local jeep_seat_model = "models/nova/jeep_seat.mdl"
local lamp_model = "models/maxofs2d/lamp_flashlight.mdl"

local elements = {
    "Actions",
    {
        type = "Button",
        text = "Export JSON",
        action = function( form )
            local vehicle = {}

            vehicle.seats = {}
            for i, v in ipairs( form.entities ) do
                local obj = {}
                table.Add( obj, { v:GetPos():Unpack() } )
                table.Add( obj, { v:GetAngles():Unpack() } )

                local name = v.PartType .. "s"
                vehicle[name][#vehicle[name] + 1] = obj
            end

            print( util.TableToJSON( { [form.vehicle:GetVehicleClass()] = vehicle }, true ) )
        end
    },
} 

local function add_ent_elements( name, model, angles )
    local els = {
        name:sub( 1, 1 ):upper() .. name:sub( 2, #name ) .. "s",
        {
            type = "Button",
            text = "Add " .. name,
            action = function( form, modelpanel )
                local ent = ClientsideModel( model )
                    ent:SetNoDraw( true )
                    ent:SetAngles( modelpanel.Entity:GetAngles() )
                    ent.PartType = name

                --  > combobox
                local combobox = form.elements[name .. "_combo_box"]
                combobox:AddChoice( name:sub( 1, 1 ):upper() .. name:sub( 2, #name ) .. " #" .. #combobox.choices + 1, ent, true )
                combobox:CloseMenu()

                local choice = combobox.choices[#combobox.choices]
                combobox:OnSelect( #combobox.choices, choice.value, choice.data )

                --  > set pos to the selected choice
                local last_ent = combobox:GetSelected() and combobox:GetSelected().data
                if IsValid( last_ent ) then
                    ent:SetPos( last_ent:GetPos() )
                end

                form.entities[#form.entities + 1] = ent
            end
        },
        {
            type = "Button",
            text = "Remove " .. name,
            action = function( form, modelpanel )
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

                local sliders = form.elements[name .. "_vector"]
                local pos = form[name]:GetPos()

                sliders.x:SetValue( pos.x )
                sliders.y:SetValue( pos.y )
                sliders.z:SetValue( pos.z )
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
end
add_ent_elements( "seat", jeep_seat_model, true )
add_ent_elements( "lamp", lamp_model, true )

function GNCars.OpenCreatorMenu()
    local form = { elements = {}, entities = {} }

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

        chat.AddText( GNLib.Colors.Alizarin, "GNCars: ", GNLib.Colors.Clouds, "Please go in a vehicle before opening this panel." )
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
            ent:SetMaterial( "models/wireframe" )
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
        local label = optionlist:Add( "DLabel" )
            label:Dock( TOP )
            label:DockMargin( 10, 10, 0, 0 )
            label:SetText( text )
            label:SetFont( "GNLFontB15" )
            label:SetColor( GNLib.Colors.Clouds )
            label:SizeToContents()

        return label
    end

    for i, v in ipairs( elements ) do
        if isstring( v ) then 
            add_label( v ) 
        else
            local element
            if v.type == "Button" then
                local button = optionlist:Add( "GNButton" )
                    button:Dock( TOP )
                    button:DockMargin( 15, 2, 20, 0 )
                    button:SetText( v.text )
                    button.DoClick = function()
                        if v.action then v.action( form, modelpanel, optionlist ) end
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
            elseif v.type == "Vector" then
                element = {}

                if v.text then
                    add_label( v.text )
                end

                local vector = Vector()
                for i = 1, 3 do
                    local axis = i == 1 and "x" or i == 2 and "y" or "z"

                    local numslider = optionlist:Add( "DNumSlider" )
                        numslider:Dock( TOP )
                        numslider:DockMargin( 15, 0, 5, 0 )
                        --numslider:SetWide( optionlist:GetWide() )
                        numslider:SetMinMax( -100, 100 )
                        numslider:SetValue( 0 )
                        numslider:SetText( axis )
                        numslider.OnValueChanged = function( self, value )
                            vector[axis] = value
                            v.action( form, vector )
                        end

                    element[axis] = numslider
                end
            elseif v.type == "Angle" then
                element = {}

                if v.text then
                    add_label( v.text )
                end

                local angle = Angle()
                for i = 1, 3 do
                    local axis = i == 1 and "p" or i == 2 and "y" or "r"

                    local numslider = optionlist:Add( "DNumSlider" )
                        numslider:Dock( TOP )
                        numslider:DockMargin( 15, 0, 5, 0 )
                        --numslider:SetWide( optionlist:GetWide() )
                        numslider:SetMinMax( -360, 360 )
                        numslider:SetValue( 0 )
                        numslider:SetText( axis )
                        numslider.OnValueChanged = function( self, value )
                            angle[axis] = value
                            v.action( form, angle )
                        end

                    element[axis] = numslider
                end
            end

            if element and v.id then
                form.elements[v.id] = element 
            end
        end
    end

    --  > load
    local config = GNCars.Vehicles[vehicle:GetVehicleClass()]
    if config then
        local seats = {}

        for i, v in ipairs( config.seats ) do
            local ent = ClientsideModel( jeep_seat_model )
                ent:SetNoDraw( true )
                ent:SetPos( v )

            form.elements.seat_combo_box:AddChoice( "Seat #" .. i, ent )
            seats[i] = ent
        end

        table.Add( form.entities, seats ) 
    end
end
concommand.Add( "gncars_creatormenu", GNCars.OpenCreatorMenu )