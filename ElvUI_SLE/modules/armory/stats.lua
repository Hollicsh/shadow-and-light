local SLE, _, E = unpack(select(2, ...))
local Armory = SLE.Armory_Core
local SA = SLE.Armory_Stats
local M = E.Misc

local _G = _G
local math_min = math.min
local format = format
local GetAverageItemLevel, BreakUpLargeNumbers = GetAverageItemLevel, BreakUpLargeNumbers
local UnitClass = UnitClass
local GetCombatRatingBonus = GetCombatRatingBonus
SA.totalShown = 0
SA.OriginalPaperdollStats = E:CopyTable({}, PAPERDOLL_STATCATEGORIES)

function SA:BuildNewStats()
	SA:CreateStatCategory('OffenseCategory', STAT_CATEGORY_ATTACK)
	SA:CreateStatCategory('DefenseCategory', DEFENSE)

	SA.AlteredPaperdollStats = {
		[1] = {
			categoryFrame = 'AttributesCategory',
			stats = {
				[1] = { stat = 'STRENGTH', primary = LE_UNIT_STAT_STRENGTH },
				[2] = { stat = 'AGILITY', primary = LE_UNIT_STAT_AGILITY },
				[3] = { stat = 'INTELLECT', primary = LE_UNIT_STAT_INTELLECT },
				[4] = { stat = 'STAMINA' },
				[5] = { stat = 'HEALTH', option = true },
				[6] = { stat = 'POWER', option = true },
				[7] = { stat = 'ALTERNATEMANA', option = true, classes = {'PRIEST', 'SHAMAN', 'DRUID'} },
				[8] = { stat = 'MOVESPEED', option = true },
			},
		},
		[2] = {
			categoryFrame = 'OffenseCategory',
			stats = {
				[1] = { stat = 'ATTACK_DAMAGE', option = true, hideAt = 0 },
				[2] = { stat = 'ATTACK_AP', option = true, hideAt = 0 },
				[3] = { stat = 'SPELLPOWER', option = true, hideAt = 0 },
				[4] = { stat = 'MANAREGEN', option = true, power = 'MANA' },
				[5] = { stat = 'ENERGY_REGEN', option = true, power = 'ENERGY', hideAt = 0, roles = {'TANK', 'DAMAGER'},  classes = {'ROUGE', 'DRUID', 'MONK'} },
				[6] = { stat = 'FOCUS_REGEN', option = true, power = 'FOCUS', hideAt = 0, classes = {'HUNTER'} },
				[7] = { stat = 'RUNE_REGEN', option = true, power = 'RUNIC_POWER', hideAt = 0, classes = {'DEATHKNIGHT'} },
			},
		},
		[3] = {
			categoryFrame = 'EnhancementsCategory',
			stats = {
				[1] = { stat = 'CRITCHANCE', option = true, hideAt = 0 },
				[2] = { stat = 'HASTE', option = true, hideAt = 0 },
				[3] = { stat = 'MASTERY', option = true, hideAt = 0 },
				[4] = { stat = 'VERSATILITY', option = true, hideAt = 0 },
				[5] = { stat = 'LIFESTEAL', option = true, hideAt = 0 },
			},
		},
		[4] = {
			categoryFrame = 'DefenseCategory',
			stats = {
				[1] = { stat = 'ARMOR', option = true, },
				[2] = { stat = 'AVOIDANCE', option = true, hideAt = 0 },
				[3] = { stat = 'DODGE', option = true,},
				[4] = { stat = 'PARRY', option = true, hideAt = 0, },
				[5] = { stat = 'BLOCK', option = true, hideAt = 0, },
				[6] = { stat = 'STAGGER', hideAt = 0, roles = {'TANK'}, },
			},
		},
	}
	if GetLocale() ~= "ruRU" then
		SA.AlteredPaperdollStats[2].stats[8] = { stat = 'ATTACK_ATTACKSPEED', option = true, hideAt = 0, numericValue = 0 }
	end
end

function SA:CreateStatCategory(catName, text)
	if _G.CharacterStatsPane[catName] then return end

	_G.CharacterStatsPane[catName] = CreateFrame('Frame', nil, _G.CharacterStatsPane, 'CharacterStatFrameCategoryTemplate')
	_G.CharacterStatsPane[catName].Title:SetText(text)
	_G.CharacterStatsPane[catName]:StripTextures()
	_G.CharacterStatsPane[catName]:CreateBackdrop('Transparent')
	_G.CharacterStatsPane[catName].backdrop:ClearAllPoints()
	_G.CharacterStatsPane[catName].backdrop:SetPoint('CENTER')
	_G.CharacterStatsPane[catName].backdrop:SetWidth(150)
	_G.CharacterStatsPane[catName].backdrop:SetHeight(18)
end

function SA:BuildScrollBar() --Creating new scroll
	--Scrollframe Parent Frame
	SA.ScrollframeParentFrame = CreateFrame('Frame', 'SLE_Armory_ScrollParent', _G.CharacterFrameInsetRight)
	SA.ScrollframeParentFrame:SetSize(198, 352)
	SA.ScrollframeParentFrame:SetPoint('TOP', _G.CharacterFrameInsetRight, 'TOP', -4, -4)
	--Scrollframe
	SA.ScrollFrame = CreateFrame('ScrollFrame', 'SLE_Armory_Scroll', SA.ScrollframeParentFrame)
	SA.ScrollFrame:SetPoint('TOP')
	SA.ScrollFrame:SetSize(SA.ScrollframeParentFrame:GetSize())

	--Scrollbar
	SA.Scrollbar = CreateFrame('Slider', nil, SA.ScrollFrame, 'UIPanelScrollBarTemplate')
	SA.Scrollbar:SetPoint('TOPLEFT', _G.CharacterFrameInsetRight, 'TOPRIGHT', -12, -20)
	SA.Scrollbar:SetPoint('BOTTOMLEFT', _G.CharacterFrameInsetRight, 'BOTTOMRIGHT', -12, 18)
	SA.Scrollbar:SetMinMaxValues(1, 2)
	SA.Scrollbar:SetValueStep(1)
	SA.Scrollbar.scrollStep = 1
	SA.Scrollbar:SetValue(0)
	SA.Scrollbar:SetWidth(8)
	SA.Scrollbar:SetScript('OnValueChanged', function(frame, value)
		local offset = value > 1 and frame:GetParent():GetVerticalScrollRange()/(SA.totalShown*Armory.Constants.Stats.ScrollStepMultiplier) or 1
		frame:GetParent():SetVerticalScroll(value*offset)
	end)
	SLE.Skins:ConvertScrollBarToThin(SA.Scrollbar)
	SA.Scrollbar:Hide()

	SA.ScrollChild = CreateFrame('Frame', nil, SA.ScrollFrame)
	SA.ScrollChild:SetSize(SA.ScrollFrame:GetSize())
	SA.ScrollFrame:SetScrollChild(SA.ScrollChild)

	CharacterStatsPane:ClearAllPoints()
	CharacterStatsPane:SetParent(SA.ScrollChild)
	CharacterStatsPane:SetSize(SA.ScrollChild:GetSize())
	CharacterStatsPane:SetPoint('TOP', SA.ScrollChild, 'TOP', 0, 0)

	CharacterStatsPane.ClassBackground:ClearAllPoints()
	CharacterStatsPane.ClassBackground:SetParent( _G["CharacterFrameInsetRight"])
	CharacterStatsPane.ClassBackground:SetPoint("CENTER")

	-- Enable mousewheel scrolling
	SA.ScrollFrame:EnableMouseWheel(true)
	SA.ScrollFrame:SetScript('OnMouseWheel', function(_, delta)
		local cur_val = SA.Scrollbar:GetValue()

		SA.Scrollbar:SetValue(cur_val - delta*SA.totalShown) --This controls the speed of the scroll
	end)

	PaperDollSidebarTab1:HookScript('OnShow', function()
		SA.ScrollframeParentFrame:Show()
	end)

	PaperDollSidebarTab1:HookScript('OnClick', function()
		SA.ScrollframeParentFrame:Show()
	end)

	PaperDollSidebarTab2:HookScript('OnClick', function()
		SA.ScrollframeParentFrame:Hide()
	end)

	PaperDollSidebarTab3:HookScript('OnClick', function()
		SA.ScrollframeParentFrame:Hide()
	end)
end

function SA:UpdateCharacterItemLevel(frame, which)
	if not frame or which ~= 'Character' then return end

	SA:UpdateIlvlFont()
	if not E.db.sle.armory.stats.enable or not E.db.general.itemLevel.displayCharacterInfo then return end
	local total, equipped = GetAverageItemLevel()
	if E.db.sle.armory.stats.IlvlFull then
		if E.db.sle.armory.stats.IlvlColor then
			local r, g, b = E:ColorGradient((equipped / total), 1, 0, 0, 1, 1, 0, 0, 1, 0)
			local avColor = E.db.sle.armory.stats.AverageColor
			frame.ItemLevelText:SetFormattedText('%s%.2f|r |cffffffff/|r %s%.2f|r', E:RGBToHex(r, g, b), equipped, E:RGBToHex(avColor.r, avColor.g, avColor.b), total)
		else
			frame.ItemLevelText:SetFormattedText('%.2f / %.2f', equipped, total)
		end
	end
end

function SA:PaperDollFrame_UpdateStats()
	SA.totalShown = 0
	local categoryYOffset, statYOffset = 0, 0

	if E.db.sle.armory.stats.enable then
		if E.db.sle.armory.stats.IlvlFull then
			local total, equipped = GetAverageItemLevel()
			if E.db.sle.armory.stats.IlvlColor then
				local r, g, b = E:ColorGradient((equipped / total), 1, 0, 0, 1, 1, 0, 0, 1, 0)
				local avColor = E.db.sle.armory.stats.AverageColor
				_G.CharacterStatsPane.ItemLevelFrame.Value:SetFormattedText('%s%.2f|r |cffffffff/|r %s%.2f|r', E:RGBToHex(r, g, b), equipped, E:RGBToHex(avColor.r, avColor.g, avColor.b), total)
			else
				_G.CharacterStatsPane.ItemLevelFrame.Value:SetFormattedText('%.2f / %.2f', equipped, total)
			end
		else
			_G.CharacterStatsPane.ItemLevelFrame.Value:SetTextColor(GetItemLevelColor())
			PaperDollFrame_SetItemLevel(_G.CharacterStatsPane.ItemLevelFrame, 'player')
		end

		_G.CharacterStatsPane.ItemLevelCategory:SetPoint('TOP', _G.CharacterStatsPane, 'TOP', 0, 8)
		_G.CharacterStatsPane.AttributesCategory:SetPoint('TOP', _G.CharacterStatsPane.ItemLevelFrame, 'BOTTOM', 0, 2)

		categoryYOffset = 8
		statYOffset = 0
	end

	_G.CharacterStatsPane.ItemLevelCategory:Show()
	_G.CharacterStatsPane.ItemLevelCategory.Title:FontTemplate(E.LSM:Fetch('font', E.db.sle.armory.stats.enable and E.db.sle.armory.stats.statHeaders.font or E.db.general.itemLevel.itemLevelFont), E.db.sle.armory.stats.enable and E.db.sle.armory.stats.statHeaders.fontSize or (E.db.general.itemLevel.itemLevelFontSize or 12), E.db.sle.armory.stats.enable and E.db.sle.armory.stats.statHeaders.fontOutline or 'NONE')
	_G.CharacterStatsPane.ItemLevelFrame:Show()

	local _, powerType = UnitPowerType('player')
	local spec, role
	spec = GetSpecialization()
	if spec then
		role = GetSpecializationRole(spec)
	end

	_G.CharacterStatsPane.statsFramePool:ReleaseAll()
	-- we need a stat frame to first do the math to know if we need to show the stat frame
	-- so effectively we'll always pre-allocate
	local statFrame = _G.CharacterStatsPane.statsFramePool:Acquire()

	local lastAnchor
	local statLabels = {
		font = E.db.sle.armory.stats.statLabels.font,
		fontSize = E.db.sle.armory.stats.statLabels.fontSize,
		fontOutline = E.db.sle.armory.stats.statLabels.fontOutline,
	}
	local statHeaders = {
		font = E.db.sle.armory.stats.statLabels.font,
		fontSize = E.db.sle.armory.stats.statLabels.fontSize,
		fontOutline = E.db.sle.armory.stats.statLabels.fontOutline,
	}

	for catIndex = 1, #PAPERDOLL_STATCATEGORIES do
		local catFrame = _G['CharacterStatsPane'][PAPERDOLL_STATCATEGORIES[catIndex].categoryFrame]
		catFrame.Title:FontTemplate(E.LSM:Fetch('font', E.db.sle.armory.stats.enable and statHeaders.font or E.db.general.itemLevel.itemLevelFont), E.db.sle.armory.stats.enable and statHeaders.fontSize or (E.db.general.itemLevel.itemLevelFontSize or 12), E.db.sle.armory.stats.enable and statHeaders.fontOutline or 'NONE')
		local numStatInCat = 0

		for statIndex = 1, #PAPERDOLL_STATCATEGORIES[catIndex].stats do
			local stat = PAPERDOLL_STATCATEGORIES[catIndex].stats[statIndex]
			local showStat = true
			if E.db.sle.armory.stats.enable and stat.option and not E.db.sle.armory.stats.List[stat.stat] then showStat = false end
			if ( showStat and stat.primary ) then
				local primaryStat = select(6, GetSpecializationInfo(spec, nil, nil, nil, UnitSex('player')))
				if ( stat.primary ~= primaryStat ) and E.db.sle.armory.stats.OnlyPrimary then
					showStat = false
				end
			end
			if ( showStat and stat.roles ) then
				local foundRole = false
				for _, statRole in pairs(stat.roles) do
					if ( role == statRole ) then
						foundRole = true
						break
					end
				end
				if foundRole and stat.classes then
					for _, statClass in pairs(stat.classes) do
						if ( E.myclass == statClass ) then
							showStat = true
							break
						end
					end
				else
					showStat = foundRole
				end
			end
			if showStat and stat.power and stat.power ~= powerType then showStat = false end
			if ( showStat ) then
				statFrame.onEnterFunc = nil
				PAPERDOLL_STATINFO[stat.stat].updateFunc(statFrame, 'player')
				statFrame.Label:FontTemplate(E.LSM:Fetch('font', E.db.sle.armory.stats.enable and statLabels.font or statLabels.font), E.db.sle.armory.stats.enable and statLabels.fontSize or (E.db.general.itemLevel.itemLevelFontSize or 12), E.db.sle.armory.stats.enable and statLabels.fontOutline or 'NONE')
				statFrame.Value:FontTemplate(E.LSM:Fetch('font', E.db.sle.armory.stats.enable and statLabels.font or statLabels.font), E.db.sle.armory.stats.enable and statLabels.fontSize or (E.db.general.itemLevel.itemLevelFontSize or 12), E.db.sle.armory.stats.enable and statLabels.fontOutline or 'NONE')
				if ( not stat.hideAt or stat.hideAt ~= statFrame.numericValue ) then
					if ( numStatInCat == 0 ) then
						if ( lastAnchor ) then
							catFrame:SetPoint('TOP', lastAnchor, 'BOTTOM', 0, categoryYOffset)
						end
						lastAnchor = catFrame
						statFrame:SetPoint('TOP', catFrame, 'BOTTOM', 0, 6)
					else
						statFrame:SetPoint('TOP', lastAnchor, 'BOTTOM', 0, statYOffset)
					end
					if statFrame:IsShown() then
						SA.totalShown = SA.totalShown + 1
						numStatInCat = numStatInCat + 1
						-- statFrame.Background:SetShown((numStatInCat % 2) == 0)
						statFrame.Background:SetShown(false)
						if statFrame.leftGrad then statFrame.leftGrad:Hide() end
						if statFrame.rightGrad then statFrame.rightGrad:Hide() end
						lastAnchor = statFrame
					end
					-- done with this stat frame, get the next one
					statFrame = _G.CharacterStatsPane.statsFramePool:Acquire()
				end
			end
		end
		catFrame:SetShown(numStatInCat > 0)
	end
	-- release the current stat frame
	_G.CharacterStatsPane.statsFramePool:Release(statFrame)
	if SA.Scrollbar then
		if SA.totalShown > 14 then
			SA.Scrollbar:SetMinMaxValues(1, SA.totalShown*Armory.Constants.Stats.ScrollStepMultiplier)
			SA.Scrollbar:Show()
		else
			SA.Scrollbar:SetMinMaxValues(1, 1)
			SA.Scrollbar:Hide()
		end
		SA.Scrollbar:SetValue(SA.Scrollbar:GetValue())
	end
end

function SA:UpdateIlvlFont()
	local db = E.db.sle.armory.stats
	local font, size, outline
	font = db.enable and E.LSM:Fetch('font', db.itemLevel.font) or nil
	size = db.enable and (db.itemLevel.fontSize or 12) or 20
	outline = db.enable and db.itemLevel.fontOutline or nil
	local gradient = db.gradient

	_G.CharacterFrame.ItemLevelText:FontTemplate(font, size, outline)

	local ItemLevelFrame = _G.CharacterStatsPane.ItemLevelFrame
	ItemLevelFrame.Value:FontTemplate(font, size, outline)
	ItemLevelFrame:SetHeight(size)
	ItemLevelFrame.Background:SetHeight(size)

	if gradient.style == 'levelupbg' then
		if not ItemLevelFrame.bg then
			ItemLevelFrame:LevelUpBG()
		end
		ItemLevelFrame.bg:ClearAllPoints()
		ItemLevelFrame.bg:SetPoint('CENTER')
		ItemLevelFrame.bg:Point('TOPLEFT', ItemLevelFrame, 0, 3)
		ItemLevelFrame.bg:Point('BOTTOMRIGHT', ItemLevelFrame, 0, -2)
	elseif gradient.style == 'blizzard' then
		ItemLevelFrame.leftGrad:SetHeight(size)
		ItemLevelFrame.rightGrad:SetHeight(size)
	end

	if ItemLevelFrame.bg then
		ItemLevelFrame.lineTop:SetShown(gradient.style == 'levelupbg')
		ItemLevelFrame.lineBottom:SetShown(gradient.style == 'levelupbg')
		ItemLevelFrame.bg:SetShown(gradient.style == 'levelupbg')
	end
	ItemLevelFrame.leftGrad:SetShown(gradient.style == 'blizzard')
	ItemLevelFrame.rightGrad:SetShown(gradient.style == 'blizzard')

	if not E.db.general.itemLevel.displayCharacterInfo then
		_G.CharacterFrame.ItemLevelText:SetText('')
	end
end

function SA:ToggleArmory()
	local isEnabled = E.db.sle.armory.stats.enable
	PAPERDOLL_STATCATEGORIES = isEnabled and SA.AlteredPaperdollStats or SA.OriginalPaperdollStats
	_G.CharacterStatsPane.OffenseCategory:SetShown(isEnabled)
	_G.CharacterStatsPane.DefenseCategory:SetShown(isEnabled)
	_G.CharacterStatsPane.ItemLevelFrame:SetPoint('TOP', _G.CharacterStatsPane.ItemLevelCategory, 'BOTTOM', 0, isEnabled and 6 or 0)
	if isEnabled then
		_G.CharacterFrame.ItemLevelText:SetText('')
	else
		SA.Scrollbar:Hide()
	end

	PaperDollFrame_UpdateStats()
	M:UpdateCharacterItemLevel()
	if not E.db.general.itemLevel.displayCharacterInfo then
		_G.CharacterFrame.ItemLevelText:SetText('')
	end
end

local function GetLabelReplacement(original)
	local statLocale = E.db.sle.armory.stats.textReplacements[original]
	local isReplaced = (statLocale and (statLocale ~= '' and statLocale ~= _G[original])) and true or false

	local label = isReplaced and statLocale or _G[original]

	return label, isReplaced
end

--* Attributes
--! Uses PaperDollFrame_SetStat (check for Str, Agi, Int, Sta)
local function PaperDollFrame_SetStat(statFrame, unit, statIndex) --! Text Replaced Done
	if unit ~= 'player' then statFrame:Hide() return end
	local label, isReplaced = GetLabelReplacement('SPELL_STAT'..statIndex..'_NAME')
	if not isReplaced then return end

	local _, effectiveStat, _, negBuff = UnitStat(unit, statIndex)
	local effectiveStatDisplay = BreakUpLargeNumbers(effectiveStat)

	if ( negBuff < 0 and not GetPVPGearStatRules() ) then
		effectiveStatDisplay = RED_FONT_COLOR_CODE..effectiveStatDisplay..FONT_COLOR_CODE_CLOSE
	end

	PaperDollFrame_SetLabelAndText(statFrame, label, effectiveStatDisplay, false, effectiveStat)
end

local function PaperDollFrame_SetHealth(statFrame, unit) --! Text Replaced Done
	local label, isReplaced = GetLabelReplacement('HEALTH')
	if not isReplaced then return end

	if not unit then unit = 'player' end
	local health = UnitHealthMax(unit)
	local healthText = BreakUpLargeNumbers(health)

	PaperDollFrame_SetLabelAndText(statFrame, label, healthText, false, health)
end

local function PaperDollFrame_SetPower(statFrame, unit) --! Text Replaced Done (Maybe lol)
	if not unit then unit = 'player' end

	local _, powerToken = UnitPowerType(unit)
	local power = UnitPowerMax(unit) or 0
	local powerText = BreakUpLargeNumbers(power)
	if powerToken and _G[powerToken] then
		local label, isReplaced = GetLabelReplacement(powerToken)
		if not isReplaced then return end

		PaperDollFrame_SetLabelAndText(statFrame, label, powerText, false, power)
	end
end

local function PaperDollFrame_SetAlternateMana(statFrame, unit) --! Text Replaced Done
	if not unit then unit = player end
	local _, class = UnitClass(unit)
	if (class ~= 'DRUID' and (class ~= 'MONK' or GetSpecialization() ~= SPEC_MONK_MISTWEAVER)) then
		statFrame:Hide()
		return
	end
	local _, powerToken = UnitPowerType(unit)
	if powerToken == 'MANA' then
		statFrame:Hide()
		return
	end

	local label, isReplaced = GetLabelReplacement('MANA')
	if not isReplaced then return end

	local power = UnitPowerMax(unit, 0)
	local powerText = BreakUpLargeNumbers(power)

	PaperDollFrame_SetLabelAndText(statFrame, label, powerText, false, power)
end

local function MovementSpeed_OnUpdate(statFrame) --! Text Replaced Done
	local label, isReplaced = GetLabelReplacement('STAT_MOVEMENT_SPEED')
	if not isReplaced then return end

	local unit = statFrame.unit
	local _, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed(unit)
	runSpeed = runSpeed / BASE_MOVEMENT_SPEED * 100
	flightSpeed = flightSpeed / BASE_MOVEMENT_SPEED * 100
	swimSpeed = swimSpeed / BASE_MOVEMENT_SPEED * 100

	-- Pets seem to always actually use run speed
	if unit == 'pet' then
		swimSpeed = runSpeed
	end

	-- Determine whether to display running, flying, or swimming speed
	local speed = runSpeed
	local swimming = IsSwimming(unit)
	if swimming then
		speed = swimSpeed
	elseif IsFlying(unit) then
		speed = flightSpeed
	end

	-- Hack so that your speed doesn't appear to change when jumping out of the water
	if IsFalling(unit) and statFrame.wasSwimming then
		speed = swimSpeed
	end

	local valueText = format("%d%%", speed + 0.5)

	PaperDollFrame_SetLabelAndText(statFrame, label, valueText, false, speed)
end

--! Attack
--* Blizzard's local function for PaperDollFrame_SetDamage function
local function GetAppropriateDamage(unit)
	if IsRangedWeapon() then
		local _, minDamage, maxDamage, _, _, percent = UnitRangedDamage(unit)
		return minDamage, maxDamage, nil, nil, 0, 0, percent
	else
		return UnitDamage(unit)
	end
end
local function PaperDollFrame_SetDamage(statFrame, unit) --! Text Replaced Done
	local label, isReplaced = GetLabelReplacement('DAMAGE')
	if not isReplaced then return end

	-- local speed, offhandSpeed = UnitAttackSpeed(unit)
	local minDamage, maxDamage, _, _, physicalBonusPos, physicalBonusNeg, percent = GetAppropriateDamage(unit)

	-- remove decimal points for display values
	local displayMin = max(floor(minDamage),1)
	local displayMinLarge = BreakUpLargeNumbers(displayMin)
	local displayMax = max(ceil(maxDamage),1)
	local displayMaxLarge = BreakUpLargeNumbers(displayMax)

	-- calculate base damage
	minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg
	maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg

	local baseDamage = (minDamage + maxDamage) * 0.5
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent
	local totalBonus = (fullDamage - baseDamage)
	-- set tooltip text with base damage
	-- local damageTooltip = BreakUpLargeNumbers(max(floor(minDamage),1)).." - "..BreakUpLargeNumbers(max(ceil(maxDamage),1))

	local colorPos = '|cff20ff20'
	local colorNeg = '|cffff2020'

	-- epsilon check
	if ( totalBonus < 0.1 and totalBonus > -0.1 ) then
		totalBonus = 0.0
	end

	local value
	if ( totalBonus == 0 ) then
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then
			value = displayMinLarge.." - "..displayMaxLarge
		else
			value = displayMinLarge.."-"..displayMaxLarge
		end
	else
		-- set bonus color and display
		local color
		if ( totalBonus > 0 ) then
			color = colorPos
		else
			color = colorNeg
		end
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then
			value = color..displayMinLarge.." - "..displayMaxLarge.."|r"
		else
			value = color..displayMinLarge.."-"..displayMaxLarge.."|r"
		end
	end

	PaperDollFrame_SetLabelAndText(statFrame, label, value, false, displayMax)
end

local function PaperDollFrame_SetAttackPower(statFrame, unit) --! Text Replaced Done
	local label, isReplaced = GetLabelReplacement('STAT_ATTACK_POWER')
	if not isReplaced then return end

	local base, posBuff, negBuff, tag
	local rangedWeapon = IsRangedWeapon()

	if ( rangedWeapon ) then
		base, posBuff, negBuff = UnitRangedAttackPower(unit)
		tag = RANGED_ATTACK_POWER
	else
		base, posBuff, negBuff = UnitAttackPower(unit)
		tag = MELEE_ATTACK_POWER
	end

	local value, valueText
	if (GetOverrideAPBySpellPower() ~= nil) then
		local holySchool = 2
		-- Start at 2 to skip physical damage
		local spellPower = GetSpellBonusDamage(holySchool)
		for i=(holySchool+1), MAX_SPELL_SCHOOLS do
			spellPower = min(spellPower, GetSpellBonusDamage(i))
		end
		spellPower = min(spellPower, GetSpellBonusHealing()) * GetOverrideAPBySpellPower()

		value = spellPower
		valueText = PaperDollFormatStat(tag, spellPower, 0, 0)
	else
		value = base
		valueText = PaperDollFormatStat(tag, base, posBuff, negBuff)
	end

	PaperDollFrame_SetLabelAndText(statFrame, label, valueText, false, value)
end

local function PaperDollFrame_SetAttackSpeed(statFrame, unit) --! Text Replaced Done
	local label, isReplaced = GetLabelReplacement('WEAPON_SPEED')
	if not isReplaced then return end

	local speed, offhandSpeed = UnitAttackSpeed(unit)
	local displaySpeed = format("%.2F", speed)
	if ( offhandSpeed ) then
		offhandSpeed = format("%.2F", offhandSpeed)
	end
	if ( offhandSpeed ) then
		displaySpeed =  BreakUpLargeNumbers(displaySpeed).." / ".. offhandSpeed
	else
		displaySpeed =  BreakUpLargeNumbers(displaySpeed)
	end

	PaperDollFrame_SetLabelAndText(statFrame, label, displaySpeed, false, speed)
end

local function PaperDollFrame_SetSpellPower(statFrame, unit) --! Text Replaced Done
	local label, isReplaced = GetLabelReplacement('STAT_SPELLPOWER')
	if not isReplaced then return end

	local minModifier = 0
	if unit == 'player' then
		local holySchool = 2
		-- Start at 2 to skip physical damage
		minModifier = GetSpellBonusDamage(holySchool)

		if statFrame.bonusDamage then
			table.wipe(statFrame.bonusDamage)
		else
			statFrame.bonusDamage = {}
		end
		statFrame.bonusDamage[holySchool] = minModifier
		for i = (holySchool+1), MAX_SPELL_SCHOOLS do
			local bonusDamage = GetSpellBonusDamage(i)
			minModifier = min(minModifier, bonusDamage)
			statFrame.bonusDamage[i] = bonusDamage
		end
	elseif unit == 'pet' then
		minModifier = GetPetSpellBonusDamage()
		statFrame.bonusDamage = nil
	end

	PaperDollFrame_SetLabelAndText(statFrame, label, BreakUpLargeNumbers(minModifier), false, minModifier)
end

local function PaperDollFrame_SetManaRegen(statFrame, unit) --! Text Replaced Done
	if unit ~= 'player' then statFrame:Hide() return end

	local label, isReplaced = GetLabelReplacement('MANA_REGEN')
	if not isReplaced then return end

	if not UnitHasMana('player') then
		PaperDollFrame_SetLabelAndText(statFrame, label, NOT_APPLICABLE, false, 0)
		return
	end

	local _, combat = GetManaRegen()
	-- All mana regen stats are displayed as mana/5 sec.
	combat = floor(combat * 5.0)
	local combatText = BreakUpLargeNumbers(combat)
	-- Combat mana regen is most important to the player, so we display it as the main value
	PaperDollFrame_SetLabelAndText(statFrame, label, combatText, false, combat)
end

local function PaperDollFrame_SetEnergyRegen(statFrame, unit) --! Text Replaced Done
	--* Text Replacement Only
	if unit ~= 'player' then statFrame:Hide() return end

	local _, powerToken = UnitPowerType(unit)
	if powerToken ~= 'ENERGY' then statFrame:Hide() return end

	local label, isReplaced = GetLabelReplacement('STAT_ENERGY_REGEN')
	if not isReplaced then return end

	local regenRate = GetPowerRegen()
	local regenRateText = BreakUpLargeNumbers(regenRate)
	PaperDollFrame_SetLabelAndText(statFrame, label, regenRateText, false, regenRate)
end

local function PaperDollFrame_SetFocusRegen(statFrame, unit) --! Text Replaced Done
	if unit ~= 'player' then statFrame:Hide() return end

	local _, powerToken = UnitPowerType(unit)
	if powerToken ~= 'FOCUS' then statFrame:Hide() return end

	local label, isReplaced = GetLabelReplacement('STAT_FOCUS_REGEN')
	if not isReplaced then return end

	local regenRate = GetPowerRegen()
	local regenRateText = BreakUpLargeNumbers(regenRate)
	PaperDollFrame_SetLabelAndText(statFrame, label, regenRateText, false, regenRate)
end

local function PaperDollFrame_SetRuneRegen(statFrame, unit) --! Text Replaced Done
	--* Text Replacement Only
	if unit ~= 'player' then statFrame:Hide() return end

	local _, class = UnitClass(unit)
	if class ~= 'DEATHKNIGHT' then statFrame:Hide() return end

	local label, isReplaced = GetLabelReplacement('STAT_RUNE_REGEN')
	if not isReplaced then return end

	local _, regenRate = GetRuneCooldown(1) -- Assuming they are all the same for now
	local regenRateText = (format(STAT_RUNE_REGEN_FORMAT, regenRate))
	PaperDollFrame_SetLabelAndText(statFrame, label, regenRateText, false, regenRate)
end

--! Enhancements
local function PaperDollFrame_SetCritChance(statFrame, unit) --! Text Replaced Done (Decimal Option Here)
	if unit ~= 'player' then statFrame:Hide() return end

	local label = GetLabelReplacement('STAT_CRITICAL_STRIKE')
	local spellCrit, rangedCrit, meleeCrit, critChance

	-- Start at 2 to skip physical damage
	local holySchool = 2
	local minCrit = GetSpellCritChance(holySchool)
	statFrame.spellCrit = {}
	statFrame.spellCrit[holySchool] = minCrit

	for i=(holySchool+1), MAX_SPELL_SCHOOLS do
		spellCrit = GetSpellCritChance(i)
		minCrit = math_min(minCrit, spellCrit)
		statFrame.spellCrit[i] = spellCrit
	end

	spellCrit = minCrit
	rangedCrit = GetRangedCritChance()
	meleeCrit = GetCritChance()

	if (spellCrit >= rangedCrit and spellCrit >= meleeCrit) then
		critChance = spellCrit
	elseif (rangedCrit >= meleeCrit) then
		critChance = rangedCrit
	else
		critChance = meleeCrit
	end

	if E.db.sle.armory.stats.decimals then
		PaperDollFrame_SetLabelAndText(statFrame, label, format('%.2f%%', critChance), false, critChance)
	else
		PaperDollFrame_SetLabelAndText(statFrame, label, critChance, true, critChance)
	end
end

local function PaperDollFrame_SetHaste(statFrame, unit) --! Text Replaced Done (Decimal Option Here)
	if unit ~= 'player' then statFrame:Hide() return end

	local decimals = E.db.sle.armory.stats.decimals
	local label = GetLabelReplacement('STAT_HASTE')
	local haste = GetHaste()
	local hasteString = decimals and '%.2f%%' or '%d%%'
	local hasteValue = decimals and haste or (haste + 0.5)

	local hasteFormatString
	if (haste < 0) then
		hasteFormatString = RED_FONT_COLOR_CODE..'%s'..FONT_COLOR_CODE_CLOSE
	else
		hasteFormatString = '%s'
	end

	PaperDollFrame_SetLabelAndText(statFrame, label, format(hasteFormatString, format(hasteString, hasteValue)), false, haste)
end

local function PaperDollFrame_SetMastery(statFrame, unit) --! Text Replaced Done (Decimal Option Here)
	if unit ~= 'player' then statFrame:Hide() return end

	local decimals = E.db.sle.armory.stats.decimals
	local label = GetLabelReplacement('STAT_MASTERY')
	local mastery = GetMasteryEffect()

	PaperDollFrame_SetLabelAndText(statFrame, label, decimals and format('%.2f%%', mastery) or mastery, not decimals, mastery)
end

local function PaperDollFrame_SetVersatility(statFrame, unit) --! Text Replaced Done (Decimal Option Here)
	if unit ~= 'player' then statFrame:Hide() return end

	local decimals = E.db.sle.armory.stats.decimals
	local label = GetLabelReplacement('STAT_VERSATILITY')
	local versatilityDamageBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
	local versatilityDamageTakenReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN)

	PaperDollFrame_SetLabelAndText(statFrame, label, decimals and format('%.2f%%', versatilityDamageBonus)..'/'..format('%.2f%%', versatilityDamageTakenReduction) or versatilityDamageBonus, not decimals, versatilityDamageBonus)
end

local function PaperDollFrame_SetLifesteal(statFrame, unit) --! Text Replaced Done (Decimal Option Here)
	if unit ~= 'player' then statFrame:Hide() return end

	local label = GetLabelReplacement('STAT_LIFESTEAL')
	local lifesteal = GetLifesteal()

	if E.db.sle.armory.stats.decimals then
		PaperDollFrame_SetLabelAndText(statFrame, label, format('%.2f%%', lifesteal), false, lifesteal)
	else
		PaperDollFrame_SetLabelAndText(statFrame, label, lifesteal, true, lifesteal)
	end
end

local function PaperDollFrame_SetSpeed(statFrame, unit) --! Text Replaced Done
	if unit ~= 'player' then statFrame:Hide() return end

	local label, isReplaced = GetLabelReplacement('STAT_SPEED')
	if not isReplaced then return end

	local speed = GetSpeed()
	PaperDollFrame_SetLabelAndText(statFrame, label, speed, true, speed)
end

--! Defense
local function PaperDollFrame_SetArmor(statFrame, unit) --! Text Replaced Done
	local label, isReplaced = GetLabelReplacement('STAT_ARMOR')
	if not isReplaced then return end

	local _, effectiveArmor = UnitArmor(unit)
	PaperDollFrame_SetLabelAndText(statFrame, label, BreakUpLargeNumbers(effectiveArmor), false, effectiveArmor)
end

local function PaperDollFrame_SetAvoidance(statFrame, unit) --! Text Replaced Done (Decimal Option Here)
	if (unit ~= 'player') then statFrame:Hide() return end

	local label = GetLabelReplacement('STAT_AVOIDANCE')
	local avoidance = GetAvoidance()

	if E.db.sle.armory.stats.decimals then
		PaperDollFrame_SetLabelAndText(statFrame, label, format('%.2f%%', avoidance), false, avoidance)
	else
		PaperDollFrame_SetLabelAndText(statFrame, label, avoidance, true, avoidance)
	end
end

local function PaperDollFrame_SetDodge(statFrame, unit) --! Text Replaced Done (Decimal Option Here)
	if unit ~= 'player' then statFrame:Hide() return end

	local label = GetLabelReplacement('STAT_DODGE')
	local chance = GetDodgeChance()

	if E.db.sle.armory.stats.decimals then
		PaperDollFrame_SetLabelAndText(statFrame, label, format('%.2f%%', chance), false, chance)
	else
		PaperDollFrame_SetLabelAndText(statFrame, label, chance, true, chance)
	end
end

local function PaperDollFrame_SetParry(statFrame, unit) --! Text Replaced Done (Decimal Option Here)
	if unit ~= 'player' then statFrame:Hide() return end

	local label = GetLabelReplacement('STAT_PARRY')
	local chance = GetParryChance()

	if E.db.sle.armory.stats.decimals then
		PaperDollFrame_SetLabelAndText(statFrame, label, format('%.2f%%', chance), false, chance)
	else
		PaperDollFrame_SetLabelAndText(statFrame, label, chance, true, chance)
	end
end

local function PaperDollFrame_SetBlock(statFrame, unit) --! Text Replaced Done
	if unit ~= 'player' then statFrame:Hide() return end

	local label, isReplaced = GetLabelReplacement('STAT_BLOCK')
	if not isReplaced then return end

	local chance = GetBlockChance()

	PaperDollFrame_SetLabelAndText(statFrame, label, chance, true, chance)
end

local function PaperDollFrame_SetStagger(statFrame, unit) --! Text Replaced Done
	local label, isReplaced = GetLabelReplacement('STAT_STAGGER')
	if not isReplaced then return end

	local stagger = C_PaperDollInfo.GetStaggerPercentage(unit)
	PaperDollFrame_SetLabelAndText(statFrame, label, BreakUpLargeNumbers(stagger), true, stagger)
end

local blizzFuncs = {
	--* Attributes
	PaperDollFrame_SetStat = PaperDollFrame_SetStat,					-- Strength, Agility, Stamina, Intellect (SPELL_STAT'..statIndex..'_NAME)
	PaperDollFrame_SetHealth = PaperDollFrame_SetHealth,				-- Health (HEALTH)
	PaperDollFrame_SetPower = PaperDollFrame_SetPower,					-- Select PowerTokens (MANA, RAGE, FOCUS, ENERGY, FURY)
	PaperDollFrame_SetAlternateMana = PaperDollFrame_SetAlternateMana,	-- Handles MANA text. Only appears for Druids when in shapeshift form (per blizzard comments in PaperDollFrame.lua)
	MovementSpeed_OnUpdate = MovementSpeed_OnUpdate,					-- Movement Speed (STAT_MOVEMENT_SPEED)
	--* Attack
	PaperDollFrame_SetDamage = PaperDollFrame_SetDamage,				-- Damage (DAMAGE)
	PaperDollFrame_SetAttackPower = PaperDollFrame_SetAttackPower,		-- Attack Power (STAT_ATTACK_POWER)
	PaperDollFrame_SetAttackSpeed = PaperDollFrame_SetAttackSpeed,		-- Attack Speed (WEAPON_SPEED)
	PaperDollFrame_SetSpellPower = PaperDollFrame_SetSpellPower,		-- Spell Power (STAT_SPELLPOWER)
	PaperDollFrame_SetManaRegen = PaperDollFrame_SetManaRegen,			-- Mana Regen (MANA_REGEN)
	PaperDollFrame_SetEnergyRegen = PaperDollFrame_SetEnergyRegen,		-- Energy Regen (STAT_ENERGY_REGEN)
	PaperDollFrame_SetFocusRegen = PaperDollFrame_SetFocusRegen,		-- Focus Regen (STAT_FOCUS_REGEN)
	PaperDollFrame_SetRuneRegen = PaperDollFrame_SetRuneRegen,			-- Rune Speed (STAT_RUNE_REGEN)
	--* Enhancements
	PaperDollFrame_SetCritChance = PaperDollFrame_SetCritChance,		-- Critical Strike (STAT_CRITICAL_STRIKE)
	PaperDollFrame_SetHaste = PaperDollFrame_SetHaste,					-- Haste (STAT_HASTE)
	PaperDollFrame_SetMastery = PaperDollFrame_SetMastery,				-- Mastery (STAT_MASTERY)
	PaperDollFrame_SetVersatility = PaperDollFrame_SetVersatility,		-- Versatility (STAT_VERSATILITY)
	PaperDollFrame_SetLifesteal = PaperDollFrame_SetLifesteal,			-- Leech (STAT_LIFESTEAL)
	PaperDollFrame_SetSpeed = PaperDollFrame_SetSpeed,					-- Speed (STAT_SPEED)
	--* Defense
	PaperDollFrame_SetArmor = PaperDollFrame_SetArmor,					-- Armor (STAT_ARMOR)
	PaperDollFrame_SetAvoidance = PaperDollFrame_SetAvoidance,			-- Avoidance (STAT_AVOIDANCE)
	PaperDollFrame_SetDodge = PaperDollFrame_SetDodge,					-- Dodge (STAT_DODGE)
	PaperDollFrame_SetParry = PaperDollFrame_SetParry,					-- Parry (STAT_PARRY)
	PaperDollFrame_SetBlock = PaperDollFrame_SetBlock,					-- Block (STAT_BLOCK)
	PaperDollFrame_SetStagger = PaperDollFrame_SetStagger,				-- Stagger (STAT_STAGGER)
}

function SA:ToggleFunctionHooks()
	for k, v in pairs(blizzFuncs) do
		if E.db.sle.armory.stats.enable and not SA:IsHooked(k) then
			SA:SecureHook(k, v)
		elseif SA:IsHooked(k) then
			SA:Unhook(k)
		end
	end
end

function SA:LoadAndSetup()
	if SLE._Compatibility['DejaCharacterStats'] then return end

	SA:ToggleFunctionHooks()
	hooksecurefunc('PaperDollFrame_UpdateStats', SA.PaperDollFrame_UpdateStats)
	hooksecurefunc(M, 'UpdateCharacterItemLevel', SA.UpdateCharacterItemLevel)
	hooksecurefunc(M, 'ToggleItemLevelInfo', SA.UpdateCharacterItemLevel)
	hooksecurefunc(M, 'UpdateAverageString', SA.UpdateCharacterItemLevel)

	SA:BuildScrollBar()
	SA:BuildNewStats()
	SA:ToggleArmory()

	_G.CharacterFrame:HookScript('OnShow', SA.UpdateCharacterItemLevel)

	_G.CharacterFrame.ItemLevelText:SetText('')
end
