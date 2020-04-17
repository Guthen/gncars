function GNCars.OpenCreatorMenu()
    local frame = GNLib.CreateFrame( "GNCars - Creator Menu", ScrW() * .4, ScrH() * .5 )

    local modelpanel = frame:Add( "DModelPanel" )
        modelpanel:Dock( LEFT )
        modelpanel:DockMargin( 5, 5, 5, 5 )
        modelpanel:InvalidateParent( true )
        modelpanel:SetWide( modelpanel:GetTall() )
        modelpanel:SetModel( "models/tdmcars/ast_db5.mdl" )
        modelpanel:SetCamPos( modelpanel:GetCamPos() + Vector( 0, 50, 0 ) )
        modelpanel.LayoutEntity = function() end
end
concommand.Add( "gncars_creatormenu", GNCars.OpenCreatorMenu )