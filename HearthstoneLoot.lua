local HearthstoneLoot = LibStub("AceAddon-3.0"):NewAddon("HearthstoneLoot", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("HearthstoneLoot", true)
local AceGUI = LibStub("AceGUI-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local lootItemRarity = {3, 4, 5}

local rarityFromColor = {
	["blue"] = 3,
	["purple"] = 4,
	["orange"] = 5,
}

local hslWarforged = { 44, 448, 499, 546, 547, 560, 561, 562, 571, 644, 645, 646, 651, 656, 754, 755, 756, 757, 758, 759, 760, 761, 762, 763, 764, 765, 766, 1822, 3336, 3339, 3388, 3389, 3441, 3492, 3585, 3590, 3622, 3624, 3626, 4741, 4742, 4743, 4744, 4745, 4746, 4747, 4748, 4749, 4750, 4751, 4781, 4783, 5131, 5133, 5385, 5471, 5474, 5476, 6310, 6313, 6317, 6319, 6354, 6356, 6425, 6427, 6430, 6431,
	3337, 3338, 3442, 4782, 4784, 6318, 6320 } --Titanforged

local HearthstoneLoot_alreadyVORarity = {}

function HearthstoneLoot:InitializeVariables()
	if not HSL_RECIPE or not HSL_TRADE_SKILL then
		local _, _, _, _, _, itemTypeTradeSkill = GetItemInfo(7974)
		if itemTypeTradeSkill then
			HSL_TRADE_SKILL = itemTypeTradeSkill
			if HSL_TRADE_SKILL and not HearthstoneLootOptionsData[HSL_TRADE_SKILL] then
				HearthstoneLootOptionsData[HSL_TRADE_SKILL] = 5
			end
		end

		local _, _, _, _, _, itemTypeRecipe = GetItemInfo(21099)
		if itemTypeTradeSkill then
			HSL_RECIPE = itemTypeRecipe
			if HSL_RECIPE and not HearthstoneLootOptionsData[HSL_RECIPE] then
				HearthstoneLootOptionsData[HSL_RECIPE] = 5
			end
		end

		if HSL_RECIPE and HSL_TRADE_SKILL then
			loadHearthstoneLootOptions()
			self:RegisterChatCommand("hsl", "HearthstoneLootChatCommand")
			self:Print(L["HSL_WELCOME"])
		end
	else
		self:UnregisterEvent("BAG_UPDATE")
		self:UnregisterEvent("PLAYER_STARTED_MOVING")
		self:RegisterEvent("BAG_NEW_ITEMS_UPDATED", function(event)
			C_Timer.After(0, function(event)
				HearthstoneLoot:OnEventNewItemsUpdated(event)
			end)
			C_Timer.After(1, function(event)
				HearthstoneLoot:OnEventNewItemsUpdated(event)
			end)
		end)
	end
end

function HearthstoneLoot:OnInitialize()
	-- HearthstoneLootOptionsData
	if not HearthstoneLootOptionsData then
		HearthstoneLootOptionsData = {}
	end
	if not HearthstoneLootOptionsData[ARMOR] then
		HearthstoneLootOptionsData[ARMOR] = 3
	end
	if not HearthstoneLootOptionsData[WEAPON] then
		HearthstoneLootOptionsData[WEAPON] = 3
	end
	if not HearthstoneLootOptionsData[BAG_FILTER_CONSUMABLES] then
		HearthstoneLootOptionsData[BAG_FILTER_CONSUMABLES] = 5
	end
	if HearthstoneLootOptionsData[MISCELLANEOUS] then
		HearthstoneLootOptionsData[MISCELLANEOUS] = nil
	end
	if not HearthstoneLootOptionsData[OTHER] then
		HearthstoneLootOptionsData[OTHER] = 100
	end
	if MAW_POWER_DESCRIPTION and not HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION] then
		HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION] = 3
	end

	if not HearthstoneLoot_alreadyLootedItems then
		HearthstoneLoot_alreadyLootedItems = {}
	end

	if not HearthstoneLoot_alreadyGainBuff then
		HearthstoneLoot_alreadyGainBuff = {}
	end

	if MAW_POWER_DESCRIPTION then
		if not HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION] then
			HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION] = 3
		end
		self:RegisterEvent("JAILERS_TOWER_LEVEL_UPDATE", "OnEventTowerLevelUpdate")
	end
	self:RegisterEvent("PLAYER_STARTED_MOVING", "InitializeVariables")
	self:RegisterEvent("BAG_UPDATE", "InitializeVariables")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEventEnteringWorld")
	self:RegisterEvent("BOSS_KILL", "OnEventBossKill")

	hooksecurefunc(C_NewItems, "RemoveNewItem", function(i, j)
		local itemID = GetContainerItemID(i, j)
		if itemID and i <= NUM_BAG_SLOTS  then
			eraseAlreadyLooted(itemID)
		end
	end)
end

function HearthstoneLoot:OnEnable()
	-- Called when the addon is enabled
end

function HearthstoneLoot:OnDisable()
	-- Called when the addon is disabled
end

local hslSoundHandle = nil
function HearthstoneLoot:HearthstoneLootChatCommand()
	ACD:Open("HearthstoneLoot")
	if hslSoundHandle then
		StopSound(hslSoundHandle)
		hslSoundHandle = nil
	end
	_, hslSoundHandle = PlaySoundFile(1068313, "Music")
end

function HearthstoneLoot:OnEventNewItemsUpdated(event)
	local rarity = 0
	local isWarforged = nil
	local bagCheckTime = time()
	for bag = 0, NUM_BAG_SLOTS do
		for j = 1, GetContainerNumSlots(bag) do
			if C_NewItems.IsNewItem(bag, j) then
				local _, _, _, quality, _, _, itemLink, _, _, itemID = GetContainerItemInfo(bag, j)
				local _, _, _, _, _, itemType = GetItemInfo(itemID)
				local timeAlreadyLooted, bagAlreadyLooted = hslGetAlreadyLooted(itemLink)
				if tContains(lootItemRarity, quality) and ((HearthstoneLootOptionsData[itemType] and quality >= HearthstoneLootOptionsData[itemType]) or (not HearthstoneLootOptionsData[itemType] and quality >= HearthstoneLootOptionsData[OTHER])) then
					if not timeAlreadyLooted then
						if quality > rarity or (not isWarforged and quality == rarity) then
							rarity = quality

							isWarforged = nil
							local itemstring = string.match(itemLink, "item[%-?%d:]+")
							if itemstring then
								local numbonuses = select(14, strsplit(":", itemstring))
								numbonuses = tonumber(numbonuses) or 0
								for k = 1, numbonuses do
									local bonus = select(14 + k, strsplit(":", itemstring))
									if tContains(hslWarforged, tonumber(bonus)) then
										isWarforged = true
									end
								end
							end
						end
					end
					hslMarkAsAlreadyLooted(itemLink, bag, bagCheckTime)
				end
			end
		end
	end

	if rarity > 0 and not HearthstoneLootOptionsData["LootShoutDisabled"] then
		HearthstoneLoot_PlayQualitySoundFile(rarity, isWarforged)
	end

	for key, value in pairs(HearthstoneLoot_alreadyLootedItems) do
		local timeAlreadyLooted, bagAlreadyLooted = hslGetAlreadyLooted(key)
		if timeAlreadyLooted ~= bagCheckTime then
			eraseAlreadyLooted(key)
		end
	end
end

function hslMarkAsAlreadyLooted(itemID, bag, time)
	if itemID and bag and time then
		HearthstoneLoot_alreadyLootedItems[itemID] = time.."-"..bag
	end
end

function hslGetAlreadyLooted(itemID)
	local time, bag
	local alreadyLootedItems = HearthstoneLoot_alreadyLootedItems[itemID]
	if alreadyLootedItems then
		if type(alreadyLootedItems) == "string" then
			time, bag = strsplit("-", HearthstoneLoot_alreadyLootedItems[itemID])
			if time then
				time = tonumber(time)
			end
			if bag then
				bag = tonumber(bag)
			end
		else
			eraseAlreadyLooted(itemID)
		end
	end
	return time, bag
end

function eraseAlreadyLooted(itemID)
	if HearthstoneLoot_alreadyLootedItems[itemID] then
		HearthstoneLoot_alreadyLootedItems[itemID] = nil
	end
end

function HearthstoneLoot:OnEventTowerLevelUpdate(event, level)
	if not HearthstoneLootOptionsData["TorghastShoutDisabled"] and level == 1 then
		self:RegisterEvent("UNIT_AURA", "OnEventUnitAura")
		HearthstoneLoot_alreadyGainBuff = {}
	end
end

function HearthstoneLoot:OnEventEnteringWorld(event)
	if MAW_POWER_DESCRIPTION then
		hslRegisterUnitAura()
	end
end

function hslRegisterUnitAura()
	if not HearthstoneLootOptionsData["TorghastShoutDisabled"] and IsInJailersTower() then
		HearthstoneLoot:RegisterEvent("UNIT_AURA", "OnEventUnitAura")
	end
end

function HearthstoneLoot:OnEventUnitAura(event, unit)
	if not HearthstoneLootOptionsData["TorghastShoutDisabled"] and IsInJailersTower() and unit == "player" then
		local numAura = 1
		local name, _, count, _, _, _, _, _, _, spellId = UnitAura("player", numAura, "MAW")
		while spellId and count do
			if not HearthstoneLoot_alreadyGainBuff[spellId.."-"..count] then
				HearthstoneLoot_alreadyGainBuff[spellId.."-"..count] = true
				if C_Spell.GetMawPowerBorderAtlasBySpellID(spellId) then
					local _, _, _, rarityColor = strsplit("-", C_Spell.GetMawPowerBorderAtlasBySpellID(spellId))
					local rarity = rarityFromColor[rarityColor]
					if rarity and HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION] and rarity >= HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION] then
						HearthstoneLoot_PlayQualitySoundFile(rarity)
					end
				end
			end
			numAura = numAura + 1
			name, _, count, _, _, _, _, _, _, spellId = UnitAura("player", numAura, "MAW")
		end
	elseif not IsInJailersTower() then
		self:UnregisterEvent("UNIT_AURA")
	end
end

function HearthstoneLoot:OnEventBossKill()
	if HearthstoneLootOptionsData["VictoryMusicEnabled"] then
		PlaySoundFile(1068315, HearthstoneLootOptionsData["soundChannel"] or "Music")
	end
end

function HearthstoneLoot_PlayQualitySoundFile(rarity, isWarforged)
	local warforgedString = ""
	if isWarforged then
		warforgedString = "-GOLDEN"
	end
	if not HearthstoneLoot_alreadyVORarity[rarity] then
		HearthstoneLoot_alreadyVORarity[rarity] = true
		if rarity == 3 then
			HearthstoneLoot_PlaySoundFile("card_turn_over_rare", HearthstoneLootOptionsData["soundChannel"] or "Dialog", true)
			HearthstoneLoot_PlaySoundFile("VO_ANNOUNCER_RARE_27"..warforgedString, HearthstoneLootOptionsData["soundChannel"] or "Dialog")
		elseif rarity == 4 then
			HearthstoneLoot_PlaySoundFile("card_turn_over_epic", HearthstoneLootOptionsData["soundChannel"] or "Dialog", true)
			HearthstoneLoot_PlaySoundFile("VO_ANNOUNCER_EPIC_26"..warforgedString, HearthstoneLootOptionsData["soundChannel"] or "Dialog")
		elseif rarity == 5 then
			HearthstoneLoot_PlaySoundFile("card_turn_over_legendary", HearthstoneLootOptionsData["soundChannel"] or "Dialog", true)
			HearthstoneLoot_PlaySoundFile("VO_ANNOUNCER_LEGENDARY_25"..warforgedString, HearthstoneLootOptionsData["soundChannel"] or "Dialog")
		end

		C_Timer.After(2, function()
			HearthstoneLoot_alreadyVORarity[rarity] = nil
		end)
	end
end

function HearthstoneLoot_PlaySoundFile(soundFile, channel)
	local locale = HearthstoneLootOptionsData["language"] or GetLocale()
	local willPlay = PlaySoundFile("Interface\\AddOns\\HearthstoneLoot\\sound\\"..soundFile.."_"..locale..".ogg", channel)
	if not willPlay then
		PlaySoundFile("Interface\\AddOns\\HearthstoneLoot\\sound\\"..soundFile..".ogg", channel)
	end
end
