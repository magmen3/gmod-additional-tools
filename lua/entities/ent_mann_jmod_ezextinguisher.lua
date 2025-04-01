-- Mannytko 2025
AddCSLuaFile()
if not JMod or JMod == nil then
	error("invisible...")
	return
end

ENT.Type = "anim"
ENT.Author = "Mannytko"
ENT.Category = "JMod - EZ Misc."
ENT.PrintName = "EZ Fire Extinguisher"
ENT.Information = "A portable fire extinguisher that consumes gas with water, handles napalm well."
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.JModPreferredCarryAngles = Angle(0, -90, 0)
ENT.DamageThreshold = 65
ENT.JModEZstorable = true
ENT.MaxGas = 100
ENT.MaxWater = 100
ENT.SWEP = "wep_mann_jmod_ezextinguisher"

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Gas")
	self:NetworkVar("Int", 0, "Water")
end

if SERVER then
	function ENT:SpawnFunction(ply, tr)
		local SpawnPos = tr.HitPos + tr.HitNormal * 40
		local ent = ents.Create(self.ClassName)
		ent:SetAngles(angle_zero)
		ent:SetPos(SpawnPos)
		JMod.SetEZowner(ent, ply)
		if JMod.Config.Machines.SpawnMachinesFull then ent.SpawnFull = true end
		ent:Spawn()
		ent:Activate()
		return ent
	end

	function ENT:Initialize()
		self:SetModel("models/weapons/w_fire_extinguisher.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(true)
		self:SetUseType(SIMPLE_USE)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetMass(60)
			phys:Wake()
		end

		if self.SpawnFull then
			self:SetGas(self.MaxGas)
			self:SetWater(self.MaxWater)
		end
	end

	function ENT:PhysicsCollide(data, physobj)
		if data.DeltaTime > 0.2 and data.Speed > 100 then
			self:EmitSound("SolidMetal.ImpactSoft")
			self:EmitSound("Canister.ImpactHard")
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
		elseif not activator:HasWeapon(self.SWEP) then
			activator:Give(self.SWEP)
			activator:SelectWeapon(self.SWEP)

			timer.Simple(0, function()
				local Wep = activator:GetWeapon(self.SWEP)

				if IsValid(Wep) then
					Wep:SetEZsupplies(JMod.EZ_RESOURCE_TYPES.GAS, self:GetGas())
					Wep:SetEZsupplies(JMod.EZ_RESOURCE_TYPES.WATER, self:GetWater())
				end

				self:Remove()
			end)
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

	language.Add("ent_mann_jmod_ezextinguisher", "EZ Fire Extinguisher")
end