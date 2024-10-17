local HearthstoneLoot = LibStub("AceAddon-3.0"):NewAddon("HearthstoneLoot", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("HearthstoneLoot", true)
local AceGUI = LibStub("AceGUI-3.0")

hsl_Armor      = 4
hsl_Weapon     = 2
hsl_Tradegoods = 7
hsl_Recipe     = 9
hsl_Consumable = 0
hsl_Other      = "Other"

local lootItemRarity = {3, 4, 5}

local hslWarforged = { 44, 448, 499, 546, 547, 560, 561, 562, 571, 644, 645, 646, 651, 656, 754, 755, 756, 757, 758, 759, 760, 761, 762, 763, 764, 765, 766, 1822, 3336, 3339, 3388, 3389, 3441, 3492, 3585, 3590, 3622, 3624, 3626, 4741, 4742, 4743, 4744, 4745, 4746, 4747, 4748, 4749, 4750, 4751, 4781, 4783, 5131, 5133, 5385, 5471, 5474, 5476, 6310, 6313, 6317, 6319, 6354, 6356, 6425, 6427, 6430, 6431,
	3337, 3338, 3442, 4782, 4784, 6318, 6320 } --Titanforged

local HearthstoneLoot_alreadyVORarity = {}

function HearthstoneLoot:OnInitialize()
	-- HearthstoneLootOptionsData
	if not HearthstoneLootOptionsData then
		HearthstoneLootOptionsData = {}
	end

	if not HearthstoneLootOptionsData["DataCleaning_1.3"] then -- Cleaning
		if HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION] == 5 then
			HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION] = 100
		end
		HearthstoneLootOptionsData["DataCleaning_1.3"] = true
	end
	
	if not HearthstoneLootOptionsData["DataCleaning_1.4"] then -- Cleaning
		local DataCleaning13 = HearthstoneLootOptionsData["DataCleaning_1.3"]
		local language = HearthstoneLootOptionsData["language"] 
		local soundChannel = HearthstoneLootOptionsData["soundChannel"]
		local VictoryMusicEnabled = HearthstoneLootOptionsData["VictoryMusicEnabled"]
		local LootShoutDisabled = HearthstoneLootOptionsData["LootShoutDisabled"]
		local LootShoutInMailboxEnabled = HearthstoneLootOptionsData["LootShoutInMailboxEnabled"] 
		local TorghastShoutDisabled = HearthstoneLootOptionsData["TorghastShoutDisabled"]
		local AnimaPower = MAW_POWER_DESCRIPTION and HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION]
		
		HearthstoneLootOptionsData = {}
		if DataCleaning13 then
			HearthstoneLootOptionsData["DataCleaning_1.3"] = DataCleaning13
		end
		if language then
			HearthstoneLootOptionsData["language"] = language
		end
		if soundChannel then
			HearthstoneLootOptionsData["soundChannel"] = soundChannel
		end
		if VictoryMusicEnabled then
			HearthstoneLootOptionsData["VictoryMusicEnabled"] = VictoryMusicEnabled
		end
		if LootShoutDisabled then
			HearthstoneLootOptionsData["LootShoutDisabled"] = LootShoutDisabled
		end
		if LootShoutInMailboxEnabled then
			HearthstoneLootOptionsData["LootShoutInMailboxEnabled"] = LootShoutInMailboxEnabled
		end
		if TorghastShoutDisabled then
			HearthstoneLootOptionsData["TorghastShoutDisabled"] = TorghastShoutDisabled
		end
		if MAW_POWER_DESCRIPTION and AnimaPower then
			HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION] = AnimaPower
		end
		HearthstoneLootOptionsData["DataCleaning_1.4"] = true
	end
	
	if not HearthstoneLootOptionsData[hsl_Armor] then -- Armor
		HearthstoneLootOptionsData[hsl_Armor] = 3
	end
	if not HearthstoneLootOptionsData[hsl_Weapon] then -- Weapon
		HearthstoneLootOptionsData[hsl_Weapon] = 3
	end
	if not HearthstoneLootOptionsData[hsl_Tradegoods] then -- Tradegoods
		HearthstoneLootOptionsData[hsl_Tradegoods] = 5
	end
	if not HearthstoneLootOptionsData[hsl_Recipe] then -- Recipe
		HearthstoneLootOptionsData[hsl_Recipe] = 5
	end
	if not HearthstoneLootOptionsData[hsl_Consumable] then -- Consumable
		HearthstoneLootOptionsData[hsl_Consumable] = 5
	end
	if not HearthstoneLootOptionsData[hsl_Other] then
		HearthstoneLootOptionsData[hsl_Other] = 100
	end
	if MAW_POWER_DESCRIPTION and
			(not HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION]
					or HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION] == 2) then -- Fixed: 2 is not a correct value
		HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION] = 3
	end
	
	if not HearthstoneLoot_alreadyLootedItems then
		HearthstoneLoot_alreadyLootedItems = {}
	end

	if MAW_POWER_DESCRIPTION then
		hooksecurefunc(C_PlayerChoice, "SendPlayerChoiceResponse", HearthstoneLoot_SendPlayerChoiceResponseHook)
	end
	
	self:RegisterEvent("BOSS_KILL", "OnEventBossKill")

	hooksecurefunc(C_NewItems, "RemoveNewItem", function(i, j)
		local itemID = C_Container.GetContainerItemID(i, j)
		if itemID and i <= NUM_TOTAL_EQUIPPED_BAG_SLOTS  then
			eraseAlreadyLooted(itemID)
		end
	end)
	
	loadHearthstoneLootOptions()
	self:RegisterChatCommand("hsl", "HearthstoneLootChatCommand")
	self:Print(L["HSL_WELCOME"])

	self:RegisterEvent("BAG_NEW_ITEMS_UPDATED", function(event)
		C_Timer.After(0, function(event)
			HearthstoneLoot:OnEventNewItemsUpdated(event)
		end)
		C_Timer.After(1, function(event)
			HearthstoneLoot:OnEventNewItemsUpdated(event)
		end)
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
	HearthstoneLoot_OpenOptions()
end

function HearthstoneLoot:OnEventNewItemsUpdated(event)
	local rarity = 0
	local isWarforged = nil
	local bagCheckTime = time()
	for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
		for j = 1, C_Container.GetContainerNumSlots(bag) do
			if C_NewItems.IsNewItem(bag, j) then
				local itemInfo = C_Container.GetContainerItemInfo(bag, j)
				local _, _, _, _, _, classID = GetItemInfoInstant(itemInfo.itemID)
				local timeAlreadyLooted, bagAlreadyLooted = hslGetAlreadyLooted(itemInfo.hyperlink)
				if tContains(lootItemRarity, itemInfo.quality) and ((HearthstoneLootOptionsData[classID] and itemInfo.quality >= HearthstoneLootOptionsData[classID]) or (not HearthstoneLootOptionsData[classID] and itemInfo.quality >= HearthstoneLootOptionsData[hsl_Other])) then
					if not timeAlreadyLooted then
						if itemInfo.quality > rarity or (not isWarforged and itemInfo.quality == rarity) then
							rarity = itemInfo.quality
							isWarforged = nil
							local itemstring = string.match(itemInfo.hyperlink, "item[%-?%d:]+")
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
					hslMarkAsAlreadyLooted(itemInfo.hyperlink, bag, bagCheckTime)
				end
			end
		end
	end

	if rarity > 0 and not HearthstoneLootOptionsData["LootShoutDisabled"]
			and (HearthstoneLootOptionsData["LootShoutInMailboxEnabled"]
				or not MailFrame:IsShown()) then
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

function HearthstoneLoot_SendPlayerChoiceResponseHook(buttonId)
	if not HearthstoneLootOptionsData["TorghastShoutDisabled"] then
		if PlayerChoiceFrame.choiceInfo and PlayerChoiceFrame.choiceInfo.options then
			local choiceRarity
			for k,v in pairs(PlayerChoiceFrame.choiceInfo.options) do
				if v.buttons then
					for k2,v2 in pairs(v.buttons) do
						if v2.id == buttonId and v.rarity then
							choiceRarity = v.rarity + 1 -- to match objects quality
							break
						end
					end
				end
			end
			if choiceRarity and HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION] and choiceRarity >= HearthstoneLootOptionsData[MAW_POWER_DESCRIPTION] then
				HearthstoneLoot_PlayQualitySoundFile(choiceRarity)
			end
		end
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
