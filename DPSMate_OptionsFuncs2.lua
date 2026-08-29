DPSMateFile("DPSMate_OptionsFuncs2.lua")
DPSMateMark("opt:FUNCS2")
-- Teil 2 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:InitializeConfigMenu()
	if DPSMate_RebuildWindowMenuButtons then
		DPSMate_RebuildWindowMenuButtons()
	end
		
	-- Tab Window
	DPSMate_ConfigMenu_Tab_Window_Lock:SetChecked(DPSMateSettings["lock"])
	
	-- Tab Bars
	if not DPSMate_ConfigMenu_Tab_Bars_BarTexture.tex then
		DPSMate_ConfigMenu_Tab_Bars_BarTexture.tex = DPSMate_ConfigMenu_Tab_Bars_BarTexture:CreateTexture("BG", "ARTWORK")
		DPSMate_ConfigMenu_Tab_Bars_BarTexture.tex:SetWidth(110)
		DPSMate_ConfigMenu_Tab_Bars_BarTexture.tex:SetHeight(15)
		DPSMate_ConfigMenu_Tab_Bars_BarTexture.tex:SetPoint("TOPLEFT", DPSMate_ConfigMenu_Tab_Bars_BarTexture, "TOPLEFT", 23, -7)
	end
	
	-- Tab Title bar
	if not DPSMate_ConfigMenu_Tab_TitleBar_BarTexture.tex then
		DPSMate_ConfigMenu_Tab_TitleBar_BarTexture.tex = DPSMate_ConfigMenu_Tab_TitleBar_BarTexture:CreateTexture("BG", "ARTWORK")
		DPSMate_ConfigMenu_Tab_TitleBar_BarTexture.tex:SetWidth(110)
		DPSMate_ConfigMenu_Tab_TitleBar_BarTexture.tex:SetHeight(15)
		DPSMate_ConfigMenu_Tab_TitleBar_BarTexture.tex:SetPoint("TOPLEFT", DPSMate_ConfigMenu_Tab_TitleBar_BarTexture, "TOPLEFT", 23, -7)
	end
	
	-- Tab General Options
	DPSMate_ConfigMenu_Tab_GeneralOptions_Minimap:SetChecked(DPSMateSettings["showminimapbutton"])
	if not DPSMateSettings["showminimapbutton"] then
		DPSMate_MiniMap:Hide()
	end
	DPSMate_ConfigMenu_Tab_GeneralOptions_Total:SetChecked(DPSMateSettings["showtotals"])
	DPSMate_ConfigMenu_Tab_GeneralOptions_BossFights:SetChecked(DPSMateSettings["onlybossfights"])
	DPSMate_ConfigMenu_Tab_GeneralOptions_Solo:SetChecked(DPSMateSettings["hidewhensolo"])
	DPSMate_ConfigMenu_Tab_GeneralOptions_Combat:SetChecked(DPSMateSettings["hideincombat"])
	DPSMate_ConfigMenu_Tab_GeneralOptions_Login:SetChecked(DPSMateSettings["hideonlogin"])
	DPSMate_ConfigMenu_Tab_GeneralOptions_PVP:SetChecked(DPSMateSettings["hideinpvp"])
	DPSMate_ConfigMenu_Tab_GeneralOptions_Disable:SetChecked(DPSMateSettings["disablewhilehidden"])
	DPSMate_ConfigMenu_Tab_GeneralOptions_MergePets:SetChecked(DPSMateSettings["mergepets"])
	DPSMate_ConfigMenu_Tab_GeneralOptions_Segments:SetValue(DPSMateSettings["datasegments"])
	DPSMate_ConfigMenu_Tab_GeneralOptions_TargetScale:SetValue(DPSMateSettings["targetscale"])
	
	-- Tab Columns
	for i=1, 4 do
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_DPS_Check"..i):SetChecked(DPSMateSettings["columnsdps"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Damage_Check"..i):SetChecked(DPSMateSettings["columnsdmg"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_DamageTaken_Check"..i):SetChecked(DPSMateSettings["columnsdmgtaken"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_DTPS_Check"..i):SetChecked(DPSMateSettings["columnsdtps"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_EDD_Check"..i):SetChecked(DPSMateSettings["columnsedd"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_EDT_Check"..i):SetChecked(DPSMateSettings["columnsedt"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Healing_Check"..i):SetChecked(DPSMateSettings["columnshealing"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_HealingTaken_Check"..i):SetChecked(DPSMateSettings["columnshealingtaken"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_HPS_Check"..i):SetChecked(DPSMateSettings["columnshps"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Overhealing_Check"..i):SetChecked(DPSMateSettings["columnsoverhealing"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_EffectiveHealing_Check"..i):SetChecked(DPSMateSettings["columnsehealing"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_EffectiveHealingTaken_Check"..i):SetChecked(DPSMateSettings["columnsehealingtaken"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_EffectiveHPS_Check"..i):SetChecked(DPSMateSettings["columnsehps"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_EffectiveHPS_Check"..i):SetChecked(DPSMateSettings["columnsehps"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_HAB_Check"..i):SetChecked(DPSMateSettings["columnshab"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_FriendlyFire_Check"..i):SetChecked(DPSMateSettings["columnsfriendlyfire"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Threat_Check"..i):SetChecked(DPSMateSettings["columnsthreat"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_TPS_Check"..i):SetChecked(DPSMateSettings["columnstps"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Absorbs_Check"..i):SetChecked(DPSMateSettings["columnsabsorbs"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_AbsorbsTaken_Check"..i):SetChecked(DPSMateSettings["columnsabsorbstaken"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_OHealingTaken_Check"..i):SetChecked(DPSMateSettings["columnsohealingtaken"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_OHPS_Check"..i):SetChecked(DPSMateSettings["columnsohps"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_FriendlyFireTaken_Check"..i):SetChecked(DPSMateSettings["columnsfriendlyfiretaken"][i])
	end
	for i=1, 2 do
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Deaths_Check"..i):SetChecked(DPSMateSettings["columnsdeaths"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Interrupts_Check"..i):SetChecked(DPSMateSettings["columnsinterrupts"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Dispels_Check"..i):SetChecked(DPSMateSettings["columnsdispels"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_DispelsReceived_Check"..i):SetChecked(DPSMateSettings["columnsdispelsreceived"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Decurses_Check"..i):SetChecked(DPSMateSettings["columnsdecurses"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_DecursesReceived_Check"..i):SetChecked(DPSMateSettings["columnsdecursesreceived"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Disease_Check"..i):SetChecked(DPSMateSettings["columnsdisease"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_DiseaseReceived_Check"..i):SetChecked(DPSMateSettings["columnsdiseasereceived"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Poison_Check"..i):SetChecked(DPSMateSettings["columnspoison"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_PoisonReceived_Check"..i):SetChecked(DPSMateSettings["columnspoisonreceived"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Magic_Check"..i):SetChecked(DPSMateSettings["columnsmagic"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_MagicReceived_Check"..i):SetChecked(DPSMateSettings["columnsmagicreceived"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_AurasGained_Check"..i):SetChecked(DPSMateSettings["columnsaurasgained"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_AurasLost_Check"..i):SetChecked(DPSMateSettings["columnsauraslost"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_AuraUptime_Check"..i):SetChecked(DPSMateSettings["columnsaurauptime"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Procs_Check"..i):SetChecked(DPSMateSettings["columnsprocs"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Casts_Check"..i):SetChecked(DPSMateSettings["columnscasts"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_Fails_Check"..i):SetChecked(DPSMateSettings["columnsfails"][i])
		_G("DPSMate_ConfigMenu_Tab_Columns_Child_CCBreaker_Check"..i):SetChecked(DPSMateSettings["columnsccbreaker"][i])
	end
	
	-- Tab Tooltips
	DPSMate_ConfigMenu_Tab_Tooltips_Tooltips:SetChecked(DPSMateSettings["showtooltips"])
	DPSMate_ConfigMenu_Tab_Tooltips_InformativeTooltips:SetChecked(DPSMateSettings["informativetooltips"])
	DPSMate_ConfigMenu_Tab_Tooltips_Rows:SetValue(DPSMateSettings["subviewrows"])
	
	-- Tab Broadcasting
	DPSMate_ConfigMenu_Tab_Broadcasting_Enable:SetChecked(DPSMateSettings["broadcasting"])
	DPSMate_ConfigMenu_Tab_Broadcasting_Cooldowns:SetChecked(DPSMateSettings["bccd"])
	DPSMate_ConfigMenu_Tab_Broadcasting_Ress:SetChecked(DPSMateSettings["bcress"])
	DPSMate_ConfigMenu_Tab_Broadcasting_KillingBlows:SetChecked(DPSMateSettings["bckb"])
	DPSMate_ConfigMenu_Tab_Broadcasting_Fails:SetChecked(DPSMateSettings["bcfail"])
	DPSMate_ConfigMenu_Tab_Broadcasting_RaidWarning:SetChecked(DPSMateSettings["bcrw"])
	
	-- Mode menu
	for cat, _ in DPSMateSettings["hiddenmodes"] do
		DPSMate.Options.Options[1]["args"][cat] = nil
	end
end

DPSMate.Options.OldLogout = Logout
