-- doVictoryBooster
-- Author: yepzer
-- Original PlotMath and Timers by connan.morris
-- DateCreated: 7/29/2024 10:19:46 AM
--------------------------------------------------------------

local iTURNS = 10 
local MAX_CITY_DISTANCE = 5
local iFOC = GameInfoTypes.FEATURE_NWVB_FOC
local iGED = GameInfoTypes.FEATURE_NWVB_GED
print("Loaded OK: "..iTURNS..","..iFOC..","..iGED)


--------------------------------------------------------------
-- connan.morris: Methods for finding plots in any direction from a given plot
PlotMath = {};

	function PlotMath.isEvenRow(yPosition)
		if yPosition == 0 or math.fmod(yPosition,2) == 0 then
			return true
		end
		return false
	end

	function PlotMath.getHexNorthWest(position)
		local newPosition = {}
		newPosition.xPosition = position.xPosition
		newPosition.yPosition = position.yPosition + 1

		if PlotMath.isEvenRow(position.yPosition) == true then
			newPosition.xPosition = newPosition.xPosition - 1
		end
		return newPosition
	end

	function PlotMath.getHexNorthEast(position)
		local newPosition = {}
		newPosition.xPosition = position.xPosition
		newPosition.yPosition = position.yPosition + 1

		if PlotMath.isEvenRow(position.yPosition) == false then
			newPosition.xPosition = newPosition.xPosition + 1
		end
		return newPosition
	end

	function PlotMath.getHexSouthWest(position)
		local newPosition = {}
		newPosition.xPosition = position.xPosition 
		newPosition.yPosition = position.yPosition - 1

		if PlotMath.isEvenRow(position.yPosition) == true then
			newPosition.xPosition = newPosition.xPosition - 1
		end
		return newPosition
	end

	function PlotMath.getHexSouthEast(position)
		local newPosition = {}
		newPosition.xPosition = position.xPosition
		newPosition.yPosition = position.yPosition - 1

		if PlotMath.isEvenRow(position.yPosition) == false then
			newPosition.xPosition = newPosition.xPosition + 1
		end
		return newPosition
	end

	function PlotMath.getHexEast(position)
		local newPosition = {}
		newPosition.xPosition = position.xPosition + 1
		newPosition.yPosition = position.yPosition
		return newPosition
	end

	function PlotMath.getHexWest(position)
		local newPosition = {}
		newPosition.xPosition = position.xPosition - 1
		newPosition.yPosition = position.yPosition
		return newPosition
	end

--------------------------------------------------------------
-- connan.morris: Set the owner of a plot
function setPlotOwner(mapPlot, iPlayer, iCity, iOriginalOwner)

	local pPlot = Map.GetPlot(mapPlot.xPosition, mapPlot.yPosition)
	local iOwner = nil

	if(iPlayer == nil) then
		-- print("Nil iPlayer")
		return
	end
	--print("iPlayer: " .. iPlayer)
	
	local pPlayer = Players[iPlayer]

	if(pPlot == nil) then
		-- print("Nil Plot")
		return
	end

	-- Give land back to nature
	if(iPlayer == -1) then
		local iClosestCity = nil

		-- Check for original owner
		if(iOriginalOwner == nil or iOriginalOwner == -1) then
			iOwner = pPlot:GetOwner()
			if(iOwner == nil or iOwner == -1) then
				print("!!!!owner is nil!!!")
				return
			end
		else
			iOwner = iOriginalOwner
		end
		
		-- Dont retake land if plot is close enough to a city owned by the owner
		for pCity in Players[iOwner]:Cities() do
			local pCityPlot = pCity:Plot()
			if(Map.PlotDistance(pCityPlot:GetX(), pCityPlot:GetY(), pPlot:GetX(), pPlot:GetY()) < MAX_CITY_DISTANCE) then
				return
			end
		end

		-- Dont retake land if plot is owned by someone other than the owner
		if(pPlot:GetOwner() ~= iOwner) then
			-- print("Don't retake land owned by someone else")
			return
		end

		-- print ("Nature retakes land at: " .. pPlot:GetX() .. ", " .. pPlot:GetY())
	else
		local iPlotOwner = pPlot:GetOwner()
		if(iPlotOwner ~= nil and iPlotOwner ~= -1) then
			local iPlotPlayerTeam = Players[iPlotOwner]:GetTeam()
			local pPlayerTeam = Teams[iPlayer]
			-- Don't take plots from players you are not at war with
			if(pPlayerTeam:IsAtWar(iPlotPlayerTeam) == false) then
				-- print("Don't take plot from friend")
				return
			end
		end

		--print ( Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescriptionKey()) .. " Taking land at: " .. pPlot:GetX() .. ", " .. pPlot:GetY())
	end
	pPlot:SetOwner(iPlayer, 8192)
end

--------------------------------------------------------------
-- connan.morris: claimTerritoryAroundHex
function claimTerritoryAroundHex(centerPlot, iPlayer, iOwner)
	setPlotOwner(centerPlot, iPlayer, 8192, iOwner)
	setPlotOwner(PlotMath.getHexEast(centerPlot), iPlayer, 8192, iOwner)
	setPlotOwner(PlotMath.getHexWest(centerPlot), iPlayer, 8192, iOwner)
	setPlotOwner(PlotMath.getHexNorthWest(centerPlot), iPlayer, 8192, iOwner)
	setPlotOwner(PlotMath.getHexNorthEast(centerPlot), iPlayer, 8192, iOwner)
	setPlotOwner(PlotMath.getHexSouthWest(centerPlot), iPlayer, 8192, iOwner)
	setPlotOwner(PlotMath.getHexSouthEast(centerPlot), iPlayer, 8192, iOwner)
	
	local pPlayer = Players[iPlayer]
	sPlayer = Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescriptionKey())
	local x = centerPlot.xPosition
	local y =  centerPlot.yPosition
	print (sPlayer.." Taking land at: "..x.. ", "..y)
end

--------------------------------------------------------------
function setPlotOwnershipTimer(iFT,iPlayer)
	local db = Modding.OpenSaveData()
	local timerkey = ""
	local ownerkey = ""
	if (iFT == iFOC) then timerkey="NWVB_FOC-timer" end
	if (iFT == iFOC) then ownerkey="NWVB_FOC-owner" end
	if (iFT == iGED) then timerkey="NWVB_GED-timer" end
	if (iFT == iGED) then ownerkey="NWVB_GED-owner" end

	if (timerkey == "") then return end
	if (ownerkey == "") then return end
	local pPlayer = Players[iPlayer]
	sPlayer = Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescriptionKey())
	print ("setPlotOwnershipTimer: "..sPlayer..","..ownerkey..","..timerkey)
	db.SetValue(timerkey, iTURNS)
	db.SetValue(ownerkey, iPlayer)
end

--------------------------------------------------------------
function doTurn(iPlayer)
	if(iPlayer ~= 0) then return end

end


function doUnitPositionChanged(iPlayer,iUnit,iX,iY)
	-- Initialize --
	local pPlot = Map.GetPlot(iX,iY)
	if not pPlot then return end
	if (pPlot:IsCity()) then return end

	local pPlayer = Players[iPlayer]
	local pUnit = pPlayer:GetUnitByID(iUnit)
	if ( pUnit == nil ) then return end
	if ( pPlayer == nil ) then return end
		
	local iFeatureType = pPlot:GetFeatureType()	
	if ((iFeatureType ~= iFOC) and (iFeatureType ~= iGED)) then return end
	print("Unit OK, Plot OK, Feature OK: "..iFeatureType)

	-- Set Owner and Timer
	local centerPlot = {}
	centerPlot.xPosition = iX
	centerPlot.yPosition = iY
	local iPlotOwner = pPlot:GetOwner()
	claimTerritoryAroundHex(centerPlot, iPlayer, iPlotOwner)
	setPlotOwnershipTimer(iFeatureType,iPlayer)

	-- notify
	local popup = GameInfo.Features[iFeatureType].Description
	local text = "Hold "..popup.."for "..iTURNS.." turns"
	pPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, text, popup, iX, iY)	
end

--------------------------------------------------------------
GameEvents.PlayerDoTurn.Add( doTurn )
GameEvents.UnitSetXY.Add( doUnitPositionChanged )
