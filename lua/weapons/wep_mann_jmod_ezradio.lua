-- Mannytko 2025
AddCSLuaFile()
if not JMod or JMod == nil then
	error("invisible...")
	return
end

JMod.SetWepSelectIcon(SWEP, "entities/ent_mann_jmod_ezradio", false)
SWEP.Base = "weapon_base"
SWEP.PrintName = "EZ Portable Radio"
SWEP.Author = "Mannytko"
SWEP.Purpose = "A portable walkie-talkie that you can use to order things."
SWEP.Spawnable = false
SWEP.AutoSwitchFrom = false
SWEP.AutoSwitchTo = false
SWEP.InstantPickup = true -- Fort Fights compatibility
SWEP.BodyHolsterModel = ""
SWEP.EZdroppable = true
SWEP.Slot = 0
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.ViewModel = "models/radio/c_radio.mdl"
SWEP.UseHands = true
SWEP.ViewModelFOV = 75
SWEP.WorldModel = "models/radio/w_radio.mdl"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.ConnectionAttempts = 0
SWEP.EZradio = true

local STATE_OFF, STATE_CONNECTING = 0, 1
function SWEP:SetupDataTables()
	self:NetworkVar("Int", 1, "OutpostID")
	self:NetworkVar("Int", 2, "State")
end

function SWEP:GetVoice()
	return "normal"
end

function SWEP:OnDrop()
	local Owner = self.EZdropper
	if IsValid(Owner) then
		local Ent = ents.Create("ent_mann_jmod_ezradio")
		Ent:SetPos(Owner:GetShootPos() + Owner:GetAimVector() * 20)
		Ent:SetAngles(Owner:GetAimVector():Angle())
		Ent:Spawn()
		Ent:Activate()
		Ent:GetPhysicsObject():SetVelocity(Owner:GetVelocity())
		self:Remove()
	end
end

function SWEP:Reload()
	return
end

function SWEP:Initialize()
	local Path = "/npc/combine_soldier/vo/"
	local Files, Folders = file.Find("sound" .. Path .. "*.wav", "GAME")
	self.Voices = Files
	self.NextRealThink = 0
	self.ConnectionlessThinks = 0
	self:SetState(STATE_OFF)
	self:SetHoldType("normal")
	self.NextIdle = 0
end

function SWEP:Speak(msg, parrot)
	if self:GetState() < 1 then return end
	if not msg then msg = "uhhhh" end
	if SERVER and parrot then
		for _, ply in ipairs(player.GetAll()) do
			if ply:Alive() and (ply:GetPos():DistToSqr(self:GetPos()) <= 200 * 200 or (self:UserIsAuthorized(ply) and ply.EZarmor and ply.EZarmor.effects.teamComms)) then
				net.Start("JMod_EZradio")
				net.WriteBool(true)
				net.WriteBool(true)
				net.WriteString(parrot)
				net.WriteEntity(self)
				net.Send(ply)
			end
		end
	end

	local MsgLength = string.len(msg)
	for i = 1, math.Round(MsgLength / 15) do
		timer.Simple(i * .75, function() if IsValid(self) and (self:GetState() > 0) then self:EmitSound("/npc/combine_soldier/vo/" .. self.Voices[math.random(1, #self.Voices)], 65, 120) end end)
	end

	timer.Simple(.5, function()
		if SERVER and IsValid(self) then
			for _, ply in ipairs(player.GetAll()) do
				if ply:Alive() and (ply:GetPos():DistToSqr(self:GetPos()) <= 200 * 200 or (self:UserIsAuthorized(ply) and ply.EZarmor and ply.EZarmor.effects.teamComms)) then
					net.Start("JMod_EZradio")
					net.WriteBool(true)
					net.WriteBool(false)
					net.WriteString(msg)
					net.WriteEntity(self)
					net.Send(ply)
				end
			end
		end
	end)
end

function SWEP:TurnOn(activator)
	self:SetState(STATE_CONNECTING)
	self:GetOwner():EmitSound("snds_jack_gmod/ezsentry_startup.ogg", 50, 100)
	self.ConnectionAttempts = 0
	self:SetHoldType("slam")
end

function SWEP:TurnOff()
	local State = self:GetState()
	if State == STATE_OFF then return end
	self:SetState(STATE_OFF)
	self:GetOwner():EmitSound("snds_jack_gmod/ezsentry_shutdown.ogg", 50, 100)
	self:SetHoldType("normal")
end

function SWEP:Connect(ply)
	if CLIENT then return end
	local Team = 0
	if IsValid(ply) then
		if engine.ActiveGamemode() == "sandbox" and ply:Team() == TEAM_UNASSIGNED then
			Team = ply:AccountID()
		else
			Team = ply:Team()
		end
	end

	JMod.EZradioEstablish(self, tostring(Team)) -- we store team indices as strings because they might be huge (if it's a player's acct id)
	local OutpostID = self:GetOutpostID()
	local Station = JMod.EZ_RADIO_STATIONS[OutpostID]
	if not Station or Station == nil then
		self:Speak("Couldn't find a free station, try again next time.")
		self:TurnOff()
	end
	self:SetState(Station.state)
	timer.Simple(1, function()
		if IsValid(self) then
			self:Speak("Comm line established with J.I. Radio Outpost " .. OutpostID)
			self.ConnectionAttempts = 0
		end
	end)
end

function SWEP:Deploy()
	if self:GetState() == STATE_OFF then self:TurnOn() end
	if SERVER then
		JMod.Hint(self:GetOwner(), "ent_jack_gmod_ezaidradio")
		JMod.Hint(self:GetOwner(), "aid wait")
	end

	self:UpdateNextIdle()
end

function SWEP:PrimaryAttack()
	if self:GetOwner():IsSprinting() then return end
	if SERVER and self:GetState() == JMod.EZ_STATION_STATE_READY then
		net.Start("JMod_EZradio")
		net.WriteBool(false)
		net.WriteEntity(self)
		net.WriteTable(JMod.Config.RadioSpecs.AvailablePackages)
		net.Send(self:GetOwner())
		self:GetOwner():EmitSound("snds_jack_gmod/radio_chk.ogg")
		self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
		self:UpdateNextIdle()
	end

	self:SetNextPrimaryFire(CurTime() + 2)
	self:SetNextSecondaryFire(CurTime() + 2)
end

function SWEP:SecondaryAttack()
	return
end

function SWEP:Think()
	local State, Time = self:GetState(), CurTime()
	local idletime = self.NextIdle
	if idletime > 0 and Time > idletime then
		self:SendWeaponAnim(ACT_VM_IDLE)
		self:UpdateNextIdle()
	end

	if self.NextRealThink < Time then
		self.NextRealThink = Time + 4
		if State == STATE_CONNECTING then
			self:Speak("Broadcast received, establishing comm line...")
			self:Connect(self:GetOwner())
			self.ConnectionAttempts = self.ConnectionAttempts + 1
			if self.ConnectionAttempts >= 2 then
				timer.Simple(1, function()
					if IsValid(self) then
						self:TurnOff()
						self.ConnectionAttempts = 0
					end
				end)
			end
		elseif State > 0 then
			self.ConnectionlessThinks = 0
		end
	end
end

function SWEP:UpdateNextIdle()
	local vm = self:GetOwner():GetViewModel()
	self.NextIdle = CurTime() + vm:SequenceDuration()
end

function SWEP:UserIsAuthorized(ply)
	if not ply then return false end
	if not ply:IsPlayer() then return false end
	if self:GetOwner() and (ply == self:GetOwner()) then return true end
	local Allies = (self:GetOwner() and self:GetOwner().JModFriends) or {}
	if table.HasValue(Allies, ply) then return true end
	if not (engine.ActiveGamemode() == "sandbox" and ply:Team() == TEAM_UNASSIGNED) then
		local OurTeam = nil
		if IsValid(self:GetOwner()) then OurTeam = self:GetOwner():Team() end
		return (OurTeam and ply:Team() == OurTeam) or false
	end
	return false
end

function SWEP:EZreceiveSpeech(ply, txt)
	if CLIENT then return end
	local State = self:GetState()
	if State < 2 then return end
	if not self:UserIsAuthorized(ply) then return end
	txt = string.lower(txt)
	local NormalReq, BFFreq = string.sub(txt, 1, 14) == "supply radio: ", string.sub(txt, 1, 6) == "heyo: "
	if NormalReq or BFFreq then
		local Name, ParrotPhrase = string.sub(txt, 15), txt
		if BFFreq then Name = string.sub(txt, 7) end
		if Name == "help" then
			if State == 2 then
				local Msg, Num = 'stand near radio and say in chat "supply radio: status", or "supply radio: [package]". available packages are:', 1
				self:Speak(Msg, ParrotPhrase)
				local str = ""
				for name, items in pairs(JMod.Config.RadioSpecs.AvailablePackages) do
					str = str .. name
					if Num > 0 and Num % 10 == 0 then
						local newStr = str
						timer.Simple(Num / 10, function() if IsValid(self) then self:Speak(newStr) end end)
						str = ""
					else
						str = str .. ", "
					end

					Num = Num + 1
				end

				timer.Simple(Num / 10, function() if IsValid(self) then self:Speak(str) end end)
				JMod.Hint(self:GetOwner(), "aid package")
				return true
			end
		elseif Name == "status" then
			self:Speak(JMod.EZradioStatus(self, self:GetOutpostID(), ply, BFFreq), ParrotPhrase)
			return true
		elseif JMod.Config.RadioSpecs.AvailablePackages[Name] then
			self:Speak(JMod.EZradioRequest(self, self:GetOutpostID(), ply, Name, BFFreq), ParrotPhrase)
			return true
		end
	end
	return false
end

if CLIENT then
	local Downness = 0
	function SWEP:GetViewModelPosition(pos, ang)
		local FT = FrameTime()
		local ply = self:GetOwner()
		if ply:IsSprinting() or ply:KeyDown(IN_ZOOM) or (self:GetState() < 1 or self:GetState() == STATE_CONNECTING) then
			Downness = Lerp(FT * 2, Downness, 6)
		else
			Downness = Lerp(FT * 2, Downness, 2)
		end

		ang:RotateAroundAxis(ang:Right(), -Downness * 5)
		return pos, ang
	end

	local StateMsgs = {
		[STATE_OFF] = "Off",
		[STATE_CONNECTING] = "Connecting...",
		[JMod.EZ_STATION_STATE_READY] = "Ready",
		[JMod.EZ_STATION_STATE_DELIVERING] = "Delivering",
		[JMod.EZ_STATION_STATE_BUSY] = "Busy"
	}

	local clr_hint1, clr_hint2, clr_hint3 = Color(255, 255, 255, 200), Color(255, 255, 255, 50), Color(0, 0, 0, 50)
	function SWEP:DrawHUD()
		local W, H = ScrW(), ScrH()
		draw.SimpleTextOutlined("Status: " .. StateMsgs[self:GetState()], "Trebuchet24", W * .4, H * .7 + 30, clr_hint1, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 3, clr_hint3)
		draw.SimpleTextOutlined("Backspace: drop", "Trebuchet24", W * .4, H * .7 + 60, clr_hint2, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 3, clr_hint3)
	end

	function SWEP:PrimaryAttack()
		return
	end
end