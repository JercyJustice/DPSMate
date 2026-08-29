DPSMateFile("DPSMate_OptionsData.lua")
DPSMateFile("DPSMate_Options.lua")
DPSMateMark("opt:FILE-START")
-- Global Variables
DPSMate.Options.fonts = {
	["FRIZQT"] = "Fonts\\FRIZQT__.TTF",
	["ARIALN"] = "Fonts\\ARIALN.TTF",
	["MORPHEUS"] = "Fonts\\MORPHEUS.TTF",
	["ABF"] = "Interface\\AddOns\\DPSMate\\fonts\\ABF.TTF",
	["Accidental Presidency"] = "Interface\\AddOns\\DPSMate\\fonts\\Accidental Presidency.TTF",
	["Adventure"] = "Interface\\AddOns\\DPSMate\\fonts\\Adventure.TTF",
	["Avqest"] = "Interface\\AddOns\\DPSMate\\fonts\\Avqest.TTF",
	["Bazooka"] = "Interface\\AddOns\\DPSMate\\fonts\\Bazooka.TTF",
	["BigNoodleTitling"] = "Interface\\AddOns\\DPSMate\\fonts\\BigNoodleTitling.TTF",
	["BigNoodleTitling-Oblique"] = "Interface\\AddOns\\DPSMate\\fonts\\BigNoodleTitling-Oblique.TTF",
	["BlackChancery"] = "Interface\\AddOns\\DPSMate\\fonts\\BlackChancery.TTF",
	["Emblem"] = "Interface\\AddOns\\DPSMate\\fonts\\Emblem.TTF",
	["Enigma__2"] = "Interface\\AddOns\\DPSMate\\fonts\\Enigma__2.TTF",
	["Movie_Poster-Bold"] = "Interface\\AddOns\\DPSMate\\fonts\\Movie_Poster-Bold.TTF",
	["Porky"] = "Interface\\AddOns\\DPSMate\\fonts\\Porky.TTF",
	["rm_midse"] = "Interface\\AddOns\\DPSMate\\fonts\\rm_midse.TTF",
	["Tangerin"] = "Interface\\AddOns\\DPSMate\\fonts\\Tangerin.TTF",
	["Tw_Cen_MT_Bold"] = "Interface\\AddOns\\DPSMate\\fonts\\Tw_Cen_MT_Bold.TTF",
	["Ultima_Campagnoli"] = "Interface\\AddOns\\DPSMate\\fonts\\Ultima_Campagnoli.TTF",
	["VeraSe"] = "Interface\\AddOns\\DPSMate\\fonts\\VeraSe.TTF",
	["Yellowjacket"] = "Interface\\AddOns\\DPSMate\\fonts\\Yellowjacket.TTF",
	["visitor2"] = "Interface\\AddOns\\DPSMate\\fonts\\visitor2.TTF",
}
DPSMate.Options.fontflags = {
	["None"] = "NONE",
	["Outline"] = "OUTLINE",
	["Monochrome"] = "MONOCHROME",
	["Outlined monochrome"] = "OUTLINE, MONOCHROME",
	["Tick outlined"] = "THICKOUTLINE",
}
DPSMate.Options.statusbars = {
	["Aluminium"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\Aluminium", 
	["Armory"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\Armory", 
	["BantoBar"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\BantoBar", 
	["Glaze2"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\Glaze2", 
	["Gloss"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\Gloss", 
	["Graphite"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\Graphite", 
	["Grid"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\Grid", 
	["Healbot"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\Healbot", 
	["LiteStep"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\LiteStep", 
	["Minimalist"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\Minimalist", 
	["normTex"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\normTex", 
	["Otravi"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\Otravi", 
	["Outline"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\Outline", 
	["Perl"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\Perl", 
	["Round"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\Round", 
	["Smooth"] = "Interface\\AddOns\\DPSMate\\images\\statusbar\\Smooth", 
}
DPSMate.Options.bgtexture = {
	["Solid Background"] = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
	["UI-Tooltip-Background"] = "Interface\\Tooltips\\UI-Tooltip-Background",
}
DPSMate.Options.stratas = {
	[1] = "BACKGROUND",
	[2] = "LOW",
	[3] = "HIGH",
}
DPSMate.Options.bordertextures = {
	["UI-Tooltip-Border"] = "Interface\\Tooltips\\UI-Tooltip-Border",
}
DPSMateMark("opt:pre-dewdrop")
DPSMate.Options.Dewdrop = DPSMate_GetLib("DPSDewdrop-2.0",
	{ Register = function() end, Open = function() end, Close = function() end,
	  IsOpen = function() return nil end, Refresh = function() end,
	  GetOpenedParent = function() return { Key = 1 } end,
	  InjectAceOptionsTable = function() end })
DPSMate.Options.graph = DPSMate_GetLib("DPSGraph-1.0", {})
DPSMateMark("opt:got-graph")
DPSMate.Options.Options = {
	[1] = {
		type = 'group',
		args = {
		},
		handler = DPSMate.Options,
	},
	[2] = {
		type = 'group',
		args = {
			total = {
				order = 10,
				type = 'toggle',
				name = DPSMate.L["total"],
				desc = DPSMate.L["totalmode"],
				get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["options"][2]["total"] end,
				set = function() DPSMate.Options:ToggleDrewDrop(2, "total", DPSMate.Options.Dewdrop:GetOpenedParent()) end,
			},
			currentFight = {
				order = 20,
				type = 'toggle',
				name = DPSMate.L["mcurrent"],
				desc = DPSMate.L["currentmode"],
				get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["options"][2]["currentfight"] end,
				set = function() DPSMate.Options:ToggleDrewDrop(2, "currentfight", DPSMate.Options.Dewdrop:GetOpenedParent()) end,
			},
		},
		handler = DPSMate.Options,
	},
	[3] = {
		type = 'group',
		args = {
			test = {
				order = 5,
				type = 'toggle',
				name = DPSMate.L["testmode"],
				desc = DPSMate.L["testmodedesc"],
				get = function() return DPSMate.Options.TestMode end,
				set = function() DPSMate.Options:ActivateTestMode(); DPSMate.Options.Dewdrop:Close() end,
			},
			report = {
				order = 10,
				type = 'execute',
				name = DPSMate.L["report"],
				desc = DPSMate.L["reportsegment"],
				func = function() DPSMate_Report:Show(); DPSMate.Options.Dewdrop:Close() end,
			},
			reset = {
				order = 11,
				type = 'execute',
				name = DPSMate.L["reset"],
				desc = DPSMate.L["resetdesc"],
				func = function() DPSMate_PopUp:Show(); DPSMate.Options.Dewdrop:Close() end,
			},
			realtime = {
				order = 12,
				type = 'group',
				name = DPSMate.L["mrealtime"],
				desc = DPSMate.L["mrealtimedesc"],
				args = {
					damage = {
						order = 1,
						type = 'execute',
						name = DPSMate.L["damagedone"],
						desc = DPSMate.L["realtimedmgdone"],
						func = function() DPSMate.Options:SelectRealtime(DPSMate.Options.Dewdrop:GetOpenedParent(), "damage") end
					},
					dmgt = {
						order = 2,
						type = 'execute',
						name = DPSMate.L["damagetaken"],
						desc = DPSMate.L["realtimedmgtaken"],
						func = function() DPSMate.Options:SelectRealtime(DPSMate.Options.Dewdrop:GetOpenedParent(), "dmgt") end
					},
					heal = {
						order = 3,
						type = 'execute',
						name = DPSMate.L["healing"],
						desc = DPSMate.L["realtimehealing"],
						func = function() DPSMate.Options:SelectRealtime(DPSMate.Options.Dewdrop:GetOpenedParent(), "heal") end
					},
					eheal = {
						order = 4,
						type = 'execute',
						name = DPSMate.L["effectivehealing"],
						desc = DPSMate.L["realtimeehealing"],
						func = function() DPSMate.Options:SelectRealtime(DPSMate.Options.Dewdrop:GetOpenedParent(), "eheal") end
					}
				}
			},
			blank1 = {
				order = 20,
				type = 'header',
			},
			startnewsegment = {
				order = 25,
				type = 'execute',
				name = DPSMate.L["newsegment"],
				desc = DPSMate.L["newsegmentdesc"],
				func = function() DPSMate.Options:NewSegment("New segment"); DPSMate.Options.Dewdrop:Close() end,
			},
			deletesegment = {
				order = 30,
				type = 'group',
				name = DPSMate.L["removesegment"],
				desc = DPSMate.L["removesegmentdesc"],
				args = {},
			},
			blank2 = {
				order = 31,
				type = 'header',
			},
			showAll  = {
				order = 32,
				type = 'execute',
				name = DPSMate.L["showAll"],
				desc = DPSMate.L["showAllDesc"],
				func = function() for _, val in DPSMateSettings["windows"] do DPSMate.Options:Show(getglobal("DPSMate_"..val["name"])) end; DPSMate.Options.Dewdrop:Close() end,
			},
			hideAll  = {
				order = 33,
				type = 'execute',
				name = DPSMate.L["hideAll"],
				desc = DPSMate.L["hideAllDesc"],
				func = function() for _, val in DPSMateSettings["windows"] do DPSMate.Options:Hide(getglobal("DPSMate_"..val["name"])) end; DPSMate.Options.Dewdrop:Close() end,
			},
			showwindow = {
				order = 36,
				type = 'group',
				name = DPSMate.L["showwindow"],
				desc = DPSMate.L["showwindowdesc"],
				args = {},
			},
			hidewindow = {
				order = 37,
				type = 'group',
				name = DPSMate.L["hidewindow"],
				desc = DPSMate.L["hidewindowdesc"],
				args = {},
			},
			blank3 = {
				order = 38,
				type = 'header',
			},
			lock = {
				order = 40,
				type = 'toggle',
				name = DPSMate.L["lock"],
				desc = DPSMate.L["lockdesc"],
				get = function() return DPSMateSettings["lock"] end,
				set = function() DPSMate.Options:Lock(); DPSMate.Options.Dewdrop:Close() end,
			},
			unlock = {
				order = 50,
				type = 'toggle',
				name = DPSMate.L["unlock"],
				desc = DPSMate.L["unlock"],
				get = function() return not DPSMateSettings["lock"] end,
				set = function() DPSMate.Options:Unlock(); DPSMate.Options.Dewdrop:Close() end,
			},
			configure = {
				order = 80,
				type = 'execute',
				name = DPSMate.L["config"],
				desc = DPSMate.L["config"],
				func = function() DPSMate_ConfigMenu:Show(); DPSMate.Options.Dewdrop:Close() end,
			},
			close = {
				order = 90,
				type = 'execute',
				name = DPSMate.L["close"],
				desc = DPSMate.L["close"],
				func = function() DPSMate.Options.Dewdrop:Close() end,
			},
		},
		handler = DPSMate.Options,
	},
	[4] = {
		type = 'group',
		args = {
			report = {
				order = 10,
				type = 'group',
				name = DPSMate.L["report"],
				desc = DPSMate.L["reportdesc"],
				args = {
					whisper = {
						order = 10,
						type = "text",
						name = DPSMate.L["whisper"],
						desc = DPSMate.L["whisperdesc"],
						get = function() return "" end,
						set = function(name) DPSMate.Options:ReportUserDetails(DPSMate.Options.Dewdrop:GetOpenedParent(), DPSMate.L["whisper"], name); DPSMate.Options.Dewdrop:Close() end,
						usage = "<name>",
					},
				},
			},
			compare = {
				order = 20,
				type = 'group',
				name = DPSMate.L["comparewith"],
				desc = DPSMate.L["comparewithdesc"],
				args = {
				
				},
			}
		},
		handler = DPSMate.Options,
	},
	[5] = {
		type = 'group',
		args = {
			classes = {
				order = 10,
				type = 'group',
				name = DPSMate.L["classes"],
				desc = DPSMate.L["classesdesc"],
				args = {
					warrior = {
						order = 10,
						type = 'toggle',
						name = DPSMate.L["warrior"],
						desc = DPSMate.L["warriordesc"],
						get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["warrior"] end,
						set = function() DPSMate.Options:ToggleFilterClass(DPSMate.Options.Dewdrop:GetOpenedParent().Key, "warrior") end,
					},
					rogue = {
						order = 20,
						type = 'toggle',
						name = DPSMate.L["rogue"],
						desc = DPSMate.L["roguedesc"],
						get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["rogue"] end,
						set = function() DPSMate.Options:ToggleFilterClass(DPSMate.Options.Dewdrop:GetOpenedParent().Key, "rogue") end,
					},
					priest = {
						order = 30,
						type = 'toggle',
						name = DPSMate.L["priest"],
						desc = DPSMate.L["priestdesc"],
						get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["priest"] end,
						set = function() DPSMate.Options:ToggleFilterClass(DPSMate.Options.Dewdrop:GetOpenedParent().Key, "priest") end,
					},
					hunter = {
						order = 40,
						type = 'toggle',
						name = DPSMate.L["hunter"],
						desc = DPSMate.L["hunterdesc"],
						get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["hunter"] end,
						set = function() DPSMate.Options:ToggleFilterClass(DPSMate.Options.Dewdrop:GetOpenedParent().Key, "hunter") end,
					},
					druid = {
						order = 50,
						type = 'toggle',
						name = DPSMate.L["druid"],
						desc = DPSMate.L["druiddesc"],
						get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["druid"] end,
						set = function() DPSMate.Options:ToggleFilterClass(DPSMate.Options.Dewdrop:GetOpenedParent().Key, "druid") end,
					},
					mage = {
						order = 60,
						type = 'toggle',
						name = DPSMate.L["mage"],
						desc = DPSMate.L["magedesc"],
						get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["mage"] end,
						set = function() DPSMate.Options:ToggleFilterClass(DPSMate.Options.Dewdrop:GetOpenedParent().Key, "mage") end,
					},
					warlock = {
						order = 70,
						type = 'toggle',
						name = DPSMate.L["warlock"],
						desc = DPSMate.L["warlockdesc"],
						get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["warlock"] end,
						set = function() DPSMate.Options:ToggleFilterClass(DPSMate.Options.Dewdrop:GetOpenedParent().Key, "warlock") end,
					},
					paladin = {
						order = 80,
						type = 'toggle',
						name = DPSMate.L["paladin"],
						desc = DPSMate.L["paladindesc"],
						get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["paladin"] end,
						set = function() DPSMate.Options:ToggleFilterClass(DPSMate.Options.Dewdrop:GetOpenedParent().Key, "paladin") end,
					},
					shamen = {
						order = 90,
						type = 'toggle',
						name = DPSMate.L["shaman"],
						desc = DPSMate.L["shamandesc"],
						get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["filterclasses"]["shaman"] end,
						set = function() DPSMate.Options:ToggleFilterClass(DPSMate.Options.Dewdrop:GetOpenedParent().Key, "shaman") end,
					},
				},
			},
			people = {
				order = 20,
				type = 'text',
				name = DPSMate.L["certainnames"],
				desc = DPSMate.L["certainnamesdesc"],
				get = function() if DPSMate.Options.Dewdrop:GetOpenedParent() then return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["filterpeople"] else return "" end end,
				set = function(names) DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["filterpeople"] = names;DPSMate:SetStatusBarValue();DPSMate.Options.Dewdrop:Close() end,
				usage = "<names>",
			},
			group = {
				order = 30,
				type = "toggle",
				name = DPSMate.L["grouponly"],
				desc = DPSMate.L["grouponlydesc"],
				get = function() return DPSMateSettings["windows"][(DPSMate.Options.Dewdrop:GetOpenedParent() or DPSMate).Key or 1]["grouponly"] end,
				set = function() DPSMate.DB:OnGroupUpdate();DPSMate.Options:SimpleToggle(DPSMate.Options.Dewdrop:GetOpenedParent().Key, "grouponly");DPSMate.Options.Dewdrop:Close() end,
			}
		},
		handler = DPSMate.Options,
	},
}
-- Diese Datei ersetzt Options.Options komplett; der in DPSMate.lua gesetzte
-- args-Schutz waere damit weg. Erneut anwenden.
for i = 1, 5 do
	if DPSMate.Options.Options[i] and DPSMate.Options.Options[i].args then
		DPSMate_GuardTable(DPSMate.Options.Options[i].args, "args")
	end
end
DPSMateMark("opt:options-table")
DPSMate.Options.TestMode = false
