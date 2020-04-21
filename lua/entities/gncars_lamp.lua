--  > derive from gmod_lamp : https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/entities/entities/gmod_lamp.lua
AddCSLuaFile()

ENT.Base = "gmod_lamp"

ENT.PrintName = "Lamp"

if SERVER then

    function ENT:Think()
        --self.BaseClass.Think( self )
    end

end

--  > code pasted and edited from gmod_lamp 
local sprite_mat, beam_mat = Material( "sprites/light_ignorez" ), Material( "effects/lamp_beam" )
local draw_beam, sprite_size_multiplicator, alpha_multiplicator = false, 2, .8
function ENT:DrawTranslucent()
	local LightNrm = self:GetAngles():Forward()
	local ViewNormal = self:GetPos() - EyePos()
	local Distance = ViewNormal:Length()
	ViewNormal:Normalize()
	local ViewDot = ViewNormal:Dot( LightNrm * -1 )
	local LightPos = self:GetPos() + LightNrm * 5

    local Col = self:GetColor()
    local dist = self:GetDistance()

    self.alpha_lerp = Lerp( FrameTime() * 10, self.alpha_lerp or 0, self:GetOn() and 1 or 0 )

    -- glow sprite
    if draw_beam then
        render.SetMaterial( beam_mat )
        
        local BeamDot = 0.25
        local beam_size = 64

        render.StartBeam( 3 )
            render.AddBeam( LightPos + LightNrm * 1 - self:GetForward() * 2, beam_size, 0.0, Color( Col.r, Col.g, Col.b, 64 * BeamDot * self.alpha_lerp * alpha_multiplicator ) )
            render.AddBeam( LightPos + LightNrm * dist / 10, beam_size, 0.5, Color( Col.r, Col.g, Col.b, 32 * BeamDot * self.alpha_lerp * alpha_multiplicator ) )
            render.AddBeam( LightPos + LightNrm * dist / 5, beam_size, 1, Color( Col.r, Col.g, Col.b, 0 ) )
        render.EndBeam()
    end
	
    --  > sprite drawing
	if ( ViewDot >= 0 ) then

		render.SetMaterial( sprite_mat )
		local Visible = util.PixelVisible( LightPos, 16, self.PixVis )

		if ( !Visible ) then return end

		local Size = math.Clamp( Distance * Visible * ViewDot * 2 * dist / 100 / 5, 64, 128 )

		Distance = math.Clamp( Distance, 32, 800 )
		local Alpha = math.Clamp( ( dist / 2 ) * Visible * ViewDot * self.alpha_lerp, 0, 100 * alpha_multiplicator )
		Col.a = Alpha

        --local sprite_size_multiplicator = sprite_size_multiplicator * Distance / 100 * 2
		render.DrawSprite( LightPos, Size * sprite_size_multiplicator, Size * sprite_size_multiplicator / 2, Col, Visible * ViewDot )
		render.DrawSprite( LightPos, Size * sprite_size_multiplicator * .4, Size * sprite_size_multiplicator * .4 / 2, Color( 255, 255, 255, Alpha ), Visible * ViewDot )

	end
end