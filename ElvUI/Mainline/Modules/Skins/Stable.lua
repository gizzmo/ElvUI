local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule('Skins')

local _G = _G
local hooksecurefunc = hooksecurefunc

local function AbilitiesList_Layout(list)
	if not list.abilityPool then return end

	for frame in list.abilityPool:EnumerateActive() do
		if not frame.IsSkinned then
			S:HandleIcon(frame.Icon)
			frame.IsSkinned = true
		end
	end
end

function S:Blizzard_StableUI()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.stable) then return end

	local StableFrame = _G.StableFrame
	S:HandlePortraitFrame(StableFrame)
	StableFrame.MainHelpButton:Hide()
	S:HandleButton(StableFrame.StableTogglePetButton)
	S:HandleButton(StableFrame.ReleasePetButton)

	local StabledPetList = StableFrame.StabledPetList
	StabledPetList:StripTextures()
	StabledPetList.ListName:FontTemplate(nil, 32)
	StabledPetList.ListCounter:StripTextures()
	StabledPetList.ListCounter:CreateBackdrop('Transparent')

	S:HandleEditBox(StabledPetList.FilterBar.SearchBox)
	--S:HandleButton(StabledPetList.FilterBar.FilterButton) -- FIX ME 11.0
	--S:HandleCloseButton(StabledPetList.FilterBar.FilterButton.ResetButton) -- FIX ME 11.0
	S:HandleTrimScrollBar(StabledPetList.ScrollBar)

	local modelScene = StableFrame.PetModelScene
	if modelScene then
		local sceneShadow = modelScene.PetModelSceneShadow
		if sceneShadow then
			sceneShadow:SetInside()
		end

		local inset = modelScene.Inset
		if inset then
			inset.NineSlice:SetTemplate()
			inset.Bg:Hide()
		end

		local abilitiesList = modelScene.AbilitiesList
		if abilitiesList then
			hooksecurefunc(abilitiesList, 'Layout', AbilitiesList_Layout)
		end

		local petInfo = modelScene.PetInfo
		if petInfo then
			if petInfo.Type then
				hooksecurefunc(petInfo.Type, 'SetText', S.ReplaceIconString)
			end

			--[[ this sucks need something better; pushed also broke
			local editButton = petInfo.NameBox.EditButton
			if editButton then
				local icon = editButton.Icon:GetAtlas()
				S:HandleButton(editButton)
				editButton.Icon:SetAtlas(icon)
				editButton.Icon:SetTexCoord(.22, .8, .22, .8)
			end
			]]
		end
	end

	S:HandleModelSceneControlButtons(modelScene.ControlFrame)
end

S:AddCallbackForAddon('Blizzard_StableUI')
