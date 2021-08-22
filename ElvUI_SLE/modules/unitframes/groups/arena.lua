local SLE, T, E, L, V, P, G = unpack(select(2, ...))
local SUF = SLE.UnitFrames
local UF = E.UnitFrames

--GLOBALS: hooksecurefunc
local _G = _G

function SUF:ArrangeArena()
	local enableState = E.private.sle.module.shadows.enable and E.db.unitframe.units.arena.enable

	for i = 1, 5 do
		local frame = _G["ElvUF_Arena"..i]
		if not frame then return end
		local db = E.db.sle.shadows.unitframes.arena

		frame.SLLEGACY_ENHSHADOW = enableState and db.legacy or false
		frame.SLHEALTH_ENHSHADOW = enableState and db.health or false
		frame.SLPOWER_ENHSHADOW = enableState and db.power or false

		-- Health
		SUF:Configure_Health(frame)

		-- Power
		SUF:Configure_Power(frame)
	end
end
