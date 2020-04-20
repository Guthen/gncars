local last_pressed = "no bind pressed"

hook.Add( "PlayerBindPress", "GNCars:BindTransmit", function( _, bind )
    last_pressed = bind

    net.Start( "GNCars:BindTransmit" )
        net.WriteString( bind )
    net.SendToServer()
end )

--[[ hook.Add( "HUDPaint", "GNCars:BindDebug", function()
    draw.WordBox( 10, 5, 5, last_pressed, "Trebuchet24", Color( 58, 58, 58, 150 ), color_white )
end ) ]]