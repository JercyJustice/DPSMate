DPSMateFile("DPSMate.lua")
-- Global Variables
DPSMate = {}
DPSMateMark("core:start")
DPSMate.VERSION = 85
DPSMate.LOCALE = GetLocale()
DPSMate.SYNCVERSION = DPSMate.VERSION..DPSMate.LOCALE
DPSMate.Parser = {}
DPSMateMark("core:pre-acelocale")
DPSMate.L = DPSMate_NewLocaleTable()
DPSMateMark("core:got-acelocale")
DPSMate.DB = {}
-- Skeleton, damit die ~60 Modul-Dateien niemals auf ein nil treffen.
-- DPSMate_Options.lua ueberschreibt Options.Options gleich komplett; laeuft
-- diese Datei aus irgendeinem Grund nicht, haengen die Module ihre Eintraege
-- hier ein statt mit 'attempt to index field Options' abzubrechen.
DPSMate.Options = {}
DPSMate.Options.Options = {
	[1] = { type = 'group', args = {} },
	[2] = { type = 'group', args = {} },
	[3] = { type = 'group', args = {} },
	[4] = { type = 'group', args = {} },
	[5] = { type = 'group', args = {} },
}
for i = 1, 5 do
	DPSMate.Options.Options[i].handler = DPSMate.Options
	-- Fehlt eine Modul-Datei, fehlt ihr args-Eintrag. Ohne Schutz bricht dann
	-- z.B. args[CurMode].name in SetStatusBarValue ab.
	DPSMate_GuardTable(DPSMate.Options.Options[i].args, "args")
end
-- Minimale Standardwerte. DPSMate_OptionsData.lua ueberschreibt sie mit der
-- vollen Auswahl; laedt die Datei nicht, laufen die Fenster trotzdem an.
DPSMate.Options.fonts = { ["FRIZQT"] = "Fonts\FRIZQT__.TTF" }
DPSMate.Options.fontflags = { ["None"] = "NONE", ["Outline"] = "OUTLINE" }
DPSMate.Options.statusbars = { ["Gloss"] = "Interface\AddOns\DPSMate\images\statusbar\Gloss" }
DPSMate.Options.bgtexture = { ["Solid Background"] = "Interface\CHATFRAME\CHATFRAMEBACKGROUND" }
DPSMate.Options.stratas = { [1] = "BACKGROUND", [2] = "LOW", [3] = "HIGH" }
DPSMate.Options.bordertextures = { ["UI-Tooltip-Border"] = "Interface\Tooltips\UI-Tooltip-Border" }
-- Wird als Wahrheitswert abgefragt. Ohne echten Wert liefert die Schutz-
-- Metatable unten einen truthy Platzhalter, und SetStatusBarValue kehrt
-- sofort zurueck -- die Balken werden dann nie versteckt oder befuellt.
DPSMate.Options.TestMode = false

-- Auf diesem Client werden einzelne Lua-Dateien nicht ausgefuehrt (Analyse in
-- EMBERVEIL-BUG.md). Fehlt dadurch eine Methode, gab es bei jedem Aufruf ein
-- Fehlerfenster. Unbekannte Methoden liefern jetzt eine No-op-Funktion.
DPSMate.Modules = {}
-- Siehe DPSMate_Emberveil.lua: der Client laesst pro Login wechselnde Dateien
-- aus. Diese drei Tabellen enthalten nur Funktionen bzw. Untertabellen und
-- koennen deshalb gefahrlos auf No-op zurueckfallen.
DPSMate_GuardTable(DPSMate.Options, "Options")
DPSMate_GuardTable(DPSMate.Modules, "Modules")
DPSMateMark("core:tables")
DPSMate.Events = {
	"CHAT_MSG_COMBAT_SELF_HITS",
	"CHAT_MSG_COMBAT_SELF_MISSES",
	"CHAT_MSG_SPELL_SELF_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE", 
	"CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE", 
	"CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE",
	"CHAT_MSG_COMBAT_PARTY_HITS",
	"CHAT_MSG_SPELL_PARTY_DAMAGE",
	"CHAT_MSG_COMBAT_PARTY_MISSES",
	"CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS",
	"CHAT_MSG_COMBAT_FRIENDLYPLAYER_MISSES",
	"CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE",
	
	--"COMBAT_TEXT_UPDATE",
	
	"CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS",
	"CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES",
	"CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",
	"CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS",
	"CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES",
	"CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", 
	"CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", 
	"CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS", 
	"CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_MISSES",
	"CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", 
	
	"CHAT_MSG_SPELL_SELF_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS",
	"CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS",
	"CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS",
	"CHAT_MSG_SPELL_PARTY_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS",
	
	"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF", 
	"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS", 
	"CHAT_MSG_SPELL_BREAK_AURA", 
	"CHAT_MSG_SPELL_AURA_GONE_SELF", 
	"CHAT_MSG_SPELL_AURA_GONE_OTHER", 
	"CHAT_MSG_SPELL_AURA_GONE_PARTY", 
	
	"CHAT_MSG_COMBAT_FRIENDLY_DEATH",
	"CHAT_MSG_COMBAT_HOSTILE_DEATH",
	
	"CHAT_MSG_COMBAT_PET_HITS",
	"CHAT_MSG_COMBAT_PET_MISSES",
	"CHAT_MSG_SPELL_PET_BUFF",
	"CHAT_MSG_SPELL_PET_DAMAGE",
	
	-- Emberveil: stands in for the CastSpell / CastSpellByName hooks, which are
	-- protected. See DPSMate_Emberveil.lua.
	"SPELLCAST_START",
	--"SPELLCAST_CHANNEL_START", --
	--"SPELLCAST_STOP", --
	--"SPELLCAST_FAILED", --
	--"SPELLCAST_INTERRUPTED", --
	
	"PLAYER_AURAS_CHANGED",
}
DPSMate.Registered = false
DPSMate.RegistredModules = {}
DPSMate.ModuleNames = {}
local function EchoTranslation(_, s) return s end
DPSMate.BabbleSpell = DPSMate_GetLib("DPSBabble-Spell-2.3",
	{ GetTranslation = EchoTranslation, HasTranslation = function() return nil end, HasReverseTranslation = function() return nil end })
DPSMate.BabbleBoss = DPSMate_GetLib("DPSBabble-Boss-2.3",
	{ GetTranslation = EchoTranslation, HasTranslation = function() return nil end })
DPSMate.NPCDB = DPSMate_GetLib("NPCDB-1.0", {})
DPSMate.UserId = nil
DPSMate.AbilityId = nil
DPSMate.Key = 1

-- Local Variables
local _G = getglobal
local classcolor = {
	rogue = {r=1.0, g=0.96, b=0.41},
	priest = {r=1,g=1,b=1},
	druid = {r=1,g=0.49,b=0.04},
	warrior = {r=0.78,g=0.61,b=0.43},
	warlock = {r=0.58,g=0.51,b=0.79},
	mage = {r=0.41,g=0.8,b=0.94},
	hunter = {r=0.67,g=0.83,b=0.45},
	paladin = {r=0.96,g=0.55,b=0.73},
	shaman = {r=0,g=0.44,b=0.87},
}
local t = {}
local tinsert = table.insert
local strgsub = string.gsub
local func = function(c) tinsert(t, c) end
local strformat = string.format
local strgfind = string.gfind
local strgsub = string.gsub

-- Begin functions

function DPSMate:OnLoad()
	SLASH_DPSMate1 = "/dps"
	SlashCmdList["DPSMate"] = function(msg) DPSMate:SlashCMDHandler(msg) end

	pcall(function() DPSMate:InitializeFrames() end)
	pcall(function() DPSMate:ApplyWindowVisibility() end)
	pcall(function() DPSMate:Enable() end)
	if DPSMate.DB and DPSMate.DB.CombatTime then
		pcall(function() DPSMate.DB:CombatTime() end)
	end
	if DPSMate.Options and DPSMate.Options.InitializeConfigMenu then
		pcall(function() DPSMate.Options:InitializeConfigMenu() end)
	end
	DPSMate_ScheduleMiniMapRestore()
end

function DPSMate:SlashCMDHandler(msg)
	if (msg) then
		local cmd = msg
		if cmd == "lock" then
			DPSMate.Options:Lock()
		elseif cmd == "unlock" then
			DPSMate.Options:Unlock()
		elseif cmd == "config" then
			DPSMate_ConfigMenu:Show()
		elseif cmd == "showAll" then
			for _, val in DPSMateSettings["windows"] do DPSMate.Options:Show(getglobal("DPSMate_"..val["name"])) end
		elseif cmd == "hideAll" then
			for _, val in DPSMateSettings["windows"] do DPSMate.Options:Hide(getglobal("DPSMate_"..val["name"])) end
		elseif strsub(cmd, 1, 4) == "show" then
			local frame = _G("DPSMate_"..strsub(cmd, 6))
			if frame then
				DPSMate.Options:Show(frame)
			else
				DPSMate:SendMessage(DPSMate.L["framesavailable"])
				for _, val in pairs(DPSMateSettings["windows"]) do
					DPSMate:SendMessage("|c3ffddd80- "..val["name"].."|r")
				end
			end
		elseif strsub(cmd, 1, 4) == "hide" then
			local frame = _G("DPSMate_"..strsub(cmd, 6))
			if frame then
				DPSMate.Options:Hide(frame)
			else
				DPSMate:SendMessage(DPSMate.L["framesavailable"])
				for _, val in pairs(DPSMateSettings["windows"]) do
					DPSMate:SendMessage("|c3ffddd80- "..val["name"].."|r")
				end
			end
		else
			DPSMate:SendMessage(DPSMate.L["slashabout"])
			DPSMate:SendMessage(DPSMate.L["slashusage"])
			DPSMate:SendMessage(DPSMate.L["slashlock"])
			DPSMate:SendMessage(DPSMate.L["slashunlock"])
			DPSMate:SendMessage(DPSMate.L["slashshowAll"])
			DPSMate:SendMessage(DPSMate.L["slashhideAll"])
			DPSMate:SendMessage(DPSMate.L["slashshow"])
			DPSMate:SendMessage(DPSMate.L["slashhide"])
			DPSMate:SendMessage(DPSMate.L["slashconfig"])
		end
		end
	end

-- Inhalt an die Fenstergroesse anpassen. Wird aus OnSizeChanged und nach dem
-- Ziehen am Resize-Griff aufgerufen; OnSizeChanged allein reicht hier nicht.
-- Breite nicht per SetWidth (wird hier oft ignoriert, XML-200px bleibt,
-- Text sitzt dann in der Mitte). Stattdessen zwei Anker an einer Kante.
local function DPSMate_TextWidth(fs, maxW)
	local text = ""
	if fs and fs.GetText then text = fs:GetText() or "" end
	local n = string.len(text)
	if n < 1 then n = 8 end
	local tw = n * 9 + 24
	if maxW and maxW > 0 and tw > maxW then tw = maxW end
	if tw < 24 then tw = 24 end
	return tw
end

local function DPSMate_PlaceLeft(fs, parent, x, maxW)
	if not fs or not parent then return end
	if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end
	local tw = DPSMate_TextWidth(fs, maxW)
	fs:ClearAllPoints()
	fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, 0)
	fs:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", x + tw, -16)
end

local function DPSMate_PlaceRight(fs, parent, x, maxW)
	if not fs or not parent then return end
	if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end
	local tw = DPSMate_TextWidth(fs, maxW)
	fs:ClearAllPoints()
	fs:SetPoint("TOPRIGHT", parent, "TOPRIGHT", x, 0)
	fs:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", x, 0)
	fs:SetPoint("LEFT", parent, "RIGHT", x - tw, 0)
	if fs.SetWidth then fs:SetWidth(tw) end
end

function DPSMate:LayoutBarText(bar, width, indent)
	if not bar then return end
	indent = indent or 2
	local inner = (width or 120) - indent
	if inner < 40 then inner = 40 end
	local name = bar.name or _G(bar:GetName().."_Name")
	local value = bar.value or _G(bar:GetName().."_Value")
	if name then
		if name.SetDrawLayer then name:SetDrawLayer("OVERLAY") end
		DPSMate_PlaceLeft(name, bar, indent, inner)
	end
	if value then
		if value.SetDrawLayer then value:SetDrawLayer("OVERLAY") end
		DPSMate_PlaceRight(value, bar, -4, inner)
	end
end

function DPSMate:LayoutHeadTitle(frame, w, top, nButtons)
	if not frame or not frame.GetName then return end
	local n = frame:GetName()
	local head = _G(n.."_Head")
	local hfont = _G(n.."_Head_Font")
	if not head or not hfont then return end
	if type(w) ~= "number" then w = frame:GetWidth() or 150 end
	if type(nButtons) ~= "number" then nButtons = 3 end
	local maxW = w - (nButtons * 15 + 8)
	if maxW < 48 then maxW = 48 end
	if hfont.SetDrawLayer then hfont:SetDrawLayer("ARTWORK") end
	DPSMate_PlaceLeft(hfont, head, 4, maxW)
end


-- Zwei-Anker-Span (TOPLEFT+TOPRIGHT) und StartSizing ziehen auf diesem Client
-- auseinander: der Border folgt der Layout-Rect, Head/ScrollFrame/Griff nicht.
-- Deshalb jedes Kind mit einem Anker plus SetWidth/SetHeight setzen.
-- https://emberveil.org/wiki/lua/widgets/Region#setpoint
-- https://emberveil.org/wiki/lua/widgets/Region#setwidth
local function PinTL(region, parent, x, y, w, h)
	if not region then return end
	if region.ClearAllPoints then region:ClearAllPoints() end
	if region.SetPoint then
		region:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, y or 0)
	end
	if w and region.SetWidth then region:SetWidth(w) end
	if h and region.SetHeight then region:SetHeight(h) end
end

function DPSMate:UpdateFrameSize(frame)
	if not frame or not frame.GetName then return end
	local n = frame:GetName()
	local w, h = frame:GetWidth(), frame:GetHeight()
	if type(w) ~= "number" or type(h) ~= "number" then return end
	if w < 1 then w = 1 end
	if h < 1 then h = 1 end

	local border = frame.fborder or _G(n.."_Border")
	if border then
		PinTL(border, frame, -4, 4, w + 8, h + 8)
	end

	local head = _G(n.."_Head")
	local top = 0
	local headShown = head and (not head.IsShown or head:IsShown())
	if headShown then
		top = head:GetHeight() or 16
		if type(top) ~= "number" or top < 1 then top = 16 end
		PinTL(head, frame, 0, 0, w, top)
		PinTL(_G(n.."_Head_Background"), head, 0, 0, w, top)
		local names = {"Config", "Reset", "Segments", "Filter", "Report", "Sync", "Enable"}
		local cwin = DPSMateSettings and frame.Key and DPSMateSettings["windows"][frame.Key]
		local i = 0
		local bi
		for bi = 1, 7 do
			local bname = names[bi]
			local button = _G(n.."_Head_"..bname)
			if button and (not cwin or cwin["titlebar"..strlower(bname)] ~= false) then
				if not button.IsShown or button:IsShown() then
					button:ClearAllPoints()
					button:SetPoint("RIGHT", head, "RIGHT", -i * 15 - 2, 0)
					i = i + 1
				end
			end
		end
		DPSMate:LayoutHeadTitle(frame, w, top, i)
	end

	local sf = _G(n.."_ScrollFrame")
	local sh = h - top
	if sh < 1 then sh = 1 end
	if sf then
		PinTL(sf, frame, 0, -top, w, sh)
		PinTL(_G(n.."_ScrollFrame_Background"), sf, 0, 0, w, sh)
	end
	local child = _G(n.."_ScrollFrame_Child")
	if child then child:SetWidth(w) end
	local total = _G(n.."_ScrollFrame_Child_Total")
	if total then total:SetWidth(w) end

	local rz = _G(n.."_Resize")
	if rz then
		rz:ClearAllPoints()
		rz:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	end

	local c = DPSMateSettings and frame.Key and DPSMateSettings["windows"][frame.Key]
	local indent = 2
	if c and c["classicons"] then indent = c["barheight"] or 19 end
	if total then DPSMate:LayoutBarText(total, w, indent) end
	local i
	for i = 1, 40 do
		DPSMate:LayoutBarText(_G(n.."_ScrollFrame_Child_StatusBar"..i), w, indent)
	end
end

-- Eigenes Resize statt StartSizing: StartSizing aendert hier eine Layout-Rect,
-- an der nur der vierfach verankerte Border klebt, nicht die gespeicherte
-- Breite. Wiki: Frame:StartSizing(point), GetCursorPosition in UI-Pixeln.
-- https://emberveil.org/wiki/lua/widgets/Frame#startsizing
-- https://emberveil.org/wiki/lua/globals/Cursor#getcursorposition
local sizeDrag, sizeTicker, sizeCap

local function CursorUI()
	local x, y = GetCursorPosition()
	if type(x) ~= "number" or type(y) ~= "number" then return end
	local scale = 1
	if UIParent and UIParent.GetEffectiveScale then
		local s = UIParent:GetEffectiveScale()
		if type(s) == "number" and s > 0 then scale = s end
	end
	return x / scale, y / scale
end

local function EnsureSizeTicker()
	if not sizeTicker then
		sizeTicker = CreateFrame("Frame")
		sizeTicker:Hide()
		sizeTicker:SetScript("OnUpdate", function()
			if DPSMate and DPSMate.TickWindowResize then
				DPSMate:TickWindowResize()
			end
		end)
	end
	if not sizeCap then
		sizeCap = CreateFrame("Frame", nil, UIParent)
		sizeCap:Hide()
		sizeCap:SetFrameStrata("TOOLTIP")
		if sizeCap.EnableMouse then sizeCap:EnableMouse(true) end
		sizeCap:SetScript("OnMouseUp", function()
			if DPSMate and DPSMate.EndWindowResize then
				DPSMate:EndWindowResize()
			end
		end)
	end
	return sizeTicker, sizeCap
end

function DPSMate:BeginWindowResize(frame)
	if not frame or not frame.GetWidth then return end
	if DPSMateSettings and DPSMateSettings.lock then return end
	if sizeDrag and sizeDrag.frame == frame then return end
	local cx, cy = CursorUI()
	if not cx then return end
	local left, top = frame:GetLeft(), frame:GetTop()
	if type(left) == "number" and type(top) == "number" then
		pcall(function()
			frame:ClearAllPoints()
			frame:SetPoint("TOPLEFT", "UIParent", "BOTTOMLEFT", left, top)
		end)
	end
	sizeDrag = {
		frame = frame,
		cx = cx,
		cy = cy,
		w = frame:GetWidth(),
		h = frame:GetHeight(),
	}
	local ticker, cap = EnsureSizeTicker()
	if cap then
		local sw, sh = GetScreenWidth(), GetScreenHeight()
		if type(sw) == "number" and type(sh) == "number" then
			cap:ClearAllPoints()
			cap:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", 0, 0)
			cap:SetWidth(sw)
			cap:SetHeight(sh)
		end
		cap:Show()
	end
	if ticker then ticker:Show() end
end

function DPSMate:TickWindowResize()
	local d = sizeDrag
	if not d or not d.frame then
		DPSMate:EndWindowResize()
		return
	end
	local cx, cy = CursorUI()
	if not cx then return end
	local w = d.w + (cx - d.cx)
	local h = d.h + (d.cy - cy)
	if w < 120 then w = 120 end
	if h < 40 then h = 40 end
	if w > 1200 then w = 1200 end
	if h > 1000 then h = 1000 end
	d.frame:SetWidth(w)
	d.frame:SetHeight(h)
	DPSMate:UpdateFrameSize(d.frame)
end

function DPSMate:EndWindowResize()
	local d = sizeDrag
	sizeDrag = nil
	if sizeTicker then sizeTicker:Hide() end
	if sizeCap then sizeCap:Hide() end
	if not d or not d.frame then return end
	if d.frame.StopMovingOrSizing then
		pcall(function() d.frame:StopMovingOrSizing() end)
	end
	DPSMate:UpdateFrameSize(d.frame)
	DPSMate:SaveFramePosition(d.frame)
	if DPSMate.SetStatusBarValue then
		DPSMate:SetStatusBarValue()
	end
end

-- Position und Groesse pro Fenster sichern, damit sie den Reload ueberleben.
function DPSMate:SaveFramePosition(frame)
	if not frame or not frame.GetName or not DPSMateSettings then return end
	local k = frame.Key
	if not k or not DPSMateSettings["windows"][k] then return end
	local c = DPSMateSettings["windows"][k]
	-- GetPoint braucht hier den 1-basierten Index, und der gelieferte Y-Wert ist
	-- gegenueber SetPoint negiert (https://emberveil.org/wiki/lua/widgets/Region).
	local point, _, relPoint, x, y = frame:GetPoint(1)
	if point then
		c["point"], c["relPoint"] = point, relPoint
		c["posx"], c["posy"] = x, -y
	end
	c["width"], c["height"] = frame:GetWidth(), frame:GetHeight()
end

function DPSMate:SaveMiniMapPosition()
	local frame = DPSMate_MiniMap
	if not frame or not DPSMateSettings then return end
	local ok, left, bottom = pcall(function()
		return frame:GetLeft(), frame:GetBottom()
	end)
	-- https://emberveil.org/wiki/lua/widgets/Region#getleft
	if not ok or type(left) ~= "number" or type(bottom) ~= "number" then return end
	if left == 0 and bottom == 0 then return end
	DPSMateSettings["minimappos"] = { x = left, y = bottom }
end

function DPSMate:RestoreMiniMapPosition()
	local frame = DPSMate_MiniMap
	local c = DPSMateSettings and DPSMateSettings["minimappos"]
	if not frame or type(c) ~= "table" then return end
	if type(c.x) ~= "number" or type(c.y) ~= "number" then return end
	-- Altes GetPoint-Format nicht als Bildschirmkoordinaten verwenden.
	pcall(function()
		frame:ClearAllPoints()
		-- https://emberveil.org/wiki/lua/widgets/Region#setpoint
		frame:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", c.x, c.y)
	end)
end

function DPSMate:RestoreFramePosition(frame)
	if not frame or not DPSMateSettings then return end
	local k = frame.Key
	if not k or not DPSMateSettings["windows"][k] then return end
	local c = DPSMateSettings["windows"][k]
	if c["width"] and c["height"] then
		frame:SetWidth(c["width"])
		frame:SetHeight(c["height"])
	end
	if c["point"] then
		pcall(function()
			frame:ClearAllPoints()
			frame:SetPoint(c["point"], "UIParent", c["relPoint"] or c["point"],
				c["posx"] or 0, c["posy"] or 0)
		end)
	end
	DPSMate:UpdateFrameSize(frame)
end


function DPSMate:InitializeFrames()
	if not DPSMate:WindowsExist() then return end
	for k, val in pairs(DPSMateSettings["windows"]) do
		if not _G("DPSMate_"..val["name"]) then
			local f=CreateFrame("Frame", "DPSMate_"..val["name"], UIParent, "DPSMate_Statusframe")
			f.Key=k
		end
		local frame = _G("DPSMate_"..val["name"])
		-- Liess sich der Frame nicht anlegen, dieses Fenster ueberspringen statt
		-- die ganze Schleife (und damit alle weiteren Fenster) abzubrechen.
		if frame then
		frame.fborder = _G("DPSMate_"..val["name"].."_Border")
			
		frame.Key = k
		DPSMate:RestoreFramePosition(frame)
		frame:SetToplevel(true)
		
		if DPSMate.Options.ToggleDrewDrop then
			DPSMate.Options:ToggleDrewDrop(1, DPSMate.DB:GetOptionsTrue(1, k), frame)
			DPSMate.Options:ToggleDrewDrop(2, DPSMate.DB:GetOptionsTrue(2, k), frame)
		end
		
		if frame.fborder then
			if frame.fborder.SetFrameStrata and DPSMate.Options.stratas then
				frame.fborder:SetFrameStrata(DPSMate.Options.stratas[val["borderstrata"] or 1])
			end
			if frame.fborder.SetBackdrop then
				frame.fborder:SetBackdrop({
					bgFile = "",
					edgeFile = DPSMate.Options.bordertextures and DPSMate.Options.bordertextures[val["bordertexture"] or "UI-Tooltip-Border"],
					tile = true, tileSize = 12, edgeSize = 10,
					insets = { left = 5, right = 5, top = 3, bottom = 1 }
				})
			end
		end
		
		local head = _G("DPSMate_"..val["name"].."_Head")
		if head then
		head.font = _G("DPSMate_"..val["name"].."_Head_Font")
		head.bg = _G("DPSMate_"..val["name"].."_Head_Background")
		head.sync = _G("DPSMate_"..val["name"].."_Head_Sync")
		
		if head.sync and head.sync.GetNormalTexture then
			local nt = head.sync:GetNormalTexture()
			if nt and nt.SetVertexColor then
				if DPSMateSettings["sync"] then
					nt:SetVertexColor(0.67,0.83,0.45,1)
				else
					nt:SetVertexColor(1,0,0,1)
				end
			end
		end
		
		if DPSMateSettings["lock"] then
			local rz = _G("DPSMate_"..val["name"].."_Resize")
			if rz then rz:Hide() end
		end
		if not val["titlebar"] then
			head:Hide()
		end
		if head.font and val["titlebarfontcolor"] and head.font.SetVertexColor then
			head.font:SetVertexColor(val["titlebarfontcolor"][1],val["titlebarfontcolor"][2],val["titlebarfontcolor"][3])
		end
		if head.bg then
			head.bg:SetTexture(DPSMate.Options.statusbars[val["titlebartexture"]])
			if val["titlebarbgcolor"] then
				head.bg:SetVertexColor(val["titlebarbgcolor"][1], val["titlebarbgcolor"][2], val["titlebarbgcolor"][3])
			end
			head.bg:SetAlpha(val["titlebaropacity"] or 1)
		end
		if val["titlebarheight"] then head:SetHeight(val["titlebarheight"]) end
		DPSMate:UpdateFrameSize(frame)
		_G("DPSMate_"..val["name"].."_ScrollFrame_Background"):SetTexture(DPSMate.Options.bgtexture[val["contentbgtexture"]])
		_G("DPSMate_"..val["name"].."_ScrollFrame_Background"):SetVertexColor(val["contentbgcolor"][1], val["contentbgcolor"][2], val["contentbgcolor"][3])
		_G("DPSMate_"..val["name"].."_ScrollFrame_Background"):SetAlpha(val["bgopacity"] or 1)
		frame:SetScale(val["scale"])
		local en = _G("DPSMate_"..val["name"].."_Head_Enable")
		if en and en.SetChecked then en:SetChecked(DPSMateSettings["enable"]) end
		
		-- Styles // Bars
		local child = _G("DPSMate_"..val["name"].."_ScrollFrame_Child")
		-- OnSizeChanged feuert beim ersten Aufbau nicht zwangslaeufig; dann behaelt
		-- child seine XML-Breite und die Balken ragen aus dem Fenster.
		if child then
			child:SetWidth(frame:GetWidth())
			local sf = _G("DPSMate_"..val["name"].."_ScrollFrame")
			if sf then sf:SetHeight(frame:GetHeight()-16) end
		end
		_G("DPSMate_"..val["name"].."_ScrollFrame_Child_Total"):SetPoint("TOPLEFT", child, "TOPLEFT")
		_G("DPSMate_"..val["name"].."_ScrollFrame_Child_Total"):SetPoint("TOPRIGHT", child, "TOPRIGHT")
		if DPSMateSettings["showtotals"] then
			_G("DPSMate_"..val["name"].."_ScrollFrame_Child_Total"):SetHeight(val["barheight"])
		else
			_G("DPSMate_"..val["name"].."_ScrollFrame_Child_Total"):SetHeight(0.00001)
		end
		_G("DPSMate_"..val["name"].."_ScrollFrame_Child_Total"):SetStatusBarTexture(DPSMate.Options.statusbars[val["bartexture"]])
		_G("DPSMate_"..val["name"].."_ScrollFrame_Child_Total"):SetStatusBarColor(1,1,1,val["totopacity"] or 1)
		_G("DPSMate_"..val["name"].."_ScrollFrame_Child_Total_BG"):SetTexture(DPSMate.Options.statusbars[val["bartexture"]])
		DPSMate:LayoutBarText(_G("DPSMate_"..val["name"].."_ScrollFrame_Child_Total"), child:GetWidth(), 2)
		for i=1, 40 do
			local bar = _G("DPSMate_"..val["name"].."_ScrollFrame_Child_StatusBar"..i)
			if not bar then break end
			bar.name = _G("DPSMate_"..val["name"].."_ScrollFrame_Child_StatusBar"..i.."_Name")
			bar.value = _G("DPSMate_"..val["name"].."_ScrollFrame_Child_StatusBar"..i.."_Value")
			bar.icon = _G("DPSMate_"..val["name"].."_ScrollFrame_Child_StatusBar"..i.."_Icon")
			bar.bg = _G("DPSMate_"..val["name"].."_ScrollFrame_Child_StatusBar"..i.."_BG")
			
			-- Postition
			-- ClearAllPoints ist noetig: sonst bleibt der TOPLEFT-Anker an "child"
			-- bestehen und alle Balken liegen uebereinander.
			bar:ClearAllPoints()
			bar:SetPoint("TOPRIGHT", child, "TOPRIGHT")
			if i>1 then
				bar:SetPoint("TOPLEFT", _G("DPSMate_"..val["name"].."_ScrollFrame_Child_StatusBar"..(i-1)), "BOTTOMLEFT", 0, -1*val["barspacing"])
			else
				if DPSMateSettings["showtotals"] then
					bar:SetPoint("TOPLEFT", _G("DPSMate_"..val["name"].."_ScrollFrame_Child_Total"), "BOTTOMLEFT", 0, -1*val["barspacing"])
				else
					bar:SetPoint("TOPLEFT", _G("DPSMate_"..val["name"].."_ScrollFrame_Child_Total"), "BOTTOMLEFT", 0, -1)
				end
			end
			-- Was sonst das OnLoad des Balkens macht. Wird der Handler beim
			-- Nachladen ueber die Addon-Liste uebersprungen, fehlt es sonst.
			bar:SetMinMaxValues(1, 100)
			if bar.bg then bar.bg:SetAlpha(0.5) end

			local indent = 2
			if val["classicons"] then
				indent = val["barheight"]
				if bar.icon then
					bar.icon:SetWidth(val["barheight"])
					bar.icon:SetHeight(val["barheight"])
					bar.icon:Show()
				end
			elseif bar.icon then
				bar.icon:Hide()
			end
			bar:SetHeight(val["barheight"])
			DPSMate:LayoutBarText(bar, child:GetWidth(), indent)
			bar:SetStatusBarTexture(DPSMate.Options.statusbars[val["bartexture"]])
			if bar.bg then
				bar.bg:SetTexture(DPSMate.Options.statusbars[val["bartexture"]])
			end
			if bar.bg and val["bgbarcolor"] then
				if val["barbg"] then
					bar.bg:SetVertexColor(val["bgbarcolor"][1],val["bgbarcolor"][2],val["bgbarcolor"][3], 0)
				else
					bar.bg:SetVertexColor(val["bgbarcolor"][1],val["bgbarcolor"][2],val["bgbarcolor"][3], 0.5)
				end
			end
		end
		if DPSMate_RepairWindowSettings then DPSMate_RepairWindowSettings(val) end
		if DPSMate_ApplyWindowFonts then DPSMate_ApplyWindowFonts(val) end
		if DPSMate_ApplyWindowAlphas then DPSMate_ApplyWindowAlphas(val) end
		DPSMate.Options:SelectRealtime(frame, val["realtime"])
		end
		end
	end
	-- frisch aufgebaute Balken sind sichtbar; erst leeren
	DPSMate:HideStatusBars()
	DPSMate.Options:ToggleTitleBarButtonState()
	for k, val in pairs(DPSMateSettings["windows"]) do
		local fr = _G("DPSMate_"..val["name"])
		if fr then DPSMate:UpdateFrameSize(fr) end
	end
	DPSMate:ApplyWindowVisibility()
	DPSMate.Options:HideWhenSolo()
	if not DPSMateSettings["enable"] then
		self:Disable()
	end
	
	-- Die Detail-Fenster wurden entfernt; ausserdem fehlen auf diesem Client
	-- immer wieder einzelne Dateien. Beides darf hier nicht abbrechen.
	local function TopLevel(name)
		local f = _G(name)
		if f and f.SetToplevel then f:SetToplevel(true) end
	end
	for _, n in pairs({"DPSMate_MiniMap", "DPSMate_PopUp", "DPSMate_Logout",
	                   "DPSMate_Report", "DPSMate_ConfigMenu"}) do
		TopLevel(n)
	end
end

function DPSMate:ApplyWindowVisibility()
	local windows = DPSMateSettings and DPSMateSettings["windows"]
	if type(windows) ~= "table" then return end
	-- Einmalig: der Minimap-Toggle hatte alle Fenster auf hidden=true gesetzt,
	-- ohne sie beim Login wieder einzublenden. hideonlogin bleibt die Option
	-- fuer "beim Login versteckt".
	-- Zweiter Durchgang: Ziehen am Minimap-Icon hat bisher OnMouseUp ausgeloest
	-- und die Fenster versteckt. Das war kein gewolltes Ausblenden.
	local hide = DPSMateSettings["hideonlogin"]
	local _, val
	for _, val in pairs(windows) do
		if val then
			if hide then
				val["hidden"] = true
			else
				val["hidden"] = false
			end
			local frame = getglobal("DPSMate_"..val["name"])
			if frame then
				if val["hidden"] then
					frame:Hide()
				else
					frame:Show()
				end
			end
		end
	end
end

function DPSMate:WindowsExist()
	if (DPSMate:TableLength(DPSMateSettings.windows)==0) then
		return false
	end
	return true
end

function DPSMate:TMax(t)
	local max = 0
	for _,val in pairs(t) do
		if val>max then
			max=val
		end
	end
	return max
end

function DPSMate:TableLength(t)
	local count = 0
	if (t) then
		for _,_ in pairs(t) do
			count = count + 1
		end
	end
	return count
end

function DPSMate:TContains(t, value)
	if (t) then
		for cat, val in pairs(t) do
			if val == value or cat==value then
				return true
			end
		end
	end
	return false
end

function DPSMate:GetKeyByVal(t, value)
	for cat, val in pairs(t) do
		if val == value then
			return cat
		end
	end
end

function DPSMate:GetKeyByValInTT(t, x, y)
	for cat, val in pairs(t) do
		if (type(val) == "table") then
			if (x==val[y]) then
				return cat
			end
		end
	end
end

function DPSMate:InvertTable(t)
	local s={}
	for cat, val in pairs(t) do
		s[val]=cat
	end
	return s
end

function DPSMate:CopyTable(t)
	local s={}
	for cat, val in pairs(t) do
		s[cat] = val
	end
	return s
end

function DPSMate:GetUserById(id)
	if not self.UserId then
		self.UserId = {}
		for cat, val in DPSMateUser do
			self.UserId[val[1]] = cat
		end
	end
	return self.UserId[id]
end

function DPSMate:GetAbilityById(id)
	if not self.AbilityId then
		self.AbilityId = {}
		for cat, val in DPSMateAbility do
			self.AbilityId[val[1]] = cat
		end
	end
	return self.AbilityId[id]
end

function DPSMate:PlayerExist(arr, name)
	if DPSMateSettings["mergepets"] then
		for cat, val in pairs(arr) do
			if (cat == name) then
				return true
			end
		end
	end
	return false
end

function DPSMate:GetMaxValue(arr, key)
	local max = 0
	for _, val in arr do
		if val[key]>max then
			max=val[key]
		end
	end
	return max
end

function DPSMate:GetMinValue(arr, key)
	local min
	for _, val in arr do
		if not min or val[key]<min then
			min = val[key]
		end
	end
	return min or 0
end

function DPSMate:ScaleDown(arr, start)
	local t = {}
	for cat, val in arr do
		t[cat] = {(val[1]-start+1), val[2]}
	end
	return t
end

function DPSMate:SetStatusBarValue()
	if not self:WindowsExist() or self.Options.TestMode then return end
	self:HideStatusBars()
	for k,c in DPSMateSettings.windows do
		if c and c["name"] then
		local arr, cbt, ecbt = self:GetMode(k)
		if not arr then arr, cbt, ecbt = {}, 0, 0 end
		local user, val, perc, strt = self:GetSettingValues(arr,cbt,k,ecbt)
		if not user then user, val, perc, strt = {}, {}, {}, {"",""} end
		local prefix = "DPSMate_"..c["name"]
		if DPSMateSettings["showtotals"] then
			local tn = _G(prefix.."_ScrollFrame_Child_Total_Name")
			local tv = _G(prefix.."_ScrollFrame_Child_Total_Value")
			if tn then tn:SetText(self.L["total"]) end
			if tv then tv:SetText((strt[1] or "")..(strt[2] or "")) end
			local totalBar = _G(prefix.."_ScrollFrame_Child_Total")
			local child = _G(prefix.."_ScrollFrame_Child")
			if totalBar then
				local bw = child and child.GetWidth and child:GetWidth() or totalBar:GetWidth()
				DPSMate:LayoutBarText(totalBar, bw, 2)
			end
		end
		if not c["cbtdisplay"] then
			local hf = _G(prefix.."_Head_Font")
			local modeArgs = DPSMate.Options.Options[1] and DPSMate.Options.Options[1]["args"]
			local modeName = modeArgs and modeArgs[c["CurMode"]] and modeArgs[c["CurMode"]].name or c["CurMode"]
			if hf then
				local tstr = ""
				if DPSMate.Options.FormatTime then
					tstr = DPSMate.Options:FormatTime(cbt) or ""
				end
				hf:SetText(tostring(modeName).." ["..tstr.."]")
				local fr = _G(prefix)
				if fr then DPSMate:LayoutHeadTitle(fr) end
			end
		end
		local totalBar = _G(prefix.."_ScrollFrame_Child_Total")
		if (user[1]) then
			if totalBar then
				if DPSMateSettings["showtotals"] then totalBar:Show() else totalBar:Hide() end
			end
			local maxBars = self:MaxVisibleBars(c)
			for i=1, 40 do
				if (not user[i]) or i > maxBars then break end
				local statusbar = _G(prefix.."_ScrollFrame_Child_StatusBar"..i)
				local name = _G(prefix.."_ScrollFrame_Child_StatusBar"..i.."_Name")
				local value = _G(prefix.."_ScrollFrame_Child_StatusBar"..i.."_Value")
				local texture = _G(prefix.."_ScrollFrame_Child_StatusBar"..i.."_Icon")
				if not statusbar then break end
				local child = _G(prefix.."_ScrollFrame_Child")
				if child then child:SetHeight((i+1)*(c["barheight"]+c["barspacing"])) end
				local r,g,b,img = self:GetClassColor(user[i])
				statusbar:SetStatusBarColor(r,g,b, 1)
				local p = ""
				if c["ranks"] then p=i..". " end
				if name then name:SetText(p..user[i]) end
				if value then value:SetText(val[i]) end
				if texture and img then texture:SetTexture("Interface\\AddOns\\DPSMate\\images\\class\\"..img) end
				statusbar:SetValue(perc[i])
				statusbar.user = user[i]
				statusbar:Show()
				local bw = child and child.GetWidth and child:GetWidth() or statusbar:GetWidth()
				local indent = 2
				if c["classicons"] then indent = c["barheight"] or 19 end
				DPSMate:LayoutBarText(statusbar, bw, indent)
			end
		else
			if totalBar then totalBar:Hide() end
		end
		end
	end
end

function DPSMate:strrev(str)
	local res = "";
	local len = strlen(str) 
	for i=0, len-1 do
		res = res..strsub(str, len-i, len-i)
	end
	return res;
end

function DPSMate:Commas(n,k)
	if DPSMateSettings["windows"][k]["numberformat"] == 3 then 
		n = strformat("%.0f", n)
		for left, num, right in strgfind(n, '([^%d]*%d)(%d+)') do
			return left and left..self:strrev(strgsub(self:strrev(num), '(%d%d%d)','%1,')) or n
		end
	else
		return n;
	end
end

function DPSMate:FormatNumbers(dmg,total,sort,k)
	local oldd, oldt, olds = dmg, total, sort
	if DPSMateSettings["windows"][k]["numberformat"] == 2 then
		if dmg>10000 then
			dmg = strformat("%.0f", (dmg/1000))
		end
		if total>10000 then
			total = strformat("%.0f", (total/1000))
		end
		if sort>10000 then
			sort = strformat("%.0f", (sort/1000))
		end
	elseif DPSMateSettings["windows"][k]["numberformat"] == 4 then
		if dmg>10000 then
			dmg = strformat("%.1f", (dmg/1000))
		end
		if total>10000 then
			total = strformat("%.1f", (total/1000))
		end
		if sort>10000 then
			sort = strformat("%.1f", (sort/1000))
		end
	end
	return dmg, total, sort, oldd, oldt, olds
end

function DPSMate:ApplyFilter(key, name)
	if not key or not name or not DPSMateUser[name] then return true end
	local class = DPSMateUser[name][2] or "warrior"
	if class == "" then class = "warrior" end
	local path = DPSMateSettings["windows"][key]
	t = {}
	if path["grouponly"] then
		if not DPSMate.Parser.TargetParty[name] and DPSMate.Parser.TargetParty ~= {} then
			-- Allow pets of group members (incl. SuperWoW "Pet (Owner)" names)
			local ownerId = DPSMateUser[name][6]
			local ownerName = ownerId and self:GetUserById(ownerId)
			if not ownerName or not DPSMate.Parser.TargetParty[ownerName] then
				return false
			end
		end
	end
	-- Certain people
	strgsub(path["filterpeople"], "(.-),", func)
	for cat, val in pairs(t) do
		if name == val then
			return true
		end
	end
	if path["filterpeople"] == "" then
		-- classes
		for cat, val in pairs(path["filterclasses"]) do
			if not val then
				if cat == class then
					return false
				end
			end
		end
	else
		return false
	end
	return true
end

function DPSMate:GetSettingValues(arr, cbt, k, ecbt)
	k = k or 1
	return DPSMate.RegistredModules[DPSMateSettings["windows"][k]["CurMode"]]:GetSettingValues(arr, cbt, k, ecbt)
end

function DPSMate:EvalTable(k)
	k = k or 1
	return DPSMate.RegistredModules[DPSMateSettings["windows"][k]["CurMode"]]:EvalTable(DPSMateUser[UnitName("player")], k)
end

function DPSMate:GetClassColor(class)
	if (class) then
		if DPSMateUser[class] then class = DPSMateUser[class][2] end
		if classcolor[class] then
			return classcolor[class].r, classcolor[class].g, classcolor[class].b, class
		else
			return 0.78,0.61,0.43, "Warrior"
		end
	end
	return 0.78,0.61,0.43, "Warrior"
end

function DPSMate:GetMode(k)
	k = k or 1
	local Handler = DPSMate.RegistredModules[DPSMateSettings["windows"][k]["CurMode"]]
	-- Fehlt das Modul des aktuellen Modus (Datei vom Client uebersprungen) oder
	-- wurde ihm noch keine Datenquelle zugewiesen, leer zurueckgeben statt
	-- abzubrechen -- sonst reisst es jedes Neuzeichnen mit.
	if not Handler or not Handler.DB or not DPSMateCombatTime then
		return {}, 0, 0
	end
	local result = {total={Handler.DB[1], DPSMateCombatTime["total"], DPSMateCombatTime["effective"][1]}, currentfight={Handler.DB[2], DPSMateCombatTime["current"], DPSMateCombatTime["effective"][2]}}
	for cat, val in pairs(DPSMateSettings["windows"][k]["options"][2]) do
		if val then
			if strfind(cat, "segment") then
				local num = tonumber(strsub(cat, 8))
				if DPSMateHistory[Handler.Hist][num] then
					return DPSMateHistory[Handler.Hist][num], DPSMateCombatTime["segments"][num][1], DPSMateCombatTime["segments"][num][2]
				else
					return {}, 0, 0
				end
			else
				return result[cat][1], result[cat][2], result[cat][3]
			end
		end
	end
end

function DPSMate:GetModeByArr(arr, k, Hist)
	local result = {total={arr[1], DPSMateCombatTime["total"], DPSMateCombatTime["effective"][1]}, currentfight={arr[2], DPSMateCombatTime["current"], DPSMateCombatTime["effective"][2]}}
	for cat, val in pairs(DPSMateSettings["windows"][k]["options"][2]) do
		if val then
			if strfind(cat, "segment") then
				local num = tonumber(strsub(cat, 8))
				if DPSMateHistory[Hist or arr.Hist][num] then
					return DPSMateHistory[Hist or arr.Hist][num], DPSMateCombatTime["segments"][num][1], DPSMateCombatTime["segments"][num][2]
				else
					return {}, 0, 0
				end
			else
				return result[cat][1], result[cat][2], result[cat][3]
			end
		end
	end
end

function DPSMate:GetModeName(k)
	k = k or 1
	local result = {total="Total", currentfight="Current fight"}
	for cat, val in pairs(DPSMateSettings["windows"][k]["options"][2]) do
		if val then 
			if strfind(cat, "segment") then
				local num = tonumber(strsub(cat, 8))
				return DPSMateHistory["names"][num]
			else
				return result[cat]
			end
		end
	end
end

function DPSMate:MaxVisibleBars(c)
	if type(c) ~= "table" or not c["name"] then return 40 end
	local frame = _G("DPSMate_"..c["name"])
	if not frame or not frame.GetHeight then return 40 end
	local h = frame:GetHeight() or 100
	local top = 0
	if c["titlebar"] ~= false then top = c["titlebarheight"] or 16 end
	local bh = (c["barheight"] or 19) + (c["barspacing"] or 1)
	if bh < 1 then bh = 20 end
	local n = math.floor((h - top - 2) / bh)
	if n < 1 then n = 1 end
	if n > 40 then n = 40 end
	return n
end

function DPSMate:HideStatusBars()
	for _,val in pairs(DPSMateSettings.windows) do
		for i=1, 40 do
			local b = _G("DPSMate_"..val["name"].."_ScrollFrame_Child_StatusBar"..i)
			if b then b:Hide() end
		end
	end
end

function DPSMate:EventHolder()
	if DPSMateEventFrame then return DPSMateEventFrame end
	if DPSMate_Options then
		DPSMateEventFrame = DPSMate_Options
		return DPSMateEventFrame
	end
	local f = CreateFrame("Frame", "DPSMateEventFrame", UIParent)
	f:SetScript("OnEvent", function(self, ev, msg)
		if DPSMate_OnCombatEvent then
			DPSMate_OnCombatEvent(self, ev, msg)
		end
	end)
	DPSMateEventFrame = f
	return f
end

function DPSMate:Disable()
	local holder = DPSMate:EventHolder()
	if DPSMate.Registered and holder and holder.UnregisterEvent then
		for _, ev in pairs(DPSMate.Events) do
			pcall(holder.UnregisterEvent, holder, ev)
		end
		self.Registered = false
	end
end

function DPSMate:Enable()
	local holder = DPSMate:EventHolder()
	if not DPSMate.Registered and holder and holder.RegisterEvent then
		for _, ev in pairs(DPSMate.Events) do
			pcall(holder.RegisterEvent, holder, ev)
		end
		self.Registered = true
	end
end

function DPSMate:Broadcast(type, who, what, with, value, failtype)
	if DPSMateSettings["broadcasting"] then
		if IsRaidLeader() or IsRaidOfficer() then
			ch = "RAID"
			if DPSMateSettings["bcrw"] then
				ch = "RAID_WARNING"
			end
			if DPSMateSettings["bccd"] and type == 1 then
				DPSMate_SendChat(self.L["bccdo"](who, what), ch, nil, nil)
				return
			elseif DPSMateSettings["bccd"] and type == 6 then
				DPSMate_SendChat(self.L["bccdt"](who, what), ch, nil, nil)
				return
			elseif DPSMateSettings["bcress"] and type == 2 then
				DPSMate_SendChat(self.L["bcress"](who, what), ch, nil, nil)
				return
			elseif DPSMateSettings["bckb"] and type == 4 then
				DPSMate_SendChat(self.L["bckb"](who, what, with, value), ch, nil, nil)
				return
			elseif DPSMateSettings["bcfail"] and type == 3 then
				if failtype == 1 then
					DPSMate_SendChat(self.L["bcfailo"](what, who, value, with), ch, nil, nil)
				elseif failtype == 3 then
					DPSMate_SendChat(self.L["bcfailt"](who, with), ch, nil, nil)
				else
					DPSMate_SendChat(self.L["bcfailth"](who, value, with, what), ch, nil, nil)
				end
				return
			end
		end
	end
end

function DPSMate:SendMessage(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080"..self.L["name"].."|r: "..msg)
end

function DPSMate:Register(prefix, table, name)
	DPSMate.ModuleNames[name] = prefix
	DPSMate.RegistredModules[prefix] = table
end