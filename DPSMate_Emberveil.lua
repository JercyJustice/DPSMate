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

-- Lua 5.1 hat string.gfind in string.gmatch umbenannt. Die Parser-Dateien
-- machen `local strgfind = string.gfind` beim Laden; ohne Alias ist jeder
-- Combat-Log-Treffer `attempt to call a nil value` (in pcall verschluckt),
-- die Balken bleiben leer, die Combatzeit laeuft trotzdem.
-- https://emberveil.org/wiki/lua/conventions  (Lua 5.1)
if type(string.gfind) ~= "function" and type(string.gmatch) == "function" then
	string.gfind = string.gmatch
end

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

-- UIPanelButtonTemplate kopiert hier oft weder Textur noch FontString.
-- Button:SetText / SetFont / SetBackdrop sind dokumentiert.
-- https://emberveil.org/wiki/lua/widgets/Button#settext
function DPSMate_StylePanelButton(btn, caption)
	if not btn then return end
	local function hideTex(tex)
		if tex and tex.Hide then tex:Hide() end
	end
	if btn.GetNormalTexture then hideTex(btn:GetNormalTexture()) end
	if btn.GetPushedTexture then hideTex(btn:GetPushedTexture()) end
	if btn.GetHighlightTexture then hideTex(btn:GetHighlightTexture()) end
	if btn.SetBackdrop then
		btn:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tileSize = 8,
			edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		if btn.SetBackdropColor then btn:SetBackdropColor(0.20, 0.10, 0.08, 1) end
		if btn.SetBackdropBorderColor then btn:SetBackdropBorderColor(0.70, 0.55, 0.20, 1) end
	end
	if btn.SetFont then btn:SetFont("Fonts\\FRIZQT__.TTF", 12) end
	if caption and btn.SetText then btn:SetText(caption) end
	if btn.SetTextColor then btn:SetTextColor(1, 0.82, 0, 1) end
	local fs = btn.GetFontString and btn:GetFontString()
	if fs then
		if fs.SetJustifyH then fs:SetJustifyH("CENTER") end
		if fs.SetVertexColor then fs:SetVertexColor(1, 0.82, 0, 1) end
	end
	local named = btn.GetName and getglobal(btn:GetName().."Text")
	if named and caption and named.SetText then
		named:SetText(caption)
		if named.SetVertexColor then named:SetVertexColor(1, 0.82, 0, 1) end
	end
end

-- SetAlpha kopiert auf diesem Client nur auf Texturen/FontStrings DIESES
-- Objekts, nicht auf Kind-Frames. Deshalb Baum + Backdrop-Alpha.
-- https://emberveil.org/wiki/lua/widgets/UIObject#setalpha
-- https://emberveil.org/wiki/lua/widgets/Frame#setbackdropbordercolor
local function DPSMate_ApplyAlphaTree(obj, a)
	if not obj then return end
	if obj.SetAlpha then obj:SetAlpha(a) end
	if obj.GetRegions then
		local regs = { obj:GetRegions() }
		local i
		for i = 1, table.getn(regs) do
			if regs[i] and regs[i].SetAlpha then regs[i]:SetAlpha(a) end
		end
	end
	if obj.GetChildren then
		local kids = { obj:GetChildren() }
		local i
		for i = 1, table.getn(kids) do
			DPSMate_ApplyAlphaTree(kids[i], a)
		end
	end
end

function DPSMate_RepairWindowSettings(win)
	if type(win) ~= "table" then return end
	-- Slider-Fill hat OnValueChanged mit GetValue()=Min ausgeloest und
	-- Opacity 0 / Fontsize 1 gespeichert. Einmalig zuruecksetzen.
	if type(win["barfontsize"]) ~= "number" or win["barfontsize"] < 8 then
		win["barfontsize"] = 14
	end
	if type(win["titlebarfontsize"]) ~= "number" or win["titlebarfontsize"] < 8 then
		win["titlebarfontsize"] = 12
	end
	if win["titlebaropacity"] == 0 then win["titlebaropacity"] = 1 end
	if win["bgopacity"] == 0 then win["bgopacity"] = 1 end
	if win["opacity"] == 0 then win["opacity"] = 1 end
end

function DPSMate_ApplyWindowAlphas(win)
	if type(win) ~= "table" or not win["name"] then return end
	local o = win["opacity"]
	if type(o) ~= "number" then o = 1 end
	if o < 0 then o = 0 end
	if o > 1 then o = 1 end
	local name = win["name"]
	local frame = getglobal("DPSMate_"..name)
	if not frame then return end
	DPSMate_ApplyAlphaTree(frame, o)
	local function A(obj, a)
		if obj and obj.SetAlpha then obj:SetAlpha(a) end
	end
	local tb = win["titlebaropacity"]
	if type(tb) ~= "number" then tb = 1 end
	A(getglobal("DPSMate_"..name.."_Head_Background"), tb * o)
	local bg = win["bgopacity"]
	if type(bg) ~= "number" then bg = 1 end
	A(getglobal("DPSMate_"..name.."_ScrollFrame_Background"), bg * o)
	local bo = win["borderopacity"]
	if type(bo) ~= "number" then bo = 1 end
	local border = getglobal("DPSMate_"..name.."_Border")
	A(border, bo * o)
	if border and border.SetBackdropBorderColor then
		local c = win["contentbordercolor"]
		if type(c) ~= "table" then c = { 0, 0, 0 } end
		border:SetBackdropBorderColor(c[1], c[2], c[3], bo * o)
	end
end

function DPSMate_OnWindowAlphaSlider(var)
	local win = DPSMate_CurrentWindow()
	if not win or not var then return end
	local s = this
	local v = s and s.GetValue and s:GetValue()
	if type(v) ~= "number" then return end
	win[var] = v
	DPSMate_ApplyWindowAlphas(win)
end

-- FontString:SetFont tut hier nichts, solange ein Font-Objekt haengt
-- (XML inherits="TextStatusBarText"). Groesse geht nur ueber CreateFont
-- plus Font:SetFont plus FontString:SetFontObject. Flags werden ignoriert.
-- https://emberveil.org/wiki/lua/widgets/FontString#setfont
-- https://emberveil.org/wiki/lua/widgets/Font#setfont
-- https://emberveil.org/wiki/lua/globals/Frame#createfont
local function DPSMate_FontKey(s)
	return string.gsub(tostring(s or "x"), "[^%w]", "_")
end

function DPSMate_ApplyFontString(fs, key, path, size, color, layer, justify)
	if not fs then return end
	if type(size) ~= "number" or size < 1 then size = 12 end
	if type(path) ~= "string" or path == "" then path = "Fonts\\FRIZQT__.TTF" end
	local fname = "DPSMate_Font_"..DPSMate_FontKey(key).."_"..math.floor(size)
	local font = getglobal(fname)
	if not font and CreateFont then
		font = CreateFont(fname)
	end
	-- Erst eine geladene Face kopieren, dann Groesse setzen. SetFont ohne
	-- geladene Face ist No-Op; ohne Seed waere der Titel leer.
	-- https://emberveil.org/wiki/lua/widgets/Font#setfont
	if font and font.SetFontObject then
		if GameFontNormalSmall then
			font:SetFontObject(GameFontNormalSmall)
		elseif GameFontNormal then
			font:SetFontObject(GameFontNormal)
		end
	end
	if font and font.SetFont then
		font:SetFont(path, size)
	end
	if font and fs.SetFontObject then
		fs:SetFontObject(font)
	end
	if layer and fs.SetDrawLayer then fs:SetDrawLayer(layer) end
	if justify then
		if fs.SetJustifyH then fs:SetJustifyH(justify) end
		local fo = fs.GetFontObject and fs:GetFontObject()
		if fo and fo.SetJustifyH then fo:SetJustifyH(justify) end
	end
	if type(color) == "table" and fs.SetVertexColor then
		fs:SetVertexColor(color[1], color[2], color[3], 1)
	end
end

function DPSMate_ApplyWindowFonts(win)
	if type(win) ~= "table" or not win["name"] then return end
	local opt = DPSMate and DPSMate.Options
	local fonts = opt and opt.fonts
	local path = (fonts and fonts[win["barfont"]]) or "Fonts\\FRIZQT__.TTF"
	local size = win["barfontsize"]
	local color = win["barfontcolor"] or {1, 1, 1}
	local name = win["name"]
	-- Getrennte Font-Objekte: SetJustifyH schreibt sonst in dasselbe Font
	-- und Name/Wert bekommen dieselbe Ausrichtung.
	local keyL = "barL_"..name
	local keyR = "barR_"..name
	DPSMate_ApplyFontString(getglobal("DPSMate_"..name.."_ScrollFrame_Child_Total_Name"), keyL, path, size, color, "OVERLAY", "LEFT")
	DPSMate_ApplyFontString(getglobal("DPSMate_"..name.."_ScrollFrame_Child_Total_Value"), keyR, path, size, color, "OVERLAY", "RIGHT")
	local i
	for i = 1, 40 do
		DPSMate_ApplyFontString(getglobal("DPSMate_"..name.."_ScrollFrame_Child_StatusBar"..i.."_Name"), keyL, path, size, color, "OVERLAY", "LEFT")
		DPSMate_ApplyFontString(getglobal("DPSMate_"..name.."_ScrollFrame_Child_StatusBar"..i.."_Value"), keyR, path, size, color, "OVERLAY", "RIGHT")
	end
	local tpath = (fonts and fonts[win["titlebarfont"]]) or "Fonts\\FRIZQT__.TTF"
	local tsize = win["titlebarfontsize"]
	local tcolor = win["titlebarfontcolor"] or {1, 0.82, 0}
	DPSMate_ApplyFontString(getglobal("DPSMate_"..name.."_Head_Font"), "title_"..name, tpath, tsize, tcolor, "ARTWORK", "LEFT")
end

function DPSMate_OnBarFontSizeSlider()
	local win = DPSMate_CurrentWindow()
	if not win then return end
	local v = this and this.GetValue and this:GetValue()
	if type(v) == "number" then win["barfontsize"] = v end
	DPSMate_ApplyWindowFonts(win)
end

function DPSMate_OnTitleBarFontSizeSlider()
	local win = DPSMate_CurrentWindow()
	if not win then return end
	local v = this and this.GetValue and this:GetValue()
	if type(v) == "number" then win["titlebarfontsize"] = v end
	DPSMate_ApplyWindowFonts(win)
end

function DPSMate_OnConfigSliderChanged(frame)
	if frame then this = frame end
	if not this then return end
	local edit = this.GetName and getglobal(this:GetName().."_Editbox")
	if edit and edit.SetText and this.GetValue then
		local v = this:GetValue()
		if type(v) == "number" then
			edit:SetText(string.format("%.1f", v))
		end
	end
	-- FillSetValue loest OnValueChanged aus. Ohne diese Sperre wuerde
	-- GetValue() (oft 0/Min) die gespeicherten Settings ueberschreiben.
	if DPSMate_SliderFilling then return end
	if type(this.func) == "function" then
		pcall(this.func)
	end
end

-- ColorPickerFrame ist ColorSelect. Das Farbrad (ColorWheelTexture) zeichnet
-- dieser Client nicht; CreateFrame("ColorSelect") ist laut Wiki verboten.
-- https://emberveil.org/wiki/lua/widgets/ColorSelect
-- https://emberveil.org/wiki/lua/conventions#widget-methods
-- Ersatz: Palette (Buttons) + RGB-Slider (CreateFrame Slider/Button/Frame).
local colorPick = { r = 1, g = 1, b = 1, prevR = 1, prevG = 1, prevB = 1 }
local colorPickBusy

local function HSVToRGB(h, s, v)
	if h < 0 then h = h + 360 end
	if h >= 360 then h = h - 360 end
	local c = v * s
	local hp = h / 60
	local x = c * (1 - math.abs(hp - 2 * math.floor(hp / 2) - 1))
	local m = v - c
	local r, g, b = 0, 0, 0
	if hp < 1 then r, g, b = c, x, 0
	elseif hp < 2 then r, g, b = x, c, 0
	elseif hp < 3 then r, g, b = 0, c, x
	elseif hp < 4 then r, g, b = 0, x, c
	elseif hp < 5 then r, g, b = x, 0, c
	else r, g, b = c, 0, x end
	return r + m, g + m, b + m
end

local function ColorPickSolid(tex, r, g, b)
	if not tex then return end
	if tex.SetTexture then
		tex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	end
	if tex.SetVertexColor then tex:SetVertexColor(r, g, b, 1) end
end

local function ColorPickApplySwatch(r, g, b)
	local obj = colorPick.obj
	if not obj or not obj.GetName then return end
	local n = obj:GetName()
	local swatch = getglobal(n.."NormalTexture")
	local bg = getglobal(n.."_SwatchBg")
	if swatch and swatch.SetVertexColor then swatch:SetVertexColor(r, g, b) end
	if bg and bg.SetVertexColor then bg:SetVertexColor(r, g, b) end
	if bg then
		bg.r, bg.g, bg.b = r, g, b
	end
end

local function ColorPickCommit(r, g, b)
	colorPick.r, colorPick.g, colorPick.b = r, g, b
	local key = DPSMate_ConfigMenu_Menu and DPSMate_ConfigMenu_Menu.Key
	if key and DPSMateSettings and DPSMateSettings["windows"] and DPSMateSettings["windows"][key] and colorPick.var then
		DPSMateSettings["windows"][key][colorPick.var] = { r, g, b }
	end
	ColorPickApplySwatch(r, g, b)
	if type(colorPick.rfunc) == "function" then
		pcall(colorPick.rfunc)
	end
end

local function PinXY(region, parent, x, y, w, h)
	if not region then return end
	if region.ClearAllPoints then region:ClearAllPoints() end
	if region.SetPoint then
		region:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	end
	if w and region.SetWidth then region:SetWidth(w) end
	if h and region.SetHeight then region:SetHeight(h) end
end

local function ColorPickCursor()
	local x, y = GetCursorPosition()
	if type(x) ~= "number" then return end
	local scale = 1
	if UIParent and UIParent.GetEffectiveScale then
		local s = UIParent:GetEffectiveScale()
		if type(s) == "number" and s > 0 then scale = s end
	end
	return x / scale, y / scale
end

local function ColorPickPlaceThumb(s)
	if not s then return end
	local thumb = colorPick.thumbs and colorPick.thumbs[s]
	local width = colorPick.sliderW or 150
	if not thumb then return end
	local v = 0
	if s.GetValue then v = s:GetValue() or 0 end
	local x = (v / 100) * (width - 10)
	if x < 0 then x = 0 end
	PinXY(thumb, s, x, -2, 10, 18)
end

local function ColorPickPlaceAllThumbs()
	ColorPickPlaceThumb(colorPick.sR)
	ColorPickPlaceThumb(colorPick.sG)
	ColorPickPlaceThumb(colorPick.sB)
end

local function ColorPickSyncSliders(r, g, b)
	colorPickBusy = 1
	if colorPick.sR then colorPick.sR:SetValue(math.floor(r * 100 + 0.5)) end
	if colorPick.sG then colorPick.sG:SetValue(math.floor(g * 100 + 0.5)) end
	if colorPick.sB then colorPick.sB:SetValue(math.floor(b * 100 + 0.5)) end
	if colorPick.preview then ColorPickSolid(colorPick.preview, r, g, b) end
	ColorPickPlaceAllThumbs()
	colorPickBusy = nil
end

local function ColorPickFromSliders()
	if colorPickBusy then return end
	local r = (colorPick.sR and colorPick.sR:GetValue() or 0) / 100
	local g = (colorPick.sG and colorPick.sG:GetValue() or 0) / 100
	local b = (colorPick.sB and colorPick.sB:GetValue() or 0) / 100
	if colorPick.preview then ColorPickSolid(colorPick.preview, r, g, b) end
	ColorPickPlaceAllThumbs()
	ColorPickCommit(r, g, b)
end

local function ColorPickSliderFromCursor(s)
	if not s or not s.GetLeft then return end
	local cx = ColorPickCursor()
	if not cx then return end
	local left, w = s:GetLeft(), s:GetWidth()
	if type(left) ~= "number" or type(w) ~= "number" or w < 1 then return end
	local pct = (cx - left) / w
	if pct < 0 then pct = 0 end
	if pct > 1 then pct = 1 end
	s:SetValue(pct * 100)
end

local function ColorPickHitSlider()
	local cx, cy = ColorPickCursor()
	if not cx then return end
	local list = { colorPick.sR, colorPick.sG, colorPick.sB }
	local i
	for i = 1, 3 do
		local s = list[i]
		if s and s.GetLeft then
			local L, B, W, H = s:GetLeft(), s:GetBottom(), s:GetWidth(), s:GetHeight()
			if type(L) == "number" and type(B) == "number" and type(W) == "number" and type(H) == "number" then
				if cx >= L and cx <= L + W and cy >= B - 4 and cy <= B + H + 4 then
					return s
				end
			end
		end
	end
end

local function MakeSwatch(parent, x, y, size, rr, gg, bb)
	local btn = CreateFrame("Button", nil, parent)
	if btn.EnableMouse then btn:EnableMouse(true) end
	PinXY(btn, parent, x, y, size, size)
	local tex = btn:CreateTexture(nil, "ARTWORK")
	PinXY(tex, btn, 0, 0, size, size)
	ColorPickSolid(tex, rr, gg, bb)
	btn:SetScript("OnClick", function()
		ColorPickSyncSliders(rr, gg, bb)
		ColorPickCommit(rr, gg, bb)
	end)
	return btn
end

local function MakeSlider(parent, x, y, w, label, color)
	local lab = parent:CreateFontString(nil, "OVERLAY")
	if lab then
		if lab.SetFont then lab:SetFont("Fonts\\FRIZQT__.TTF", 12) end
		PinXY(lab, parent, x, y, 16, 16)
		if lab.SetText then lab:SetText(label) end
		if lab.SetTextColor then lab:SetTextColor(1, 0.82, 0) end
		if lab.SetJustifyH then lab:SetJustifyH("LEFT") end
	end
	local s = CreateFrame("Slider", nil, parent)
	if s.EnableMouse then s:EnableMouse(true) end
	if s.EnableMouseWheel then s:EnableMouseWheel(true) end
	if s.Enable then s:Enable() end
	if parent.GetFrameLevel and s.SetFrameLevel then
		s:SetFrameLevel(parent:GetFrameLevel() + 6)
	end
	PinXY(s, parent, x + 18, y, w, 20)
	if s.SetOrientation then s:SetOrientation("HORIZONTAL") end
	if s.SetMinMaxValues then s:SetMinMaxValues(0, 100) end
	if s.SetValueStep then s:SetValueStep(1) end
	local track = s:CreateTexture(nil, "BACKGROUND")
	PinXY(track, s, 0, -7, w, 6)
	ColorPickSolid(track, color[1], color[2], color[3])
	local thumb = s:CreateTexture(nil, "OVERLAY")
	ColorPickSolid(thumb, 1, 1, 1)
	if s.SetThumbTexture then s:SetThumbTexture(thumb) end
	if not colorPick.thumbs then colorPick.thumbs = {} end
	colorPick.thumbs[s] = thumb
	colorPick.sliderW = w
	PinXY(thumb, s, 0, -2, 10, 18)
	s:SetScript("OnValueChanged", function()
		ColorPickFromSliders()
	end)
	s:SetScript("OnMouseDown", function()
		colorPick.drag = s
		ColorPickSliderFromCursor(s)
	end)
	s:SetScript("OnMouseUp", function()
		colorPick.drag = nil
	end)
	s:SetScript("OnMouseWheel", function(self, delta)
		delta = delta or arg1 or 0
		local v = s:GetValue() or 0
		s:SetValue(v + delta * 5)
	end)
	return s
end

local function MakeTextBtn(parent, x, y, w, h, label, r, g, b, onclick)
	local btn = CreateFrame("Button", nil, parent)
	if btn.EnableMouse then btn:EnableMouse(true) end
	PinXY(btn, parent, x, y, w, h)
	local bg = btn:CreateTexture(nil, "BACKGROUND")
	PinXY(bg, btn, 0, 0, w, h)
	ColorPickSolid(bg, r, g, b)
	if btn.SetFont then btn:SetFont("Fonts\\FRIZQT__.TTF", 13) end
	if btn.SetText then btn:SetText(label) end
	if btn.SetTextColor then btn:SetTextColor(1, 0.82, 0) end
	btn:SetScript("OnClick", onclick)
	return btn
end

function DPSMate_EnsureColorPicker()
	if colorPick.frame then return colorPick.frame end
	local W, H = 220, 268
	local f = CreateFrame("Frame", "DPSMate_ColorPicker", UIParent)
	f:SetWidth(W)
	f:SetHeight(H)
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	if f.SetToplevel then f:SetToplevel(true) end
	if f.EnableMouse then f:EnableMouse(true) end
	f:SetScript("OnMouseDown", function()
		local hit = ColorPickHitSlider()
		if hit then
			colorPick.drag = hit
			ColorPickSliderFromCursor(hit)
		end
	end)
	f:SetScript("OnMouseUp", function()
		colorPick.drag = nil
	end)
	f:SetScript("OnUpdate", function()
		if colorPick.drag then
			ColorPickSliderFromCursor(colorPick.drag)
		end
	end)
	DPSMate_ApplyDialogColor(f, 1)
	local fill = f:CreateTexture(nil, "BACKGROUND")
	PinXY(fill, f, 4, -4, W - 8, H - 8)
	ColorPickSolid(fill, 0.157, 0.08, 0.06)

	local title = f:CreateFontString(nil, "OVERLAY")
	if title then
		if title.SetFont then title:SetFont("Fonts\\FRIZQT__.TTF", 13) end
		PinXY(title, f, 8, -8, W - 16, 16)
		if title.SetText then title:SetText("Color Picker") end
		if title.SetTextColor then title:SetTextColor(1, 0.82, 0) end
		if title.SetJustifyH then title:SetJustifyH("CENTER") end
	end

	local hues = { 0, 45, 90, 135, 180, 225, 270, 315 }
	local vals = { 1, 0.72, 0.48, 0.28 }
	local size, gap, cols = 20, 2, 8
	local ox, oy = 12, -28
	local row, col
	for row = 1, 4 do
		for col = 1, cols do
			local rr, gg, bb = HSVToRGB(hues[col], 1, vals[row])
			MakeSwatch(f, ox + (col - 1) * (size + gap), oy - (row - 1) * (size + gap), size, rr, gg, bb)
		end
	end
	local extras = {
		{1,1,1}, {0.7,0.7,0.7}, {0.4,0.4,0.4}, {0,0,0},
		{1,0.82,0}, {0.02,0,1}, {0.78,0.61,0.43}, {0.96,0.55,0.73},
	}
	local ei
	for ei = 1, 8 do
		local c = extras[ei]
		MakeSwatch(f, ox + (ei - 1) * (size + gap), oy - 4 * (size + gap), size, c[1], c[2], c[3])
	end

	local gridBottom = 28 + 5 * (size + gap)
	local preview = f:CreateTexture(nil, "ARTWORK")
	PinXY(preview, f, 12, -(gridBottom + 8), 28, 28)
	ColorPickSolid(preview, 1, 1, 1)
	colorPick.preview = preview

	local sy = -(gridBottom + 8)
	colorPick.sR = MakeSlider(f, 46, sy, 150, "R", {0.8, 0.15, 0.15})
	colorPick.sG = MakeSlider(f, 46, sy - 24, 150, "G", {0.15, 0.7, 0.15})
	colorPick.sB = MakeSlider(f, 46, sy - 48, 150, "B", {0.2, 0.35, 0.85})

	local by = sy - 76
	MakeTextBtn(f, 16, by, 88, 22, "Okay", 0.45, 0.08, 0.08, function()
		ColorPickFromSliders()
		f:Hide()
	end)
	MakeTextBtn(f, 116, by, 88, 22, "Cancel", 0.45, 0.08, 0.08, function()
		ColorPickSyncSliders(colorPick.prevR, colorPick.prevG, colorPick.prevB)
		ColorPickCommit(colorPick.prevR, colorPick.prevG, colorPick.prevB)
		f:Hide()
	end)

	f:Hide()
	colorPick.frame = f
	return f
end

function DPSMate_OpenColorPicker(obj, var, func)
	if ColorPickerFrame and ColorPickerFrame.Hide then
		ColorPickerFrame:Hide()
	end
	local f = DPSMate_EnsureColorPicker()
	if not f then return end
	local button = obj and obj.GetName and getglobal(obj:GetName().."_SwatchBg")
	local r, g, b = 1, 1, 1
	if button then
		r = button.r or r
		g = button.g or g
		b = button.b or b
	end
	if type(r) ~= "number" then r = 1 end
	if type(g) ~= "number" then g = 1 end
	if type(b) ~= "number" then b = 1 end
	colorPick.obj = obj
	colorPick.var = var
	colorPick.rfunc = func
	colorPick.prevR, colorPick.prevG, colorPick.prevB = r, g, b
	ColorPickSyncSliders(r, g, b)
	f:ClearAllPoints()
	f:SetWidth(220)
	f:SetHeight(268)
	f:SetPoint("CENTER", "UIParent", "CENTER", 0, 0)
	f:Show()
end

-- CheckButton: SetChecked existiert. CheckedTexture nur per XML, kein Lua-Setter.
-- Nur die XML-CheckedTexture, kein zweites X-Overlay (sonst Haken und X gleichzeitig).
-- https://emberveil.org/wiki/lua/widgets/CheckButton#setchecked
function DPSMate_IsOn(v)
	if v == false or v == nil or v == 0 or v == "0" then return false end
	return true
end

function DPSMate_SetChecked(btn, checked)
	if not btn then return end
	if btn.SetChecked then
		if DPSMate_IsOn(checked) then
			btn:SetChecked(true)
		else
			btn:SetChecked()
		end
	end
	-- Altes X-Overlay ausblenden, falls die FontString noch im XML liegt.
	local tick = btn.GetName and getglobal(btn:GetName().."_Tick")
	if tick and tick.Hide then tick:Hide() end
end

function DPSMate_CurrentWindow()
	local key = DPSMate_ConfigMenu_Menu and DPSMate_ConfigMenu_Menu.Key
	if not key or not DPSMateSettings or not DPSMateSettings["windows"] then return end
	local win = DPSMateSettings["windows"][key]
	if type(win) ~= "table" then return end
	return win, key
end

-- Klick dreht die gespeicherte Option und zwingt den Haken auf denselben Stand.
-- Nicht GetChecked lesen: der Client toggelt das Flag nicht immer vor OnClick.
function DPSMate_OnWindowCheckClick(var)
	local win = DPSMate_CurrentWindow()
	if not win or not var then return end
	local on = not DPSMate_IsOn(win[var])
	win[var] = on
	DPSMate_SetChecked(this, on)
	return on, win
end

function DPSMate_OnTitleBarButtonClick(var)
	DPSMate_OnWindowCheckClick(var)
	if DPSMate and DPSMate.Options and DPSMate.Options.ToggleTitleBarButtonState then
		DPSMate.Options:ToggleTitleBarButtonState()
	end
end

function DPSMate_OnTitleBarEnableClick()
	local on, win = DPSMate_OnWindowCheckClick("titlebar")
	if not win then return end
	local head = getglobal("DPSMate_"..win["name"].."_Head")
	local frame = getglobal("DPSMate_"..win["name"])
	if on then
		if head and head.Show then head:Show() end
	else
		if head and head.Hide then head:Hide() end
	end
	if frame and DPSMate and DPSMate.UpdateFrameSize then
		DPSMate:UpdateFrameSize(frame)
	end
end

-- Balken-Klick. SetScript ruft handler(self, button) auf; XML setzt this/arg1.
-- https://emberveil.org/wiki/lua/widgets/UIObject#setscript
function DPSMate_WindowKeyFromBar(bar)
	local p = bar
	local i
	for i = 1, 8 do
		if not p then return end
		if p.Key then return p.Key, p end
		if p.GetParent then
			p = p:GetParent()
		else
			return
		end
	end
end

function DPSMate_OnBarMouseUp(a, b)
	local bar, button
	if a and type(a) ~= "string" then
		bar, button = a, b
	else
		bar, button = this, a
	end
	bar = bar or this
	button = button or arg1
	if not bar then return end
	local name = ""
	if bar.GetName then name = bar:GetName() or "" end
	local isTotal = string.find(name, "_Total$")
	if button == "RightButton" and not isTotal then
		if DPSMate and DPSMate.Options and DPSMate.Options.InializePlayerDewDrop then
			DPSMate.Options:InializePlayerDewDrop(bar)
		end
		if DPSMate and DPSMate.Options and DPSMate.Options.OpenMenu then
			DPSMate.Options:OpenMenu(4, bar)
		end
		return
	end
	if not DPSMate or not DPSMate.Options then return end
	if isTotal then
		if DPSMate.Options.UpdateTotalDetails then
			DPSMate.Options:UpdateTotalDetails(bar)
		end
	elseif DPSMate.Options.UpdateDetails then
		DPSMate.Options:UpdateDetails(bar)
	end
end

-- 1.12-FrameXML. Fehlt FauxScrollFrame, sollen die Original-Details nicht
-- an nil-Funktionen scheitern. https://emberveil.org/wiki/lua/widgets/Frame#setscript
if type(FauxScrollFrame_GetOffset) ~= "function" then
	function FauxScrollFrame_GetOffset(frame)
		return (frame and frame.offset) or 0
	end
	function FauxScrollFrame_SetOffset(frame, offset)
		if frame then frame.offset = offset or 0 end
	end
	function FauxScrollFrame_Update(frame, numItems, numToDisplay, valueStep)
		if not frame then return end
		if not frame.offset then frame.offset = 0 end
	end
	function FauxScrollFrame_OnVerticalScroll(value, updateFunction)
		local frame = this
		local height, scroll = 24, arg1
		if type(value) == "number" and type(updateFunction) == "function" then
			height = value
		elseif type(value) == "function" then
			updateFunction = value
		end
		if type(scroll) ~= "number" then scroll = 0 end
		if frame then
			frame.offset = math.floor((scroll / height) + 0.5)
		end
		if type(updateFunction) == "function" then
			updateFunction()
		end
	end
end

function DPSMate_EnsurePlayerEval()
	if not DPSMate or not DPSMate.Modules or not rawget then return end
	local d = rawget(DPSMate.Modules, "DetailsDamage")
	if type(d) == "table" and type(d.UpdateDetails) == "function" then return end
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080DPSMate|r: Detailfenster nicht geladen (DPSMate_PlayerEval.lua).")
	end
end

function DPSMate_BindMeterBar(bar)
	if not bar or not bar.SetScript then return end
	if bar.EnableMouse then bar:EnableMouse(true) end
	bar:SetScript("OnMouseUp", function(self, button)
		DPSMate_OnBarMouseUp(self, button)
	end)
	local name = ""
	if bar.GetName then name = bar:GetName() or "" end
	if not string.find(name, "_Total$") then
		bar:SetScript("OnEnter", function(self)
			if DPSMate and DPSMate.Options and DPSMate.Options.ShowTooltip then
				DPSMate.Options:ShowTooltip(self)
			end
		end)
		bar:SetScript("OnLeave", function()
			if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
		end)
	end
end

function DPSMate_OnCombatEvent(a, b, c)
	-- SetScript: handler(self, ...). OnEvent kann (self, event, arg1) sein
	-- oder XML-Globals event/arg1. https://emberveil.org/wiki/lua/widgets/UIObject#setscript
	local ev, msg
	if a and type(a) ~= "string" then
		ev, msg = b, c
	else
		ev, msg = a, b
	end
	ev = ev or event
	msg = msg or arg1
	if type(ev) ~= "string" then return end
	if DPSMate and DPSMate.DB and DPSMate.DB.OnEvent then
		pcall(DPSMate.DB.OnEvent, DPSMate.DB, ev)
	end
	if DPSMate and DPSMate.Parser and DPSMate.Parser.OnEvent then
		pcall(DPSMate.Parser.OnEvent, DPSMate.Parser, ev, msg)
	end
	if DPSMate and DPSMate.Options and DPSMate.Options.OnEvent then
		pcall(DPSMate.Options.OnEvent, DPSMate.Options, ev)
	end
end

function DPSMate_BindCombatEvents()
	local f = DPSMate_Options
	if not f or not f.SetScript then
		if DPSMate and DPSMate.EventHolder then
			f = DPSMate:EventHolder()
		end
	end
	if not f or not f.SetScript then return end
	f:SetScript("OnEvent", function(self, ev, a1)
		DPSMate_OnCombatEvent(self, ev, a1)
	end)
	if f.RegisterEvent and DPSMate and DPSMate.Events then
		local i, ev
		for i = 1, table.getn(DPSMate.Events) do
			ev = DPSMate.Events[i]
			if type(ev) == "string" then pcall(f.RegisterEvent, f, ev) end
		end
		pcall(f.RegisterEvent, f, "PLAYER_REGEN_DISABLED")
		pcall(f.RegisterEvent, f, "PLAYER_REGEN_ENABLED")
		pcall(f.RegisterEvent, f, "PLAYER_ENTERING_WORLD")
		pcall(f.RegisterEvent, f, "PLAYER_TARGET_CHANGED")
		pcall(f.RegisterEvent, f, "PLAYER_PET_CHANGED")
	end
	if DPSMate then DPSMate.Registered = true end
end

function DPSMate_OnCbtDisplayClick()
	local on, win = DPSMate_OnWindowCheckClick("cbtdisplay")
	if not win then return end
	if on then
		local font = getglobal("DPSMate_"..win["name"].."_Head_Font")
		local mode = win["CurMode"]
		local opt = DPSMate and DPSMate.Options and DPSMate.Options.Options
		if font and font.SetText and opt and opt[1] and opt[1]["args"] and mode and opt[1]["args"][mode] then
			font:SetText(opt[1]["args"][mode].name)
		end
	elseif DPSMate and DPSMate.SetStatusBarValue then
		DPSMate:SetStatusBarValue()
	end
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

local function DPSMate_FillSetValue(widget, value)
	if widget and widget.SetValue and value ~= nil then
		DPSMate_SliderFilling = true
		pcall(widget.SetValue, widget, value)
		DPSMate_SliderFilling = nil
	end
end

local function DPSMate_FillDrop(widget, value)
	if not widget or value == nil then return end
	if UIDropDownMenu_SetSelectedValue then
		pcall(UIDropDownMenu_SetSelectedValue, widget, value)
	end
	local text = widget.GetName and getglobal(widget:GetName().."Text")
	if text and text.SetText then
		text:SetText(tostring(value))
	end
end

local function DPSMate_FillSwatch(name, color)
	if type(color) ~= "table" then return end
	local nt = getglobal(name.."NormalTexture")
	if nt and nt.SetVertexColor then
		nt:SetVertexColor(color[1], color[2], color[3])
	end
	local bg = getglobal(name.."_SwatchBg")
	if bg then
		bg.r = color[1]
		bg.g = color[2]
		bg.b = color[3]
	end
end

-- Lua-Untermenue (Bars / Title bar / Content) hat kein XML-this.func, das die
-- Widgets aus den Fenstereinstellungen fuellt. Ohne diesen Schritt bleiben
-- Checkboxen, Dropdowns und Farben beim Oeffnen leer.
function DPSMate_FillWindowConfigTab(suffix, key)
	if not suffix or not key then return end
	local windows = DPSMateSettings and DPSMateSettings["windows"]
	local win = windows and windows[key]
	if type(win) ~= "table" then return end
	local opt = DPSMate and DPSMate.Options
	if suffix == "_Tab_TitleBar" then
		DPSMate_SetChecked(DPSMate_ConfigMenu_Tab_TitleBar_Enable, win["titlebar"])
		DPSMate_FillSetValue(DPSMate_ConfigMenu_Tab_TitleBar_BarFontSize, win["titlebarfontsize"])
		DPSMate_FillSetValue(DPSMate_ConfigMenu_Tab_TitleBar_BarHeight, win["titlebarheight"])
		DPSMate_FillSetValue(DPSMate_ConfigMenu_Tab_TitleBar_BGOpacity, win["titlebaropacity"] or 1)
		DPSMate_SetChecked(DPSMate_ConfigMenu_Tab_TitleBar_Box1_Report, win["titlebarreport"])
		DPSMate_SetChecked(DPSMate_ConfigMenu_Tab_TitleBar_Box1_Reset, win["titlebarreset"])
		DPSMate_SetChecked(DPSMate_ConfigMenu_Tab_TitleBar_Box1_Mode, win["titlebarsegments"])
		DPSMate_SetChecked(DPSMate_ConfigMenu_Tab_TitleBar_Box1_Config, win["titlebarconfig"])
		DPSMate_SetChecked(DPSMate_ConfigMenu_Tab_TitleBar_Box1_Sync, win["titlebarsync"])
		DPSMate_SetChecked(DPSMate_ConfigMenu_Tab_TitleBar_Box1_Enable, win["titlebarenable"])
		DPSMate_SetChecked(DPSMate_ConfigMenu_Tab_TitleBar_Box1_Filter, win["titlebarfilter"])
		DPSMate_SetChecked(DPSMate_ConfigMenu_Tab_TitleBar_Box1_CBTDisplay, win["cbtdisplay"])
		DPSMate_FillSwatch("DPSMate_ConfigMenu_Tab_TitleBar_BGColor", win["titlebarbgcolor"])
		DPSMate_FillSwatch("DPSMate_ConfigMenu_Tab_TitleBar_FontColor", win["titlebarfontcolor"])
		DPSMate_FillDrop(DPSMate_ConfigMenu_Tab_TitleBar_BarTexture, win["titlebartexture"])
		DPSMate_FillDrop(DPSMate_ConfigMenu_Tab_TitleBar_BarFont, win["titlebarfont"])
		DPSMate_FillDrop(DPSMate_ConfigMenu_Tab_TitleBar_BarFontFlag, win["titlebarfontflag"])
		if DPSMate_ConfigMenu_Tab_TitleBar_BarTexture and DPSMate_ConfigMenu_Tab_TitleBar_BarTexture.tex and opt and opt.statusbars then
			DPSMate_ConfigMenu_Tab_TitleBar_BarTexture.tex:SetTexture(opt.statusbars[win["titlebartexture"]])
		end
		if DPSMate_ConfigMenu_Tab_TitleBar_BarFontText and DPSMate_ConfigMenu_Tab_TitleBar_BarFontText.SetFont and opt and opt.fonts then
			pcall(DPSMate_ConfigMenu_Tab_TitleBar_BarFontText.SetFont, DPSMate_ConfigMenu_Tab_TitleBar_BarFontText, opt.fonts[win["titlebarfont"]], 12)
		end
		if DPSMate_ConfigMenu_Tab_TitleBar_BarFontFlagText and DPSMate_ConfigMenu_Tab_TitleBar_BarFontFlagText.SetFont and opt and opt.fonts and opt.fontflags then
			pcall(DPSMate_ConfigMenu_Tab_TitleBar_BarFontFlagText.SetFont, DPSMate_ConfigMenu_Tab_TitleBar_BarFontFlagText, opt.fonts["FRIZQT"], 12, opt.fontflags[win["titlebarfontflag"]])
		end
	elseif suffix == "_Tab_Bars" then
		DPSMate_FillSetValue(DPSMate_ConfigMenu_Tab_Bars_BarFontSize, win["barfontsize"])
		DPSMate_FillSetValue(DPSMate_ConfigMenu_Tab_Bars_BarSpacing, win["barspacing"])
		DPSMate_FillSetValue(DPSMate_ConfigMenu_Tab_Bars_BarHeight, win["barheight"])
		DPSMate_FillSetValue(DPSMate_ConfigMenu_Tab_Bars_TotalAlpha, win["totopacity"] or 1)
		DPSMate_SetChecked(DPSMate_ConfigMenu_Tab_Bars_ClassIcons, win["classicons"])
		DPSMate_SetChecked(DPSMate_ConfigMenu_Tab_Bars_Ranks, win["ranks"])
		DPSMate_SetChecked(DPSMate_ConfigMenu_Tab_Bars_DisableBG, win["barbg"])
		DPSMate_FillDrop(DPSMate_ConfigMenu_Tab_Bars_BarFont, win["barfont"])
		DPSMate_FillDrop(DPSMate_ConfigMenu_Tab_Bars_BarFontFlag, win["barfontflag"])
		DPSMate_FillDrop(DPSMate_ConfigMenu_Tab_Bars_BarTexture, win["bartexture"])
		DPSMate_FillSwatch("DPSMate_ConfigMenu_Tab_Bars_FontColor", win["barfontcolor"])
		DPSMate_FillSwatch("DPSMate_ConfigMenu_Tab_Bars_BackgroundBarColor", win["bgbarcolor"])
		if DPSMate_ConfigMenu_Tab_Bars_BarTexture and DPSMate_ConfigMenu_Tab_Bars_BarTexture.tex and opt and opt.statusbars then
			DPSMate_ConfigMenu_Tab_Bars_BarTexture.tex:SetTexture(opt.statusbars[win["bartexture"]])
		end
		if DPSMate_ConfigMenu_Tab_Bars_BarFontText and DPSMate_ConfigMenu_Tab_Bars_BarFontText.SetFont and opt and opt.fonts then
			pcall(DPSMate_ConfigMenu_Tab_Bars_BarFontText.SetFont, DPSMate_ConfigMenu_Tab_Bars_BarFontText, opt.fonts[win["barfont"]], 12)
		end
		if DPSMate_ConfigMenu_Tab_Bars_BarFontFlagText and DPSMate_ConfigMenu_Tab_Bars_BarFontFlagText.SetFont and opt and opt.fonts and opt.fontflags then
			pcall(DPSMate_ConfigMenu_Tab_Bars_BarFontFlagText.SetFont, DPSMate_ConfigMenu_Tab_Bars_BarFontFlagText, opt.fonts["FRIZQT"], 12, opt.fontflags[win["barfontflag"]])
		end
	elseif suffix == "_Tab_Content" then
		DPSMate_FillSetValue(DPSMate_ConfigMenu_Tab_Content_Scale, win["scale"])
		DPSMate_FillSetValue(DPSMate_ConfigMenu_Tab_Content_Opacity, win["opacity"])
		DPSMate_FillSetValue(DPSMate_ConfigMenu_Tab_Content_BorderOpacity, win["borderopacity"] or 0)
		DPSMate_FillSetValue(DPSMate_ConfigMenu_Tab_Content_BGOpacity, win["bgopacity"] or 1)
		DPSMate_FillDrop(DPSMate_ConfigMenu_Tab_Content_NumberFormat, win["numberformat"])
		DPSMate_FillDrop(DPSMate_ConfigMenu_Tab_Content_BGDropDown, win["contentbgtexture"])
		DPSMate_FillDrop(DPSMate_ConfigMenu_Tab_Content_BorderTexture, win["bordertexture"] or "UI-Tooltip-Border")
		DPSMate_FillDrop(DPSMate_ConfigMenu_Tab_Content_BorderStrata, win["borderstrata"] or 1)
		DPSMate_FillSwatch("DPSMate_ConfigMenu_Tab_Content_BGColor", win["contentbgcolor"])
		DPSMate_FillSwatch("DPSMate_ConfigMenu_Tab_Content_BorderColor", win["contentbordercolor"])
		local preview = DPSMate_ConfigMenu_Tab_Content_BGDropDown_Texture
		if preview and preview.SetBackdrop and opt and opt.bgtexture then
			pcall(preview.SetBackdrop, preview, {
				bgFile = opt.bgtexture[win["contentbgtexture"]],
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true, tileSize = 12, edgeSize = 12,
				insets = { left = 4, right = 4, top = 4, bottom = 4 }
			})
			if preview.SetBackdropColor and type(win["contentbgcolor"]) == "table" then
				preview:SetBackdropColor(win["contentbgcolor"][1], win["contentbgcolor"][2], win["contentbgcolor"][3])
			end
		end
	end
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
	DPSMate_FillWindowConfigTab(suffix, menu.Key)
end

local function DPSMate_WindowMenuLastVisible(f)
	if not f or not f.GetName then return f end
	local last = f
	local i
	for i = 1, 3 do
		local s = getglobal(f:GetName().."_Button"..i)
		if s and s.IsShown and s:IsShown() then
			last = s
		end
	end
	return last
end

local function DPSMate_CollapseWindowRows()
	local windows = DPSMateSettings and DPSMateSettings["windows"]
	if type(windows) ~= "table" then return end
	local cat
	for cat, _ in pairs(windows) do
		local base = "DPSMate_ConfigMenu_Menu_Button"..(9+cat)
		local exp = getglobal(base.."Expand")
		local col = getglobal(base.."Collapse")
		if exp then exp:Show() end
		if col then col:Hide() end
		local i
		for i = 1, 3 do
			local s = getglobal(base.."_Button"..i)
			if s then s:Hide() end
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
			if DPSMate_ConfigMenu_Menu then DPSMate_ConfigMenu_Menu.Key = parent.Key end
			DPSMate_RelayoutWindowMenu()
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
			DPSMate_RelayoutWindowMenu()
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
				this.Key = parent and parent.Key
				this.func = function()
					DPSMate_SwitchConfigTab(this.tabSuffix, this.Key)
				end
				DPSMate_ConfigMenuClick()
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
		local cat
		for cat = 1, 24 do
			if windows[cat] then
				local f = getglobal("DPSMate_ConfigMenu_Menu_Button"..(9+cat))
				if f then
					f:ClearAllPoints()
					if last then f:SetPoint("TOP", last, "BOTTOM") end
					last = DPSMate_WindowMenuLastVisible(f)
					n = n + 1
				end
			end
		end
	end
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
	DPSMate_CollapseWindowRows()
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
		pumpFrame.wait = INTERVAL
		pumpFrame.last = GetTime()
		pumpFrame:SetScript("OnUpdate", Pump)
	end
end

----------------------------------------------------------------------------------
--------------                    TEST MODE FIGHT                   --------------
----------------------------------------------------------------------------------
-- Original-Testmode malt nur "Test 1" ohne statusbar.user und ohne DB.
-- Linksklick -> "Could not find this user!". Hier ein Vanilla-Raid-Fight
-- (ca. 3 min), damit die Details anklickbar sind.

local TEST_CBT = 180

local function TestSpell(en)
	if not en then return "AutoAttack" end
	if (en == "AutoAttack" or en == "AutoShot") and DPSMate and DPSMate.L and type(DPSMate.L[en]) == "string" then
		return DPSMate.L[en]
	end
	local bs = DPSMate and DPSMate.BabbleSpell
	if bs and type(bs.GetTranslation) == "function" then
		local ok, t = pcall(bs.GetTranslation, bs, en)
		if ok and type(t) == "string" and t ~= "" and t ~= "None" then return t end
	end
	return en
end

local function TestEnsureUser(name, class)
	if not DPSMateUser then DPSMateUser = {} end
	if DPSMate.DB and DPSMate.DB.BuildUser then
		DPSMate.DB:BuildUser(name, class)
	end
	if not DPSMateUser[name] then
		DPSMateUser[name] = {
			[1] = (DPSMate.TableLength and DPSMate:TableLength(DPSMateUser) or 1) + 1,
			[2] = class,
		}
		DPSMate.UserId = nil
	end
	DPSMateUser[name][2] = class
	return DPSMateUser[name][1]
end

local function TestEnsureAbility(name)
	if not DPSMateAbility then DPSMateAbility = {} end
	if DPSMate.DB and DPSMate.DB.BuildAbility then
		DPSMate.DB:BuildAbility(name)
	end
	if not DPSMateAbility[name] then
		DPSMateAbility[name] = {
			[1] = (DPSMate.TableLength and DPSMate:TableLength(DPSMateAbility) or 1) + 1,
		}
		DPSMate.AbilityId = nil
	end
	return DPSMateAbility[name][1]
end

local function TestSeries(amount, dur)
	local ts, n, acc, s = {}, 24, 0, 0
	if amount < 1 then return ts end
	for s = 1, n do
		local t = math.floor(s * dur / n)
		if t < 1 then t = 1 end
		local chunk = math.floor(amount / n)
		if s == n then
			chunk = amount - acc
		else
			chunk = math.floor(chunk * (0.62 + ((s * 7) % 9) * 0.08))
			if chunk < 1 then chunk = 1 end
		end
		if chunk < 0 then chunk = 0 end
		ts[t] = (ts[t] or 0) + chunk
		acc = acc + chunk
	end
	return ts
end

-- hits, crits, miss, parry, dodge, resist, glance, block, hitAvg, critAvg
local function TestAbil(amount, hits, crits, miss, parry, dodge, resist, glance, block, hitAvg, critAvg)
	hits = hits or 0
	crits = crits or 0
	miss = miss or 0
	parry = parry or 0
	dodge = dodge or 0
	resist = resist or 0
	glance = glance or 0
	block = block or 0
	hitAvg = hitAvg or 0
	critAvg = critAvg or 0
	local gAvg, bAvg = 0, 0
	if glance > 0 then gAvg = math.floor(hitAvg * 0.72) end
	if block > 0 then bAvg = math.floor(hitAvg * 0.55) end
	local hMin, hMax = 0, 0
	if hits > 0 then
		hMin = math.max(1, math.floor(hitAvg * 0.68))
		hMax = math.floor(hitAvg * 1.38)
	end
	local cMin, cMax = 0, 0
	if crits > 0 then
		cMin = math.max(1, math.floor(critAvg * 0.78))
		cMax = math.floor(critAvg * 1.42)
	end
	return {
		[1] = hits, [2] = hMin, [3] = hMax, [4] = hitAvg,
		[5] = crits, [6] = cMin, [7] = cMax, [8] = critAvg,
		[9] = miss, [10] = parry, [11] = dodge, [12] = resist,
		[13] = amount,
		[14] = glance,
		[15] = glance > 0 and math.max(1, math.floor(gAvg * 0.7)) or 0,
		[16] = glance > 0 and math.floor(gAvg * 1.2) or 0,
		[17] = gAvg,
		[18] = block,
		[19] = block > 0 and math.max(1, math.floor(bAvg * 0.7)) or 0,
		[20] = block > 0 and math.floor(bAvg * 1.2) or 0,
		[21] = bAvg,
		[22] = hits + crits + miss + parry + dodge + resist + glance + block,
		["i"] = TestSeries(amount, TEST_CBT),
	}
end

local function TestPutPlayer(name, class, list)
	local uid = TestEnsureUser(name, class)
	local rec, tot, i = { i = 0 }, 0, 1
	for i = 1, table.getn(list) do
		local row = list[i]
		local abn = TestSpell(row[1])
		local aid = TestEnsureAbility(abn)
		rec[aid] = TestAbil(row[2], row[3], row[4], row[5], row[6], row[7], row[8], row[9], row[10], row[11], row[12])
		tot = tot + (row[2] or 0)
	end
	rec.i = tot
	if not DPSMateDamageDone then DPSMateDamageDone = { [1] = {}, [2] = {} } end
	if not DPSMateDamageDone[1] then DPSMateDamageDone[1] = {} end
	if not DPSMateDamageDone[2] then DPSMateDamageDone[2] = {} end
	DPSMateDamageDone[1][uid] = rec
	DPSMateDamageDone[2][uid] = rec
	if DPSMateCombatTime then
		if not DPSMateCombatTime.effective then DPSMateCombatTime.effective = { [1] = {}, [2] = {} } end
		if not DPSMateCombatTime.effective[1] then DPSMateCombatTime.effective[1] = {} end
		if not DPSMateCombatTime.effective[2] then DPSMateCombatTime.effective[2] = {} end
		DPSMateCombatTime.effective[1][name] = TEST_CBT - 6
		DPSMateCombatTime.effective[2][name] = TEST_CBT - 6
	end
	return tot, uid
end

local function TestPaintBars(rows)
	if not DPSMateSettings or not DPSMateSettings.windows then return end
	local _G = getglobal
	if DPSMate.HideStatusBars then DPSMate:HideStatusBars() end
	local maxD, total, i = 1, 0, 1
	for i = 1, table.getn(rows) do
		if rows[i][2] > maxD then maxD = rows[i][2] end
		total = total + rows[i][2]
	end
	for k, c in pairs(DPSMateSettings.windows) do
		if c and c["name"] then
			local prefix = "DPSMate_"..c["name"]
			local child = _G(prefix.."_ScrollFrame_Child")
			local indent = 2
			if c["classicons"] then indent = c["barheight"] or 19 end
			local maxBars = 40
			if DPSMate.MaxVisibleBars then maxBars = DPSMate:MaxVisibleBars(c) end
			if DPSMateSettings["showtotals"] then
				local tn = _G(prefix.."_ScrollFrame_Child_Total_Name")
				local tv = _G(prefix.."_ScrollFrame_Child_Total_Value")
				local tb = _G(prefix.."_ScrollFrame_Child_Total")
				if tn then tn:SetText(DPSMate.L and DPSMate.L["total"] or "Total") end
				if tv then tv:SetText(string.format("%.1f", total / TEST_CBT).." ("..total..")") end
				if tb then
					tb:Show()
					local bw = c["width"]
					local fr = _G(prefix)
					if (not bw or bw < 40) and fr and fr.GetWidth then bw = fr:GetWidth() end
					if DPSMate.LayoutBarText then DPSMate:LayoutBarText(tb, bw, 2) end
					if DPSMate_BindMeterBar then DPSMate_BindMeterBar(tb) end
				end
			end
			local hf = _G(prefix.."_Head_Font")
			if hf then
				local modeArgs = DPSMate.Options and DPSMate.Options.Options and DPSMate.Options.Options[1] and DPSMate.Options.Options[1]["args"]
				local modeName = (modeArgs and modeArgs[c["CurMode"]] and modeArgs[c["CurMode"]].name) or c["CurMode"] or "DPS"
				local tstr = "3:00m"
				if DPSMate.Options and DPSMate.Options.FormatTime then
					tstr = DPSMate.Options:FormatTime(TEST_CBT) or tstr
				end
				hf:SetText(tostring(modeName).." ["..tstr.."]")
				local fr = _G(prefix)
				if fr and DPSMate.LayoutHeadTitle then DPSMate:LayoutHeadTitle(fr) end
			end
			local nshow = table.getn(rows)
			if nshow > maxBars then nshow = maxBars end
			for i = 1, nshow do
				local statusbar = _G(prefix.."_ScrollFrame_Child_StatusBar"..i)
				local nameFS = _G(prefix.."_ScrollFrame_Child_StatusBar"..i.."_Name")
				local valueFS = _G(prefix.."_ScrollFrame_Child_StatusBar"..i.."_Value")
				local texture = _G(prefix.."_ScrollFrame_Child_StatusBar"..i.."_Icon")
				if not statusbar then break end
				if child then child:SetHeight((i + 1) * (c["barheight"] + c["barspacing"])) end
				local uname, dmg, class = rows[i][1], rows[i][2], rows[i][3]
				local r, g, b, img = 0.78, 0.61, 0.43, class or "warrior"
				if DPSMate.GetClassColor then
					r, g, b, img = DPSMate:GetClassColor(uname)
				end
				statusbar:SetStatusBarColor(r, g, b, 1)
				local p = ""
				if c["ranks"] then p = i..". " end
				if nameFS then nameFS:SetText(p..uname) end
				if valueFS then valueFS:SetText(string.format("%.1f", dmg / TEST_CBT).." ("..dmg..")") end
				if texture and img then
					texture:SetTexture("Interface\\AddOns\\DPSMate\\images\\class\\"..string.lower(img))
				end
				statusbar:SetValue(100 * dmg / maxD)
				statusbar.user = uname
				if DPSMate_BindMeterBar then DPSMate_BindMeterBar(statusbar) end
				statusbar:Show()
				local bw = c["width"]
				local fr = _G(prefix)
				if (not bw or bw < 40) and fr and fr.GetWidth then bw = fr:GetWidth() end
				if DPSMate.LayoutBarText then DPSMate:LayoutBarText(statusbar, bw, indent) end
			end
		end
	end
end

function DPSMate_ClearTestFight()
	local snap = DPSMate.Options and DPSMate.Options._testSnap
	if not snap then return end
	if DPSMateDamageDone then
		local i
		for i = 1, table.getn(snap.uids) do
			local uid = snap.uids[i]
			if DPSMateDamageDone[1] then DPSMateDamageDone[1][uid] = nil end
			if DPSMateDamageDone[2] then DPSMateDamageDone[2][uid] = nil end
		end
	end
	if DPSMateCombatTime then
		DPSMateCombatTime.total = snap.total
		DPSMateCombatTime.current = snap.current
		if DPSMateCombatTime.effective then
			local i
			for i = 1, table.getn(snap.names) do
				local n = snap.names[i]
				if DPSMateCombatTime.effective[1] then
					DPSMateCombatTime.effective[1][n] = snap.eff1[n]
				end
				if DPSMateCombatTime.effective[2] then
					DPSMateCombatTime.effective[2][n] = snap.eff2[n]
				end
			end
		end
	end
	if DPSMate.Parser and DPSMate.Parser.TargetParty then
		local i
		for i = 1, table.getn(snap.names) do
			if snap.party[snap.names[i]] == nil then
				DPSMate.Parser.TargetParty[snap.names[i]] = nil
			end
		end
	end
	DPSMate.Options._testSnap = nil
end

function DPSMate_SeedTestFight()
	if DPSMate.Options and DPSMate.Options._testSnap then
		DPSMate_ClearTestFight()
	end
	if not DPSMateCombatTime then
		DPSMateCombatTime = { total = 1, current = 1, segments = {}, effective = { [1] = {}, [2] = {} } }
	end
	local names = {
		"Rennick", "Thrain", "Aelira", "Morvane", "Kaelen", "Huffer",
		"Thornpaw", "Selene", "Stormhoof", "Lightbrand", "Oakwhisper",
		"Stonewall", "Whisperheal",
	}
	local snap = {
		total = DPSMateCombatTime.total or 1,
		current = DPSMateCombatTime.current or 1,
		eff1 = {},
		eff2 = {},
		party = {},
		names = names,
		uids = {},
	}
	local i
	for i = 1, table.getn(names) do
		local n = names[i]
		if DPSMateCombatTime.effective and DPSMateCombatTime.effective[1] then
			snap.eff1[n] = DPSMateCombatTime.effective[1][n]
		end
		if DPSMateCombatTime.effective and DPSMateCombatTime.effective[2] then
			snap.eff2[n] = DPSMateCombatTime.effective[2][n]
		end
		if DPSMate.Parser and DPSMate.Parser.TargetParty then
			snap.party[n] = DPSMate.Parser.TargetParty[n]
			DPSMate.Parser.TargetParty[n] = true
		end
	end
	DPSMateCombatTime.total = TEST_CBT
	DPSMateCombatTime.current = TEST_CBT

	-- { spell, amount, hits, crits, miss, parry, dodge, resist, glance, block, hitAvg, critAvg }
	local rows = {}
	local function addRow(name, class, dmg)
		table.insert(rows, { name, dmg, class })
	end

	addRow("Rennick", "rogue", TestPutPlayer("Rennick", "rogue", {
		{ "AutoAttack", 41200, 168, 42, 14, 9, 11, 0, 22, 3, 178, 356 },
		{ "Sinister Strike", 36800, 86, 21, 5, 4, 6, 0, 0, 0, 318, 636 },
		{ "Backstab", 27400, 38, 14, 3, 2, 2, 0, 0, 0, 512, 1024 },
		{ "Eviscerate", 9800, 12, 4, 1, 1, 1, 0, 0, 0, 610, 1220 },
		{ "Blade Flurry", 3600, 18, 4, 2, 1, 1, 0, 0, 0, 150, 300 },
	}))
	addRow("Thrain", "warrior", TestPutPlayer("Thrain", "warrior", {
		{ "AutoAttack", 39800, 150, 28, 10, 12, 14, 0, 30, 6, 210, 420 },
		{ "Heroic Strike", 28600, 72, 14, 4, 6, 5, 0, 0, 0, 330, 660 },
		{ "Bloodthirst", 22400, 38, 9, 2, 3, 3, 0, 0, 0, 470, 940 },
		{ "Whirlwind", 12200, 22, 5, 2, 2, 2, 0, 0, 0, 430, 860 },
		{ "Execute", 5000, 6, 2, 0, 1, 1, 0, 0, 0, 620, 1240 },
	}))
	addRow("Aelira", "mage", TestPutPlayer("Aelira", "mage", {
		{ "Fireball", 61200, 78, 22, 0, 0, 0, 8, 0, 0, 580, 1160 },
		{ "Fire Blast", 18400, 28, 7, 0, 0, 0, 3, 0, 0, 510, 1020 },
		{ "Scorch", 12800, 36, 8, 0, 0, 0, 4, 0, 0, 280, 560 },
		{ "Pyroblast", 6600, 4, 2, 0, 0, 0, 1, 0, 0, 1100, 2200 },
	}))
	addRow("Morvane", "warlock", TestPutPlayer("Morvane", "warlock", {
		{ "Shadow Bolt", 54800, 70, 18, 0, 0, 0, 9, 0, 0, 600, 1200 },
		{ "Corruption", 18600, 90, 0, 0, 0, 0, 6, 0, 0, 206, 0 },
		{ "Immolate", 12400, 48, 0, 0, 0, 0, 4, 0, 0, 258, 0 },
		{ "Searing Pain", 4200, 14, 3, 0, 0, 0, 2, 0, 0, 240, 480 },
		{ "Siphon Life", 1800, 24, 0, 0, 0, 0, 2, 0, 0, 75, 0 },
	}))
	local hunterD = TestPutPlayer("Kaelen", "hunter", {
		{ "Auto Shot", 28600, 110, 22, 8, 0, 0, 0, 0, 0, 210, 420 },
		{ "Aimed Shot", 32400, 36, 10, 3, 0, 0, 0, 0, 0, 700, 1400 },
		{ "Multi-Shot", 14800, 22, 6, 2, 0, 0, 0, 0, 0, 520, 1040 },
		{ "Arcane Shot", 6200, 18, 4, 1, 0, 0, 2, 0, 0, 270, 540 },
		{ "Serpent Sting", 4400, 40, 0, 0, 0, 0, 3, 0, 0, 110, 0 },
	})
	local petD = TestPutPlayer("Huffer", "warrior", {
		{ "AutoAttack", 12400, 80, 12, 6, 8, 9, 0, 10, 2, 130, 260 },
		{ "Claw", 6200, 40, 8, 3, 4, 4, 0, 0, 0, 128, 256 },
		{ "Bite", 3400, 16, 4, 2, 2, 2, 0, 0, 0, 170, 340 },
	})
	if DPSMateUser["Huffer"] then
		DPSMateUser["Huffer"][4] = true
		DPSMateUser["Huffer"][6] = DPSMateUser["Kaelen"][1]
	end
	if DPSMateUser["Kaelen"] then DPSMateUser["Kaelen"][5] = "Huffer" end
	local merge = true
	if DPSMateSettings and DPSMateSettings["mergepets"] == false then merge = false end
	if merge then
		addRow("Kaelen", "hunter", hunterD + petD)
	else
		addRow("Kaelen", "hunter", hunterD)
		addRow("Huffer", "warrior", petD)
	end
	addRow("Thornpaw", "druid", TestPutPlayer("Thornpaw", "druid", {
		{ "AutoAttack", 26800, 120, 24, 8, 7, 9, 0, 18, 2, 180, 360 },
		{ "Shred", 31200, 42, 14, 3, 3, 4, 0, 0, 0, 560, 1120 },
		{ "Ferocious Bite", 12800, 10, 3, 1, 1, 1, 0, 0, 0, 960, 1920 },
		{ "Rip", 5400, 8, 0, 0, 0, 0, 0, 0, 0, 675, 0 },
		{ "Rake", 3000, 12, 0, 0, 1, 1, 0, 0, 0, 250, 0 },
	}))
	addRow("Selene", "priest", TestPutPlayer("Selene", "priest", {
		{ "Mind Blast", 28600, 40, 12, 0, 0, 0, 5, 0, 0, 540, 1080 },
		{ "Mind Flay", 22400, 70, 0, 0, 0, 0, 6, 0, 0, 320, 0 },
		{ "Shadow Word: Pain", 14800, 80, 0, 0, 0, 0, 5, 0, 0, 185, 0 },
		{ "Smite", 2600, 8, 2, 0, 0, 0, 1, 0, 0, 260, 520 },
	}))
	addRow("Stormhoof", "shaman", TestPutPlayer("Stormhoof", "shaman", {
		{ "AutoAttack", 28600, 130, 22, 8, 6, 8, 0, 16, 2, 175, 350 },
		{ "Earth Shock", 12400, 28, 6, 0, 0, 0, 3, 0, 0, 360, 720 },
		{ "Flame Shock", 8200, 20, 0, 0, 0, 0, 2, 0, 0, 410, 0 },
		{ "Lightning Bolt", 4800, 10, 2, 0, 0, 0, 2, 0, 0, 400, 800 },
	}))
	addRow("Lightbrand", "paladin", TestPutPlayer("Lightbrand", "paladin", {
		{ "AutoAttack", 22400, 110, 16, 8, 7, 8, 0, 14, 3, 165, 330 },
		{ "Seal of Command", 14800, 40, 10, 3, 2, 3, 0, 0, 0, 290, 580 },
		{ "Judgement", 4200, 12, 3, 1, 1, 1, 0, 0, 0, 270, 540 },
		{ "Hammer of Wrath", 1800, 4, 1, 0, 0, 0, 0, 0, 0, 360, 720 },
	}))
	addRow("Oakwhisper", "druid", TestPutPlayer("Oakwhisper", "druid", {
		{ "Starfire", 18600, 22, 6, 0, 0, 0, 3, 0, 0, 650, 1300 },
		{ "Wrath", 14200, 40, 8, 0, 0, 0, 4, 0, 0, 290, 580 },
		{ "Moonfire", 6800, 24, 0, 0, 0, 0, 3, 0, 0, 283, 0 },
	}))
	addRow("Stonewall", "warrior", TestPutPlayer("Stonewall", "warrior", {
		{ "AutoAttack", 16400, 90, 8, 12, 18, 16, 0, 22, 10, 140, 280 },
		{ "Revenge", 6200, 28, 4, 2, 6, 5, 0, 0, 4, 180, 360 },
		{ "Cleave", 3800, 14, 2, 1, 3, 2, 0, 0, 0, 230, 460 },
		{ "Heroic Strike", 2400, 10, 1, 1, 2, 2, 0, 0, 1, 200, 400 },
	}))
	addRow("Whisperheal", "priest", TestPutPlayer("Whisperheal", "priest", {
		{ "Shoot", 5200, 70, 6, 4, 0, 0, 0, 0, 0, 68, 136 },
		{ "Smite", 2000, 8, 1, 0, 0, 0, 1, 0, 0, 220, 440 },
	}))

	local a, b
	for a = 1, table.getn(rows) do
		for b = a + 1, table.getn(rows) do
			if rows[b][2] > rows[a][2] then
				rows[a], rows[b] = rows[b], rows[a]
			end
		end
	end
	snap.uids = {}
	for i = 1, table.getn(names) do
		if DPSMateUser[names[i]] then
			table.insert(snap.uids, DPSMateUser[names[i]][1])
		end
	end
	if DPSMate.Options then DPSMate.Options._testSnap = snap end
	if DPSMate.Modules and DPSMate.Modules.DPS then
		DPSMate.Modules.DPS.DB = DPSMateDamageDone
	end
	if DPSMate.Modules and DPSMate.Modules.Damage then
		DPSMate.Modules.Damage.DB = DPSMateDamageDone
	end
	TestPaintBars(rows)
end
