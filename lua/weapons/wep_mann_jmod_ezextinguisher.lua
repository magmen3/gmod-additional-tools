-- Mannytko 2025
AddCSLuaFile()
AddCSLuaFile("effects/mann_extinguisher_effect.lua")
if not JMod or JMod == nil then
	error("invisible...")
	return
end

SWEP.PrintName = "EZ Fire Extinguisher"
SWEP.Author = "Mannytko"
SWEP.Purpose = "A portable fire extinguisher that consumes gas with water, handles napalm well."
JMod.SetWepSelectIcon(SWEP, "entities/ent_mann_jmod_ezextinguisher", true)
SWEP.Spawnable = false
SWEP.UseHands = true
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.EZdroppable = true
SWEP.ViewModel = "models/weapons/c_fire_extinguisher.mdl"
SWEP.WorldModel = "models/weapons/w_fire_extinguisher.mdl"
--[[SWEP.BodyHolsterModel = "models/weapons/w_fire_extinguisher.mdl"
SWEP.BodyHolsterSlot = "back"
SWEP.BodyHolsterAng = Angle(-70, 0, 200)
SWEP.BodyHolsterAngL = Angle(-70, 0, 200)
SWEP.BodyHolsterPos = Vector(0, -15, 10)
SWEP.BodyHolsterPosL = Vector(0, -15, 10)
SWEP.BodyHolsterScale = 1]]
SWEP.ViewModelFOV = 55
SWEP.Slot = 4
SWEP.SlotPos = 3
SWEP.InstantPickup = true -- Fort Fights compatibility
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.EZconsumes = {JMod.EZ_RESOURCE_TYPES.GAS, JMod.EZ_RESOURCE_TYPES.WATER}
SWEP.MaxGas = 100
SWEP.MaxWater = 100
SWEP.NextExtinguish = 0
SWEP.NextSparkTime = 0

local STATE_NOTHIN, STATE_SPRAYIN = 0, 1
function SWEP:Initialize()
	self:SetHoldType("slam")
	self.NextIdle = 0
	self:Deploy()
	self:SetGas(0)
	self:SetWater(0)
end

local Downness, Backness = 0, 0
function SWEP:GetViewModelPosition(pos, ang)
	local owner = self:GetOwner()

	local FT = FrameTime()
	if IsValid(owner) and (owner:IsSprinting() or owner:KeyDown(IN_ZOOM)) then
		Downness = Lerp(FT * 2, Downness, 10)
	else
		Downness = Lerp(FT * 2, Downness, -0.5)
	end

	local Flamin = self:GetState() == STATE_SPRAYIN
	if Flamin then
		Backness = Lerp(FT * 2, Backness, 8)
	else
		Backness = Lerp(FT * 2, Backness, 0)
	end

	ang:RotateAroundAxis(ang:Right(), -Downness * 5)
	pos = pos - ang:Forward() * Backness
	if Flamin then pos = pos + VectorRand() * .05 end
	return pos, ang
end

function SWEP:SetupDataTables()
	self:NetworkVar("Int", 1, "Gas")
	self:NetworkVar("Int", 2, "Water")
	self:NetworkVar("Int", 3, "State")
end

function SWEP:UpdateNextIdle()
	local owner = self:GetOwner()

	if not owner:IsPlayer() then return end
	local vm = owner:GetViewModel()
	self.NextIdle = CurTime() + vm:SequenceDuration()
end

function SWEP:GetEZsupplies(resourceType)
	local AvailableResources = {
		[JMod.EZ_RESOURCE_TYPES.GAS] = self:GetGas(),
		[JMod.EZ_RESOURCE_TYPES.WATER] = self:GetWater()
	}

	if resourceType then
		if AvailableResources[resourceType] and AvailableResources[resourceType] > 0 then
			return AvailableResources[resourceType]
		else
			return nil
		end
	else
		return AvailableResources
	end
end

function SWEP:SetEZsupplies(typ, amt, setter)
	if not SERVER then return end
	local ResourceSetMethod = self["Set" .. JMod.EZ_RESOURCE_TYPE_METHODS[typ]]
	if ResourceSetMethod then ResourceSetMethod(self, amt) end
end

function SWEP:Cease()
	self:SetState(STATE_NOTHIN)
	if self.SoundLoop then self.SoundLoop:Stop() end
end

function SWEP:GetNozzle()
	local Owner = self:GetOwner()
	local AimVec = Owner:GetAimVector()
	local ShootPos = Owner:GetShootPos()
	local FirePos, FireAng
	--
	if CLIENT then
		FireAng = Owner:EyeAngles()
		local FireUp, FireRight, FireForward = FireAng:Up(), FireAng:Right(), FireAng:Forward()
		if not Owner:ShouldDrawLocalPlayer() then
			FirePos = ShootPos + (FireForward * 20 + FireRight * 4 + FireUp * -5)
		else
			FirePos = ShootPos + (FireForward * 40 + FireRight * 8 + FireUp * -15)
		end
	elseif SERVER then
		FireAng = AimVec:Angle()
		local FireUp, FireRight, FireForward = FireAng:Up(), FireAng:Right(), FireAng:Forward()
		--FireAng:RotateAroundAxis(FireAng:Right(), 5)
		FirePos = ShootPos + (FireForward * 15 + FireRight * 7 + FireUp * -8)
	end

	local SafetyTr = util.QuickTrace(ShootPos, FirePos - ShootPos, Owner)
	if SafetyTr.Hit then FirePos = SafetyTr.HitPos end
	--[[if SERVER then
		debugoverlay.Cross(FirePos, 10, 2, Color(0, 89, 255), true)
		debugoverlay.Line(FirePos, FirePos + FireAng:Forward() * 5000, 2, Color(0, 89, 255), false)
	else
		debugoverlay.Cross(FirePos, 10, 2, Color(255, 251, 0), true)
		debugoverlay.Line(FirePos, FirePos + FireAng:Forward() * 5000, 2, Color(255, 251, 0), false)
	end]]
	return FirePos, FireAng
end

local EntsToRemove = {
	["ent_jack_gmod_eznapalm"] = true,
	["ent_jack_gmod_ezfirehazard"] = true
}
SWEP.NextSupplyTime = 0
function SWEP:PrimaryAttack()
	local Time = CurTime()
	local NextAttackTime = .08
	self:SetNextPrimaryFire(Time + NextAttackTime)
	local owner = self:GetOwner()

	if SERVER then
		local Gas, Water, State = self:GetGas(), self:GetWater(), self:GetState()
		if Gas <= 0 or Water <= 0 then
			self:Cease()
			self:Msg("Out of water or gas!\nPress Alt+Use on resource container to refill.")
		else
			local FirePos, FireAng = self:GetNozzle()
			local FireUp, FireRight, FireForward = FireAng:Up(), FireAng:Right(), FireAng:Forward()
			if State == STATE_NOTHIN then
				self:SetState(STATE_SPRAYIN)
				if self.SoundLoop then self.SoundLoop:Stop() end
				self.SoundLoop = CreateSound(self, "snds_jack_gmod/intense_liquid_spray.wav")
				self.SoundLoop:SetSoundLevel(75)
				self.SoundLoop:Play()
			elseif State == STATE_SPRAYIN and self.NextSparkTime < Time then
				self.NextSparkTime = Time + 0.1
				local Splach = EffectData()
				local SplachTr = util.QuickTrace(FirePos + FireRight + FireUp * 3, FireForward * 20, owner)
				Splach:SetOrigin(SplachTr.HitPos + SplachTr.HitNormal * 20 + FireRight * 5 - FireUp * 10)
				Splach:SetStart(FireForward)
				Splach:SetScale(1)

				local ExtTrace = util.QuickTrace(FirePos + FireRight + FireUp * -25, FireForward * 250, owner)
				util.Effect("eff_jack_gmod_spranklerspray", Splach, true, true)
				JMod.LiquidSpray(FirePos + FireRight, FireForward * 450, 2, self:EntIndex(), 1)

				local ExtPos = ExtTrace.HitPos
				for k, v in ipairs(ents.FindInSphere(ExtPos, 75)) do
					if IsValid(v) and v ~= nil then
						if v:IsOnFire() then v:Extinguish() end
						v:RemoveAllDecals()

						local class = v:GetClass()
						if string.find(class, "env_fire") then
							v:Fire("Extinguish")
						end
						if EntsToRemove[class] and math.random(1, 3) >= 2 then
							SafeRemoveEntity(v)
						end
						if v.Hydration and table.HasValue(v.EZconsumes, JMod.EZ_RESOURCE_TYPES.WATER) and math.random(1, 4) > 3 then
							--debugoverlay.Line(self:GetPos() + Vector(0, 0, 64), v:GetPos(), 2, Color(0, 225, 255), true)
							v.Hydration = math.Clamp(v.Hydration + 0.8, 0, 100) -- mmm watah
						end

						if v:OnGround() and (v:IsPlayer() and v ~= self:GetOwner() or v:IsNPC()) then
							v:SetVelocity(FireForward * 160 * (v:IsNPC() and 5 or 1))
						end

						local phys = v:GetPhysicsObject()
						if IsValid(phys) then
							phys:AddVelocity(FireForward * 70)
						end
					end
				end
				--debugoverlay.Line(FirePos + FireRight, ExtTrace.HitPos, 1)
			end

			if State == STATE_SPRAYIN then
				local vm = owner:GetViewModel()
				if IsValid(vm) and vm.LookupSequence then
					vm:SendViewModelMatchingSequence(vm:LookupSequence("fire_start"))
				end
				self:Pawnch()
				owner:ViewPunch(AngleRand() * .002)
				local FlameTr = util.TraceLine({
					start = FirePos,
					endpos = FirePos + FireAng:Forward() * 200,
					filter = {self, owner},
					mask = MASK_SHOT
				})

				FirePos = FlameTr.HitPos + FireAng:Forward() * -5
				if self.NextSupplyTime < Time then
					local DrainMult = JMod.Config.Weapons.FlamethrowerFuelDrainMult or 1
					self:SetEZsupplies(JMod.EZ_RESOURCE_TYPES.GAS, math.Clamp(Gas - 1 * DrainMult, 0, 100))
					self:SetEZsupplies(JMod.EZ_RESOURCE_TYPES.WATER, math.Clamp(Water - 1 * DrainMult, 0, 100))
					self.NextSupplyTime = Time + 0.1
				end
			end

			local vm = owner:GetViewModel()
			if IsValid(vm) and vm.LookupSequence then
				vm:SendViewModelMatchingSequence(vm:LookupSequence("fire_stop"))
			end

			self.NextExtinguishTime = Time + NextAttackTime * 2
		end
	end

	if CLIENT and self:GetState() == STATE_SPRAYIN then
		local effectdata = EffectData()
		effectdata:SetAttachment(1)
		effectdata:SetEntity(owner)
		effectdata:SetOrigin(owner:GetShootPos())
		effectdata:SetNormal(owner:GetAimVector())
		effectdata:SetScale(1)
		util.Effect("mann_extinguisher_effect", effectdata)
	end
end

function SWEP:SecondaryAttack()
	return
end

function SWEP:Msg(msg)
	self:GetOwner():PrintMessage(HUD_PRINTCENTER, msg)
end

function SWEP:Pawnch()
	self:GetOwner():SetAnimation(PLAYER_ATTACK1)
	self:UpdateNextIdle()
end

function SWEP:TryLoadResource(typ, amt)
	if amt < 1 then return 0 end
	local Accepted = 0
	for _, v in pairs(self.EZconsumes) do
		if typ == v then
			local CurAmt = self:GetEZsupplies(typ) or 0
			local Take = math.min(amt, self.MaxGas - CurAmt)
			if Take > 0 then
				self:SetEZsupplies(typ, CurAmt + Take)
				sound.Play("snds_jack_gmod/gas_load.ogg", self:GetPos(), 65, math.random(90, 110))
				Accepted = Take
			end
		end
	end
	return Accepted
end

function SWEP:OnDrop()
	local Owner = self.EZdropper
	if IsValid(Owner) then
		local Ent = ents.Create("ent_mann_jmod_ezextinguisher")
		Ent:SetPos(Owner:GetShootPos() + Owner:GetAimVector() * 20)
		Ent:SetAngles(Owner:GetAimVector():Angle())
		Ent:Spawn()
		Ent:Activate()
		Ent:GetPhysicsObject():SetVelocity(Owner:GetVelocity())
		Ent:SetGas(self:GetEZsupplies(JMod.EZ_RESOURCE_TYPES.GAS))
		Ent:SetWater(self:GetEZsupplies(JMod.EZ_RESOURCE_TYPES.WATER))
		self:Remove()
	end
end

function SWEP:OnRemove()
	self:Cease()
end

function SWEP:Holster(wep)
	self:Cease()
	return true
end

function SWEP:Deploy()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	if SERVER then
		JMod.Hint(owner, "flamethrower ignite") --!! изменить
	end

	local Time = CurTime()
	self:SetNextPrimaryFire(Time + 1)
	self:SetNextSecondaryFire(Time + 1)
	self.NextExtinguishTime = Time

	if not owner:IsPlayer() then return end
	local vm = owner:GetViewModel()
	if IsValid(vm) and vm.LookupSequence then
		vm:SendViewModelMatchingSequence(vm:LookupSequence("draw"))
		Downness = 10
		self:UpdateNextIdle()
		self:EmitSound("snds_jack_gmod/toolbox" .. math.random(1, 7) .. ".ogg", 65, math.random(90, 110))
	end
	return true
end

function SWEP:Think()
	local Time = CurTime()
	local idletime = self.NextIdle
	local State = self:GetState()
	if idletime > 0 and Time > idletime then self:UpdateNextIdle() end
	local owner = self:GetOwner()

	if owner:IsPlayer() and (owner:IsSprinting() or owner:KeyDown(IN_ZOOM)) then
		self:SetHoldType("normal")
		if State > STATE_NOTHIN then self:Cease() end
	else
		self:SetHoldType("slam")
	end

	if SERVER and State > STATE_NOTHIN and self.NextExtinguishTime < Time then
		self:Cease()
	end
end

local clr_hint1, clr_hint2 = Color(255, 255, 255, 100), Color(0, 0, 0, 50)
function SWEP:DrawHUD()
	if GetConVar("cl_drawhud"):GetBool() == false then return end
	local Ply = self:GetOwner()
	if Ply:ShouldDrawLocalPlayer() then return end

	local W, H = ScrW(), ScrH()
	draw.SimpleTextOutlined("Water: " .. math.floor(self:GetWater()), "Trebuchet24", W * .1, H * .5, clr_hint1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 3, clr_hint2)
	draw.SimpleTextOutlined("Gas: " .. math.floor(self:GetGas()), "Trebuchet24", W * .1, H * .5 + 30, clr_hint1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 3, clr_hint2)
end