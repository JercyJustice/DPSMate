DPSMateFile("DPSMate_Details_Damage.lua")
-- Original tdymel Damage-Details. Nur Emberveil-Anpassungen:
-- Lua 5.1 pairs(), GetSummarizedTable ohne Sync, fehlendes XML -> Fallback.
DPSMate.Modules.DetailsDamage = {}

-- Local variables
local DetailsArr, DetailsTotal, DmgArr, DetailsUser, DetailsSelected  = {}, 0, {}, "", 1
local DetailsArrComp, DetailsTotalComp, DmgArrComp, DetailsUserComp, DetailsSelectedComp  = {}, 0, {}, "", 1
local g, g2, g3, g4, g5, g6, g7
local curKey = 1
local db, cbt, db2 = {}, 0, {}
local _G = getglobal
local tinsert = table.insert
local strformat = string.format
local toggle, toggle2, toggle3 = false, false, false
local t1, t2, TTotal = {}, {}, 0
local t1Comp, t2Comp, TTotalComp = {}, {}, 0
local ecbt = {}
local PSelected = 1
local PSelected2 = 1

-- GraphLib DrawLine setzt BOTTOMLEFT+TOPRIGHT; hier clippt nichts, Achsen
-- und Pie liegen ueber der Welt. Wiki Region SetPoint.
-- https://emberveil.org/wiki/lua/widgets/Region#setpoint
local function HideGraph(gr)
	if not gr then return end
	if gr.SetScript then gr:SetScript("OnUpdate", nil) end
	if gr.HideLines then pcall(gr.HideLines, gr, gr) end
	if gr.HideFontStrings then pcall(gr.HideFontStrings, gr) end
	if gr.HideTextures then pcall(gr.HideTextures, gr) end
	if gr.GetChildren then
		local kids = { gr:GetChildren() }
		local i
		for i = 1, table.getn(kids) do
			if kids[i] and kids[i].Hide then kids[i]:Hide() end
		end
	end
	if gr.GetRegions then
		local regs = { gr:GetRegions() }
		local i
		for i = 1, table.getn(regs) do
			if regs[i] and regs[i].Hide then regs[i]:Hide() end
		end
	end
	if gr.Hide then gr:Hide() end
end

-- Beide Anker an TOPLEFT: feste Box, laeuft nicht in Nachbarpanels.
-- SetWidth auf FontStrings wird oft ignoriert.
-- https://emberveil.org/wiki/lua/widgets/Region#setpoint
local function PinFS(fs, parent, x, y, w, h)
	if not fs or not parent then return end
	if fs.ClearAllPoints then fs:ClearAllPoints() end
	if fs.SetPoint then
		fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
		fs:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", x + (w or 40), y - (h or 14))
	end
end

local function PlaceDetailsText(fs, parent, x, y, h, maxW)
	if not fs or not parent then return end
	local text = ""
	if fs.GetText then text = fs:GetText() or "" end
	local tw = string.len(text) * 8 + 12
	if maxW and maxW > 0 and tw > maxW then tw = maxW end
	if tw < 24 then tw = 24 end
	PinFS(fs, parent, x, y, tw, h)
end

-- SetJustifyH wird ignoriert: Box am LEFT, breit genug fuer das Wort.
local function LeftText(fs, parent, x, y, h, maxW)
	if not fs or not parent then return end
	local t = ""
	if fs.GetText then t = fs:GetText() or "" end
	local tw = string.len(t) * 7 + 8
	if tw < 48 then tw = 48 end
	if maxW and maxW > 0 and tw > maxW then tw = maxW end
	PinFS(fs, parent, x, y, tw, h or 13)
end

local graphBars = {}
local graphTexs = {}
local graphLabs = {}
local GRAPH_W = 800
local GRAPH_H = 200

function DPSMate.Modules.DetailsDamage:DrawTimeGraph()
	local parent = DPSMate_Details_DiagramLine
	if not parent then return end
	local gi
	for gi = 1, 120 do
		local old = _G("DPSMate_Details_GBar"..gi)
		if old and old.Hide then old:Hide() end
		local tex = _G("DPSMate_Details_GTex"..gi)
		if tex and tex.Hide then tex:Hide() end
		local col = _G("DPSMate_Details_GCol"..gi)
		if col and col.Hide then col:Hide() end
	end
	for gi = 1, table.getn(graphTexs) do
		if graphTexs[gi] and graphTexs[gi].Hide then graphTexs[gi]:Hide() end
	end
	local canvas = _G("DPSMate_Details_GraphCanvas")
	if canvas and canvas.Hide then canvas:Hide() end

	local sumTable
	local ok, st = pcall(function()
		return self:GetSummarizedTable(db, nil)
	end)
	if ok then sumTable = st end
	if type(sumTable) ~= "table" then sumTable = {} end
	local n = table.getn(sumTable)
	local useAbilities = n < 2
	local maxV = 0
	local series = {}
	local i
	if useAbilities and DetailsArr and DmgArr then
		n = DPSMate:TableLength(DetailsArr)
		for i = 1, n do
			local amt = 0
			if DmgArr[i] then amt = tonumber(DmgArr[i][1]) or 0 end
			series[i] = amt
			if amt > maxV then maxV = amt end
		end
	else
		for i = 1, n do
			local v = sumTable[i]
			local amt = 0
			if type(v) == "table" then amt = tonumber(v[2]) or 0 end
			series[i] = amt
			if amt > maxV then maxV = amt end
		end
	end
	if maxV < 1 then maxV = 1 end
	n = table.getn(series)

	local yi
	-- Nur 3 Labels im Graph (250px): oben / Mitte / unten. Keine Werte auf Procs/Pie.
	local yvals = { maxV, maxV * 0.5, 0 }
	local ypos = { -10, -90, -170 }
	for yi = 1, 3 do
		local fs = graphLabs[yi]
		if not fs then
			fs = parent:CreateFontString("DPSMate_Details_GY"..yi, "OVERLAY")
			graphLabs[yi] = fs
		end
		if DPSMate_ApplyFontString then
			DPSMate_ApplyFontString(fs, "details_glab", "Fonts\\FRIZQT__.TTF", 10, { 1, 1, 1 }, "OVERLAY")
		end
		fs:SetText(strformat("%.0f", yvals[yi]))
		LeftText(fs, parent, 4, ypos[yi], 12, 40)
		fs:Show()
	end
	for yi = 4, table.getn(graphLabs) do
		if graphLabs[yi] and graphLabs[yi].Hide then graphLabs[yi]:Hide() end
	end

	local maxBars = 60
	local step = 1
	if n > maxBars then step = math.ceil(n / maxBars) end
	local count = 0
	for i = 1, n, step do count = count + 1 end
	if count < 1 then
		for i = 1, table.getn(graphBars) do
			if graphBars[i] then graphBars[i]:Hide() end
		end
		for i = 1, table.getn(graphTexs) do
			if graphTexs[i] and graphTexs[i].Hide then graphTexs[i]:Hide() end
		end
		return
	end
	-- GCol-Frames ignorieren BOTTOMRIGHT und wachsen durch Procs/Pie.
	-- Saeulen als Texture auf DiagramLine, gleiche PinFS-Anker.
	local bw = 8
	local inner = 800
	if count > 0 and inner / count < 8 then
		bw = inner / count
	end
	if bw < 2 then bw = 2 end
	if bw > 8 then bw = 8 end
	local idx = 0
	for i = 1, n, step do
		idx = idx + 1
		local x = 48 + (idx - 1) * bw
		if x + bw > 860 then break end
		local tex = graphTexs[idx]
		if not tex then
			tex = parent:CreateTexture("DPSMate_Details_GTex"..idx, "ARTWORK")
			graphTexs[idx] = tex
		end
		local val = series[i] or 0
		local maxH = 200
		local h = maxH * (val / maxV)
		if h < 3 then h = 3 end
		if h > maxH then h = maxH end
		local yTop = -(18 + (maxH - h))
		if tex.ClearAllPoints then tex:ClearAllPoints() end
		if tex.SetPoint then
			tex:SetPoint("TOPLEFT", parent, "TOPLEFT", x, yTop)
			tex:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", x + bw - 1, -218)
		end
		if tex.SetTexture then tex:SetTexture(0.85, 0.12, 0.12, 1) end
		if tex.Show then tex:Show() end
	end
	for i = idx + 1, table.getn(graphTexs) do
		if graphTexs[i] and graphTexs[i].Hide then graphTexs[i]:Hide() end
	end
	for i = 1, table.getn(graphBars) do
		if graphBars[i] and graphBars[i].Hide then graphBars[i]:Hide() end
	end
end

function DPSMate.Modules.DetailsDamage:EnsureLogButtons(comp)
	if not comp then comp = "" end
	local path = "DPSMate_Details"..comp.."_Log"
	local parent = _G(path)
	if not parent then return end
	local i
	for i = 1, 10 do
		local bname = path.."_ScrollButton"..i
		local btn = _G(bname)
		if not btn then
			btn = CreateFrame("Button", bname, parent)
		end
		if btn.SetID then btn:SetID(i) end
		if btn.EnableMouse then btn:EnableMouse(true) end
		local y = -4 - (i - 1) * 17
		btn:ClearAllPoints()
		btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
		btn:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", 198, y - 16)
		local icon = _G(bname.."_Icon")
		if not icon and btn.CreateTexture then
			icon = btn:CreateTexture(bname.."_Icon", "ARTWORK")
		end
		if icon then
			icon:Hide()
		end
		local nf = _G(bname.."_Name")
		if not nf and btn.CreateFontString then
			nf = btn:CreateFontString(bname.."_Name", "OVERLAY")
		end
		local vf = _G(bname.."_Value")
		if not vf and btn.CreateFontString then
			vf = btn:CreateFontString(bname.."_Value", "OVERLAY")
		end
		if DPSMate_ApplyFontString then
			DPSMate_ApplyFontString(nf, "details_log_name", "Fonts\\FRIZQT__.TTF", 9, {1, 1, 1}, "OVERLAY")
			DPSMate_ApplyFontString(vf, "details_log_value", "Fonts\\FRIZQT__.TTF", 9, {1, 1, 1}, "OVERLAY")
		end
		if nf and nf.SetNonSpaceWrap then nf:SetNonSpaceWrap(false) end
		if vf then vf:Hide() end
		btn.name = nf
		btn.value = vf
		local id, c = i, comp
		btn:SetScript("OnClick", function(self)
			local n = (self and self.GetID and self:GetID()) or id
			DPSMate.Modules.DetailsDamage:SelectDetailsButton(n, c)
		end)
		btn:Show()
	end
end

function DPSMate.Modules.DetailsDamage:UpdateDetails(obj, key)
	if not DPSMate_Details then
		if DPSMate.Breakdown and DPSMate.Breakdown.UpdateDetails then
			DPSMate.Breakdown:UpdateDetails(obj, key)
		end
		return
	end
	curKey = key
	db, cbt,ecbt = DPSMate:GetMode(key)
	db2 = DPSMate:GetModeByArr(DPSMateEDT, key, "EDTaken")
	DPSMate_Details.proc = "None"
	if UIDropDownMenu_SetSelectedValue and DPSMate_Details_DiagramLegend_Procs then
		pcall(UIDropDownMenu_SetSelectedValue, DPSMate_Details_DiagramLegend_Procs, "None")
	end
	DetailsUser = obj.user
	DetailsUserComp = nil
	if DPSMate_ApplyDialogColor then DPSMate_ApplyDialogColor(DPSMate_Details, 1) end
	if DPSMate_Details_Title then
		DPSMate_Details_Title:SetText(DPSMate.L["dmgdoneby"]..obj.user)
		if DPSMate_ApplyFontString then
			DPSMate_ApplyFontString(DPSMate_Details_Title, "details_title", "Fonts\\FRIZQT__.TTF", 12, {1, 0.82, 0}, "OVERLAY")
		end
		if DPSMate_Details_Title.SetNonSpaceWrap then DPSMate_Details_Title:SetNonSpaceWrap(false) end
		PinFS(DPSMate_Details_Title, DPSMate_Details, 12, -4, 420, 16)
	end
	if DPSMate_Details_SubTitle then
		local act = DPSMate.L["activity"] or "Activity"
		if not strfind(act, ":") then act = act..": " end
		if strsub(act, -1) ~= " " then act = act.." " end
		DPSMate_Details_SubTitle:SetText(act..strformat("%.2f", (ecbt[obj.user] or 0)+1).."s "..DPSMate.L["of"].." "..strformat("%.2f", cbt).."s ("..strformat("%.2f", 100*((ecbt[obj.user] or 0)+1)/cbt).."%)")
		if DPSMate_ApplyFontString then
			DPSMate_ApplyFontString(DPSMate_Details_SubTitle, "details_sub", "Fonts\\FRIZQT__.TTF", 10, {1, 0.82, 0}, "OVERLAY")
		end
		if DPSMate_Details_SubTitle.SetNonSpaceWrap then DPSMate_Details_SubTitle:SetNonSpaceWrap(false) end
		PinFS(DPSMate_Details_SubTitle, DPSMate_Details, 12, -20, 420, 13)
	end
	DPSMate_Details:Show()
	if UIDropDownMenu_Initialize and DPSMate_Details_DiagramLegend_Procs then
		pcall(UIDropDownMenu_Initialize, DPSMate_Details_DiagramLegend_Procs, DPSMate.Modules.DetailsDamage.ProcsDropDown)
	end
	DetailsArr, DetailsTotal, DmgArr = DPSMate.Modules.Damage:EvalTable(DPSMateUser[DetailsUser], curKey)
	t1, t2, TTotal = self:EvalToggleTable()
	
	HideGraph(g)
	HideGraph(g2)
	HideGraph(g3)
	HideGraph(_G("DMGLineGraph"))
	HideGraph(_G("DMGPieChart"))
	HideGraph(_G("DMGStackedGraph"))
	if DPSMate.Options and DPSMate.Options.graph and DPSMate.Options.graph.HideLines then
		if DPSMate_Details_LogDetails then
			pcall(DPSMate.Options.graph.HideLines, DPSMate.Options.graph, DPSMate_Details_LogDetails)
		end
		if DPSMate_Details_DiagramLine then
			pcall(DPSMate.Options.graph.HideLines, DPSMate.Options.graph, DPSMate_Details_DiagramLine)
		end
	end
	self:EnsureLogButtons("")
	
	if toggle then
		self:Player_Update("")
		self:PlayerSpells_Update(1,"")
		self:SelectDetailsButton(1,"")
	else
		self:ScrollFrame_Update("")
		self:SelectDetailsButton(1,"")
	end
	self:DrawTimeGraph()
	self:RelayoutLogDetails("")
	
	DPSMate_Details_CompareDamage:Hide()
	DPSMate_Details_CompareDamage_Graph:Hide()
	
	-- Nicht durch UIParent:GetScale teilen: auf diesem Client kommt oft
	-- ein kleiner Wert, Scale wird dann wieder ~1 und das Fenster riesig.
	if DPSMate_Details.SetScale then DPSMate_Details:SetScale(0.48) end
	if DPSMate_Details.SetFrameStrata then DPSMate_Details:SetFrameStrata("TOOLTIP") end
	if DPSMate_Details.SetToplevel then DPSMate_Details:SetToplevel(true) end
	if DPSMate_Details.Raise then DPSMate_Details:Raise() end
	-- Nur den Maus-Blocker aus: Compare-Graph ist 1800px breit, enableMouse.
	local function Quiet(f)
		if not f then return end
		if f.Hide then f:Hide() end
		if f.EnableMouse then f:EnableMouse(false) end
	end
	Quiet(DPSMate_Details_CompareDamage)
	Quiet(DPSMate_Details_CompareDamage_Graph)
	Quiet(_G("DPSMate_Details_GraphCanvas"))
	local qi
	for qi = 1, 120 do
		local gc = _G("DPSMate_Details_GCol"..qi)
		if gc and gc.EnableMouse then gc:EnableMouse(false) end
	end
	-- Nur Farbe, kein neues Backdrop (das lag als Layer ueber dem Inhalt).
	local function Paint(f)
		if f and f.SetBackdropColor then f:SetBackdropColor(0.20, 0.17, 0.14, 1) end
	end
	Paint(DPSMate_Details)
	Paint(DPSMate_Details_DiagramLine)
	Paint(DPSMate_Details_Diagram)
	Paint(DPSMate_Details_DiagramLegend)
	Paint(DPSMate_Details_Log)
	Paint(DPSMate_Details_LogDetails)
	
end

function DPSMate.Modules.DetailsDamage:RelayoutLogDetails(comp)
	if not comp then comp = "" end
	local p = _G("DPSMate_Details"..comp.."_LogDetails")
	if not p then return end
	local function style(fs, gold)
		if not fs then return end
		if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end
		if DPSMate_ApplyFontString then
			local c = gold and {1, 0.82, 0} or {1, 1, 1}
			DPSMate_ApplyFontString(fs, gold and "details_ldg" or "details_ldw", "Fonts\\FRIZQT__.TTF", 9, c, "OVERLAY")
		end
	end
	local function pin(name, x, y, w, h, gold)
		local fs = _G("DPSMate_Details"..comp.."_LogDetails_"..name)
		style(fs, gold)
		if fs then LeftText(fs, p, x, y, h, w) end
		return fs
	end
	-- Alles innerhalb 370px (LogDetails ist 380 breit).
	pin("Casts", 6, -4, 50, 13, true)
	pin("Amount", 58, -4, 120, 13, true)
	-- Avg/Min/Max liegen per XML rechts ausserhalb; ausblenden.
	local hideExtra = {"Average", "Min", "Max"}
	local hi
	for hi = 1, 3 do
		local fs = _G("DPSMate_Details"..comp.."_LogDetails_"..hideExtra[hi])
		if fs and fs.Hide then fs:Hide() end
	end
	local rows = {"Block", "Glance", "Hit", "Crit", "Miss", "Parry", "Dodge", "Resist"}
	local i
	for i = 1, 8 do
		local y = -16 - (i - 1) * 14
		pin(rows[i], 6, y, 52, 15, true)
		local hx
		for hx = 0, 7 do
			local a = _G("DPSMate_Details"..comp.."_LogDetails_Average"..hx)
			local mn = _G("DPSMate_Details"..comp.."_LogDetails_Min"..hx)
			local mx = _G("DPSMate_Details"..comp.."_LogDetails_Max"..hx)
			if a then a:Hide() end
			if mn then mn:Hide() end
			if mx then mx:Hide() end
		end
		local wrap = _G("DPSMate_Details"..comp.."_LogDetails_Amount"..(i - 1))
		if wrap then
			wrap:ClearAllPoints()
			wrap:SetPoint("TOPLEFT", p, "TOPLEFT", 58, y)
			wrap:SetPoint("BOTTOMRIGHT", p, "TOPLEFT", 230, y - 15)
			if wrap.EnableMouse then wrap:EnableMouse(false) end
		end
		local amt = _G("DPSMate_Details"..comp.."_LogDetails_Amount"..(i - 1).."_Amount")
		local pct = _G("DPSMate_Details"..comp.."_LogDetails_Amount"..(i - 1).."_Percent")
		local bar = _G("DPSMate_Details"..comp.."_LogDetails_Amount"..(i - 1).."_StatusBar")
		style(amt, false)
		style(pct, false)
		if amt then LeftText(amt, p, 58, y, 15) end
		if pct then LeftText(pct, p, 168, y, 15) end
		if bar then
			bar:ClearAllPoints()
			bar:SetPoint("TOPLEFT", p, "TOPLEFT", 96, y - 2)
			bar:SetPoint("BOTTOMRIGHT", p, "TOPLEFT", 162, y - 13)
			if bar.EnableMouse then bar:EnableMouse(false) end
		end
	end
end

function DPSMate.Modules.DetailsDamage:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)
	
	DPSMate_Details_CompareDamage.proc = "None"
	UIDropDownMenu_SetSelectedValue(DPSMate_Details_CompareDamage_DiagramLegend_Procs, "None")
	DetailsUserComp = comp
	DPSMate_Details_CompareDamage_Title:SetText(DPSMate.L["dmgdoneby"]..comp)
	DPSMate_Details_CompareDamage_SubTitle:SetText(DPSMate.L["activity"]..strformat("%.2f", DPSMateCombatTime["effective"][key][comp] or 0).."s "..DPSMate.L["of"].." "..strformat("%.2f", cbt).."s ("..strformat("%.2f", 100*(DPSMateCombatTime["effective"][key][comp] or 0)/cbt).."%)")
	UIDropDownMenu_Initialize(DPSMate_Details_CompareDamage_DiagramLegend_Procs, DPSMate.Modules.DetailsDamage.ProcsDropDown_CompareDamage)
	DetailsArrComp, DetailsTotalComp, DmgArrComp = DPSMate.RegistredModules[DPSMateSettings["windows"][curKey]["CurMode"]]:EvalTable(DPSMateUser[comp], curKey)
	t1Comp, t2Comp, TTotalComp = self:EvalToggleTable(comp)
	
	if not g4 then
		g4=DPSMate.Options.graph:CreateGraphPieChart("DMGPieChartComp", DPSMate_Details_CompareDamage_Diagram, "CENTER", "CENTER", 0, 0, 200, 200)
		g5=DPSMate.Options.graph:CreateGraphLine("DMGLineGraphComp",DPSMate_Details_CompareDamage_DiagramLine,"CENTER","CENTER",0,0,850,230)
		g6=DPSMate.Options.graph:CreateStackedGraph("DMGStackedGraphComp",DPSMate_Details_CompareDamage_DiagramLine,"CENTER","CENTER",0,0,850,230)
		g6:SetGridColor({0.5,0.5,0.5,0.5})
		g6:SetAxisDrawing(true,true)
		g6:SetAxisColor({1.0,1.0,1.0,1.0})
		g6:SetAutoScale(true)
		g6:SetYLabels(true, false)
		g6:SetXLabels(true)
		g7=DPSMate.Options.graph:CreateGraphLine("DMGLineGraphSum",DPSMate_Details_CompareDamage_Graph,"CENTER","CENTER",0,0,1750,230)
	end
	
	if toggle then
		self:Player_Update("_CompareDamage")
		self:PlayerSpells_Update(1, "_CompareDamage")
		self:SelectDetailsButton(1, "_CompareDamage")
		DPSMate_Details_CompareDamage_playerSpells:Show()
		DPSMate_Details_CompareDamage_player:Show()
		DPSMate_Details_CompareDamage_Diagram:Hide()
		DPSMate_Details_CompareDamage_Log:Hide()
	else
		self:ScrollFrame_Update("_CompareDamage")
		self:SelectDetailsButton(1,"_CompareDamage")
		DPSMate_Details_CompareDamage_playerSpells:Hide()
		DPSMate_Details_CompareDamage_player:Hide()
		DPSMate_Details_CompareDamage_Diagram:Show()
		DPSMate_Details_CompareDamage_Log:Show()
	end
	self:UpdatePie(g4, comp)
	if toggle2 then
		self:UpdateStackedGraph(g6, "_CompareDamage", comp)
	else
		self:UpdateLineGraph(g5, "_CompareDamage", comp)
	end
	self:UpdateSumGraph()
	
	DPSMate_Details_CompareDamage:Show()
	DPSMate_Details_CompareDamage_Graph:Show()
end

function DPSMate.Modules.DetailsDamage:UpdateSumGraph()
	-- Executing the sumGraph
	local sumTable, sumTableTwo
	if toggle3 then
		sumTable = self:GetSummarizedTable(db2, t1Comp[PSelected2], DetailsUserComp)
		sumTableTwo = self:GetSummarizedTable(db2, t1[PSelected])
	else
		sumTable = self:GetSummarizedTable(db, nil, DetailsUserComp)
		sumTableTwo = self:GetSummarizedTable(db, nil)
	end
	
	local max = DPSMate:GetMaxValue(sumTable, 2)
	local time = DPSMate:GetMaxValue(sumTable, 1)
	local min = DPSMate:GetMinValue(sumTable, 1)
	local maxT = DPSMate:GetMaxValue(sumTableTwo, 2)
	local timeT = DPSMate:GetMaxValue(sumTableTwo, 1)
	local minT = DPSMate:GetMinValue(sumTableTwo, 1)
	local smax, smin, stime = max, min, time
	
	if max<maxT then
		smax = maxT
	end
	if min>minT then
		smin = minT
	end
	if time<timeT then
		stime = timeT
	end
	g7:ResetData()
	g7:SetXAxis(0,stime-smin)
	g7:SetYAxis(0,smax+200)
	g7:SetGridSpacing((stime-smin)/20,smax/7)
	g7:SetGridColor({0.5,0.5,0.5,0.5})
	g7:SetAxisDrawing(true,true)
	g7:SetAxisColor({1.0,1.0,1.0,1.0})
	g7:SetAutoScale(true)
	g7:SetYLabels(true, false)
	g7:SetXLabels(true)
	
	local ata={{0,0}}
	for cat, val in pairs(DPSMate:ScaleDown(sumTable, min)) do
		tinsert(ata, {val[1],val[2], self:CheckProcs(DPSMate_Details_CompareDamage.proc, val[1]+min+1, DetailsUserComp)})
	end
	
	local Data2={{0,0}}
	for cat, val in pairs(DPSMate:ScaleDown(sumTableTwo, minT)) do
		tinsert(Data2, {val[1],val[2], self:CheckProcs(DPSMate_Details.proc, val[1]+minT+1)})
	end

	g7:AddDataSeries(ata,{{0.2,0.8,0.2,0.8}, {0.5,0.8,0.9,0.8}}, self:AddProcPoints(DPSMate_Details_CompareDamage.proc, ata, DetailsUserComp))
	g7:AddDataSeries(Data2,{{1.0,0.0,0.0,0.8}, {1.0,1.0,0.0,0.8}}, self:AddProcPoints(DPSMate_Details.proc, Data2))
	g7:Show()
end

function DPSMate.Modules.DetailsDamage:EvalToggleTable(comp)
	local a,b = {},{}
	local d = 0
	for cat, val in pairs(db2) do
		if val[DPSMateUser[comp or DetailsUser][1]] then
			local c = {[1] = 0,[2] = {},[3] = {}}
			for p, v in pairs(val[DPSMateUser[comp or DetailsUser][1]]) do
				if p ~= "i" then
					local i = 1
					while true do
						if (not c[2][i]) then
							tinsert(c[3], i, v)
							tinsert(c[2], i, p)
							break
						else
							if c[3][i][13] < v[13] then
								tinsert(c[3], i, v)
								tinsert(c[2], i, p)
								break
							end
						end
						i=i+1
					end
				end
			end
			c[1] = val[DPSMateUser[comp or DetailsUser][1]]["i"]
			-- pet
			if DPSMateUser[cname or DetailsUser][5] and DPSMateUser[DPSMateUser[cname or DetailsUser][5]] and DPSMateSettings["mergepets"] and DPSMateUser[cname or DetailsUser][5] ~= (cname or DetailsUser) then
				if val[DPSMateUser[DPSMateUser[cname or DetailsUser][5]][1]] then
					for p, v in pairs(val[DPSMateUser[DPSMateUser[cname or DetailsUser][5]][1]]) do
						if p ~= "i" then
							local i = 1
							while true do
								if (not c[2][i]) then
									tinsert(c[3], i, v)
									tinsert(c[2], i, p)
									break
								else
									if c[3][i][13] < v[13] then
										tinsert(c[3], i, v)
										tinsert(c[2], i, p)
										break
									end
								end
								i=i+1
							end
						end
					end
					c[1] = c[1] + val[DPSMateUser[DPSMateUser[cname or DetailsUser][5]][1]]["i"]
				end
			end
			local i = 1
			while true do
				if (not a[i]) then
					tinsert(b, i, c)
					tinsert(a, i, cat)
					break
				else
					if b[i][1] < c[1] then
						tinsert(b, i, c)
						tinsert(a, i, cat)
						break
					end
				end
				i=i+1
			end
			d = d + c[1]
		end
	end
	return a,b,d
end

function DPSMate.Modules.DetailsDamage:ScrollFrame_Update(comp)
	if not comp then comp = DPSMate_Details.LastScroll or "" end
	local line, lineplusoffset
	local obj = _G("DPSMate_Details"..comp.."_Log_ScrollFrame")
	local path = "DPSMate_Details"..comp.."_Log"
	local uArr, dArr, dTot, dSel = DetailsArr, DmgArr, DetailsTotal, DetailsSelected
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
		dSel = DetailsSelectedComp
	end
	local pet, len = "", DPSMate:TableLength(uArr)
	if comp ~= "" and comp~=nil then
		local coeff = len-10
		if not obj.oset or obj.oset<0 then
			obj.oset = 0
		end
		if coeff>0 then
			if (coeff-obj.oset)<0 then
				obj.oset = coeff
			end
			FauxScrollFrame_SetOffset(obj, obj.oset)
		end
	end
	if obj then FauxScrollFrame_Update(obj,len,10,24) end
	local logf = _G(path)
	for line=1,10 do
		lineplusoffset = line + ((obj and FauxScrollFrame_GetOffset(obj)) or 0)
		local btn = _G(path.."_ScrollButton"..line)
		local nameFS = _G(path.."_ScrollButton"..line.."_Name")
		local valFS = _G(path.."_ScrollButton"..line.."_Value")
		local icon = _G(path.."_ScrollButton"..line.."_Icon")
		local sel = _G(path.."_ScrollButton"..line.."_selected")
		if uArr and uArr[lineplusoffset] ~= nil and btn then
			if dArr[lineplusoffset] and dArr[lineplusoffset][2] then pet="(Pet)" else pet="" end
			local ability = DPSMate:GetAbilityById(uArr[lineplusoffset]) or tostring(uArr[lineplusoffset])
			local amt, pct = 0, 0
			if dArr[lineplusoffset] then amt = dArr[lineplusoffset][1] or 0 end
			if dTot and dTot > 0 then pct = amt * 100 / dTot end
			if nameFS and nameFS.SetText then
				local ab = ability..pet
				if string.len(ab) > 22 then ab = strsub(ab, 1, 21)..".." end
				nameFS:SetText(lineplusoffset..". "..ab.." "..strformat("%d", amt))
			end
			if valFS then valFS:Hide() end
			if icon and icon.SetTexture and DPSMate.BabbleSpell and DPSMate.BabbleSpell.GetSpellIcon then
				local iname = strsub(ability, 1, (strfind(ability, "%(") or 0)-1) or ability
				local ok, tex = pcall(DPSMate.BabbleSpell.GetSpellIcon, DPSMate.BabbleSpell, iname)
				if ok and tex then icon:SetTexture(tex) else icon:SetTexture("Interface\\AddOns\\DPSMate\\images\\dummy") end
			end
			local y = -4 - (line - 1) * 17
			btn:ClearAllPoints()
			btn:SetPoint("TOPLEFT", logf or btn:GetParent(), "TOPLEFT", 4, y)
			btn:SetPoint("BOTTOMRIGHT", logf or btn:GetParent(), "TOPLEFT", 198, y - 16)
			btn:Show()
			if nameFS and nameFS.SetNonSpaceWrap then nameFS:SetNonSpaceWrap(false) end
			if DPSMate_ApplyFontString then
				DPSMate_ApplyFontString(nameFS, "details_log_name", "Fonts\\FRIZQT__.TTF", 9, {1, 1, 1}, "OVERLAY")
			end
			LeftText(nameFS, btn, 3, -1, 13, 160)
			if valFS then valFS:Hide() end
			if sel then sel:Hide() end
		elseif btn then
			btn:Hide()
		end
		if sel then sel:Hide() end
	end
end

function DPSMate.Modules.DetailsDamage:Player_Update(comp)
	if not comp then comp = DPSMate_Details.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMate_Details"..comp.."_player"
	local obj = _G(path.."_ScrollFrame")
	local d1,d2,d3,d4 = t1,t2,TTotal,PSelected
	if comp ~= "" and comp~=nil then
		d1 = t1Comp
		d2 = t2Comp
		d3 = TTotalComp
		d4 = PSelected2
	end
	local len = DPSMate:TableLength(d1)
	local coeff = len-8
	if not obj.oset or obj.oset<0 then
		obj.oset = 0
	end
	if coeff>0 then
		if (coeff-obj.oset)<0 then
			obj.oset = coeff
		end
		FauxScrollFrame_SetOffset(obj, obj.oset)
	end
	FauxScrollFrame_Update(obj,len,8,24)
	for line=1,8 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if d1[lineplusoffset] ~= nil then
			local user = DPSMate:GetUserById(d1[lineplusoffset])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(user)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(d2[lineplusoffset][1].." ("..strformat("%.2f", (d2[lineplusoffset][1]*100/d3)).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture("Interface\\AddOns\\DPSMate\\images\\npc")
			if len < 8 then
				_G(path.."_ScrollButton"..line):SetWidth(235)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(125)
			else
				_G(path.."_ScrollButton"..line):SetWidth(220)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(110)
			end
			_G(path.."_ScrollButton"..line):Show()
		else
			_G(path.."_ScrollButton"..line):Hide()
		end
		_G(path.."_ScrollButton"..line.."_selected"):Hide()
		if d4 == lineplusoffset then
			_G(path.."_ScrollButton"..line.."_selected"):Show()
		end
	end
end

function DPSMate.Modules.DetailsDamage:PlayerSpells_Update(i, comp)
	if not comp then comp = DPSMate_Details.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMate_Details"..comp.."_playerSpells"
	local obj = _G(path.."_ScrollFrame")
	obj.id = (i + FauxScrollFrame_GetOffset(_G("DPSMate_Details"..comp.."_player_ScrollFrame"))) or obj.id
	local d1,d2,d3,d4 = t1,t2,TTotal,PSelected
	if comp ~= "" and comp~=nil then
		d2 = t2Comp
		d4 = PSelected2
	end
	local len = DPSMate:TableLength(d2[i][2])
	local coeff = len-8
	if not obj.oset or obj.oset<0 then
		obj.oset = 0
	end
	if coeff>0 then
		if (coeff-obj.oset)<0 then
			obj.oset = coeff
		end
		FauxScrollFrame_SetOffset(obj, obj.oset)
	end

	FauxScrollFrame_Update(obj,len,10,24)
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if d2[obj.id][2][lineplusoffset] ~= nil then
			local ability = DPSMate:GetAbilityById(d2[obj.id][2][lineplusoffset])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(ability)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(d2[obj.id][3][lineplusoffset][13].." ("..strformat("%.2f", (d2[obj.id][3][lineplusoffset][13]*100/d2[obj.id][1])).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture(DPSMate.BabbleSpell:GetSpellIcon(strsub(ability, 1, (strfind(ability, "%(") or 0)-1) or ability))
			if len < 10 then
				_G(path.."_ScrollButton"..line):SetWidth(235)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(125)
			else
				_G(path.."_ScrollButton"..line):SetWidth(220)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(110)
			end
			_G(path.."_ScrollButton"..line):Show()
		else
			_G(path.."_ScrollButton"..line):Hide()
		end
		_G(path.."_ScrollButton"..line.."_selected"):Hide()
		if DetailsSelected == lineplusoffset then
			_G(path.."_ScrollButton"..line.."_selected"):Show()
		end
	end
	if comp ~= "" and comp~=nil then
		PSelected2 = obj.id
	else
		PSelected = obj.id
	end
	for p=1, 8 do
		_G("DPSMate_Details"..comp.."_player_ScrollButton"..p.."_selected"):Hide()
	end
	_G("DPSMate_Details"..comp.."_player_ScrollButton"..i.."_selected"):Show()
	if toggle3 then
		if toggle2 then
			if comp ~= "" and comp~=nil then
				self:UpdateStackedGraph(g6, comp, DetailsUserComp)
			else
				self:UpdateStackedGraph(g3)
			end
		else
			if comp ~= "" and comp~=nil then
				self:UpdateLineGraph(g5, comp, DetailsUserComp)
			else
				self:UpdateLineGraph(g2, "")
			end
		end
		if DetailsUserComp then
			self:UpdateSumGraph()
		end
	end
end

function DPSMate.Modules.DetailsDamage:SelectDetailsButton(i, comp, cname)
	if not comp then comp = DPSMate_Details.LastScroll or "" end
	local pathh = ""
	local path,obj,lineplusoffset
	local uArr, dSel, d2 = DetailsArr, DetailsSelected, t2
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dSel = DetailsSelectedComp
		if not cname then
			cname = DetailsUserComp
		end
		d2 = t2Comp
	end
	local user, pet = DPSMateUser[cname or DetailsUser][1], ""
	if toggle then
		pathh = "DPSMate_Details"..comp.."_playerSpells"
		obj = _G(pathh.."_ScrollFrame")
		lineplusoffset = i + (FauxScrollFrame_GetOffset(obj) or 0)
		path = d2[obj.id][3][lineplusoffset]
	else
		pathh = "DPSMate_Details"..comp.."_Log"
		obj = _G(pathh.."_ScrollFrame")
		lineplusoffset = i + (FauxScrollFrame_GetOffset(obj) or 0)
		local ability = tonumber(uArr[lineplusoffset])
		if (db[DPSMateUser[cname or DetailsUser][1]][ability]) then user=DPSMateUser[cname or DetailsUser][1]; pet=0; else if DPSMateUser[cname or DetailsUser][5] and DPSMateUser[cname or DetailsUser][5]~=(cname or DetailsUser) then user=DPSMateUser[DPSMateUser[cname or DetailsUser][5]][1]; pet=5; else user=DPSMateUser[cname or DetailsUser][1]; pet=0; end end
		path = db[user][tonumber(uArr[lineplusoffset])]
	end
	if comp ~= "" and comp~=nil then
		DetailsSelectedComp = lineplusoffset
	else
		DetailsSelected = lineplusoffset
	end
	for p=1, 10 do
		local s = _G(pathh.."_ScrollButton"..p.."_selected")
		if s and s.Hide then s:Hide() end
	end
	local hit, crit, miss, parry, dodge, resist, hitMin, hitMax, critMin, critMax, hitav, critav, glance, glanceMin, glanceMax, glanceav, block, blockMin, blockMax, blockav = path[1], path[5], path[9], path[10], path[11], path[12], path[2], path[3], path[6], path[7], path[4], path[8], path[14], path[15], path[16], path[17], path[18], path[19], path[20], path[21]
	local total, max = hit+crit+miss+parry+dodge+resist+glance+block, DPSMate:TMax({hit, crit, miss, parry, dodge, resist, glance, block})
	
	_G("DPSMate_Details"..comp.."_LogDetails_Casts"):SetText("C: "..total)
	-- Block
	_G("DPSMate_Details"..comp.."_LogDetails_Amount0_Amount"):SetText(block)
	_G("DPSMate_Details"..comp.."_LogDetails_Amount0_Percent"):SetText(strformat("%.1f", 100*block/total).."%")
	_G("DPSMate_Details"..comp.."_LogDetails_Amount0_StatusBar"):SetValue(ceil(100*block/max))
	_G("DPSMate_Details"..comp.."_LogDetails_Amount0_StatusBar"):SetStatusBarColor(0.3,0.7,1.0,1)
	_G("DPSMate_Details"..comp.."_LogDetails_Average0"):SetText(ceil(blockav/DPSMate:ProbZero(block)))
	_G("DPSMate_Details"..comp.."_LogDetails_Min0"):SetText(blockMin)
	_G("DPSMate_Details"..comp.."_LogDetails_Max0"):SetText(blockMax)
	
	-- Glance
	_G("DPSMate_Details"..comp.."_LogDetails_Amount1_Amount"):SetText(glance)
	_G("DPSMate_Details"..comp.."_LogDetails_Amount1_Percent"):SetText(strformat("%.1f", 100*glance/total).."%")
	_G("DPSMate_Details"..comp.."_LogDetails_Amount1_StatusBar"):SetValue(ceil(100*glance/max))
	_G("DPSMate_Details"..comp.."_LogDetails_Amount1_StatusBar"):SetStatusBarColor(1.0,0.7,0.3,1)
	_G("DPSMate_Details"..comp.."_LogDetails_Average1"):SetText(ceil(glanceav/DPSMate:ProbZero(glance)))
	_G("DPSMate_Details"..comp.."_LogDetails_Min1"):SetText(glanceMin)
	_G("DPSMate_Details"..comp.."_LogDetails_Max1"):SetText(glanceMax)
	
	-- Hit
	_G("DPSMate_Details"..comp.."_LogDetails_Amount2_Amount"):SetText(hit)
	_G("DPSMate_Details"..comp.."_LogDetails_Amount2_Percent"):SetText(strformat("%.1f", 100*hit/total).."%")
	_G("DPSMate_Details"..comp.."_LogDetails_Amount2_StatusBar"):SetValue(ceil(100*hit/max))
	_G("DPSMate_Details"..comp.."_LogDetails_Amount2_StatusBar"):SetStatusBarColor(0.9,0.0,0.0,1)
	_G("DPSMate_Details"..comp.."_LogDetails_Average2"):SetText(ceil(hitav/DPSMate:ProbZero(hit)))
	_G("DPSMate_Details"..comp.."_LogDetails_Min2"):SetText(hitMin)
	_G("DPSMate_Details"..comp.."_LogDetails_Max2"):SetText(hitMax)
	
	-- Crit
	_G("DPSMate_Details"..comp.."_LogDetails_Amount3_Amount"):SetText(crit)
	_G("DPSMate_Details"..comp.."_LogDetails_Amount3_Percent"):SetText(strformat("%.1f", 100*crit/total).."%")
	_G("DPSMate_Details"..comp.."_LogDetails_Amount3_StatusBar"):SetValue(ceil(100*crit/max))
	_G("DPSMate_Details"..comp.."_LogDetails_Amount3_StatusBar"):SetStatusBarColor(0.0,0.9,0.0,1)
	_G("DPSMate_Details"..comp.."_LogDetails_Average3"):SetText(ceil(critav/DPSMate:ProbZero(crit)))
	_G("DPSMate_Details"..comp.."_LogDetails_Min3"):SetText(critMin)
	_G("DPSMate_Details"..comp.."_LogDetails_Max3"):SetText(critMax)
	
	-- Miss
	_G("DPSMate_Details"..comp.."_LogDetails_Amount4_Amount"):SetText(miss)
	_G("DPSMate_Details"..comp.."_LogDetails_Amount4_Percent"):SetText(strformat("%.1f", 100*miss/total).."%")
	_G("DPSMate_Details"..comp.."_LogDetails_Amount4_StatusBar"):SetValue(ceil(100*miss/max))
	_G("DPSMate_Details"..comp.."_LogDetails_Amount4_StatusBar"):SetStatusBarColor(0.0,0.0,1.0,1)
	_G("DPSMate_Details"..comp.."_LogDetails_Average4"):SetText("-")
	_G("DPSMate_Details"..comp.."_LogDetails_Min4"):SetText("-")
	_G("DPSMate_Details"..comp.."_LogDetails_Max4"):SetText("-")
	
	-- Parry
	_G("DPSMate_Details"..comp.."_LogDetails_Amount5_Amount"):SetText(parry)
	_G("DPSMate_Details"..comp.."_LogDetails_Amount5_Percent"):SetText(strformat("%.1f", 100*parry/total).."%")
	_G("DPSMate_Details"..comp.."_LogDetails_Amount5_StatusBar"):SetValue(ceil(100*parry/max))
	_G("DPSMate_Details"..comp.."_LogDetails_Amount5_StatusBar"):SetStatusBarColor(1.0,1.0,0.0,1)
	_G("DPSMate_Details"..comp.."_LogDetails_Average5"):SetText("-")
	_G("DPSMate_Details"..comp.."_LogDetails_Min5"):SetText("-")
	_G("DPSMate_Details"..comp.."_LogDetails_Max5"):SetText("-")
	
	-- Dodge
	_G("DPSMate_Details"..comp.."_LogDetails_Amount6_Amount"):SetText(dodge)
	_G("DPSMate_Details"..comp.."_LogDetails_Amount6_Percent"):SetText(strformat("%.1f", 100*dodge/total).."%")
	_G("DPSMate_Details"..comp.."_LogDetails_Amount6_StatusBar"):SetValue(ceil(100*dodge/max))
	_G("DPSMate_Details"..comp.."_LogDetails_Amount6_StatusBar"):SetStatusBarColor(1.0,0.0,1.0,1)
	_G("DPSMate_Details"..comp.."_LogDetails_Average6"):SetText("-")
	_G("DPSMate_Details"..comp.."_LogDetails_Min6"):SetText("-")
	_G("DPSMate_Details"..comp.."_LogDetails_Max6"):SetText("-")
	
	-- Resist
	_G("DPSMate_Details"..comp.."_LogDetails_Amount7_Amount"):SetText(resist)
	_G("DPSMate_Details"..comp.."_LogDetails_Amount7_Percent"):SetText(strformat("%.1f", 100*resist/total).."%")
	_G("DPSMate_Details"..comp.."_LogDetails_Amount7_StatusBar"):SetValue(ceil(100*resist/max))
	_G("DPSMate_Details"..comp.."_LogDetails_Amount7_StatusBar"):SetStatusBarColor(0.0,1.0,1.0,1)
	_G("DPSMate_Details"..comp.."_LogDetails_Average7"):SetText("-")
	_G("DPSMate_Details"..comp.."_LogDetails_Min7"):SetText("-")
	_G("DPSMate_Details"..comp.."_LogDetails_Max7"):SetText("-")
	self:RelayoutLogDetails(comp)
end

function DPSMate.Modules.DetailsDamage:UpdatePie(gg, cname)
	HideGraph(gg)
end

function DPSMate.Modules.DetailsDamage:UpdateLineGraph(gg, comp, cname)
	HideGraph(gg)
end

function DPSMate.Modules.DetailsDamage:UpdateStackedGraph(gg, comp, cname)
	HideGraph(gg)
end

function DPSMate.Modules.DetailsDamage:UpdateLineGraph_Orig(gg, comp, cname)
	if not comp then comp = DPSMate_Details.LastScroll or "" end
	if g3 then
		g3:Hide()
	end
	if g6 then
		g6:Hide()
	end	
	local sumTable
	if toggle3 then
		if comp ~= "" and comp~=nil then
			sumTable = self:GetSummarizedTable(db2, t1Comp[PSelected2], cname)
		else
			sumTable = self:GetSummarizedTable(db2, t1[PSelected])
		end
	else
		sumTable = self:GetSummarizedTable(db, nil, cname)
	end
	local max = DPSMate:GetMaxValue(sumTable, 2)
	local time = DPSMate:GetMaxValue(sumTable, 1)
	local min = DPSMate:GetMinValue(sumTable, 1)
	
	gg:ResetData()
	gg:SetXAxis(0,time-min)
	gg:SetYAxis(0,max+200)
	gg:SetGridSpacing((time-min)/10,max/7)
	gg:SetGridColor({0.5,0.5,0.5,0.5})
	gg:SetAxisDrawing(true,true)
	gg:SetAxisColor({1.0,1.0,1.0,1.0})
	gg:SetAutoScale(true)
	gg:SetYLabels(true, false)
	gg:SetXLabels(true)

	local Data1={{0,0}}
	for cat, val in pairs(DPSMate:ScaleDown(sumTable, min)) do
		tinsert(Data1, {val[1],val[2], self:CheckProcs(_G("DPSMate_Details"..comp).proc, val[1]+(min-1), cname)})
	end
	local colorT = {{1.0,0.0,0.0,0.8}, {1.0,1.0,0.0,0.8}}
	if cname then
		colorT = {{0.2,0.8,0.2,0.8}, {0.5,0.8,0.9,0.8}}
	end
	
	gg:AddDataSeries(Data1,colorT, self:AddProcPoints(_G("DPSMate_Details"..comp).proc, Data1, cname))
	gg:Show()
	toggle2 = false
end

function DPSMate.Modules.DetailsDamage:UpdateStackedGraph_Orig(gg, comp, cname)
	if not comp then comp = DPSMate_Details.LastScroll or "" end
	if g2 then
		g2:Hide()
	end
	if g5 then
		g5:Hide()
	end
	
	local d1,d2,d3,d4 = t1,t2,TTotal,PSelected
	if comp ~= "" and comp~=nil then
		d1 = t1Comp
		d2 = t2Comp
		d4 = PSelected2
	end
	
	local Data1 = {}
	local label = {}
	local b = {}
	local p = {}
	local maxY = 0
	local maxX = 0
	local temp = {}
	local temp2 = {}
	if toggle3 then
		for cat, val in pairs(db2[d1[d4]][DPSMateUser[cname or DetailsUser][1]]) do
			if cat~="i" and val["i"] then
				for c, v in pairs(val["i"]) do
					local key = tonumber(strformat("%.1f", c))
					if not temp[cat] then
						temp[cat] = {}
						temp2[cat] = 0
					end
					if p[key] then
						p[key] = p[key] + v
					else
						p[key] = v
					end
					local i = 1
					while true do
						if not temp[cat][i] then
							tinsert(temp[cat], i, {c,v})
							break
						elseif c<=temp[cat][i][1] then
							tinsert(temp[cat], i, {c,v})
							break
						end
						i = i + 1
					end
					temp2[cat] = temp2[cat] + val[13]
					maxY = math.max(p[key], maxY)
					maxX = math.max(c, maxX)
				end
			end
		end
		
		-- pet
		if DPSMateUser[cname or DetailsUser][5] and DPSMateUser[DPSMateUser[cname or DetailsUser][5]] and DPSMateSettings["mergepets"] and DPSMateUser[cname or DetailsUser][5] ~= (cname or DetailsUser) then
			if db2[d1[d4]][DPSMateUser[DPSMateUser[cname or DetailsUser][5]][1]] then
				for cat, val in pairs(db2[d1[d4]][DPSMateUser[DPSMateUser[cname or DetailsUser][5]][1]]) do
					if cat~="i" and val["i"] then
						for c, v in pairs(val["i"]) do
							local key = tonumber(strformat("%.1f", c))
							if not temp[cat] then
								temp[cat] = {}
								temp2[cat] = 0
							end
							if p[key] then
								p[key] = p[key] + v
							else
								p[key] = v
							end
							local i = 1
							while true do
								if not temp[cat][i] then
									tinsert(temp[cat], i, {c,v})
									break
								elseif c<=temp[cat][i][1] then
									tinsert(temp[cat], i, {c,v})
									break
								end
								i = i + 1
							end
							temp2[cat] = temp2[cat] + val[13]
							maxY = math.max(p[key], maxY)
							maxX = math.max(c, maxX)
						end
					end
				end
			end
		end
		
		local min
		for cat, val in pairs(temp) do
			local pmin = DPSMate:GetMinValue(val, 1)
			if not min or pmin<min then
				min = pmin
			end
		end
		for cat, val in pairs(temp) do
			local i = 1
			while true do
				if not b[i] then
					tinsert(b, i, temp2[cat])
					tinsert(label, i, DPSMate:GetAbilityById(cat))
					tinsert(Data1, i, val)
					break
				elseif b[i]>=temp2[cat] then
					tinsert(b, i, temp2[cat])
					tinsert(label, i, DPSMate:GetAbilityById(cat))
					tinsert(Data1, i, val)
					break
				end
				i = i + 1
			end
		end
		for cat, val in pairs(Data1) do
			Data1[cat] = DPSMate:ScaleDown(val, min)
		end
	
		gg:ResetData()
		gg:SetGridSpacing((maxX-min)/7,maxY/7)
	else
		for cat, val in pairs(db[DPSMateUser[cname or DetailsUser][1]]) do
			if cat~="i" and val["i"] then
				local temp = {}
				for c, v in pairs(val["i"]) do
					local key = tonumber(strformat("%.1f", c))
					if p[key] then
						p[key] = p[key] + v
					else
						p[key] = v
					end
					local i = 1
					while true do
						if not temp[i] then
							tinsert(temp, i, {c,v})
							break
						elseif c<temp[i][1] then
							tinsert(temp, i, {c,v})
							break
						end
						i = i + 1
					end
					maxY = math.max(p[key], maxY)
					maxX = math.max(c, maxX)
				end
				local i = 1
				while true do
					if not b[i] then
						tinsert(b, i, val[13])
						tinsert(label, i, DPSMate:GetAbilityById(cat))
						tinsert(Data1, i, temp)
						break
					elseif b[i]>=val[13] then
						tinsert(b, i, val[13])
						tinsert(label, i, DPSMate:GetAbilityById(cat))
						tinsert(Data1, i, temp)
						break
					end
					i = i + 1
				end
			end
		end
		-- Pet
		if DPSMateUser[cname or DetailsUser][5] and DPSMateUser[DPSMateUser[cname or DetailsUser][5]] and DPSMateSettings["mergepets"] and DPSMateUser[cname or DetailsUser][5] ~= (cname or DetailsUser) then
			if db[DPSMateUser[DPSMateUser[cname or DetailsUser][5]][1]] then
				for cat, val in pairs(db[DPSMateUser[DPSMateUser[cname or DetailsUser][5]][1]]) do
					if cat~="i" and val["i"] then
						local temp = {}
						for c, v in pairs(val["i"]) do
							local key = tonumber(strformat("%.1f", c))
							if p[key] then
								p[key] = p[key] + v
							else
								p[key] = v
							end
							local i = 1
							while true do
								if not temp[i] then
									tinsert(temp, i, {c,v})
									break
								elseif c<temp[i][1] then
									tinsert(temp, i, {c,v})
									break
								end
								i = i + 1
							end
							maxY = math.max(p[key], maxY)
							maxX = math.max(c, maxX)
						end
						local i = 1
						while true do
							if not b[i] then
								tinsert(b, i, val[13])
								tinsert(label, i, DPSMate:GetAbilityById(cat))
								tinsert(Data1, i, temp)
								break
							elseif b[i]>=val[13] then
								tinsert(b, i, val[13])
								tinsert(label, i, DPSMate:GetAbilityById(cat))
								tinsert(Data1, i, temp)
								break
							end
							i = i + 1
						end
					end
				end
			end
		end
	
		gg:ResetData()
		gg:SetGridSpacing(maxX/7,maxY/7)
	end
	
	gg:AddDataSeries(Data1,{1.0,0.0,0.0,0.8}, {}, label)
	gg:Show()
	toggle2 = true
end

function DPSMate.Modules.DetailsDamage:CreateGraphTable(comp)
end

function DPSMate.Modules.DetailsDamage:ProcsDropDown()
	local arr = DPSMate.Modules.DetailsDamage:GetAuraGainedArr(curKey)
	DPSMate_Details.proc = "None"
	
    local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMate_Details_DiagramLegend_Procs, this.value)
		DPSMate_Details.proc = this.value
		if not toggle2 then
			DPSMate.Modules.DetailsDamage:UpdateLineGraph(g2, "")
		end
		if DetailsUserComp then
			DPSMate.Modules.DetailsDamage:UpdateSumGraph()
		end
    end
	
	UIDropDownMenu_AddButton{
		text = "None",
		value = "None",
		func = on_click,
	}
	
	-- Adding dynamic channel
	if arr[DPSMateUser[DetailsUser][1]] then
		for cat, val in pairs(arr[DPSMateUser[DetailsUser][1]]) do
			local ability = DPSMate:GetAbilityById(cat)
			if DPSMate.Parser.procs[ability] or DPSMate.Parser.DmgProcs[ability] then
				UIDropDownMenu_AddButton{
					text = ability,
					value = cat,
					func = on_click,
				}
			end
		end
	end
	
	if DPSMate_Details.LastUser~=DetailsUser then
		UIDropDownMenu_SetSelectedValue(DPSMate_Details_DiagramLegend_Procs, "None")
	end
	DPSMate_Details.LastUser = DetailsUser
end

function DPSMate.Modules.DetailsDamage:ProcsDropDown_CompareDamage()
	local arr = DPSMate.Modules.DetailsDamage:GetAuraGainedArr(curKey)
	DPSMate_Details_CompareDamage.proc = "None"
	
    local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMate_Details_CompareDamage_DiagramLegend_Procs, this.value)
		DPSMate_Details_CompareDamage.proc = this.value
		if not toggle2 then
			DPSMate.Modules.DetailsDamage:UpdateLineGraph(g5, "_CompareDamage", DetailsUserComp)
		end
		DPSMate.Modules.DetailsDamage:UpdateSumGraph()
    end
	
	UIDropDownMenu_AddButton{
		text = "None",
		value = "None",
		func = on_click,
	}
	
	-- Adding dynamic channel
	if arr[DPSMateUser[DetailsUserComp][1]] then
		for cat, val in pairs(arr[DPSMateUser[DetailsUserComp][1]]) do
			local ability = DPSMate:GetAbilityById(cat)
			if DPSMate.Parser.procs[ability] or DPSMate.Parser.DmgProcs[ability] then
				UIDropDownMenu_AddButton{
					text = ability,
					value = cat,
					func = on_click,
				}
			end
		end
	end
	
	if DPSMate_Details_CompareDamage.LastUser~=DetailsUserComp then
		UIDropDownMenu_SetSelectedValue(DPSMate_Details_CompareDamage_DiagramLegend_Procs, "None")
	end
	DPSMate_Details_CompareDamage.LastUser = DetailsUserComp
end

function DPSMate.Modules.DetailsDamage:SortLineTable(t, b, cname)
	local newArr = {}
	if b then
		for cat, val in pairs(t[b][DPSMateUser[cname or DetailsUser][1]]) do
			if cat~="i" and val["i"] then
				for ca, va in pairs(val["i"]) do
					local i=1
					while true do
						if (not newArr[i]) then 
							tinsert(newArr, i, {ca, va})
							break
						end
						if ca<=newArr[i][1] then
							tinsert(newArr, i, {ca, va})
							break
						end
						i=i+1
					end
				end
			end
		end
		-- Pet
		if DPSMateUser[cname or DetailsUser][5] and DPSMateUser[DPSMateUser[cname or DetailsUser][5]] and DPSMateUser[cname or DetailsUser][5] ~= (cname or DetailsUser) then
			if t[DPSMateUser[DPSMateUser[cname or DetailsUser][5]][1]] then
				for cat, val in pairs(t[b][DPSMateUser[DPSMateUser[cname or DetailsUser][5]][1]]) do
					if cat~="i" and val["i"] then
						for ca, va in pairs(val["i"]) do
							local i=1
							while true do
								if (not newArr[i]) then 
									tinsert(newArr, i, {ca, va})
									break
								end
								if ca<=newArr[i][1] then
									tinsert(newArr, i, {ca, va})
									break
								end
								i=i+1
							end
						end
					end
				end
			end
		end
	else
		for cat, val in pairs(t[DPSMateUser[cname or DetailsUser][1]]) do
			if cat~="i" and val["i"] then
				for ca, va in pairs(val["i"]) do
					local i=1
					while true do
						if (not newArr[i]) then 
							tinsert(newArr, i, {ca, va})
							break
						end
						if ca<=newArr[i][1] then
							tinsert(newArr, i, {ca, va})
							break
						end
						i=i+1
					end
				end
			end
		end
		-- Pet
		if DPSMateUser[cname or DetailsUser][5] and DPSMateUser[DPSMateUser[cname or DetailsUser][5]] and DPSMateUser[cname or DetailsUser][5] ~= (cname or DetailsUser) then
			if t[DPSMateUser[DPSMateUser[cname or DetailsUser][5]][1]] then
				for cat, val in pairs(t[DPSMateUser[DPSMateUser[cname or DetailsUser][5]][1]]) do
					if cat~="i" and val["i"] then
						for ca, va in pairs(val["i"]) do
							local i=1
							while true do
								if (not newArr[i]) then 
									tinsert(newArr, i, {ca, va})
									break
								end
								if ca<=newArr[i][1] then
									tinsert(newArr, i, {ca, va})
									break
								end
								i=i+1
							end
						end
					end
				end
			end
		end
	end
	return newArr
end

function DPSMate.Modules.DetailsDamage:GetSummarizedTable(arr, b, cname)
	return DPSMate:GetSummarizedTable(self:SortLineTable(arr, b, cname))
end

function DPSMate.Modules.DetailsDamage:GetAuraGainedArr(k)
	local modes = {["total"]=1,["currentfight"]=2}
	for cat, val in pairs(DPSMateSettings["windows"][k]["options"][2]) do
		if val then
			if strfind(cat, "segment") then
				local num = tonumber(strsub(cat, 8))
				return DPSMateHistory["Auras"][num]
			else
				return DPSMateAurasGained[modes[cat]]
			end
		end
	end
end

function DPSMate.Modules.DetailsDamage:CheckProcs(name, val, cname)
	local arr = DPSMate.Modules.DetailsDamage:GetAuraGainedArr(curKey)
	if arr[DPSMateUser[cname or DetailsUser][1]] then
		if arr[DPSMateUser[cname or DetailsUser][1]][name] then
			for i=1, DPSMate:TableLength(arr[DPSMateUser[cname or DetailsUser][1]][name][1]) do
				if not arr[DPSMateUser[cname or DetailsUser][1]][name][1][i] or not arr[DPSMateUser[cname or DetailsUser][1]][name][2][i] or arr[DPSMateUser[cname or DetailsUser][1]][name][4] then return false end
				if val > arr[DPSMateUser[cname or DetailsUser][1]][name][1][i] and val < arr[DPSMateUser[cname or DetailsUser][1]][name][2][i] then
					return true
				end
			end
		end
	end
	return false
end

function DPSMate.Modules.DetailsDamage:AddProcPoints(name, dat, cname)
	local bool, data, LastVal = false, {}, 0
	local arr = self:GetAuraGainedArr(curKey)
	if arr[DPSMateUser[cname or DetailsUser][1]] then
		if arr[DPSMateUser[cname or DetailsUser][1]][name] then
			if arr[DPSMateUser[cname or DetailsUser][1]][name][4] then
				for cat, val in pairs(dat) do
					for i=1, DPSMate:TableLength(arr[DPSMateUser[cname or DetailsUser][1]][name][1]) do
						if arr[DPSMateUser[cname or DetailsUser][1]][name][1][i]<=val[1] then
							local tempbool = true
							for _, va in pairs(data) do
								if va[1] == arr[DPSMateUser[cname or DetailsUser][1]][name][1][i] then
									tempbool = false
									break
								end
							end
							if tempbool then	
								bool = true
								tinsert(data, {arr[DPSMateUser[cname or DetailsUser][1]][name][1][i], LastVal, {val[1], val[2]}})
							end
						end
					end
					LastVal = {val[1], val[2]}
				end
			end
		end
	end
	return {bool, data}
end

function DPSMate.Modules.DetailsDamage:ToggleMode(bool)
	if bool then
		if toggle2 then
			self:UpdateLineGraph(g2,"")
			if DetailsUserComp then
				self:UpdateLineGraph(g5,"_CompareDamage", DetailsUserComp)
			end
		else
			self:UpdateStackedGraph(g3)
			if DetailsUserComp then
				self:UpdateStackedGraph(g6,"_CompareDamage", DetailsUserComp)
			end
		end
	else
		if toggle then
			toggle = false
			self:ScrollFrame_Update("")
			self:SelectDetailsButton(1,"")
			DPSMate_Details_playerSpells:Hide()
			DPSMate_Details_player:Hide()
			DPSMate_Details_Diagram:Show()
			DPSMate_Details_Log:Show()
			
			if DetailsUserComp then
				self:ScrollFrame_Update("_CompareDamage")
				self:SelectDetailsButton(1,"_CompareDamage")
				DPSMate_Details_CompareDamage_playerSpells:Hide()
				DPSMate_Details_CompareDamage_player:Hide()
				DPSMate_Details_CompareDamage_Diagram:Show()
				DPSMate_Details_CompareDamage_Log:Show()
			end
		else
			toggle = true
			self:Player_Update("")
			self:PlayerSpells_Update(1,"")
			self:SelectDetailsButton(1,"")
			DPSMate_Details_playerSpells:Show()
			DPSMate_Details_player:Show()
			DPSMate_Details_Diagram:Hide()
			DPSMate_Details_Log:Hide()
			
			if DetailsUserComp then
				self:Player_Update("_CompareDamage")
				self:PlayerSpells_Update(1, "_CompareDamage")
				self:SelectDetailsButton(1, "_CompareDamage")
				DPSMate_Details_CompareDamage_playerSpells:Show()
				DPSMate_Details_CompareDamage_player:Show()
				DPSMate_Details_CompareDamage_Diagram:Hide()
				DPSMate_Details_CompareDamage_Log:Hide()
			end
		end
	end
end

function DPSMate.Modules.DetailsDamage:ToggleIndividual()
	if toggle3 then
		toggle3 = false
	else
		toggle3 = true
	end
	if toggle2 then
		self:UpdateStackedGraph(g3)
		if DetailsUserComp then 
			self:UpdateStackedGraph(g6,"_CompareDamage", DetailsUserComp)
		end
	else
		self:UpdateLineGraph(g2,"")
		if DetailsUserComp then
			self:UpdateLineGraph(g5,"_CompareDamage", DetailsUserComp)
		end
	end
	if DetailsUserComp then
		self:UpdateSumGraph()
	end
end

