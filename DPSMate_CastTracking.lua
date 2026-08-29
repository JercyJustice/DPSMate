DPSMateFile("DPSMate_CastTracking.lua")
-- Aus DPSMate_Sync.lua herausgeloest, nachdem der Raid-Sync entfernt wurde.
-- Diese Teile haben mit Sync nichts zu tun:
--   DPSMate:GetSummarizedTable  - Datenverdichtung fuer die Graphen (30 Module)
--   DPSMate.Parser:GetTarget    - Ziel-Ermittlung fuer Zauber-Zuordnung
--   NoteCast + UseAction-Hook   - ordnet Absorbs/HoTs dem Verursacher zu
-- Der Sync-Broadcast der Zauberzuordnung ist entfallen; die Zuordnung wirkt
-- jetzt nur noch lokal.

local UN = UnitName
local player = UnitName("player")
local DB = DPSMate.DB
local tinsert = table.insert
local LastMouseover = nil
local LastDecursive = nil
local _, playerclass = UnitClass("player")

-- Steckte urspruenglich in DPSMate.Sync:OnLoad(). Ohne diese Registrierung hat
-- der eigene Spieler keine Klasse gespeichert, und GetClassColor faellt auf
-- Warrior zurueck -- inklusive falschem Klassensymbol.
function DPSMate:RegisterSelf()
	if not DPSMateUser then return end
	if not DPSMateUser[player] then
		DPSMateUser[player] = {
			[1] = DPSMate:TableLength(DPSMateUser) + 1,
			[2] = strlower(playerclass or ""),
		}
	elseif playerclass and (not DPSMateUser[player][2] or DPSMateUser[player][2] == "") then
		DPSMateUser[player][2] = strlower(playerclass)
	end
end

function DPSMate:GetSummarizedTable(arr)
	local newArr, i, dmg, time, dis = {}, 1, 0, nil, 1
	local TL = DPSMate:TableLength(arr)
	if TL>100 then dis = floor(TL/100) end
	for cat, val in arr do
		if dis>1 then
			dmg=dmg+val[2]
			if time then
				if i>dis and (val[1]-time)>0 then
					tinsert(newArr, {(val[1]+time)/2, dmg/(val[1]-time)}) -- last time val // subtracting from each other to get the time in which the damage is being done
					time, dmg, i = nil, 0, 1
				end
			else
				time=val[1]
			end
		else
			tinsert(newArr, val)
		end
		i=i+1
	end
	return newArr
end

if GameTooltip and type(GameTooltip.SetUnit) == "function" then
	GameTooltip.OldSetUnit = GameTooltip.SetUnit
	GameTooltip.SetUnit = function(self, unit)
		LastMouseover = UN(unit)
		if GameTooltip.OldSetUnit then return GameTooltip.OldSetUnit(self, unit) end
	end
end

function DPSMate.Parser:GetTarget()
	local target = LastDecursive
	if not target then
		if UnitIsPlayer("target") then
			target = UnitName("target")
		else
			target = LastMouseover
		end
	end
	return target
end

-- Hooking useaction function in order to get the owner of the spell.
local OverTimeDispels = {
	[DPSMate.BabbleSpell:GetTranslation("Abolish Poison")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Abolish Disease")] = true,
}
local AbsorbAbilities = {
	[DPSMate.BabbleSpell:GetTranslation("Greater Fire Protection Potion")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Greater Frost Protection Potion")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Greater Nature Protection Potion")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Greater Holy Protection Potion")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Greater Shadow Protection Potion")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Greater Arcane Protection Potion")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Power Word: Shield")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Ice Barrier")] = true,
	[DPSMate.BabbleSpell:GetTranslation("The Burrower's Shell")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Aura of Protection")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Damage Absorb")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Physical Protection")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Harm Prevention Belt")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Mana Shield")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Frost Protection")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Frost Resistance")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Frost Ward")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Fire Protection")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Fire Ward")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Nature Protection")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Shadow Protection")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Arcane Protection")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Holy Protection")] = true,
}
local OtherAbilities = {
	[DPSMate.BabbleSpell:GetTranslation("Banish")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Curse of Recklessness")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Curse of the Elements")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Curse of Tongues")] = true,
	[DPSMate.BabbleSpell:GetTranslation("Curse of Shadow")] = true,
}
DPSMate.Parser.SendSpell = {}

-- Buchhaltung, die bisher in den Hooks UseAction/CastSpell/CastSpellByName
-- dreifach stand. CastSpell und CastSpellByName sind protected und werden
-- stattdessen ueber SPELLCAST_START bedient.
function DPSMate.Parser:NoteCast(spellName)
	if not spellName then return end
	local target = DPSMate.Parser:GetTarget()
	if target and (OverTimeDispels[spellName] or AbsorbAbilities[spellName] or OtherAbilities[spellName]) and not DPSMate.Parser.SendSpell[spellName] then
		DPSMate.Parser.SendSpell[spellName] = true
	end
	local time = GetTime()
	DB:AwaitAfflicted(player, spellName, UnitName("target"), time)
	if DPSMate.Parser.Dispels[spellName] then DB:AwaitHotDispel(spellName, target, player, time) end
	DB:AwaitingBuff(player, spellName, target, time)
	DB:AwaitingAbsorbConfirmation(player, spellName, target, time)
end

local oldUseAction = UseAction
DPSMate.Parser.UseAction = function(slot, checkCursor, onSelf)
	DPSMate_Tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	DPSMate_Tooltip:ClearLines()
	DPSMate_Tooltip:SetAction(slot)
	local aura = DPSMate_TooltipTextLeft1:GetText()
	local target = DPSMate.Parser:GetTarget()
	if aura and target and (OverTimeDispels[aura] or AbsorbAbilities[aura] or OtherAbilities[aura]) and not DPSMate.Parser.SendSpell[aura] then
	--if aura and target and not DPSMate.Parser.SendSpell[aura] then
		--DPSMate:SendMessage("Send:"..aura.." with target: "..target)
		DPSMate.Parser.SendSpell[aura] = true
	end
	if aura then
		local time = GetTime()
		DB:AwaitAfflicted(player, aura, UnitName("target"), time)
		if DPSMate.Parser.Dispels[aura] then DB:AwaitHotDispel(aura, target, player, time) end
		DB:AwaitingBuff(player, aura, target, time)
		DB:AwaitingAbsorbConfirmation(player, aura, target, time)
	end
	oldUseAction(slot, checkCursor, onSelf)
end
if not pcall(function() UseAction = DPSMate.Parser.UseAction end) then
	DPSMate.Parser.UseActionHookFailed = true
end


