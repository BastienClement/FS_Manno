local Gaze = LibStub("AceAddon-3.0"):NewAddon("FSGaze", "AceEvent-3.0", "AceConsole-3.0")

local WRATH = GetSpellInfo(186348)
local GAZE = GetSpellInfo(181597)
local EMP_GAZE = GetSpellInfo(182006)

local GAZE_IMMUNES = {}
local HUNTS_CALL = {}

-- pal mage demo rogue
local CAN_IMMUNE = { 
	[2] = true,
	[8] = true,
	[9] = true,
	[4] = true
}

-- hunt mage rogue lock
local SOAKERS_PREF = { 3, 8, 4, 9 }

function Gaze:OnInitialize()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("ENCOUNTER_START")
end

local locked = false
local wrath_locked = false
function Gaze:COMBAT_LOG_EVENT_UNFILTERED(_, _, event, ...)
	if event == "SPELL_AURA_APPLIED" then
		local target, _, _, spell = select(7, ...)
		if spell == 186362 and not wrath_locked then
			wrath_locked = true
			C_Timer.After(0.5, function()
				wrath_locked = false
				local sym = 1
				for i = 1, 20 do
					local unit = "raid" .. i
					if UnitDebuff(unit, WRATH) then
						if sym == 3 and ((UnitHealth("boss1") / UnitHealthMax("boss1")) < 0.35) then
							SetRaidTarget(unit, 6)
						else
							SetRaidTarget(unit, sym)
						end
						sym = sym + 1
					end
				end
			end)
		elseif spell == 182006 and not locked then
			locked = true
			C_Timer.After(0.5, function()
				locked = false
				
				local soakers = {}
				local gazed = {}
				
				for i = 1, 20 do
					local unit = "raid" .. i
					local class = select(3, UnitClass(unit))
					
					if UnitDebuff(unit, GAZE) or UnitDebuff(unit, EMP_GAZE) then
						gazed[unit] = { class = class }
					elseif not UnitIsDeadOrGhost(unit) then
						if not UnitDebuff(unit, WRATH) and (not HUNTS_CALL[unit] or HUNTS_CALL[unit] < 2) then
							if not soakers[class] then
								soakers[class] = {}
							end
							soakers[class][unit] = true
						end
					end
				end
				
				local function find_soaker()
					for _, class_pref in ipairs(SOAKERS_PREF) do
						if soakers[class_pref] then
							for soaker, _ in pairs(soakers[class_pref]) do
								soakers[class_pref][soaker] = nil
								if class_pref == 3 then
									HUNTS_CALL[soaker] = (HUNTS_CALL[soaker] or 0) + 1
								end
								return soaker
							end
						end
					end
				end
				
				local immuners = {}
				for unit, infos in pairs(gazed) do
					if CAN_IMMUNE[infos.class] and (not GAZE_IMMUNES[unit] or (GetTime() - GAZE_IMMUNES[unit]) < 5) then
						immuners[unit] = infos
						--[[GAZE_IMMUNES[unit] = GetTime()
						SendChatMessage(UnitName(unit) .. " >> IMMUNE", "RAID")
						SendChatMessage("SAY: " .. UnitName(unit) .. " >> IMMUNE", "RAID")]]
					else
						local soaker = find_soaker()
						if not soaker then
							local target = UnitName(unit)
							
							FS:Send("BigWigs", {
								{ "CancelAllActions", 0 },
								{ "Emphasized", 0, "RIP RIP RIP" },
								{ "Say", 0, "RIP RIP RIP", "YELL" },
								{ "Sound" , 0, "Alert" }
							}, target)
							
							FS:Send("Gaze_Color", { target = target, rip = true })
						else
							local soak = UnitName(soaker)
							local tar = UnitName(unit)
							
							FS:Send("BigWigs", {
								{ "CancelAllActions", 0 },
								{ "Emphasized", 0, "Soaked by " .. soak },
								{ "Say", 0, "Soaked by " .. soak, "YELL" },
								{ "Say", 0, "Soaked by " .. soak, delay = 2 },
								{ "Say", 0, "Soaked by " .. soak, delay = 4 },
								{ "Sound" , 0, "Warning" }
							}, tar)
							
							FS:Send("BigWigs", {
								{ "CancelAllActions", 0 },
								{ "Emphasized", 0, "Soak " .. tar },
								{ "Sound" , 0, "Warning" }
							}, soak)
							
							FS:Send("Gaze_Color", { target = tar, soaker = soak })
							
							--SendChatMessage(UnitName(soaker) .. " >> Soak " .. UnitName(unit), "RAID")
							--SendChatMessage(UnitName(unit) .. " >> Soaked by " .. UnitName(soaker), "RAID")
							--SendChatMessage("SAY: " .. UnitName(unit) .. " >> " .. UnitName(soaker), "RAID")
						end
					end
				end
				
				for unit, infos in pairs(immuners) do
					GAZE_IMMUNES[unit] = GetTime()
					local soaker = find_soaker()
					soaker = (soaker and UnitName(soaker)) or "RIP"
					
					local target = UnitName(unit)
					
					FS:Send("BigWigs", {
						{ "CancelAllActions", 0 },
						{ "Emphasized", 0, "IMMUNE OR " .. soaker },
						{ "Say", 0, "IMMUNE OR " .. soaker, "YELL" },
						{ "Sound" , 0, "Warning" }
					}, target)
					
					if soaker == "RIP" then
						FS:Send("Gaze_Color", { target = target, immune = true })
					else					
						FS:Send("Gaze_Color", { target = target, soaker = soaker, immune = true })
					end
					
					--SendChatMessage(UnitName(unit) .. " >> IMMUNE OR " .. soaker, "RAID")
					--SendChatMessage("SAY: " .. UnitName(unit) .. " >> IMMUNE OR " .. soaker, "RAID")
				end
			end)
		end
	end
end

function Gaze:ENCOUNTER_START()
	wipe(GAZE_IMMUNES)
	wipe(HUNTS_CALL)
end

function TEST_GAZE()
	local soaker = "raid18"
	local unit = "raid8"
	
	FS:Send("BigWigs", {
		{ "CancelAllActions", 0 },
		{ "Emphasized", 0, "Soaked by A" },
		{ "Emphasized", 0, "Soaked by B", delay = 0.6 }
	}, "Blash")
end

