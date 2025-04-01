-- Mannytko 2025
AddCSLuaFile()
if not JMod or JMod == nil then
	error("invisible...")
	return
end

ENT.Type = "anim"
ENT.Author = "Mannytko"
ENT.Category = "JMod - EZ Misc."
ENT.PrintName = "EZ Binoculars"
ENT.Information = "Binoculars that allow you to see farther."
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.JModPreferredCarryAngles = Angle(0, 90, 0)
ENT.DamageThreshold = 45
ENT.JModEZstorable = true

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
		self:SetModel("models/weapons/w_nvbinoculars.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(true)
		self:SetUseType(SIMPLE_USE)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetMass(15)
			phys:Wake()
		end
	end

	function ENT:PhysicsCollide(data, physobj)
		if data.DeltaTime > 0.2 and data.Speed > 100 then
			for i = 1, 2 do
				self:EmitSound("Grenade.ImpactHard")
			end
		end
	end

	function ENT:OnTakeDamage(dmginfo)
		self:TakePhysicsDamage(dmginfo)
		if dmginfo:GetDamage() > self.DamageThreshold then
			local Pos = self:GetPos()
			sound.Play("Metal_Box.Break", Pos)
			self:Remove()
		end
	end

	function ENT:Use(activator)
		if JMod.IsAltUsing(activator) then
			activator:PickupObject(self)
		elseif not activator:HasWeapon("wep_mann_jmod_ezbinoculars") then
			activator:Give("wep_mann_jmod_ezbinoculars")
			activator:SelectWeapon("wep_mann_jmod_ezbinoculars")
			activator:GetWeapon("wep_mann_jmod_ezbinoculars")
			self:Remove()
		else
			activator:PickupObject(self)
		end
	end

	function ENT:Think()
	end

	function ENT:OnRemove()
	end
elseif CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end

	language.Add("ent_mann_jmod_ezbinoculars", "EZ Binoculars")
end