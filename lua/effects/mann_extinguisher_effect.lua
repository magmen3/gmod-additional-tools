AddCSLuaFile()

function EFFECT:Init(data)
	self.Player = data:GetEntity()
	self.Origin = data:GetOrigin()
	self.Attachment = data:GetAttachment()
	self.Forward = data:GetNormal()
	self.Scale = data:GetScale()
	if not IsValid(self.Player) or not IsValid(self.Player:GetActiveWeapon()) then return end
	self.Angle = self.Forward:Angle()
	self.Position = self:GetTracerShootPos(self.Origin, self.Player:GetActiveWeapon(), self.Attachment)
	if self.Position == self.Origin then
		local att = self.Player:GetAttachment(self.Player:LookupAttachment("anim_attachment_RH"))
		if att then self.Position = att.Pos + att.Ang:Forward() * -2 end
	end

	local teh_effect = ParticleEmitter(self.Player:GetPos(), true)
	if not teh_effect then return end
	for i = 1, 6 * self.Scale do
		local particle = teh_effect:Add("effects/splash4", self.Position)
		if particle then
			local Spread = 0.1
			particle:SetVelocity((Vector(math.sin(math.Rand(0, 360)) * math.Rand(-Spread, Spread), math.cos(math.Rand(0, 360)) * math.Rand(-Spread, Spread), math.sin(math.random()) * math.Rand(-Spread, Spread) - 0.25) + self.Forward) * 400)
			local ang = self.Angle
			if i / 2 == math.floor(i / 2) then
				ang = (self.Forward * -1):Angle()
			end
			particle:SetAngles(ang)
			particle:SetDieTime(0.6)
			particle:SetColor(255, 255, 255)
			particle:SetStartAlpha(0)
			particle:SetEndAlpha(0)
			particle:SetStartSize(8)
			particle:SetEndSize(0)
			particle:SetCollide(1)
			particle:SetCollideCallback(function(particleC, HitPos, normal)
				particleC:SetAngleVelocity(angle_zero)
				particleC:SetVelocity(vector_origin)
				particleC:SetPos(HitPos + normal * 0.1)
				particleC:SetGravity(vector_origin)
				local angles = normal:Angle()
				angles:RotateAroundAxis(normal, particleC:GetAngles().y)
				particleC:SetAngles(angles)
				particleC:SetLifeTime(0)
				particleC:SetDieTime(16)
				particleC:SetStartSize(8)
				particleC:SetEndSize(0)
				particleC:SetStartAlpha(20)
				particleC:SetEndAlpha(0)
			end)
		end
	end

	teh_effect:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end