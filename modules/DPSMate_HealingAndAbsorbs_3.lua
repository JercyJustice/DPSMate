DPSMateFile("DPSMate_HealingAndAbsorbs_3.lua")
-- Global Variables
-- Register the moodule
local tinsert = table.insert
local strformat = string.format
function DPSMate.Modules.HealingAndAbsorbs:ShowTooltip(user, k)
	local a,b,c = DPSMate.Modules.HealingAndAbsorbs:EvalTable(DPSMateUser[user], k)
	if DPSMateSettings["informativetooltips"] then
		for i=1, DPSMateSettings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMate:GetAbilityById(a[i]),c[i][1].." ("..strformat("%.2f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
		end
	end
end

