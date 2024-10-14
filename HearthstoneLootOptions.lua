local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("HearthstoneLoot", true)

local _, _, _, rareColorHex = GetItemQualityColor(3)
local _, _, _, epicColorHex = GetItemQualityColor(4)
local _, _, _, legendaryColorHex = GetItemQualityColor(5)

local qualityValues = {
	[100] = NONE,
	[3] = "|c"..rareColorHex..ITEM_QUALITY3_DESC.."|r "..L["HSL_ORBETTER"],
	[4] = "|c"..epicColorHex..ITEM_QUALITY4_DESC.."|r "..L["HSL_ORBETTER"],
	[5] = "|c"..legendaryColorHex..ITEM_QUALITY5_DESC.."|r "..L["HSL_ONLY"],
}
local qualitySorting = {
	[1] = 100,
	[2] = 3,
	[3] = 4,
	[4] = 5,
}
local rarityValues = {
	[100] = NONE,
	[3] = "|c"..rareColorHex..ITEM_QUALITY3_DESC.."|r "..L["HSL_ORBETTER"],
	[4] = "|c"..epicColorHex..ITEM_QUALITY4_DESC.."|r "..L["HSL_ORBETTER"],
}
local raritySorting = {
	[1] = 100,
	[2] = 3,
	[3] = 4,
}
local languageValues = {
	["deDE"] = DEDE,
	["enGB"] = ENGB,
	["enUS"] = ENUS,
	["esES"] = ESES,
	["esMX"] = ESMX,
	["frFR"] = FRFR,
	["itIT"] = ITIT,
	["koKR"] = KOKR,
	["ptBR"] = PTBR,
	["ruRU"] = RURU,
	["zhCN"] = ZHCN,
	["zhTW"] = ZHTW,
}
local channelValues = {
	["Master"] = MASTER_VOLUME,
	["SFX"] = SOUND_VOLUME,
	["Music"] = MUSIC_VOLUME,
	["Ambience"] = AMBIENCE_VOLUME,
	["Dialog"] = DIALOG_VOLUME,
}
local channelSorting = {
	[1] = "Master",
	[2] = "SFX",
	[3] = "Music",
	[4] = "Ambience",
	[5] = "Dialog",
}
function loadHearthstoneLootOptions()
	local HearthstoneLootOptions = {
		type = "group",
		name = format("%s |cffADFF2Fv%s|r", "HearthstoneLoot", C_AddOns.GetAddOnMetadata("HearthstoneLoot", "Version")),
		args = {
			language = {
				type = "group", order = 1,
				name = GENERAL,
				inline = true,
				args = {
					language = {
						type = "select", order = 1,
						name = LANGUAGE,
						values = languageValues,
						set = function(info, val)
							HearthstoneLootOptionsData["language"] = val
							HearthstoneLoot_PlayQualitySoundFile(4, random(0, 1) == 1)
						end,
						get = function(info)
							return HearthstoneLootOptionsData["language"] or GetLocale()
						end
					},
					soundChannel = {
						type = "select", order = 2,
						name = CHANNEL.." |T130777:16|t",
						desc = SOUND_CHANNELS,
						values = channelValues,
						sorting = channelSorting,
						set = function(info, val)
							HearthstoneLootOptionsData["soundChannel"] = val
						end,
						get = function(info)
							return HearthstoneLootOptionsData["soundChannel"] or "Dialog"
						end
					},
					enableVictoryMusic = {
						type = "toggle", order = 3,
						width = "full",
						name = L["ENABLE_VICTORY_MUSIC"],
						desc = L["ENABLE_VICTORY_MUSIC_DESC"],
						set = function(info, val)
							HearthstoneLootOptionsData["VictoryMusicEnabled"] = val
							if val then
								PlaySoundFile(1068315, HearthstoneLootOptionsData["soundChannel"] or "Music")
							end
						end,
						get = function(info)
							return HearthstoneLootOptionsData["VictoryMusicEnabled"]
						end
					},
				},
			},
			loot = {
				type = "group", order = 2,
				name = L["LOOT_SECTION"],
				inline = true,
				args = {
					enableLootShouts = {
						type = "toggle", order = 1,
						width = "full",
						name = L["ENABLE_LOOT_SHOUTS"],
						desc = L["ENABLE_LOOT_SHOUTS_DESC"],
						set = function(info, val)
							HearthstoneLootOptionsData["LootShoutDisabled"] = not val
						end,
						get = function(info)
							return not HearthstoneLootOptionsData["LootShoutDisabled"]
						end
					},
					weaponQuality = {
						type = "select", order = 2,
						name = WEAPON,
						disabled = function()
							return HearthstoneLootOptionsData["LootShoutDisabled"]
						end,
						values = qualityValues,
						sorting = qualitySorting,
						set = function(info, val)
							HearthstoneLoot_PlayQualitySoundFile(val, random(0, 1) == 1)
							HearthstoneLootOptionsData[hsl_Weapon] = val
						end,
						get = function(info)
							return HearthstoneLootOptionsData[hsl_Weapon]
						end
					},
					armorQuality = {
						type = "select", order = 3,
						name = ARMOR,
						disabled = function()
							return HearthstoneLootOptionsData["LootShoutDisabled"]
						end,
						values = qualityValues,
						sorting = qualitySorting,
						set = function(info, val)
							HearthstoneLoot_PlayQualitySoundFile(val, random(0, 1) == 1)
							HearthstoneLootOptionsData[hsl_Armor] = val
						end,
						get = function(info)
							return HearthstoneLootOptionsData[hsl_Armor]
						end
					},
					recipeQuality = {
						type = "select", order = 4,
						name = PROFESSIONS_RECIPES_TAB,
						disabled = function()
							return HearthstoneLootOptionsData["LootShoutDisabled"]
						end,
						values = qualityValues,
						sorting = qualitySorting,
						set = function(info, val)
							HearthstoneLoot_PlayQualitySoundFile(val, random(0, 1) == 1)
							HearthstoneLootOptionsData[hsl_Recipe] = val
						end,
						get = function(info)
							return HearthstoneLootOptionsData[hsl_Recipe]
						end
					},
					tradeSkillQuality = {
						type = "select", order = 5,
						name = TRADESKILLS,
						disabled = function()
							return HearthstoneLootOptionsData["LootShoutDisabled"]
						end,
						values = qualityValues,
						sorting = qualitySorting,
						set = function(info, val)
							HearthstoneLoot_PlayQualitySoundFile(val, random(0, 1) == 1)
							HearthstoneLootOptionsData[hsl_Tradegoods] = val
						end,
						get = function(info)
							return HearthstoneLootOptionsData[hsl_Tradegoods]
						end
					},
					consumablesQuality = {
						type = "select", order = 6,
						name = BAG_FILTER_CONSUMABLES,
						disabled = function()
							return HearthstoneLootOptionsData["LootShoutDisabled"]
						end,
						values = qualityValues,
						sorting = qualitySorting,
						set = function(info, val)
							HearthstoneLoot_PlayQualitySoundFile(val, random(0, 1) == 1)
							HearthstoneLootOptionsData[hsl_Consumable] = val
						end,
						get = function(info)
							return HearthstoneLootOptionsData[hsl_Consumable]
						end
					},
					otherQuality = {
						type = "select", order = 7,
						name = OTHER,
						disabled = function()
							return HearthstoneLootOptionsData["LootShoutDisabled"]
						end,
						values = qualityValues,
						sorting = qualitySorting,
						set = function(info, val)
							HearthstoneLoot_PlayQualitySoundFile(val, random(0, 1) == 1)
							HearthstoneLootOptionsData[hsl_Other] = val
						end,
						get = function(info)
							return HearthstoneLootOptionsData[hsl_Other]
						end
					},
					enableLootShoutsInMailbox = {
						type = "toggle", order = 8,
						width = "full",
						name = L["ENABLE_LOOT_SHOUTS_IN_MAILBOX"],
						desc = L["ENABLE_LOOT_SHOUTS_IN_MAILBOX_DESC"],
						set = function(info, val)
							HearthstoneLootOptionsData["LootShoutInMailboxEnabled"] = val
						end,
						get = function(info)
							return HearthstoneLootOptionsData["LootShoutInMailboxEnabled"]
						end
					},
				},
			},
		},
	}

	if MAW_POWER_DESCRIPTION then
		local torghast = {
				type = "group", order = 3,
				name = string.format(L["TORGHAST_SECTION"],(DELVES_LABEL or "Delves"), (MAW_POWER_DESCRIPTION or "Maw power"), (POWER_TYPE_COBALT_POWER or "Cobalt power")),
				inline = true,
				args = {
					enableAnimaPowersShouts = {
						type = "toggle", order = 1,
						width = "full",
						name = L["ENABLE_ANIMA_POWERS_SHOUTS"],
						desc = L["ENABLE_ANIMA_POWERS_SHOUTS_DESC"],
						set = function(info, val)
							HearthstoneLootOptionsData["TorghastShoutDisabled"] = not val
						end,
						get = function(info)
							return not HearthstoneLootOptionsData["TorghastShoutDisabled"]
						end
					},
					animaPowersQuality = {
						type = "select", order = 2,
						width = 1.4,
						name = (MAW_POWER_DESCRIPTION or "Maw power").." / "..(POWER_TYPE_COBALT_POWER or "Cobalt power"),
						disabled = function()
							return not MAW_POWER_DESCRIPTION or HearthstoneLootOptionsData["TorghastShoutDisabled"]
						end,
						values = rarityValues,
						sorting = raritySorting,
						set = function(info, val)
							HearthstoneLoot_PlayQualitySoundFile(val, random(0, 1) == 1)
							HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION] = val
						end,
						get = function(info)
							return (MAW_POWER_DESCRIPTION and HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION]) or 3
						end
					},
				},
			}
		HearthstoneLootOptions.args["torghast"] = torghast
	end

	ACR:RegisterOptionsTable("HearthstoneLoot", HearthstoneLootOptions)
	ACD:AddToBlizOptions("HearthstoneLoot", "HearthstoneLoot")
	ACD:SetDefaultSize("HearthstoneLoot", 420, 543)
end

function HearthstoneLoot_OpenOptions()
	ACD:Open("HearthstoneLoot")
	if hslSoundHandle then
		StopSound(hslSoundHandle)
		hslSoundHandle = nil
	end
	_, hslSoundHandle = PlaySoundFile(1068313, "Music")
end
