-- Mannytko 2025
AddCSLuaFile()
if not JMod or JMod == nil then
	error("invisible...")
	return
end

JMod.SetWepSelectIcon(SWEP, "entities/ent_mann_jmod_ezbinoculars", false)
SWEP.PrintName = "EZ Binoculars"
SWEP.Author = "Mannytko"
SWEP.Purpose = "Binoculars that allow you to see farther."
SWEP.Spawnable = false
SWEP.ViewModel = "models/weapons/c_nvbinoculars.mdl"
SWEP.WorldModel = "models/weapons/w_nvbinoculars.mdl"
SWEP.UseHands = true
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.ViewModelFOV = 75
SWEP.Slot = 0
SWEP.SlotPos = 5
SWEP.InstantPickup = true -- Fort Fights compatibility
SWEP.EZdroppable = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
	self:SetHoldType("slam")
	self.NextIdle = 0
end

local Downness = 0
function SWEP:GetViewModelPosition(pos, ang)
	local FT = FrameTime()
	local ply = self:GetOwner()
	if ply:IsSprinting() or ply:KeyDown(IN_ZOOM) or ply:KeyDown(IN_ATTACK2) then
		Downness = Lerp(FT * 2, Downness, 6)
	else
		Downness = Lerp(FT * 2, Downness, 2)
	end

	ang:RotateAroundAxis(ang:Right(), -Downness * 5)
	return pos, ang
end

function SWEP:PrimaryAttack()
	return
end

function SWEP:SecondaryAttack()
	self:UpdateNextIdle()
	self:SetNextPrimaryFire(CurTime() + 2)
	self:SetNextSecondaryFire(CurTime() + 2)
	self:GetOwner():ScreenFade(SCREENFADE.IN, color_black, 0.5, 0.01)
end

function SWEP:Deploy()
	self:SetNextPrimaryFire(CurTime() + 1)
	self:SetNextSecondaryFire(CurTime() + 1)
	self:UpdateNextIdle()
	return true
end

function SWEP:Think()
	local ply = self:GetOwner()
	if not IsValid(ply) then return end
	local Time, idletime = CurTime(), self.NextIdle
	if idletime > 0 and Time > idletime then
		self:SendWeaponAnim(ACT_VM_IDLE)
		self:UpdateNextIdle()
	end

	if ply:KeyDown(IN_ATTACK2) and not ply:IsSprinting() then
		self:SetHoldType("camera")
	else
		self:SetHoldType("slam")
	end
end

function SWEP:UpdateNextIdle()
	local vm = self:GetOwner():GetViewModel()
	self.NextIdle = CurTime() + vm:SequenceDuration()
end

function SWEP:OnDrop()
	local Owner = self.EZdropper
	if IsValid(Owner) then
		local Ent = ents.Create("ent_mann_jmod_ezbinoculars")
		Ent:SetPos(Owner:GetShootPos() + Owner:GetAimVector() * 20)
		Ent:SetAngles(Owner:GetAimVector():Angle())
		Ent:Spawn()
		Ent:Activate()
		Ent:GetPhysicsObject():SetVelocity(Owner:GetVelocity())
		self:Remove()
	end
end

local Vignet = Material("mats_jack_gmod_sprites/vignette.png")
local clr_hint1, clr_hint2, clr_hint3 = Color(255, 255, 255, 50), Color(255, 255, 255, 100), Color(0, 0, 0, 50)
function SWEP:DrawHUD()
	local W, H = ScrW(), ScrH()
	local ply = self:GetOwner()
	if ply:KeyDown(IN_ATTACK2) and not ply:IsSprinting() then
		surface.SetMaterial(Vignet)
		surface.SetDrawColor(255, 255, 255, 255)
		for i = 1, 4 do
			surface.DrawTexturedRect(0, 0, W, H)
		end

		local Tr = ply:GetEyeTrace()
		local Dist = math.ceil(Tr.HitPos:Distance(ply:GetShootPos()) / 52)
		draw.SimpleText(Dist .. "m", "Trebuchet24", W * .5 - 150, H * .5, clr_hint2, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("X: " .. math.Round(math.ceil(100 * Tr.HitPos.x) / 10000), "Trebuchet24", W * .5 + 150, H * .5, clr_hint2, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("Y: " .. math.Round(math.ceil(100 * Tr.HitPos.y) / 10000), "Trebuchet24", W * .5 + 150, H * .5 + 30, clr_hint2, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	draw.SimpleTextOutlined("RMB: aim", "Trebuchet24", W * .4, H * .7, clr_hint1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 3, clr_hint3)
	draw.SimpleTextOutlined("Backspace: drop", "Trebuchet24", W * .4, H * .7 + 30, clr_hint1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 3, clr_hint3)
end

local CurFoV = 70
function SWEP:TranslateFOV(fov)
	local FT = FrameTime()
	local ply = self:GetOwner()
	if ply:KeyDown(IN_ATTACK2) and not ply:IsSprinting() then
		local ShootPos, AimVec = ply:GetShootPos(), ply:GetAimVector()
		local Tr = util.QuickTrace(ShootPos, AimVec * 100000, {ply})
		local Dist = Tr.HitPos:Distance(ShootPos)
		local Reduction = Dist / 500
		local DesiredFoV = math.Clamp(fov / Reduction, 1, 70)
		local ZoomRate = CurFoV / 4 * FT
		if CurFoV > DesiredFoV + .5 then
			CurFoV = CurFoV - ZoomRate
		elseif CurFoV < DesiredFoV - .5 then
			CurFoV = CurFoV + ZoomRate
		end
		return CurFoV
	end
	return fov
end

function SWEP:AdjustMouseSensitivity()
	local ply = self:GetOwner()
	if ply:KeyDown(IN_ATTACK2) and not ply:IsSprinting() then return self:GetOwner():GetFOV() / 80 end
end