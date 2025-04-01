-- Mannytko 2025
AddCSLuaFile()
if not JMod or JMod == nil then
	error("invisible...")
	return
end

ENT.Type = "anim"
ENT.Author = "Mannytko"
ENT.Category = "JMod - EZ Misc."
ENT.PrintName = "EZ Match"
ENT.NoSitAllowed = true
ENT.Spawnable = false
ENT.JModEZstorable = false
ENT.JModPreferredCarryAngles = angle_zero

local STATE_OFF, STATE_BURNIN, STATE_BURNT = 0, 1, 2

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "State")
	self:NetworkVar("Int", 1, "Fuel")
end

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
		self:SetModel("models/weapons/matchhead.mdl")
		self:SetModelScale(0.5, 0)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(true)
		self:SetUseType(SIMPLE_USE)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetMass(1)
			phys:Wake()
		end
		self:SetFuel(150)
	end

	function ENT:PhysicsCollide(data, physobj)
		if data.DeltaTime > 0.2 and data.Speed > 45 then
			self:EmitSound("Wood.ImpactSoft", 30)

			if self:GetState() == STATE_BURNIN then
				local Dmg = DamageInfo()
				Dmg:SetDamageType(DMG_BURN)
				Dmg:SetAttacker(JMod.GetEZowner(self))
				Dmg:SetInflictor(self)
				Dmg:SetDamage(1)
				Dmg:SetDamagePosition(self:GetPos())
				Dmg:SetDamageForce(vector_up)

				if data.HitEntity.TakeDamageInfo then
					data.HitEntity:TakeDamageInfo(Dmg)
				end
			end
		end
	end

	function ENT:OnTakeDamage(dmginfo)
		self:TakePhysicsDamage(dmginfo)

		if JMod.LinCh(dmginfo:GetDamage(), 1, 5) then
			if dmginfo:IsDamageType(DMG_BURN) then
				self:Light()
			else
				self:Remove()
			end
		end
	end

	function ENT:Use(activator)
		activator:PickupObject(self)
	end

	function ENT:Light()
		if self:GetState() == STATE_BURNT then return end
		self:SetState(STATE_BURNIN)
		self.BurnSound = CreateSound(self, "snds_jack_gmod/flareburn.wav")
		self.BurnSound:Play()
		self.BurnSound:ChangeVolume(0.5, 0.1)
	end

	function ENT:Burnout()
		if self:GetState() == STATE_BURNT then return end
		self:SetState(STATE_BURNT)
		self.BurnSound:Stop()
		self:SetMaterial("models/rogue_cheney/cannon/cannon_match_burned")
		SafeRemoveEntityDelayed(self, 10)
	end

	function ENT:Think()
		if self:GetState() == STATE_BURNT then return end
		local State, Fuel, Time, Pos = self:GetState(), self:GetFuel(), CurTime(), self:GetPos()

		if State == STATE_BURNIN then
			if not self.BurnMatApplied and (Fuel < 20) then
				self.BurnMatApplied = true
				self:SetMaterial("models/rogue_cheney/cannon/cannon_match_burned")
			end

			for k, v in ipairs(ents.FindInSphere(Pos, 30)) do
				if v.JModHighlyFlammableFunc then
					JMod.SetEZowner(v, self.EZowner)
					local Func = v[v.JModHighlyFlammableFunc]
					Func(v)
				end
			end

			if Fuel <= 0 then
				self:Burnout()

				return
			end

			self:SetFuel(Fuel - 1)
			self:NextThink(Time + .1)

			return true
		end
	end

	function ENT:OnRemove()
		if self.BurnSound then
			self.BurnSound:Stop()
		end
	end
elseif CLIENT then
	local col = Color(255,195,84)
	function ENT:Think()
		local State, Fuel, Pos, Ang = self:GetState(), self:GetFuel(), self:GetPos(), self:GetAngles()

		if State == STATE_BURNIN then
			local Up, Mult = Ang:Up(), (Fuel > 10 and .5) or .3
			local R, G, B = math.Clamp(col.r + 20, 0, 255), math.Clamp(col.g + 20, 0, 255), math.Clamp(col.b + 20, 0, 255)
			local DLight = DynamicLight(self:EntIndex())

			if DLight then
				DLight.Pos = Pos + Up * -5 + Vector(0, 0, 20)
				DLight.r = R
				DLight.g = G
				DLight.b = B
				DLight.Brightness = math.Rand(.4, 1) * Mult ^ 2
				DLight.Size = math.random(100, 200) * Mult ^ 2
				DLight.Decay = 15000
				DLight.DieTime = CurTime() + .3
				DLight.Style = 0
			end
		end
	end

	local GlowSprite = Material("sprites/mat_jack_basicglow")
	function ENT:Draw()
		self:DrawModel()
		local State, Fuel, Pos, Ang = self:GetState(), self:GetFuel(), self:GetPos(), self:GetAngles()
		local Up, Mult = Ang:Up(), (Fuel > 50 and .3) or .1

		if State == STATE_BURNIN then
			render.SetMaterial(GlowSprite)

			for i = 1, 10 do
				render.DrawSprite(Pos + Up * (2 + i) * Mult + VectorRand(), 10 * Mult - i, 10 * Mult - i, Color(255, 188, 63, math.random(100, 200)))
			end
		end
	end

	language.Add("ent_mann_jmod_ezmatch", "EZ Match")
end