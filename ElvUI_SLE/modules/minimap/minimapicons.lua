local E, L, V, P, G, _ = unpack(ElvUI); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB, Localize Underscore
local SMB = E:NewModule('SquareMinimapButtons', 'AceHook-3.0', 'AceEvent-3.0');

local AddOnName, NS = ...
local strsub, strlen, strfind, ceil = strsub, strlen, strfind, ceil
local tinsert, pairs, unpack = tinsert, pairs, unpack

local BorderColor
local TexCoords = { 0.1, 0.9, 0.1, 0.9 }

if E.private.sle == nil then E.private.sle = {} end
if E.private.sle.minimap == nil then E.private.sle.minimap = {} end
if E.private.sle.minimap.mapicons == nil then E.private.sle.minimap.mapicons = {} end
if E.private.sle.minimap.mapicons.enable == nil then E.private.sle.minimap.mapicons.enable = false end

if E.db.sle.minimap == nil then E.db.sle.minimap = {} end
if E.db.sle.minimap.mapicons == nil then E.db.sle.minimap.mapicons = {} end
if E.db.sle.minimap.mapicons.iconmouseover == nil then E.db.sle.minimap.mapicons.iconmouseover = false end
if E.db.sle.minimap.mapicons.iconsize == nil then E.db.sle.minimap.mapicons.iconsize = 27 end
if E.db.sle.minimap.mapicons.iconperrow == nil then E.db.sle.minimap.mapicons.iconperrow = 12 end

QueueStatusMinimapButton:SetParent(Minimap)

local ignoreButtons = {
	'AsphyxiaUIMinimapHelpButton',
	'AsphyxiaUIMinimapVersionButton',
	'FAQButton',
	'VersionButton',
	'ElvConfigToggle',
	'GameTimeFrame',
	'HelpOpenTicketButton',
	'MiniMapMailFrame',
	'MiniMapTrackingButton',
	'MiniMapVoiceChatFrame',
	'TimeManagerClockButton',
}

local function OnEnter(self)
	UIFrameFadeIn(SquareMinimapButtonBar, 0.2, SquareMinimapButtonBar:GetAlpha(), 1)
	if self:GetName() ~= 'SquareMinimapButtonBar' then
		self:SetBackdropBorderColor(.7, 0, .7)
	end
end

local function OnLeave(self)
	if E.db.sle.minimap.mapicons.iconmouseover then
		UIFrameFadeOut(SquareMinimapButtonBar, 0.2, SquareMinimapButtonBar:GetAlpha(), 0)
	end
	if self:GetName() ~= 'SquareMinimapButtonBar' then
		self:SetBackdropBorderColor(unpack(BorderColor))
	end
end

function SMB:ChangeMouseOverSetting()
	if E.db.sle.minimap.mapicons.iconmouseover then
		SquareMinimapButtonBar:SetAlpha(0)
	else
		SquareMinimapButtonBar:SetAlpha(1)
	end
end

local SkinnedMinimapButtons = {}

local GenericIgnores = {
	'Archy',
	'GatherMatePin',
	'GatherNote',
	'GuildInstance',
	'HandyNotesPin',
	'MinimMap',
	'Spy_MapNoteList_mini',
	'ZGVMarker',
}

local PartialIgnores = {
	'Node',
	'Note',
	'Pin',
}

local WhiteList = {
	'LibDBIcon',
}

local AcceptedFrames = {
	'BagSync_MinimapButton',
	'VendomaticButtonFrame',
}

local AddButtonsToBar = {
	'SmartBuff_MiniMapButton',
	'QueueStatusMinimapButton',
}

local function SkinButton(Button)
	if not Button.isSkinned then
		local Name = Button:GetName()

		if Button:GetObjectType() == 'Button' then
			local ValidIcon = false

			for i = 1, #WhiteList do
				if strsub(Name, 1, strlen(WhiteList[i])) == WhiteList[i] then ValidIcon = true break end
			end

			if not ValidIcon then
				for i = 1, #ignoreButtons do
					if Name == ignoreButtons[i] then return end
				end

				for i = 1, #GenericIgnores do
					if strsub(Name, 1, strlen(GenericIgnores[i])) == GenericIgnores[i] then return end
				end

				for i = 1, #PartialIgnores do
					if strfind(Name, PartialIgnores[i]) ~= nil then return end
				end
			end

			Button:SetPushedTexture(nil)
			Button:SetHighlightTexture(nil)
			Button:SetDisabledTexture(nil)
		end

		for i = 1, Button:GetNumRegions() do
			local Region = select(i, Button:GetRegions())
			if Region:GetObjectType() == 'Texture' then
				local Texture = Region:GetTexture()

				if Texture and (strfind(Texture, 'Border') or strfind(Texture, 'Background') or strfind(Texture, 'AlphaMask')) then
					Region:SetTexture(nil)
				else
					if Name == 'BagSync_MinimapButton' then Region:SetTexture('Interface\\AddOns\\BagSync\\media\\icon') end
					if Name == 'DBMMinimapButton' then Region:SetTexture('Interface\\Icons\\INV_Helmet_87') end
					if Name == 'SmartBuff_MiniMapButton' then Region:SetTexture(select(3, GetSpellInfo(12051))) end
					Region:ClearAllPoints()
					Region:SetInside()
					Region:SetTexCoord(unpack(TexCoords))
					Region:SetDrawLayer('ARTWORK')
					Region.SetPoint = function() return end
					Button:HookScript('OnLeave', function(self) Region:SetTexCoord(unpack(TexCoords)) end)
				end
			end
		end

		Button:SetFrameLevel(Minimap:GetFrameLevel() + 5)
		Button:Size(E.db.sle.minimap.mapicons.iconsize)

		if Name == 'VendomaticButtonFrame' then
			VendomaticButton:StripTextures()
			VendomaticButton:SetInside()
			VendomaticButtonIcon:SetTexture('Interface\\Icons\\INV_Misc_Rabbit_2')
			VendomaticButtonIcon:SetTexCoord(unpack(TexCoords))
		end

		if Name == 'QueueStatusMinimapButton' then
			QueueStatusMinimapButton:HookScript('OnUpdate', function(self)
				QueueStatusMinimapButtonIcon:SetFrameLevel(QueueStatusMinimapButton:GetFrameLevel() + 1)
			end)
			local Frame = CreateFrame('Frame', nil, SquareMinimapButtonBar)
			Frame:Hide()
			Frame:SetTemplate()
			Frame.Icon = Frame:CreateTexture(nil, 'ARTWORK')
			Frame.Icon:SetInside()
			Frame.Icon:SetTexture([[Interface\LFGFrame\LFG-Eye]])
			Frame.Icon:SetTexCoord(0, 64 / 512, 0, 64 / 256)
			Frame:SetScript('OnMouseDown', function()
				if PVEFrame:IsShown() then
					HideUIPanel(PVEFrame)
				else
					ShowUIPanel(PVEFrame)
					GroupFinderFrame_ShowGroupFrame()
				end
			end)
			SquareMinimapButtonBar:HookScript('OnUpdate', function()
				if E.db.sle.minimap.mapicons.skindungeon then
					Frame:Show()
				else
					Frame:Hide()
				end
			end)
			QueueStatusMinimapButton:HookScript('OnShow', function()
				if E.db.sle.minimap.mapicons.skindungeon then
					Frame:Show()
				else
					Frame:Hide()
				end
			end)
			Frame:HookScript('OnEnter', OnEnter)
			Frame:HookScript('OnLeave', OnLeave)
			Frame:SetScript('OnUpdate', function(self)
				if QueueStatusMinimapButton:IsShown() then
					self:EnableMouse(false)
				else
					self:EnableMouse(true)
				end
				self:Size(E.db.sle.minimap.mapicons.iconsize)
				self:SetFrameStrata(QueueStatusMinimapButton:GetFrameStrata())
				self:SetFrameLevel(QueueStatusMinimapButton:GetFrameLevel())
				self:SetPoint(QueueStatusMinimapButton:GetPoint())
			end)
		else
			Button:SetTemplate()
			Button:SetBackdropColor(0, 0, 0, 0)
		end

		Button.isSkinned = true
		tinsert(SkinnedMinimapButtons, Button)
	end
end

local SquareMinimapButtonBar = CreateFrame('Frame', 'SquareMinimapButtonBar', UIParent)
SquareMinimapButtonBar:RegisterEvent('ADDON_LOADED')
SquareMinimapButtonBar:RegisterEvent('PLAYER_ENTERING_WORLD')
SquareMinimapButtonBar.Skin = function()
	for i = 1, Minimap:GetNumChildren() do
		local object = select(i, Minimap:GetChildren())
		if object:GetObjectType() == 'Button' and object:GetName() then
			SkinButton(object)
		end
		for _, frame in pairs(AcceptedFrames) do
			if object:GetName() == frame then
				SkinButton(object)
			end
		end
	end
end

function SMB:Update(self)
	if not E.private.sle.minimap.mapicons.enable then return end

	local AnchorX, AnchorY, MaxX = 0, 1, E.db.sle.minimap.mapicons.iconperrow
	local ButtonsPerRow = E.db.sle.minimap.mapicons.iconperrow
	local NumColumns = ceil(#SkinnedMinimapButtons / ButtonsPerRow)
	local Spacing, Mult = 4, 1
	local Size = E.db.sle.minimap.mapicons.iconsize
	local ActualButtons, Maxed = 0

	if NumColumns == 1 and ButtonsPerRow > #SkinnedMinimapButtons then
		ButtonsPerRow = #SkinnedMinimapButtons
	end

	for Key, Frame in pairs(SkinnedMinimapButtons) do
		local Exception = false
		for _, Button in pairs(AddButtonsToBar) do
			if Frame:GetName() == Button then
				Exception = true
				if Frame:GetName() == 'SmartBuff_MiniMapButton' then
					SMARTBUFF_MinimapButton_CheckPos = function() end
					SMARTBUFF_MinimapButton_OnUpdate = function() end
				end
				if not E.db.sle.minimap.mapicons.skindungeon and Frame:GetName() == 'QueueStatusMinimapButton' then
					Exception = false
				end
			end
		end
		if Frame:IsVisible() or Exception then
			AnchorX = AnchorX + 1
			ActualButtons = ActualButtons + 1
			if AnchorX > MaxX then
				AnchorY = AnchorY + 1
				AnchorX = 1
				Maxed = true
			end

			local yOffset = - Spacing - ((Size + Spacing) * (AnchorY - 1))
			local xOffset = Spacing + ((Size + Spacing) * (AnchorX - 1))
			Frame:SetTemplate()
			Frame:SetBackdropColor(0, 0, 0, 0)
			Frame:SetParent(SquareMinimapButtonBar)
			Frame:ClearAllPoints()
			Frame:Point('TOPLEFT', SquareMinimapButtonBar, 'TOPLEFT', xOffset, yOffset)
			Frame:SetSize(E.db.sle.minimap.mapicons.iconsize, E.db.sle.minimap.mapicons.iconsize)
			Frame:SetFrameStrata('LOW')
			Frame:SetFrameLevel(Minimap:GetFrameLevel() + 5)
			Frame:RegisterForDrag('LeftButton')
			Frame:SetScript('OnDragStart', function(self) self:GetParent():StartMoving() end)
			Frame:SetScript('OnDragStop', function(self) self:GetParent():StopMovingOrSizing() end)
			Frame:HookScript('OnEnter', OnEnter)
			Frame:HookScript('OnLeave', OnLeave)
		end
	end

	if Maxed then ActualButtons = ButtonsPerRow end

	local BarWidth = (Spacing + ((Size * (ActualButtons * Mult)) + ((Spacing * (ActualButtons - 1)) * Mult) + (Spacing * Mult)))
	local BarHeight = (Spacing + ((Size * (AnchorY * Mult)) + ((Spacing * (AnchorY - 1)) * Mult) + (Spacing * Mult)))

	self:SetSize(BarWidth, BarHeight)
	self:Show()
end

SquareMinimapButtonBar:SetScript('OnEvent', function(self, event, addon)
	if addon == AddOnName then
		self:Hide()
		self:SetTemplate('Transparent', true)
		BorderColor = { self:GetBackdropBorderColor() }
		self:SetFrameStrata('BACKGROUND')
		self:SetClampedToScreen(true)
		self:SetMovable()
		self:SetPoint('RIGHT', UIParent, 'RIGHT', -45, 0)
		self:SetScript('OnEnter', OnEnter)
		self:SetScript('OnLeave', OnLeave)
		self:RegisterForDrag('LeftButton')
		self:SetScript('OnDragStart', self.StartMoving)
		self:SetScript('OnDragStop', self.StopMovingOrSizing)
		self:UnregisterEvent(event)
	end
	self.Skin()
	if event == 'PLAYER_ENTERING_WORLD' then ElvUI[1]:Delay(5, self.Skin) self:UnregisterEvent(event) self:RegisterEvent('ADDON_LOADED') end
	if E.private.sle.minimap.mapicons.enable then SMB:Update(self) end
	OnLeave(self)
end)

E:RegisterModule(SMB:GetName())