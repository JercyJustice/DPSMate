DPSMateFile("DPSMate_FriendlyFireTaken_1.lua")
-- Global Variables
DPSMate.Modules.FriendlyFireTaken = {}
DPSMate.Modules.FriendlyFireTaken.Hist = "EDTaken"
DPSMate.Options.Options[1]["args"]["friendlyfiretaken"] = {
	order = 261,
	type = 'toggle',
	name = DPSMate.L["friendlyfiretaken"],
	desc = DPSMate.L["show"].." "..DPSMate.L["friendlyfiretaken"]..".",
	get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["friendlyfiretaken"] end,
	set = function() DPSMate.Options:ToggleDrewDrop(1, "friendlyfiretaken", DPSMate.Options.Dewdrop:GetOpenedParent()) end,
}

-- Register the moodule
DPSMate:Register("friendlyfiretaken", DPSMate.Modules.FriendlyFireTaken, DPSMate.L["friendlyfiretaken"])

local tinsert = table.insert
local strformat = string.format

function DPSMate.Modules.FriendlyFireTaken:GetSortedTable(arr,k)
	local b, a, total = {}, {}, 0
	for c, v in pairs(arr) do
		local cName = DPSMate:GetUserById(c)
		local CV = 0
		for cat, val in pairs(v) do
			local catName = DPSMate:GetUserById(cat)
			if DPSMate:ApplyFilter(k, catName) and DPSMateUser[catName] and DPSMateUser[cName] then
				if DPSMateUser[cName][3] == DPSMateUser[catName][3] and DPSMateUser[catName][3] and DPSMateUser[cName][3] then
					CV = CV + val["i"]
				end
			end
		end
		if CV > 0 then
			local i = 1
			while true do
				if (not b[i]) then
					tinsert(b, i, CV)
					tinsert(a, i, c)
					break
				else
					if b[i] < CV then
						tinsert(b, i, CV)
						tinsert(a, i, c)
						break
					end
				end
				i=i+1
			end
			total = total + CV
		end
	end
	return b, total, a
end

function DPSMate.Modules.FriendlyFireTaken:EvalTable(user, k)
	local a, d, total, temp = {}, {}, 0, {}
	local arr = DPSMate:GetMode(k)
	if not arr[user[1]] then return end
	for c, v in arr[user[1]] do
		local cName = DPSMate:GetUserById(c)
		local CV = 0
		local aa,bb = {}, {}
		if DPSMateUser[cName][3] == user[3] and DPSMateUser[cName][3] then
			for cat, val in v do
				if cat~="i" then 
					local i = 1
					while true do
						if (not bb[i]) then
							tinsert(bb, i, val[13])
							tinsert(aa, i, cat)
							break
						else
							if bb[i] < val[13] then
								tinsert(bb, i, val[13])
								tinsert(aa, i, cat)
								break
							end
						end
						i=i+1
					end
					CV = CV + val[13]
				end
			end
		end
		if CV > 0 then
			local i = 1
			while true do
				if (not d[i]) then
					tinsert(d, i, {CV, aa, bb})
					tinsert(a, i, c)
					break
				else
					if d[i][1] < CV then
						tinsert(d, i, {CV, aa, bb})
						tinsert(a, i, c)
						break
					end
				end
				i=i+1
			end
			total = total + CV
		end
	end
	return a, total, d
end

