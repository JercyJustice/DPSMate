DPSMateFile("DPSMate_HealingAndAbsorbs_4.lua")
-- Global Variables
-- Register the moodule
local tinsert = table.insert
local strformat = string.format
function DPSMate.Modules.HealingAndAbsorbs:OpenDetails(obj, key, bool)
	if bool then
		DPSMate.Modules.DetailsHealingAndAbsorbs:UpdateCompare(obj, key, bool)
	else
		DPSMate.Modules.DetailsHealingAndAbsorbs:UpdateDetails(obj, key)
	end
end

function DPSMate.Modules.HealingAndAbsorbs:OpenTotalDetails(obj, key)
	DPSMate.Modules.DetailsHABTotal:UpdateDetails(obj, key)
end



