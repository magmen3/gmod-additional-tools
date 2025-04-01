-- Mannytko 2025
AddCSLuaFile()
if not JMod or JMod == nil then
	error("invisible...")
	return
end

ENT.Type = "anim"
ENT.Author = "Mannytko"
ENT.Category = "JMod - EZ Misc."
ENT.PrintName = "EZ Portable Radio"
ENT.Information = "A portable walkie-talkie that you can use to order things."
ENT.NoSitAllowed = true
ENT.Spawnable = true
ENT.JModPreferredCarryAngles = Angle(0, 90, 0)
ENT.DamageThreshold = 65
ENT.JModEZstorable = true
--ENT.MaxSupplies = 100
--[[function ENT:SetupDataTables() 
	self:NetworkVar("Float", 0, "Supplies") -- broken as fuck
end]]

if SERVER then
	function ENT:SpawnFunction(ply, tr)
		local SpawnPos = tr.HitPos + tr.HitNormal * 40
		local ent = ents.Create(self.ClassName)
		ent:SetAngles(angle_zero)
		ent:SetPos(SpawnPos)
		JMod.SetEZowner(ent, ply)
		--if JMod.Config.Machines.SpawnMachinesFull then ent.SpawnFull = true end
		ent:Spawn()
		ent:Activate()
		return ent
	end

	function ENT:Initialize()
		self:SetModel("models/radio/w_radio.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(true)
		self:SetUseType(SIMPLE_USE)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetMass(10)
			phys:Wake()
		end
		--self.MaxSupplies = 100
		--self:SetSupplies(self.MaxSupplies)
	end

	function ENT:PhysicsCollide(data, physobj)
		if data.DeltaTime > 0.2 and data.Speed > 100 then
			self:EmitSound("Plastic_Box.ImpactHard")
			self:EmitSound("Grenade.ImpactHard")
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
		elseif not activator:HasWeapon("wep_mann_jmod_ezradio") then
			activator:Give("wep_mann_jmod_ezradio")
			activator:SelectWeapon("wep_mann_jmod_ezradio")
			self:Remove()
			--[[self:SetMoveType(MOVETYPE_NONE) -- very hacky but idc
			self:SetSolid(SOLID_NONE)
			self:DrawShadow(false)
			self:SetNoDraw(true)]]
			--[[timer.Simple(0.25, function() -- wtf with that broken supply shit
				local Wep = activator:GetWeapon("wep_mann_jmod_ezradio")

				if IsValid(Wep) then
					Wep:SetSupplies(self:GetSupplies())
				end

				self:Remove()
			end)]]
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
		--[[local Opacity = math.random(50, 200)
		local SupplyFrac = self:GetSupplies() / self.MaxSupplies
		JMod.HoloGraphicDisplay(self, Vector(1.95, 3.4, 0.9), Angle(90, -90, 90), .012, 300, function()
			draw.SimpleTextOutlined("BATTERY "..math.Round(SupplyFrac * 100).."%","JMod-Display",0,-5,JMod.GoodBadColor(SupplyFrac, true, Opacity),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,3,Color(0,0,0,Opacity))
		end)]]
		JMod.HoloGraphicDisplay(self, Vector(1.95, 3.4, 0.89), Angle(90, -90, 90), .012, 1000, function() draw.RoundedBox(4, -116, -37, 236, 86, color_black) end)
	end

	language.Add("ent_mann_jmod_ezradio", "EZ Portable Radio")
end