DPSMateFile("DPSMate_PlayerEval.lua")
-- Emberveil-sicheres Detailfenster. Die Original-Details-XML/Lua (Pie, Graph,
-- FauxScrollFrame, UIDropDownMenu) wurden nie geladen; GuardTable hat
-- DetailsDamage:UpdateDetails still zu einem No-Op gemacht.
-- CreateFrame-Typen: Frame / Button / StatusBar.
-- https://emberveil.org/wiki/lua/conventions
-- https://emberveil.org/wiki/lua/widgets/Frame
-- https://emberveil.org/wiki/lua/widgets/StatusBar
-- https://emberveil.org/wiki/lua/widgets/UIObject#setscript

if not DPSMate then return end
DPSMate.Modules = DPSMate.Modules or {}

local B = {}
DPSMate.Breakdown = B
DPSMate.Modules.DetailsDamage = B

local _G = getglobal
local strformat = string.format
local tinsert = table.insert
local tgetn = table.getn

local WIN_W = 470
local PAD = 8
local TITLE_H = 28
local SUB_H = 16
local BAR_H = 16
local BAR_N = 14
local OUT_N = 8
local TEX = "Interface\\AddOns\\DPSMate\\images\\statusbar\\Gloss"

local frame, titleFS, subFS, closeBtn
local bars = {}
local outBars = {}
local outHead
local rows = {}
local nRows = 0
local offset = 0
local selected = 1
local curKey = 1
local curUser
local isPlayers = false
local barR, barG, barB = 0.9, 0.1, 0.1

local OUT_DEF = {
	{ 18, "block",  0.3, 0.7, 1.0, 21, 19, 20 },
	{ 14, "glance", 1.0, 0.7, 0.3, 17, 15, 16 },
	{  1, "hit",    0.9, 0.0, 0.0,  4,  2,  3 },
	{  5, "crit",   0.0, 0.9, 0.0,  8,  6,  7 },
	{  9, "miss",   0.0, 0.0, 1.0, nil, nil, nil },
	{ 10, "parry",  1.0, 1.0, 0.0, nil, nil, nil },
	{ 11, "dodge",  1.0, 0.0, 1.0, nil, nil, nil },
	{ 12, "resist", 0.0, 1.0, 1.0, nil, nil, nil },
}

local ALIASES = {
	"DetailsDamage", "DetailsDamageTotal", "DetailsDamageTaken", "DetailsDamageTakenTotal",
	"DetailsAbsorbs", "DetailsAbsorbsTotal", "DetailsAbsorbsTaken", "DetailsAbsorbsTakenTotal",
	"DetailsAuras", "DetailsAurasTotal",
	"DetailsCasts", "DetailsCastsTotal",
	"DetailsCurePoison", "DetailsCurePoisonTotal", "DetailsCurePoisonReceived",
	"DetailsCureDisease", "DetailsCureDiseaseTotal", "DetailsCureDiseaseReceived",
	"DetailsCCBreaker", "DetailsCCBreakerTotal",
	"DetailsDecurses", "DetailsDecursesTotal", "DetailsDecursesReceived",
	"DetailsDispels", "DetailsDispelsTotal", "DetailsDispelsReceived",
	"DetailsDeaths", "DetailsDeathsTotal",
	"DetailsEDD", "DetailsEDDTotal", "DetailsEDT", "DetailsEDTTotal",
	"DetailsEHealing", "DetailsEHealingTotal", "DetailsEHealingTaken", "DetailsEHealingTakenTotal",
	"DetailsFF", "DetailsFFTotal", "DetailsFFT", "DetailsFFTTotal",
	"DetailsFails", "DetailsFailsTotal",
	"DetailsHealing", "DetailsHealingTotal", "DetailsHealingTaken", "DetailsHealingTakenTotal",
	"DetailsHealingAndAbsorbs", "DetailsHABTotal",
	"DetailsInterrupts", "DetailsInterruptsTotal",
	"DetailsLiftMagic", "DetailsLiftMagicTotal", "DetailsLiftMagicReceived",
	"DetailsOverhealing", "DetailsOverhealingTotal", "DetailsOHealingTaken", "DetailsOverhealingTakenTotal",
	"DetailsProcs", "DetailsProcsTotal",
	"DetailsThreat", "DetailsThreatTotal",
	"Auras",
}

local TITLE_KEY = {
	DMGDone = "dmgdoneby",
	DMGTaken = "dmgtakenby",
	EDTaken = "dmgtakenby",
}

local function L(k, fallback)
	local t = DPSMate and DPSMate.L
	if t and t[k] and t[k] ~= "" then return t[k] end
	return fallback or k
end

local function Pin(region, parent, x, y, w, h)
	if not region then return end
	if region.ClearAllPoints then region:ClearAllPoints() end
	if region.SetPoint then region:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, y or 0) end
	if w and region.SetWidth then region:SetWidth(w) end
	if h and region.SetHeight then region:SetHeight(h) end
end

local function ApplyFS(fs, key, size, color)
	if DPSMate_ApplyFontString then
		DPSMate_ApplyFontString(fs, key, "Fonts\\FRIZQT__.TTF", size, color, "OVERLAY", nil)
	end
end

local function ProbZero(n)
	if not n or n == 0 then return 1 end
	return n
end

local function RowAmount(d)
	if type(d) == "table" then
		return tonumber(d[1]) or 0, d[2]
	end
	return tonumber(d) or 0, nil
end

local function AbilityName(id)
	local n
	if DPSMate and DPSMate.GetAbilityById then
		n = DPSMate:GetAbilityById(id)
	end
	if n and n ~= "" then return n end
	return tostring(id or "?")
end

local function ModeHandler(key)
	local win = DPSMateSettings and DPSMateSettings["windows"] and DPSMateSettings["windows"][key]
	if not win then return nil, nil end
	local mode = win["CurMode"]
	local mod = DPSMate.RegistredModules and DPSMate.RegistredModules[mode]
	return mod, mode, win
end

local function ModeTitle(mode, hist, user)
	if user then
		local key = hist and TITLE_KEY[hist]
		if key then return L(key, "Damage done by ")..user end
		local args = DPSMate.Options and DPSMate.Options.Options and DPSMate.Options.Options[1] and DPSMate.Options.Options[1]["args"]
		local nm = args and args[mode] and args[mode].name or mode or ""
		return tostring(nm).." - "..user
	end
	return L("dmgdonesum", "Damage done summary")
end

local function FindPath(arr, userName, abilityId)
	if not arr or not userName or not abilityId then return end
	local u = DPSMateUser and DPSMateUser[userName]
	if not u then return end
	local block = arr[u[1]]
	if block and block[abilityId] then return block[abilityId] end
	if u[5] and DPSMateUser[u[5]] then
		block = arr[DPSMateUser[u[5]][1]]
		if block and block[abilityId] then return block[abilityId] end
	end
end

local function DamageLike(path)
	return type(path) == "table"
		and type(path[1]) == "number"
		and type(path[5]) == "number"
		and type(path[13]) == "number"
end

local function PlaceLeftText(fs, parent, x, y, h, maxW)
	if not fs or not parent then return end
	local text = ""
	if fs.GetText then text = fs:GetText() or "" end
	local tw = string.len(text) * 9 + 24
	if maxW and maxW > 0 and tw > maxW then tw = maxW end
	if tw < 24 then tw = 24 end
	fs:ClearAllPoints()
	fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	fs:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", x + tw, y - h)
end

local function MakeBar(parent, name)
	local bar = CreateFrame("StatusBar", name, parent)
	if bar.EnableMouse then bar:EnableMouse(true) end
	if bar.EnableMouseWheel then bar:EnableMouseWheel(true) end
	bar:SetMinMaxValues(0, 100)
	bar:SetStatusBarTexture(TEX)
	bar:SetStatusBarColor(0.9, 0.1, 0.1, 1)
	local bg = bar:CreateTexture(name.."_BG", "BACKGROUND")
	if bg then
		bg:SetTexture(TEX)
		if bg.SetVertexColor then bg:SetVertexColor(0, 0, 0, 0.45) end
	end
	local nf = bar:CreateFontString(name.."_Name", "OVERLAY")
	local vf = bar:CreateFontString(name.."_Value", "OVERLAY")
	ApplyFS(nf, "peval_name", 11, { 1, 1, 1 })
	ApplyFS(vf, "peval_value", 11, { 1, 1, 1 })
	bar:SetScript("OnMouseUp", function(self)
		if B.OnBarClick then B:OnBarClick(self) end
	end)
	bar:SetScript("OnMouseWheel", function(self, delta)
		delta = delta or arg1
		if B.OnWheel then B:OnWheel(delta) end
	end)
	return bar, bg, nf, vf
end

function B:Ensure()
	if frame then return frame end
	frame = CreateFrame("Frame", "DPSMate_PlayerEval", UIParent)
	frame:SetWidth(WIN_W)
	frame:SetHeight(430)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetFrameStrata("DIALOG")
	if frame.SetToplevel then frame:SetToplevel(true) end
	if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
	if frame.EnableMouse then frame:EnableMouse(true) end
	if frame.SetMovable then frame:SetMovable(true) end
	if frame.EnableMouseWheel then frame:EnableMouseWheel(true) end
	if DPSMate_ApplyDialogColor then DPSMate_ApplyDialogColor(frame, 1) end
	frame:SetScript("OnMouseDown", function(self)
		if self and self.StartMoving then self:StartMoving() end
	end)
	frame:SetScript("OnMouseUp", function(self)
		if self and self.StopMovingOrSizing then self:StopMovingOrSizing() end
	end)
	frame:SetScript("OnMouseWheel", function(self, delta)
		delta = delta or arg1
		if B.OnWheel then B:OnWheel(delta) end
	end)

	titleFS = frame:CreateFontString("DPSMate_PlayerEval_Title", "OVERLAY")
	ApplyFS(titleFS, "peval_title", 16, { 1, 0.82, 0 })
	Pin(titleFS, frame, PAD, -6, WIN_W - 40, TITLE_H)

	subFS = frame:CreateFontString("DPSMate_PlayerEval_Sub", "OVERLAY")
	ApplyFS(subFS, "peval_sub", 11, { 0.9, 0.9, 0.9 })
	Pin(subFS, frame, PAD, -30, WIN_W - 16, SUB_H)

	closeBtn = CreateFrame("Button", "DPSMate_PlayerEval_Close", frame)
	closeBtn:SetWidth(22)
	closeBtn:SetHeight(18)
	closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
	if closeBtn.EnableMouse then closeBtn:EnableMouse(true) end
	if DPSMate_StylePanelButton then DPSMate_StylePanelButton(closeBtn, "X") end
	closeBtn:SetScript("OnMouseUp", function()
		if frame and frame.Hide then frame:Hide() end
	end)

	local y = -50
	local i
	for i = 1, BAR_N do
		local bar, bg, nf, vf = MakeBar(frame, "DPSMate_PlayerEval_Bar"..i)
		Pin(bar, frame, PAD, y, WIN_W - PAD * 2, BAR_H)
		if bg then Pin(bg, bar, 0, 0, WIN_W - PAD * 2, BAR_H) end
		if bar.SetID then bar:SetID(i) end
		bar.name = nf
		bar.value = vf
		bars[i] = { bar = bar, bg = bg, name = nf, value = vf }
		y = y - BAR_H
	end

	outHead = frame:CreateFontString("DPSMate_PlayerEval_OutHead", "OVERLAY")
	ApplyFS(outHead, "peval_sub", 11, { 1, 0.82, 0 })
	Pin(outHead, frame, PAD, y - 6, WIN_W - PAD * 2, 14)
	y = y - 22
	for i = 1, OUT_N do
		local bar, bg, nf, vf = MakeBar(frame, "DPSMate_PlayerEval_Out"..i)
		Pin(bar, frame, PAD, y, WIN_W - PAD * 2, BAR_H)
		if bg then Pin(bg, bar, 0, 0, WIN_W - PAD * 2, BAR_H) end
		if bar.EnableMouse then bar:EnableMouse(false) end
		bar:SetScript("OnMouseUp", nil)
		bar.name = nf
		bar.value = vf
		outBars[i] = { bar = bar, bg = bg, name = nf, value = vf }
		y = y - BAR_H
	end
	frame:Hide()
	return frame
end

function B:OnWheel(delta)
	if type(delta) ~= "number" then return end
	local maxOff = nRows - BAR_N
	if maxOff < 0 then maxOff = 0 end
	if delta > 0 then
		offset = offset - 1
	else
		offset = offset + 1
	end
	if offset < 0 then offset = 0 end
	if offset > maxOff then offset = maxOff end
	self:PaintList()
end

function B:OnBarClick(bar)
	if not bar or not bar.GetID then return end
	local id = bar:GetID()
	if type(id) ~= "number" then return end
	local idx = offset + id
	local row = rows[idx]
	if not row then return end
	if isPlayers and row.user then
		self:Open(row.user, curKey)
		return
	end
	selected = idx
	self:PaintList()
	self:PaintOut()
end

function B:PaintList()
	local maxAmt = 0
	local i
	for i = 1, nRows do
		if rows[i] and rows[i].amount > maxAmt then maxAmt = rows[i].amount end
	end
	if maxAmt <= 0 then maxAmt = 1 end
	for i = 1, BAR_N do
		local slot = bars[i]
		local row = rows[offset + i]
		if slot and slot.bar then
			if row then
				local perc = 100 * row.amount / maxAmt
				if perc < 0.5 then perc = 0.5 end
				slot.bar:SetStatusBarColor(barR, barG, barB, 1)
				if offset + i == selected then
					slot.bar:SetStatusBarColor(1, 0.82, 0, 1)
				end
				slot.bar:SetValue(perc)
				if slot.name and slot.name.SetText then
					local extra = ""
					if row.pet then extra = " (Pet)" end
					slot.name:SetText((offset + i)..". "..row.label..extra)
				end
				if slot.value and slot.value.SetText then
					local pct = 0
					if row.total and row.total > 0 then pct = 100 * row.amount / row.total end
					slot.value:SetText(strformat("%.2f", row.amount).." ("..strformat("%.2f", pct).."%)")
				end
				slot.bar:Show()
				if DPSMate and DPSMate.LayoutBarText then
					DPSMate:LayoutBarText(slot.bar, WIN_W - PAD * 2, 4)
				end
			else
				slot.bar:Hide()
			end
		end
	end
end

function B:PaintOut()
	local row = rows[selected]
	local path = row and row.path
	local show = DamageLike(path)
	if outHead then
		if show then
			local hit = path[1] + path[5] + path[9] + path[10] + path[11] + path[12] + (path[14] or 0) + (path[18] or 0)
			outHead:SetText("C: "..tostring(hit).."   "..L("ability", "Ability")..": "..(row.label or ""))
			outHead:Show()
		else
			outHead:SetText("")
			outHead:Hide()
		end
	end
	local i
	for i = 1, OUT_N do
		local slot = outBars[i]
		local def = OUT_DEF[i]
		if slot and slot.bar then
			if show and def then
				local count = path[def[1]] or 0
				local total = path[1] + path[5] + path[9] + path[10] + path[11] + path[12] + (path[14] or 0) + (path[18] or 0)
				if total <= 0 then total = 1 end
				local maxc = count
				local j
				for j = 1, OUT_N do
					local d = OUT_DEF[j]
					local c = path[d[1]] or 0
					if c > maxc then maxc = c end
				end
				if maxc <= 0 then maxc = 1 end
				local perc = 100 * count / maxc
				if count > 0 and perc < 0.5 then perc = 0.5 end
				slot.bar:SetStatusBarColor(def[3], def[4], def[5], 1)
				slot.bar:SetValue(perc)
				if slot.name and slot.name.SetText then
					slot.name:SetText(L(def[2], def[2]))
				end
				local extra = ""
				if def[6] and count > 0 then
					local avg = math.floor((path[def[6]] or 0) / ProbZero(count) + 0.5)
					extra = "  "..L("average", "Avg").." "..avg
					if def[7] then extra = extra.."  "..L("min", "Min").." "..(path[def[7]] or 0) end
					if def[8] then extra = extra.."  "..L("max", "Max").." "..(path[def[8]] or 0) end
				end
				if slot.value and slot.value.SetText then
					slot.value:SetText(count.." ("..strformat("%.1f", 100 * count / total).."%)"..extra)
				end
				slot.bar:Show()
				if DPSMate and DPSMate.LayoutBarText then
					DPSMate:LayoutBarText(slot.bar, WIN_W - PAD * 2, 4)
				end
			else
				slot.bar:Hide()
			end
		end
	end
end

function B:FillFromEval(mod, user, key, arr)
	rows = {}
	nRows = 0
	isPlayers = false
	local a, tot, d
	if mod and mod.EvalTable and DPSMateUser and DPSMateUser[user] then
		local ok, ra, rt, rd = pcall(mod.EvalTable, mod, DPSMateUser[user], key)
		if ok then a, tot, d = ra, rt, rd end
	end
	if type(a) ~= "table" then return end
	tot = tonumber(tot) or 0
	local i
	for i = 1, tgetn(a) do
		local amount, pet = RowAmount(d and d[i])
		local rec = {
			id = a[i],
			label = AbilityName(a[i]),
			amount = amount,
			pet = pet,
			total = tot,
			user = nil,
			path = FindPath(arr, user, a[i]),
		}
		nRows = nRows + 1
		rows[nRows] = rec
	end
end

function B:FillFromPlayers(mod, key, arr)
	rows = {}
	nRows = 0
	isPlayers = true
	if not mod or not mod.GetSortedTable then return end
	local ok, amounts, tot, names = pcall(mod.GetSortedTable, mod, arr or {}, key)
	if not ok or type(amounts) ~= "table" then return end
	tot = tonumber(tot) or 0
	local i
	for i = 1, tgetn(names) do
		nRows = nRows + 1
		rows[nRows] = {
			id = i,
			label = tostring(names[i] or "?"),
			amount = tonumber(amounts[i]) or 0,
			total = tot,
			user = names[i],
			path = nil,
		}
	end
end

function B:Open(user, key)
	self:Ensure()
	curKey = key or 1
	curUser = user
	offset = 0
	selected = 1
	local mod, mode = ModeHandler(curKey)
	local arr, cbt, ecbt = {}, 0, {}
	if DPSMate and DPSMate.GetMode then
		arr, cbt, ecbt = DPSMate:GetMode(curKey)
	end
	arr = arr or {}
	cbt = tonumber(cbt) or 0
	ecbt = ecbt or {}
	if user then
		local r, g, b = 0.9, 0.1, 0.1
		if DPSMate and DPSMate.GetClassColor then
			r, g, b = DPSMate:GetClassColor(user)
		end
		barR, barG, barB = r or 0.9, g or 0.1, b or 0.1
		self:FillFromEval(mod, user, curKey, arr)
		if titleFS and titleFS.SetText then
			titleFS:SetText(ModeTitle(mode, mod and mod.Hist, user))
		end
		if subFS and subFS.SetText then
			local act = tonumber(ecbt[user]) or 0
			subFS:SetText(L("activity", "Activity")..": "..strformat("%.2f", act).."s "..L("of", "of").." "..strformat("%.2f", cbt).."s")
		end
	else
		barR, barG, barB = 0.9, 0.82, 0.2
		self:FillFromPlayers(mod, curKey, arr)
		if titleFS and titleFS.SetText then
			titleFS:SetText(ModeTitle(mode, mod and mod.Hist, nil))
		end
		if subFS and subFS.SetText then
			subFS:SetText(L("total", "Total").."  "..strformat("%.2f", cbt).."s")
		end
	end
	if nRows < 1 then
		if DPSMate and DPSMate.SendMessage then
			DPSMate:SendMessage(L("nodetailserror", "There are no details to be reported."))
		end
		return
	end
	PlaceLeftText(titleFS, frame, PAD, -6, TITLE_H, WIN_W - 40)
	PlaceLeftText(subFS, frame, PAD, -30, SUB_H, WIN_W - 16)
	self:PaintList()
	self:PaintOut()
	frame:Show()
	if frame.Raise then frame:Raise() end
end

function B:UpdateDetails(obj, key)
	if obj and obj.user then
		self:Open(obj.user, key)
	else
		self:Open(nil, key)
	end
end

function B:UpdateCompare(obj, key, other)
	if type(other) == "string" and other ~= "" then
		self:Open(other, key)
	else
		self:UpdateDetails(obj, key)
	end
end

local ai
for ai = 1, tgetn(ALIASES) do
	DPSMate.Modules[ALIASES[ai]] = B
end
