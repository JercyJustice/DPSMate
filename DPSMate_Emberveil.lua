-- Emberveil compatibility layer for DPSMate.
--
-- Emberveil is a 1.12.1 client on Lua 5.1 (https://emberveil.org/wiki/lua).
-- XML, virtual frame templates, CreateFrame's `inherits` argument and the
-- `this` / `event` / `arg1` script globals all behave exactly as they do on
-- vanilla, so the addon needs no changes for any of that.
--
-- What does differ is the set of PROTECTED functions. Per the conventions page
-- (https://emberveil.org/wiki/lua/conventions) those may only be called by the
-- default FrameXML UI; an addon calling one raises an error. A `/script` line
-- the player types still works, but addon code -- including code reached via
-- RunScript -- does not.
--
-- The protected functions DPSMate would otherwise use are:
--   SendChatMessage   (Communication)  -> replaced by DPSMate_SendChat below
--   CastSpell         (Spell)          -> Hook entfernt, siehe DPSMate_CastTracking.lua
--   CastSpellByName   (Spell)          -> Hook entfernt, siehe DPSMate_CastTracking.lua
--   GetAddOnInfo      (Addon)          -> guarded, see libs/AceLibrary
--   LoadAddOn         (Addon)          -> guarded, see libs/AceLibrary
--
-- Everything else the addon calls was checked against the 1053-function index
-- and is available unprotected.

----------------------------------------------------------------------------------
--------------                     ALTLASTEN                        --------------
----------------------------------------------------------------------------------

-- Die Ladediagnose ist entfernt. Ihre Aufrufe stehen noch am Anfang vieler
-- Dateien und tun jetzt nichts mehr.
function DPSMateMark() end
function DPSMateFile() end

-- Minimap: Drag-Flag NICHT am Widget (kann den Client crashen).
-- Nach Drag darf OnMouseUp die Fenster nicht umschalten.
DPSMateMiniMapDragging = nil

function DPSMate_OnMiniMapDragStart()
	DPSMateMiniMapDragging = 1
	local f = DPSMate_MiniMap
	if not f then return end
	if f.LockHighlight then f:LockHighlight() end
	if f.StartMoving then f:StartMoving() end
end

function DPSMate_OnMiniMapDragStop()
	DPSMateMiniMapDragging = 1
	local f = DPSMate_MiniMap
	if f then
		if f.UnlockHighlight then f:UnlockHighlight() end
		if f.StopMovingOrSizing then f:StopMovingOrSizing() end
	end
	if DPSMate and DPSMate.SaveMiniMapPosition then
		DPSMate:SaveMiniMapPosition()
	end
end

function DPSMate_OnMiniMapMouseUp(button)
	if DPSMateMiniMapDragging then
		DPSMateMiniMapDragging = nil
		if DPSMate and DPSMate.SaveMiniMapPosition then
			DPSMate:SaveMiniMapPosition()
		end
		return
	end
	button = button or arg1
	if not DPSMate or not DPSMate.Options then return end
	if button == "LeftButton" then
		if DPSMate.Options.ToggleVisibility then
			DPSMate.Options:ToggleVisibility()
		end
	elseif DPSMate.Options.OpenMenu then
		DPSMate.Options:OpenMenu(3, DPSMate_MiniMap)
	end
end

function DPSMate_ScheduleMiniMapRestore()
	if DPSMateMiniMapRestorePending then return end
	DPSMateMiniMapRestorePending = 1
	local waiter = CreateFrame("Frame")
	local t = 0
	waiter:SetScript("OnUpdate", function(self, elapsed)
		elapsed = elapsed or arg1
		if type(elapsed) ~= "number" then elapsed = 0.05 end
		t = t + elapsed
		if t >= 0.5 then
			waiter:SetScript("OnUpdate", nil)
			DPSMateMiniMapRestorePending = nil
			if DPSMate and DPSMate.RestoreMiniMapPosition then
				pcall(function() DPSMate:RestoreMiniMapPosition() end)
			end
			if DPSMate and DPSMate.ApplyWindowVisibility then
				pcall(function() DPSMate:ApplyWindowVisibility() end)
			end
		end
	end)
end

----------------------------------------------------------------------------------
--------------              SETTINGS-FENSTER (REFERENZ)             --------------
----------------------------------------------------------------------------------

-- Referenz (DPSMate_Options.xml): Backdrop-Farbe r=0.157 g=0.08 b=0.06.
-- XML-<Color> in <Backdrop> wird auf diesem Client nicht angewendet; die Flaeche
-- bleibt dann das ungetoente Tooltip-Grau. Wiki:
-- https://emberveil.org/wiki/lua/widgets/Frame#setbackdropcolor
-- SetBackdropColor existiert, 0-1 floats, no-op ohne Backdrop.
function DPSMate_ApplyDialogColor(frame, alpha)
	if not frame or not frame.SetBackdropColor then return end
	alpha = alpha or 1
	if frame.GetBackdrop and not frame:GetBackdrop() and frame.SetBackdrop then
		frame:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tileSize = 12,
			edgeSize = 12,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
	end
	frame:SetBackdropColor(0.157, 0.08, 0.06, alpha)
end

-- XML-OnClick der Settings-Menuepunkte indizierte fehlende Subbuttons
-- ([string "OnClick"]:4). Logik hier, mit nil-Pruefung.
function DPSMate_ConfigMenuClick()
	local btn = this
	if not btn then return end
	local windows = DPSMateSettings and DPSMateSettings["windows"]
	if type(windows) == "table" then
		for cat, _ in pairs(windows) do
			local i
			for i = 1, 3 do
				local tex = getglobal("DPSMate_ConfigMenu_Menu_Button"..(9+cat).."_Button"..i.."Texture")
				if tex and tex.Hide then tex:Hide() end
			end
		end
	end
	local num = (DPSMate_ConfigMenu and DPSMate_ConfigMenu.num) or 9
	local i
	for i = 1, num do
		local b = getglobal("DPSMate_ConfigMenu_Menu_Button"..i)
		if b then b.selected = false end
		local tex = getglobal("DPSMate_ConfigMenu_Menu_Button"..i.."Texture")
		if tex and tex.Hide then tex:Hide() end
		local text = getglobal("DPSMate_ConfigMenu_Menu_Button"..i.."Text")
		DPSMate_ColorLabel(text, 1, 0.82, 0)
	end
	btn.selected = true
	if btn.Key and DPSMate_ConfigMenu_Menu then
		DPSMate_ConfigMenu_Menu.Key = btn.Key
	end
	local ownTex = btn.GetName and getglobal(btn:GetName().."Texture")
	if ownTex and ownTex.Show then ownTex:Show() end
	local ownText = btn.GetName and getglobal(btn:GetName().."Text")
	DPSMate_ColorLabel(ownText, 1, 1, 1)
	if type(btn.func) == "function" then btn.func() end
end

function DPSMate_ConfigMenuOnShow()
	local f = this or DPSMate_ConfigMenu
	if not f then return end
	DPSMate_ApplyDialogColor(f, 1)
	if f.GetChildren then
		local kids = { f:GetChildren() }
		local i
		for i = 1, table.getn(kids) do
			DPSMate_ApplyDialogColor(kids[i], 0.5)
		end
	end
	DPSMate_RebuildWindowMenuButtons()
	if DPSMate and DPSMate.Options and DPSMate.Options.RefreshWindowDropDowns then
		DPSMate.Options:RefreshWindowDropDowns()
	end
end

----------------------------------------------------------------------------------
--------------          LINKE FENSTER-LISTE (OHNE XML-VORLAGE)      --------------
----------------------------------------------------------------------------------

-- Referenz: unter "Window" steht je Statusfenster ein Eintrag plus Expand
-- (Bars / Title bar / Content). CreateFrame(..., "DPSMate_Template_WindowButton")
-- legt auf diesem Client die XML-Kinder nicht an; die Liste blieb leer und
-- RemoveWindow indizierte nil. Wiki: CreateFrame("Button") plus SetText/SetFont.
-- https://emberveil.org/wiki/lua/widgets/Button
-- https://emberveil.org/wiki/lua/conventions  (CreateFrame-Typen)

function DPSMate_ColorLabel(fs, r, g, b)
	if not fs then return end
	-- SetTextColor schreibt auf diesem Client in das geteilte Font-Objekt.
	-- SetVertexColor faerbt nur diese FontString.
	-- https://emberveil.org/wiki/lua/widgets/FontString#settextcolor
	if fs.SetVertexColor then
		fs:SetVertexColor(r, g, b, 1)
	elseif fs.SetTextColor then
		fs:SetTextColor(r, g, b, 1)
	end
end

local function DPSMate_LabelButton(btn, caption, indent)
	if not btn or not btn.CreateFontString then return end
	local name = btn.GetName and btn:GetName()
	local fsName = name and (name.."Text") or nil
	local fs = fsName and getglobal(fsName)
	if not fs then
		-- Button:SetText erzeugt ein zentriertes Default-Label (Wiki Button).
		-- Referenz-XML: GameFontNormalSmall, justifyH LEFT, Offset x=3 bzw. 18.
		fs = btn:CreateFontString(fsName, "OVERLAY", "GameFontNormalSmall")
	end
	local stock = btn.GetFontString and btn:GetFontString()
	if stock and stock ~= fs then
		stock:SetText("")
		if stock.Hide then stock:Hide() end
	end
	fs:ClearAllPoints()
	fs:SetWidth(120)
	fs:SetHeight(14)
	fs:SetPoint("TOPLEFT", btn, "TOPLEFT", indent or 3, 0)
	if fs.SetJustifyH then fs:SetJustifyH("LEFT") end
	if fs.SetJustifyV then fs:SetJustifyV("CENTER") end
	fs:SetText(caption or "")
	DPSMate_ColorLabel(fs, 1, 0.82, 0)
end

function DPSMate_SwitchConfigTab(suffix, key)
	local menu = DPSMate_ConfigMenu_Menu
	if not menu then return end
	if menu.selected then
		local cur = getglobal("DPSMate_ConfigMenu"..menu.selected)
		if cur and cur.Hide then cur:Hide() end
	end
	local tab = getglobal("DPSMate_ConfigMenu"..suffix)
	if tab and tab.Show then tab:Show() end
	menu.selected = suffix
	if key then menu.Key = key end
end

local function DPSMate_CollapseWindowRows()
	local windows = DPSMateSettings and DPSMateSettings["windows"]
	if type(windows) ~= "table" then return end
	local cat
	for cat, _ in pairs(windows) do
		local base = "DPSMate_ConfigMenu_Menu_Button"..(9+cat)
		local f = getglobal(base)
		local exp = getglobal(base.."Expand")
		local col = getglobal(base.."Collapse")
		if exp then exp:Show() end
		if col then col:Hide() end
		local i
		for i = 1, 3 do
			local s = getglobal(base.."_Button"..i)
			if s then s:Hide() end
		end
		if f and f.after then
			f.after:ClearAllPoints()
			f.after:SetPoint("TOP", f, "BOTTOM")
		end
	end
end

function DPSMate_EnsureWindowMenuButton(cat, winName)
	if not DPSMate_ConfigMenu_Menu or not cat then return end
	local name = "DPSMate_ConfigMenu_Menu_Button"..(9+cat)
	local f = getglobal(name)
	if not f then
		f = CreateFrame("Button", name, DPSMate_ConfigMenu_Menu)
		f:SetWidth(120)
		f:SetHeight(14)
		if f.EnableMouse then f:EnableMouse(true) end
		if f.SetHighlightTexture then
			f:SetHighlightTexture("Interface\\AddOns\\DPSMate\\images\\UI-Listbox-Highlight2")
		end
		f:SetScript("OnEnter", function(frame)
			if frame then this = frame end
			local fs = this and this.GetName and getglobal(this:GetName().."Text")
			DPSMate_ColorLabel(fs, 1, 1, 1)
		end)
		f:SetScript("OnLeave", function(frame)
			if frame then this = frame end
			if this and not this.selected then
				local fs = this.GetName and getglobal(this:GetName().."Text")
				DPSMate_ColorLabel(fs, 1, 0.82, 0)
			end
		end)
		f:SetScript("OnClick", function(frame)
			if frame then this = frame end
			if this then this.func = this.func or function()
				DPSMate_SwitchConfigTab("_Tab_Window", this.Key)
			end end
			DPSMate_ConfigMenuClick()
		end)

		local exp = CreateFrame("Button", name.."Expand", f)
		exp:SetWidth(16)
		exp:SetHeight(16)
		exp:SetPoint("RIGHT", f, "RIGHT", 0, 0)
		if exp.SetNormalTexture then
			exp:SetNormalTexture("Interface\\AddOns\\DPSMate\\images\\UI-Panel-ExpandButton-Up")
		end
		if exp.SetPushedTexture then
			exp:SetPushedTexture("Interface\\AddOns\\DPSMate\\images\\UI-Panel-ExpandButton-Down")
		end
		exp:SetScript("OnClick", function(frame)
			if frame then this = frame end
			local parent = this and this.GetParent and this:GetParent()
			if not parent then return end
			DPSMate_CollapseWindowRows()
			this:Hide()
			local col = getglobal(parent:GetName().."Collapse")
			if col then col:Show() end
			local i
			for i = 1, 3 do
				local s = getglobal(parent:GetName().."_Button"..i)
				if s then s:Show() end
			end
			if parent.after then
				parent.after:ClearAllPoints()
				parent.after:SetPoint("TOP", parent, "BOTTOM", 0, -42)
			end
			if DPSMate_ConfigMenu_Menu then DPSMate_ConfigMenu_Menu.Key = parent.Key end
		end)

		local col = CreateFrame("Button", name.."Collapse", f)
		col:SetWidth(16)
		col:SetHeight(16)
		col:SetPoint("RIGHT", f, "RIGHT", 0, 0)
		col:Hide()
		if col.SetNormalTexture then
			col:SetNormalTexture("Interface\\AddOns\\DPSMate\\images\\UI-Panel-CollapseButton-Up")
		end
		if col.SetPushedTexture then
			col:SetPushedTexture("Interface\\AddOns\\DPSMate\\images\\UI-Panel-CollapseButton-Down")
		end
		col:SetScript("OnClick", function(frame)
			if frame then this = frame end
			local parent = this and this.GetParent and this:GetParent()
			if not parent then return end
			this:Hide()
			local expb = getglobal(parent:GetName().."Expand")
			if expb then expb:Show() end
			local i
			for i = 1, 3 do
				local s = getglobal(parent:GetName().."_Button"..i)
				if s then s:Hide() end
			end
			if parent.after then
				parent.after:ClearAllPoints()
				parent.after:SetPoint("TOP", parent, "BOTTOM")
			end
		end)

		local subInfo = {
			{ suffix = "_Tab_Bars", caption = "Bars" },
			{ suffix = "_Tab_TitleBar", caption = "Title bar" },
			{ suffix = "_Tab_Content", caption = "Content" },
		}
		local i
		for i = 1, 3 do
			local sub = CreateFrame("Button", name.."_Button"..i, f)
			sub:SetWidth(120)
			sub:SetHeight(14)
			if i == 1 then
				sub:SetPoint("TOP", f, "BOTTOM")
			else
				sub:SetPoint("TOP", getglobal(name.."_Button"..(i-1)), "BOTTOM")
			end
			sub:Hide()
			DPSMate_LabelButton(sub, subInfo[i].caption, 18)
			if sub.SetHighlightTexture then
				sub:SetHighlightTexture("Interface\\AddOns\\DPSMate\\images\\UI-Listbox-Highlight2")
			end
			sub.tabSuffix = subInfo[i].suffix
			sub:SetScript("OnClick", function(frame)
				if frame then this = frame end
				if not this then return end
				local parent = this.GetParent and this:GetParent()
				local key = parent and parent.Key
				DPSMate_SwitchConfigTab(this.tabSuffix, key)
			end)
		end
	end
	f.Key = cat
	f.func = function()
		DPSMate_SwitchConfigTab("_Tab_Window", this and this.Key)
	end
	DPSMate_LabelButton(f, winName or ("Window "..cat), 3)
	f:Show()
	return f
end

function DPSMate_RelayoutWindowMenu()
	local last = DPSMate_ConfigMenu_Menu_Button1
	local n = 0
	local windows = DPSMateSettings and DPSMateSettings["windows"]
	if type(windows) == "table" then
		local cat, val
		for cat, val in pairs(windows) do
			local f = getglobal("DPSMate_ConfigMenu_Menu_Button"..(9+cat))
			if f then
				f:ClearAllPoints()
				if last then f:SetPoint("TOP", last, "BOTTOM") end
				if last then last.after = f end
				last = f
				n = n + 1
			end
		end
	end
	if last then last.after = DPSMate_ConfigMenu_Menu_Button2 end
	if DPSMate_ConfigMenu_Menu_Button2 then
		DPSMate_ConfigMenu_Menu_Button2:ClearAllPoints()
		if last then
			DPSMate_ConfigMenu_Menu_Button2:SetPoint("TOP", last, "BOTTOM")
		end
	end
	if DPSMate_ConfigMenu then DPSMate_ConfigMenu.num = 9 + n end
end

function DPSMate_RebuildWindowMenuButtons()
	local i
	for i = 10, 24 do
		local f = getglobal("DPSMate_ConfigMenu_Menu_Button"..i)
		if f then f:Hide() end
	end
	local windows = DPSMateSettings and DPSMateSettings["windows"]
	if type(windows) == "table" then
		local cat, val
		for cat, val in pairs(windows) do
			if val then
				DPSMate_EnsureWindowMenuButton(cat, val["name"])
			end
		end
	end
	DPSMate_RelayoutWindowMenu()
end

----------------------------------------------------------------------------------
--------------              SCHUTZ VOR FEHLENDEN DATEIEN            --------------
----------------------------------------------------------------------------------

-- Dieser Client fuehrt einzelne Lua-Dateien der .toc nicht aus. Fehlt dadurch
-- eine Funktion, gab es bei jedem Aufruf ein Fehlerfenster. Siehe
-- EMBERVEIL-BUG.md fuer die Analyse.
--
-- DPSMATE_NULL ist sowohl aufrufbar als auch weiter indexierbar, deckt also
-- X:Method() und X.Y:Method() gleichermassen ab.
DPSMATE_MISSING = {}

-- Der Rueckgabewert muss weiterverwendbar sein: Aufrufe wie
--   DPSMate.Options:FormatTime(cbt) .. "]"
-- haben mit einem nil-Rueckgabewert nur einen anderen Fehler erzeugt
-- ("attempt to concatenate a nil value"). Deshalb liefert der Aufruf wieder
-- DPSMATE_NULL, und das Objekt verhaelt sich in Verkettung wie "" und in
-- Rechnungen wie 0.
DPSMATE_NULL = nil
local function nullconcat(a, b)
	if a == DPSMATE_NULL then a = "" end
	if b == DPSMATE_NULL then b = "" end
	return tostring(a) .. tostring(b)
end
local function nullnum() return 0 end
DPSMATE_NULL = setmetatable({}, {
	__call = function() return DPSMATE_NULL end,
	__index = function() return DPSMATE_NULL end,
	__newindex = function() end,
	__tostring = function() return "" end,
	__concat = nullconcat,
	__add = nullnum, __sub = nullnum, __mul = nullnum, __div = nullnum,
	__unm = nullnum, __lt = function() return false end,
	__le = function() return false end,
})

-- Nur auf Tabellen anwenden, deren Inhalt ausschliesslich Funktionen/Untertabellen
-- sind. Auf DPSMate.DB und .Parser bewusst NICHT: dort wuerde ein truthy-Ersatz
-- fuer Datenfelder wie DB.loaded die Logik verfaelschen statt sie zu retten.
function DPSMate_GuardTable(t, label)
	if type(t) ~= "table" then return t end
	setmetatable(t, {
		__index = function(_, k)
			DPSMATE_MISSING[label .. "." .. tostring(k)] = true
			return DPSMATE_NULL
		end,
	})
	return t
end

----------------------------------------------------------------------------------
--------------                 LIBRARY LOOKUPS                      --------------
----------------------------------------------------------------------------------

-- AceLibrary(major) raises when a library failed to register, and because that
-- happens at file scope it kills the rest of the file. Losing DPSMate.lua line 9
-- or DPSMate_Options.lua line 64 that way leaves DPSMate.Options / .Options.Options
-- nil, and then all ~60 module files fail on their first statement -- one error
-- popup each, none of which names the real cause.
--
-- Bibliothek nachschlagen, ohne dass ein Fehlschlag die restliche Datei
-- mitreisst.
DPSMATE_LIBFAIL = {}

DPSMATE_LIBERR = {}

function DPSMate_GetLib(major, fallback)
	local why = "AceLibrary global is missing"
	if AceLibrary then
		local ok, lib = pcall(AceLibrary, major)
		if ok and lib then return lib end
		why = tostring(lib)
	end
	table.insert(DPSMATE_LIBFAIL, major)
	-- Keep AceLibrary's own message; it says whether the library was never
	-- registered or something else went wrong.
	table.insert(DPSMATE_LIBERR, major .. " -> " .. why)
	return fallback
end

-- DPSMate.L is only ever indexed (DPSMate.L["key"]), never called as an
-- AceLocale object, and localization/enUS.lua fills it in by plain assignment.
-- A table is all it ever needed. Unknown keys return the key itself so a missing
-- translation shows up as visible text instead of erroring on the next
-- concatenation.
function DPSMate_NewLocaleTable()
	return setmetatable({}, { __index = function(_, k) return k end })
end

----------------------------------------------------------------------------------
--------------                   ADDON LOADING                      --------------
----------------------------------------------------------------------------------

-- GetAddOnInfo and LoadAddOn are protected, so demand-loading another addon is
-- not something DPSMate can do here. AceLibrary asks before scanning for
-- standalone library copies; every library DPSMate uses is embedded, so the
-- answer is simply no.
function DPSMate_CanLoadAddOns()
	return false
end

----------------------------------------------------------------------------------
--------------                     CHAT SENDING                     --------------
----------------------------------------------------------------------------------

-- FrameXML's ChatEdit_SendText is the supported way to get a line out: it runs
-- inside the default UI, so its own SendChatMessage call is permitted.
--
-- Lines are queued and drained on a timer. A DPSMate report is up to 40 lines
-- and pushing them through the edit box in a single frame gets the player
-- disconnected for flooding.

local QUEUE = {}
local INTERVAL = 0.4
local pumpFrame

-- chatType -> the SLASH_* global holding this client's own token for it. Taking
-- the token from the client (rather than hardcoding "/raid") keeps this correct
-- on non-enUS clients, where the localized token is what ChatEdit_ParseText
-- recognises.
local SLASH_GLOBAL = {
	["SAY"] = "SLASH_SAY",
	["YELL"] = "SLASH_YELL",
	["PARTY"] = "SLASH_PARTY",
	["RAID"] = "SLASH_RAID",
	["RAID_WARNING"] = "SLASH_RAID_WARNING",
	["GUILD"] = "SLASH_GUILD",
	["OFFICER"] = "SLASH_OFFICER",
	["BATTLEGROUND"] = "SLASH_BATTLEGROUND",
	["WHISPER"] = "SLASH_WHISPER",
}

local function SlashToken(chatType)
	local base = SLASH_GLOBAL[chatType]
	if not base then return nil end
	-- SLASH_RAID1, SLASH_RAID2, ... the first defined one is this locale's token.
	for i = 1, 8 do
		local tok = getglobal(base .. i)
		if tok and tok ~= "" then return tok end
	end
	return nil
end

-- Turn a SendChatMessage argument list into the single line the edit box needs.
local function BuildLine(msg, chatType, channel)
	msg = tostring(msg or "")
	-- A leading slash in the payload would be parsed as a command.
	if strsub(msg, 1, 1) == "/" then msg = " " .. msg end

	if chatType == "CHANNEL" then
		-- ChatEdit_ParseText expands /1 .. /9 to the joined channel's name.
		-- GetChannelName returns no values for a channel we are not in, so the
		-- caller's index can be nil; 0 is likewise not a joined channel.
		local n = tonumber(channel)
		if n and n >= 1 then
			return "/" .. n .. " " .. msg
		end
		return nil
	end

	local tok = SlashToken(chatType)
	if not tok then return nil end

	if chatType == "WHISPER" then
		if not channel or channel == "" then return nil end
		return tok .. " " .. channel .. " " .. msg
	end
	return tok .. " " .. msg
end

local function SendNow(entry)
	local box = ChatFrameEditBox
	if not (box and box.SetText and type(ChatEdit_SendText) == "function") then
		-- No usable edit box (very early login, or a replacement chat addon).
		-- Show the line locally rather than dropping it silently.
		if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(entry.line) end
		return
	end

	-- Preserve whatever the player was typing, and the box's own target state.
	local prevText, prevType = "", box.chatType
	if box.GetText then prevText = box:GetText() or "" end
	local prevTell, prevChannel = box.tellTarget, box.channelTarget

	-- Set the target fields too, so the line still lands correctly if this
	-- client's ChatEdit_SendText honours them instead of re-parsing the slash.
	box.chatType = entry.chatType
	if entry.chatType == "WHISPER" then
		box.tellTarget = entry.channel
	elseif entry.chatType == "CHANNEL" then
		box.channelTarget = entry.channel
	end

	box:SetText(entry.line)
	-- nil, not 0, for addHistory: 0 is truthy in Lua, and a 40-line report has
	-- no business filling up the player's chat history.
	ChatEdit_SendText(box, nil)

	box:SetText(prevText)
	box.chatType = prevType
	box.tellTarget = prevTell
	box.channelTarget = prevChannel
end

local function Pump()
	-- 1.12 OnUpdate delivers the frame delta in arg1.
	local elapsed = arg1
	if not elapsed then
		local now = GetTime()
		elapsed = now - (pumpFrame.last or now)
		pumpFrame.last = now
	end
	if elapsed < 0 then elapsed = 0 end

	pumpFrame.wait = (pumpFrame.wait or 0) + elapsed
	if pumpFrame.wait < INTERVAL then return end
	pumpFrame.wait = 0

	local entry = tremove(QUEUE, 1)
	if not entry then
		pumpFrame:SetScript("OnUpdate", nil)
		return
	end
	SendNow(entry)
end

-- Drop-in replacement for SendChatMessage, same argument order. `language` is
-- accepted for call-site compatibility and ignored: the edit box path always
-- uses the player's default language, which is what every DPSMate call site
-- passed (nil) anyway.
function DPSMate_SendChat(msg, chatType, language, channel)
	chatType = chatType or "SAY"

	local line = BuildLine(msg, chatType, channel)
	if not line then
		-- Unsupported destination (e.g. a channel we could not resolve to a
		-- number). Keep the text visible to the player instead of losing it.
		if DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage(tostring(msg or ""))
		end
		return
	end

	tinsert(QUEUE, { line = line, chatType = chatType, channel = channel })

	if not pumpFrame then
		pumpFrame = CreateFrame("Frame", "DPSMateChatQueue")
	end
	if not pumpFrame:GetScript("OnUpdate") then
		pumpFrame.wait = INTERVAL   -- send the first line on the next frame
		pumpFrame.last = GetTime()
		pumpFrame:SetScript("OnUpdate", Pump)
	end
end
