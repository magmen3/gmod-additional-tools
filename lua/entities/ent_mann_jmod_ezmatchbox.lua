-- Mannytko 2025
AddCSLuaFile()
if not JMod or JMod == nil then
	error("invisible...")
	return
end

ENT.Type = "anim"
ENT.Author = "Mannytko"
ENT.Category = "JMod - EZ Misc."
ENT.PrintName = "EZ Match Box"
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.JModPreferredCarryAngles = Angle(-90, 0, 0)
ENT.DamageThreshold = 95
ENT.JModEZstorable = true
ENT.MatchesLeft = 5

if SERVER then
	function ENT:SpawnFunction(ply, tr)
		local SpawnPos = tr.HitPos + tr.HitNormal * 40
		local ent = ents.Create(self.ClassName)
		ent:SetAngles(angle_zero)
		ent:SetPos(SpawnPos)
		JMod.SetEZowner(ent, ply)
		ent:Spawn()
		ent:Activate()
		return ent
	end

	function ENT:Initialize()
		self:SetModel("models/weapons/w_firematch.mdl")
		self:SetModelScale(3.5, 0)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(true)
		self:SetUseType(SIMPLE_USE)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetMass(2)
			phys:Wake()
		end
	end

	function ENT:PhysicsCollide(data, physobj)
		if data.DeltaTime > 0.2 and data.Speed > 100 then
			self:EmitSound("Wood.ImpactSoft", 40)
		end
	end

	function ENT:OnTakeDamage(dmginfo)
		self:TakePhysicsDamage(dmginfo)
		if dmginfo:GetDamage() > self.DamageThreshold then
			local Pos = self:GetPos()
			sound.Play("Wood_Box.Break", Pos)
			self:Remove()
		end
	end

	function ENT:Use(activator)
		if JMod.IsAltUsing(activator) and self.MatchesLeft > 0 then
			if self.MatchesLeft <= 1 then
				SafeRemoveEntityDelayed(self, 15)
			end

			self.MatchesLeft = self.MatchesLeft - 1
			self:EmitSound("firematch_strike.wav")

			local match = ents.Create("ent_mann_jmod_ezmatch")
			match:SetAngles(angle_zero)
			match:SetPos(self:GetPos() + vector_up)
			JMod.SetEZowner(match, activator)
			match:Spawn()
			match:Activate()
			match:Light()
			activator:PickupObject(match)
		else
			activator:PickupObject(self)
		end
	end
elseif CLIENT then
	function ENT:Initialize()
	end

	function ENT:Draw()
		self:DrawModel()
	end

	language.Add("ent_jack_gmod_ezmatchbox", "EZ Match Box")
end