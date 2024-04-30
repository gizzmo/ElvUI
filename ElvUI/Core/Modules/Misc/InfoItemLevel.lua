local E, L, V, P, G = unpack(ElvUI)
local M = E:GetModule('Misc')
local LSM = E.Libs.LSM

local _G = _G
local rad = rad
local gsub = gsub
local wipe = wipe
local next = next
local pairs = pairs
local unpack = unpack

local UnitGUID = UnitGUID
local CreateFrame = CreateFrame

local InspectItems = {
	'HeadSlot',
	'NeckSlot',
	'ShoulderSlot',
	'',
	'ChestSlot',
	'WaistSlot',
	'LegsSlot',
	'FeetSlot',
	'WristSlot',
	'HandsSlot',
	'Finger0Slot',
	'Finger1Slot',
	'Trinket0Slot',
	'Trinket1Slot',
	'BackSlot',
	'MainHandSlot', -- 16
	'SecondaryHandSlot', -- 17
	E.Cata and 'RangedSlot' or nil -- 18
}

local numInspectItems = #InspectItems

function M:CreateInspectTexture(slot, x, y)
	local texture = slot:CreateTexture()
	texture:Point('BOTTOM', x, y)
	texture:SetTexCoord(unpack(E.TexCoords))
	texture:Size(14)

	local backdrop = CreateFrame('Frame', nil, slot)
	backdrop:SetTemplate(nil, nil, true)
	backdrop:SetBackdropColor(0,0,0,0)
	backdrop:SetOutside(texture)
	backdrop:Hide()

	return texture, backdrop
end

function M:GetInspectPoints(id)
	if not id then return end

	if id <= 5 or (id == 9 or id == 15) then
		return 40, 3, 18, 'BOTTOMLEFT' -- Left side
	elseif (id >= 6 and id <= 8) or (id >= 10 and id <= 14) then
		return -40, 3, 18, 'BOTTOMRIGHT' -- Right side
	else
		return 0, 46, 60, 'BOTTOM'
	end
end

function M:UpdateInspectInfo(_, arg1)
	local frame = _G.InspectFrame
	if not frame then return end

	if M.InspectTimer then -- event can spam when it has to load items
		E:CancelTimer(M.InspectTimer)
	end

	M.InspectTimer = E:ScheduleTimer(M.UpdatePageInfo, 0.2, M, frame, 'Inspect', arg1)
end

function M:UpdateCharacterInfo(event)
	if not (E.db.general.itemLevel.displayCharacterInfo and _G.CharacterFrame:IsShown()) then return end

	M:UpdatePageInfo(_G.CharacterFrame, 'Character', nil, event)
end

function M:ClearPageInfo(frame, which)
	if not (frame and frame.ItemLevelText) then return end
	frame.ItemLevelText:SetText('')

	for i = 1, numInspectItems do
		if i ~= 4 then
			local inspectItem = _G[which..InspectItems[i]]
			inspectItem.enchantText:SetText('')
			inspectItem.iLvlText:SetText('')

			for y=1, 10 do
				inspectItem['textureSlot'..y]:SetTexture()
				inspectItem['textureSlotBackdrop'..y]:Hide()
			end
		end
	end
end

function M:ToggleItemLevelInfo(setupCharacterPage)
	if E.Classic then return end

	if setupCharacterPage then
		M:CreateSlotStrings(_G.CharacterFrame, 'Character')
	end

	if E.db.general.itemLevel.displayCharacterInfo then
		M:RegisterEvent('AZERITE_ESSENCE_UPDATE', 'UpdateCharacterInfo')
		M:RegisterEvent('PLAYER_EQUIPMENT_CHANGED', 'UpdateCharacterInfo')
		M:RegisterEvent('PLAYER_AVG_ITEM_LEVEL_UPDATE', 'UpdateCharacterInfo')
		M:RegisterEvent('UPDATE_INVENTORY_DURABILITY', 'UpdateCharacterInfo')

		if E.Retail then
			_G.CharacterStatsPane.ItemLevelFrame.Value:Hide()
		end

		if not _G.CharacterFrame.CharacterInfoHooked then
			_G.CharacterFrame:HookScript('OnShow', M.UpdateCharacterInfo)
			_G.CharacterFrame.CharacterInfoHooked = true
		end

		if not setupCharacterPage then
			M:UpdateCharacterInfo()
		end
	else
		M:UnregisterEvent('AZERITE_ESSENCE_UPDATE')
		M:UnregisterEvent('PLAYER_EQUIPMENT_CHANGED')
		M:UnregisterEvent('PLAYER_AVG_ITEM_LEVEL_UPDATE')
		M:UnregisterEvent('UPDATE_INVENTORY_DURABILITY')

		if E.Retail then
			_G.CharacterStatsPane.ItemLevelFrame.Value:Show()
		end

		M:ClearPageInfo(_G.CharacterFrame, 'Character')
	end

	if E.db.general.itemLevel.displayInspectInfo then
		M:RegisterEvent('INSPECT_READY', 'UpdateInspectInfo')
	else
		M:UnregisterEvent('INSPECT_READY')
		M:ClearPageInfo(_G.InspectFrame, 'Inspect')
	end
end

function M:UpdatePageStrings(i, iLevelDB, inspectItem, slotInfo, which) -- `which` is used by plugins
	iLevelDB[i] = slotInfo.iLvl

	inspectItem.enchantText:SetText(slotInfo.enchantTextShort)
	if slotInfo.enchantColors and next(slotInfo.enchantColors) then
		inspectItem.enchantText:SetTextColor(unpack(slotInfo.enchantColors))
	end

	inspectItem.iLvlText:SetText(slotInfo.iLvl)
	if E.db.general.itemLevel.itemLevelRarity and slotInfo.itemLevelColors and next(slotInfo.itemLevelColors) then
		inspectItem.iLvlText:SetTextColor(unpack(slotInfo.itemLevelColors))
	end

	local gemStep, essenceStep = 1, 1
	for x = 1, 10 do
		local texture = inspectItem['textureSlot'..x]
		local backdrop = inspectItem['textureSlotBackdrop'..x]
		local essenceType = inspectItem['textureSlotEssenceType'..x]
		if essenceType then essenceType:Hide() end

		local gem = slotInfo.gems and slotInfo.gems[gemStep]
		local essence = not gem and (slotInfo.essences and slotInfo.essences[essenceStep])
		if gem then
			texture:SetTexture(gem)
			backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
			backdrop:Show()

			gemStep = gemStep + 1
		elseif essence and next(essence) then
			local hexColor = essence[4]
			if hexColor then
				local r, g, b = E:HexToRGB(hexColor)
				backdrop:SetBackdropBorderColor(r/255, g/255, b/255)
			else
				backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
			end

			if not essenceType then
				essenceType = inspectItem:CreateTexture()
				essenceType:SetTexture(2907423)
				essenceType:SetRotation(rad(90))
				essenceType:SetParent(backdrop)
				inspectItem['textureSlotEssenceType'..x] = essenceType
			end

			essenceType:Point('BOTTOM', texture, 'TOP', 0, -9)
			essenceType:SetAtlas(gsub(essence[2], '^tooltip%-(heartofazeroth)essence', '%1-list-selected'))
			essenceType:Size(13, 17)
			essenceType:Show()

			local selected = essence[1]
			texture:SetTexture(selected)
			backdrop:Show()

			if selected then
				backdrop:SetBackdropColor(0,0,0,0)
			else
				local r, g, b = unpack(E.media.backdropcolor)
				backdrop:SetBackdropColor(r, g, b, 1)
			end

			essenceStep = essenceStep + 1
		else
			texture:SetTexture()
			backdrop:Hide()
		end
	end
end

function M:UpdateAverageString(frame, which, iLevelDB)
	local charPage, avgItemLevel, avgTotal = which == 'Character'

	if charPage then
		avgTotal, avgItemLevel = E:GetPlayerItemLevel() -- rounded average, rounded equipped
	elseif frame.unit then
		avgItemLevel = E:CalculateAverageItemLevel(iLevelDB, frame.unit)
	end

	if avgItemLevel then
		if charPage then
			frame.ItemLevelText:SetText(avgItemLevel)

			if E.Retail then
				frame.ItemLevelText:SetTextColor(_G.CharacterStatsPane.ItemLevelFrame.Value:GetTextColor())
			end
		else
			frame.ItemLevelText:SetText(avgItemLevel)
		end

		-- we have to wait to do this on inspect so handle it in here
		if not E.db.general.itemLevel.itemLevelRarity then
			for i = 1, numInspectItems do
				if i ~= 4 then
					local ilvl = iLevelDB[i]
					if ilvl then
						local inspectItem = _G[which..InspectItems[i]]
						local r, g, b = E:ColorizeItemLevel(ilvl - (avgTotal or avgItemLevel))
						inspectItem.iLvlText:SetTextColor(r, g, b)
					end
				end
			end
		end
	else
		frame.ItemLevelText:SetText('')
	end
end

function M:TryGearAgain(frame, which, i, deepScan, iLevelDB, inspectItem)
	E:Delay(0.05, function()
		if which == 'Inspect' and (not frame or not frame.unit) then return end

		local unit = (which == 'Character' and 'player') or frame.unit
		local slotInfo = E:GetGearSlotInfo(unit, i, deepScan)
		if slotInfo == 'tooSoon' then return end

		M:UpdatePageStrings(i, iLevelDB, inspectItem, slotInfo, which)
	end)
end

do
	local iLevelDB = {}
	function M:UpdatePageInfo(frame, which, guid, event)
		if which == 'Inspect' then M.InspectTimer = nil end -- clear inspect timer
		if not (which and frame and frame.ItemLevelText) then return end
		if which == 'Inspect' and (not frame or not frame.unit or (guid and frame:IsShown() and UnitGUID(frame.unit) ~= guid)) then return end

		wipe(iLevelDB)

		local waitForItems
		for i = 1, numInspectItems do
			if i ~= 4 then
				local inspectItem = _G[which..InspectItems[i]]
				inspectItem.enchantText:SetText('')
				inspectItem.iLvlText:SetText('')

				local unit = (which == 'Character' and 'player') or frame.unit
				local slotInfo = E:GetGearSlotInfo(unit, i, true)
				if slotInfo == 'tooSoon' then
					if not waitForItems then waitForItems = true end
					M:TryGearAgain(frame, which, i, true, iLevelDB, inspectItem)
				else
					M:UpdatePageStrings(i, iLevelDB, inspectItem, slotInfo, which)
				end
			end
		end

		if event and event == 'PLAYER_EQUIPMENT_CHANGED' then
			return
		end

		if waitForItems then
			E:Delay(0.1, M.UpdateAverageString, M, frame, which, iLevelDB)
		else
			M:UpdateAverageString(frame, which, iLevelDB)
		end
	end
end

function M:CreateSlotStrings(frame, which)
	if not (frame and which) then return end

	local itemLevelFont = E.db.general.itemLevel.itemLevelFont
	local itemLevelFontSize = E.db.general.itemLevel.itemLevelFontSize or 12
	local itemLevelFontOutline = E.db.general.itemLevel.itemLevelFontOutline or 'OUTLINE'

	if which == 'Inspect' then
		frame.ItemLevelText = _G.InspectPaperDollItemsFrame:CreateFontString(nil, 'ARTWORK')
		frame.ItemLevelText:Point('BOTTOMLEFT', E.Cata and 20 or 6, E.Cata and 84 or 6)
	elseif E.Cata then
		frame.ItemLevelText = _G.PaperDollItemsFrame:CreateFontString(nil, 'ARTWORK')
		frame.ItemLevelText:Point('BOTTOMLEFT', _G.PaperDollItemsFrame, 6, 6)
	else
		frame.ItemLevelText = _G.CharacterStatsPane.ItemLevelFrame:CreateFontString(nil, 'ARTWORK')
		frame.ItemLevelText:Point('CENTER', _G.CharacterStatsPane.ItemLevelFrame.Value, 'CENTER', 0, -1)
	end

	frame.ItemLevelText:FontTemplate(nil, 18)

	for i, s in pairs(InspectItems) do
		if i ~= 4 then
			local slot = _G[which..s]
			local x, y, z, justify = M:GetInspectPoints(i)
			slot.iLvlText = slot:CreateFontString(nil, 'OVERLAY')
			slot.iLvlText:FontTemplate(LSM:Fetch('font', itemLevelFont), itemLevelFontSize, itemLevelFontOutline)
			slot.iLvlText:Point('BOTTOM', slot, x, y)

			slot.enchantText = slot:CreateFontString(nil, 'OVERLAY')
			slot.enchantText:FontTemplate(LSM:Fetch('font', itemLevelFont), itemLevelFontSize, itemLevelFontOutline)

			local itemLeft, itemRight = i == 16, (E.Retail and i == 17) or (E.Cata and i == 18)
			if itemLeft or itemRight then
				slot.enchantText:Point(itemLeft and 'BOTTOMRIGHT' or 'BOTTOMLEFT', slot, itemLeft and -40 or 40, 3)
			elseif E.Cata and i == 17 then -- cata secondary (not ranged)
				slot.enchantText:Point('TOP', slot, 'BOTTOM', 0, 3)
			else
				slot.enchantText:Point(justify, slot, x + (justify == 'BOTTOMLEFT' and 5 or -5), z)
			end

			local weapon = i == 16 or i == 17 or i == 18
			for u = 1, 10 do
				local offset = 8 + (u * 16)
				local newX = (weapon and 0) or ((justify == 'BOTTOMLEFT' or itemRight) and x+offset) or x-offset
				slot['textureSlot'..u], slot['textureSlotBackdrop'..u] = M:CreateInspectTexture(slot, newX, (weapon and offset+40) or y)
			end
		end
	end
end

function M:SetupInspectPageInfo()
	local frame = _G.InspectFrame
	if frame and not frame.ItemLevelText then
		M:CreateSlotStrings(frame, 'Inspect')
	end
end

function M:UpdateInspectPageFonts(which)
	local itemLevelFont = E.db.general.itemLevel.itemLevelFont
	local itemLevelFontSize = E.db.general.itemLevel.itemLevelFontSize or 12
	local itemLevelFontOutline = E.db.general.itemLevel.itemLevelFontOutline or 'OUTLINE'

	for i, s in pairs(InspectItems) do
		if i ~= 4 then
			local slot = _G[which..s]
			if slot then
				slot.iLvlText:FontTemplate(LSM:Fetch('font', itemLevelFont), itemLevelFontSize, itemLevelFontOutline)
				slot.enchantText:FontTemplate(LSM:Fetch('font', itemLevelFont), itemLevelFontSize, itemLevelFontOutline)
			end
		end
	end
end
