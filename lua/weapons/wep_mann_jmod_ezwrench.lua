-- Mannytko 2025
AddCSLuaFile()
if not JMod or JMod == nil then
	error("invisible...")
	return
end

SWEP.Base = "wep_jack_gmod_ezmeleebase"
SWEP.PrintName = "EZ Wrench"
SWEP.Author = "Mannytko"
SWEP.Purpose = ""
JMod.SetWepSelectIcon(SWEP, "entities/ent_mann_jmod_ezwrench")
SWEP.ViewModel = "models/weapons/c_wrench_jmod.mdl"
SWEP.WorldModel = "models/weapons/w_wrench_jmod.mdl"
SWEP.BodyHolsterModel = "models/weapons/w_wrench_jmod.mdl"
SWEP.BodyHolsterSlot = "back"
SWEP.BodyHolsterAng = Angle(-130, 5, 20)
SWEP.BodyHolsterAngL = Angle(-130, 0, 0)
SWEP.BodyHolsterPos = Vector(2, -6, -1)
SWEP.BodyHolsterPosL = Vector(4, -24, 3)
SWEP.BodyHolsterScale = .8
SWEP.ViewModelFOV = 50
SWEP.Slot = 1
SWEP.SlotPos = 7
SWEP.VElements = {}
SWEP.WElements = {
	["wrench"] = {
		type = "Model",
		model = "models/weapons/w_wrench_jmod.mdl",
		bone = "ValveBiped.Bip01_R_Hand",
		rel = "",
		pos = Vector(3.5, 1, -8),
		angle = Angle(90, 0, 0),
		size = Vector(1, 1, 1),
		color = Color(255, 255, 255, 255),
		surpresslightning = false,
		material = "",
		skin = 0,
		bodygroup = {}
	}
}

SWEP.DropEnt = "ent_mann_jmod_ezwrench"
SWEP.HitDistance = 45
SWEP.HitInclination = 5
SWEP.HitPushback = 600
SWEP.MaxSwingAngle = 120
SWEP.SwingSpeed = 5
SWEP.SwingPullback = 150
SWEP.PrimaryAttackSpeed = 1.0
SWEP.SecondaryPush = false
SWEP.DoorBreachPower = 0.3
SWEP.SprintCancel = true
SWEP.StrongSwing = false
--
SWEP.SwingSound = Sound("weapons/wrench_swing.wav")
SWEP.HitSoundWorld = Sound("Canister.ImpactHard")
SWEP.HitSoundBody = Sound("Flesh.ImpactHard")
SWEP.PushSoundBody = Sound("Flesh.ImpactSoft")
SWEP.IdleHoldType = "melee"
SWEP.SprintHoldType = "melee"

function SWEP:CustomSetupDataTables()
	self:NetworkVar("Float", 1, "TaskProgress")
end

function SWEP:CustomInit()
	self:SetHoldType("melee")
	self:SetTaskProgress(0)
	self.NextTaskTime = 0
end

function SWEP:CustomThink()
	local Time = CurTime()
	if self.NextTaskTime < Time then
		self:SetTaskProgress(0)
		self.NextTaskTime = Time + self.PrimaryAttackSpeed + 1
	end

	if CLIENT and self.ScanResults then
		self.LastScanTime = self.LastScanTime or Time
		if self.LastScanTime < (Time - 30) then
			self.ScanResults = nil
			self.LastScanTime = nil
		end
	end
end

function SWEP:OnHit(swingProgress, tr)
	if not IsFirstTimePredicted() then return end
	local Owner = self:GetOwner()
	--local SwingCos = math.cos(math.rad(swingProgress))
	--local SwingSin = math.sin(math.rad(swingProgress))
	local SwingAng = Owner:EyeAngles()
	local SwingPos = Owner:GetShootPos()
	local StrikeVector = tr.HitNormal
	local StrikePos = SwingPos - (SwingAng:Up() * 15)
	if IsValid(tr.Entity) then
		if tr.Entity:IsPlayer() or tr.Entity:IsNPC() then
			local WrenchDam = DamageInfo()
			WrenchDam:SetAttacker(Owner)
			WrenchDam:SetInflictor(self)
			WrenchDam:SetDamagePosition(StrikePos)
			WrenchDam:SetDamageType(DMG_CLUB)
			WrenchDam:SetDamage(math.random(15, 35))
			WrenchDam:SetDamageForce(StrikeVector:GetNormalized() * 150)
			tr.Entity:TakeDamageInfo(WrenchDam)
		else
			local ent = tr.Entity
			if not ent.IsJackyEZmachine or ent.Durability > 0 then return end
			local Missing = ent.MaxDurability - ent.Durability
			if Missing <= 0 then
				self:SetTaskProgress(0)
				return
			else
				sound.Play("snds_jack_gmod/ez_tools/" .. math.random(13) .. ".ogg", tr.HitPos + VectorRand(), 75, math.random(95, 110))
			end

			Accepted = math.min(Missing / 3, 10)
			--print(Missing, Accepted)
			local Broken = false
			if ent.Durability <= 0 then Broken = true end
			ent.Durability = math.min(ent.Durability + (Accepted * 3), ent.MaxDurability)
			if ent.Durability >= ent.MaxDurability then
				ent:RemoveAllDecals()
				ent:EmitSound("snd_jack_turretrepair.ogg", 65, math.random(90, 110))
			end

			if ent.Durability > 0 then
				if ent:GetState() == JMod.EZ_STATE_BROKEN then ent:SetState(JMod.EZ_STATE_OFF) end
				if Broken and ent.OnRepair then ent:OnRepair() end
			end

			ent:SetNW2Float("EZdurability", ent.Durability)
			local prog = (math.Clamp(ent.Durability, 1, ent.MaxDurability) / ent.MaxDurability) * 100
			--print(ent.Durability, ent.MaxDurability, prog)
			self:SetTaskProgress(self:GetNW2Float("EZminingProgress", 0) + prog)
		end
	end

	if tr.Entity:IsPlayer() or tr.Entity:IsNPC() or string.find(tr.Entity:GetClass(), "prop_ragdoll") then tr.Entity:SetVelocity(Owner:GetAimVector() * Vector(1, 1, 0) * self.HitPushback) end
end

function SWEP:FinishSwing(swingProgress)
	if not IsFirstTimePredicted() then return end
	if swingProgress >= self.MaxSwingAngle then
		self:SetTaskProgress(0)
	else
		self.NextTaskTime = CurTime() + self.PrimaryAttackSpeed + 1
	end
end

if CLIENT then
	local LastProg = 0
	local clr_hint1, clr_hint2, clr_hint3 = Color(255, 255, 255, 100), Color(0, 0, 0, 100), Color(0, 0, 0, 50)
	function SWEP:DrawHUD()
		if GetConVar("cl_drawhud"):GetBool() == false then return end
		local Ply = self:GetOwner()
		if Ply:ShouldDrawLocalPlayer() then return end
		local W, H = ScrW(), ScrH()
		if self.GetTaskProgress == nil then return end
		local Prog = self:GetTaskProgress()
		if Prog > 0 then
			draw.SimpleTextOutlined("Repairing...", "Trebuchet24", W * .5, H * .45, clr_hint1, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3, clr_hint3)
			draw.RoundedBox(10, W * .3, H * .5, W * .4, H * .05, clr_hint2)
			draw.RoundedBox(10, W * .3 + 5, H * .5 + 5, W * .4 * LastProg / 100 - 10, H * .05 - 10, clr_hint1)
		end

		local Tr = util.QuickTrace(Ply:EyePos(), Ply:GetAimVector() * 80, {Ply})
		local Ent = Tr.Entity
		if IsValid(Ent) and Ent.IsJackyEZmachine then
			draw.SimpleTextOutlined((Ent.PrintName and tostring(Ent.PrintName)) or tostring(Ent), "Trebuchet24", W * .7, H * .5, clr_hint1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 3, clr_hint3)
			if Ent.MaxDurability then
				draw.SimpleTextOutlined("Durability: "..tostring(math.Round(Ent:GetNW2Float("EZdurability", 0)) + Ent.MaxDurability * 2).."/"..Ent.MaxDurability*3, "Trebuchet24", W * .7, H * .5 + 30, clr_hint1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 3, clr_hint3)
			end
		end

		LastProg = Lerp(FrameTime() * 5, LastProg, Prog)
	end
end

----- Overriding think to remove hitsounds
function SWEP:Think()
	local Time = CurTime()
	local Owner = self:GetOwner()
	local vm = Owner:GetViewModel()
	local idletime = self.NextIdle
	local Swing = self:GetSwinging()
	if idletime > 0 and Time > idletime then
		vm:SendViewModelMatchingSequence(vm:LookupSequence("idle0"))
		self:UpdateNextIdle()
	end

	if self.CustomThink then self:CustomThink() end
	if (self.SprintCancel and not self.StrongSwing) and Owner:KeyDown(IN_SPEED) or Owner:KeyDown(IN_ZOOM) then
		self.SwingProgress = 0
		self:SetSwinging(false)
		self:SetHoldType(self.SprintHoldType)
	else
		self:SetHoldType(self.IdleHoldType)
		if Swing and IsFirstTimePredicted() then
			if self.SwingProgress < self.MaxSwingAngle then
				self.SwingProgress = self.SwingProgress + (self.MaxSwingAngle * self.SwingSpeed * 0.05)
				if SERVER and self.SwingProgress >= 0 then
					local p = self.SwingProgress
					local SwingCos = math.cos(math.rad(p))
					local SwingSin = math.sin(math.rad(p))
					local SwingPos = Owner:GetShootPos()
					local SwingAng = Owner:EyeAngles()
					SwingAng:RotateAroundAxis(SwingAng:Forward(), self.HitAngle)
					SwingAng:RotateAroundAxis(SwingAng:Right(), math.deg(SwingCos))
					SwingAng:RotateAroundAxis(SwingAng:Up(), 8)
					local SwingUp, SwingForward, SwingRight = SwingAng:Up(), SwingAng:Forward(), SwingAng:Right()
					local Offset = SwingRight * self.SwingOffset.x + SwingForward * SwingSin * self.SwingOffset.y + SwingUp * self.SwingOffset.z
					local StartPos = (SwingPos + Offset) + SwingForward * -self.DistanceCompensation
					local EndVector = SwingForward * self.HitDistance + SwingRight * -self.HitInclination + SwingUp * self.HitSpace - SwingUp * self.StartSwingAngle
					local tr = util.TraceLine({
						start = StartPos,
						endpos = StartPos + EndVector,
						filter = Owner,
						mask = MASK_SHOT_HULL
					})

					debugoverlay.Line(tr.StartPos, tr.HitPos, 2, Color(255, 38, 0), false)
					if tr.Hit then
						self:SetSwinging(false)
						debugoverlay.Cross(tr.HitPos, 10, 2, Color(255, 38, 0), true)
						if self.FinishSwing then self:FinishSwing(self.SwingProgress) end
						if self.OnHit then self:OnHit(p, tr, self.WasSecondarySwing) end
						if tr.Entity:IsPlayer() or string.find(tr.Entity:GetClass(), "npc") then
							local BodySound = self.HitSoundBody
							if BodySound then
								if istable(BodySound) then BodySound = BodySound[math.random(#BodySound)] end
								sound.Play(BodySound, tr.HitPos, 10, math.random(75, 100), 1)
							end

							tr.Entity:SetVelocity(Owner:GetAimVector() * Vector(1, 1, 0) * self.HitPushback)
							--
							if self.SetTaskProgress then self:SetTaskProgress(0) end
							--
							local vPoint = tr.HitPos
							local effectdata = EffectData()
							effectdata:SetOrigin(vPoint)
							util.Effect("BloodImpact", effectdata)
							--
						else
							local WorldSound = self.HitSoundWorld
							if tr.HitWorld and WorldSound then
								if istable(WorldSound) then WorldSound = WorldSound[math.random(#WorldSound)] end
								sound.Play(WorldSound, tr.HitPos, 10, math.random(75, 100), 1)
							end
						end

						local Surface = util.GetSurfaceData(tr.SurfaceProps)
						if Surface and Surface.impactHardSound then sound.Play(Surface.impactHardSound, tr.HitPos, 75, 100, 1) end
					end
				end
			else
				if self.FinishSwing then self:FinishSwing(self.SwingProgress) end
				self:SetSwinging(false)
				self.SwingProgress = 0
			end
		elseif IsFirstTimePredicted() then
			self.SwingProgress = 0
		end
	end
end