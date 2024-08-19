-- doTimedBoost
-- Author: yepzer
-- Original PlotMath and Timers by connan.morris
-- DateCreated: 7/29/2024 10:19:46 AM
--------------------------------------------------------------

local cFOC = GameInfoTypes.FEATURE_FOUNTAIN_YOUTH
local cGEE = GameInfoTypes.FEATURE_EL_DORADO
local cGKS = GameInfoTypes.FEATURE_SOLOMONS_MINES
local iHandicap = Game:GetHandicapType()
local iNumPlayers = Game.CountCivPlayersAlive()

local cBOOST_FOC = iNumPlayers * 10
local cBOOST_GEE = iNumPlayers * 10
local cBOOST_GKS = iNumPlayers * iHandicap * 1000
local cTURNS_TO_BOOST = iNumPlayers * iHandicap
local cMAX_CITY_DISTANCE = 5

print("Loaded OK: "..cTURNS_TO_BOOST.." turns for "..cBOOST_FOC.." culture")
print("Loaded OK: "..cTURNS_TO_BOOST.." turns for "..cBOOST_GEE.." golden eras")
print("Loaded OK: "..cTURNS_TO_BOOST.." turns for "..cBOOST_GKS.." gold")

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
-- connan.morris: claimTerritoryAroundHex
function claimTerritoryAroundHex(centerPlot, iPlayer)
	setPlotOwner(centerPlot, iPlayer)
	setPlotOwner(PlotMath.getHexEast(centerPlot), iPlayer)
	setPlotOwner(PlotMath.getHexWest(centerPlot), iPlayer)
	setPlotOwner(PlotMath.getHexNorthWest(centerPlot), iPlayer)
	setPlotOwner(PlotMath.getHexNorthEast(centerPlot), iPlayer)
	setPlotOwner(PlotMath.getHexSouthWest(centerPlot), iPlayer)
	setPlotOwner(PlotMath.getHexSouthEast(centerPlot), iPlayer)
end

--------------------------------------------------------------
function setPlotOwner(mapPlot, iNewPlotOwner)
	-- initialize
	if (iNewPlotOwner == nil) then return end

	local pPlot = Map.GetPlot(mapPlot.xPosition, mapPlot.yPosition)
	if (pPlot == nil) then return end
	if (pPlot:IsCity()) then return end
	local iExistingPlotOwner = pPlot:GetOwner()
	if (iExistingPlotOwner == nil) then return end

	local iSetCityTo = -1
	local iSetOwnerTo = iExistingPlotOwner -- default is to keep the current owner
	local iX = pPlot:GetX()
	local iY = pPlot:GetY()
	
	-- print("NewOwner OK, Plot OK, Existing Owner OK: "..iNewPlotOwner..","..iX..","..iY..","..iExistingPlotOwner)
	 
	-- execute
	if (iNewPlotOwner == -1) then
		-- reset to nature unless there is a city close by
		local bFoundCity = false

		if (iExistingPlotOwner ~= -1) then
			-- if there is an existing owner
			for pCity in Players[iExistingPlotOwner]:Cities() do
				-- iterate all cities
				local pCityPlot = pCity:Plot()
				if(Map.PlotDistance(pCityPlot:GetX(), pCityPlot:GetY(), iX, iY) < cMAX_CITY_DISTANCE) then
					-- if the city is close, save the city ID and set bFoundCity true and stop 
					iSetCityTo = pCity
					iSetOwnerTo = pCity:GetOwner()
					bFoundCity = true
				end
			end
		end

		-- if no cities are found close enough, reset to nature
		if (not bFoundCity) then
			iSetOwnerTo = -1
			iSetCityTo = -1
		end
	else
		if (iExistingPlotOwner == -1) then
			-- if the existing owner is nature/-1 then give it away
				iSetOwnerTo = iNewPlotOwner
				iSetCityTo = pPlot:GetPlotCity()
		else
			-- iNewPlotOwner can have the field from another actual player 
			if (iNewPlotOwner ~= iExistingPlotOwner) then
				local pNewTeam = Teams[iNewPlotOwner]
				local iExistingTeam = Players[iExistingPlotOwner]:GetTeam()
				if (pNewTeam:IsAtWar(iExistingTeam) == true) then
					-- only if at war
					iSetOwnerTo = iNewPlotOwner
					iSetCityTo = pPlot:GetPlotCity()
				end
			end
		end
	end
	
	-- return
	pPlot:SetOwner(iSetOwnerTo,iSetCityTo,true,true)
end

--------------------------------------------------------------
function giveTimedBoost(iPlayer,iFeatureType)
	-- initiate
	local sResult = ""
	local pPlayer = Players[iPlayer]
	
	-- execute
	if (iFeatureType == cGKS) then
		sResult = cBOOST_GKS.." gold."
		local iGold = pPlayer:GetGold()
		pPlayer:SetGold(iGold+cBOOST_GKS)
	end
	if (iFeatureType == cGEE) then
		sResult = cBOOST_GEE.." more Golden Eras."
		local iEras = pPlayer:GetGoldenAgeLength()
		pPlayer:ChangeGoldenAgeTurns(iEras+cBOOST_GEE)
	end
	if (iFeatureType == cFOC) then
		sResult = cBOOST_FOC.." free culture."
		local iCulture = pPlayer:GetJONSCulture()
		pPlayer:ChangeJONSCulture(cBOOST_FOC ) 
	end
	
	-- return
	return sResult
end

--------------------------------------------------------------
function getTimerActive(iFeatureType) 
	-- initiate
	local sKey = ""
	if (iFeatureType == cFOC) then sKey="NWTB_FOC" end
	if (iFeatureType == cGEE) then sKey="NWTB_GEE" end
	if (iFeatureType == cGKS) then sKey="NWTB_GKS" end
	if (sKey == "") then return nil end
	local sFullkey = sKey.."_timer"

	-- execute
	local db = Modding.OpenSaveData()
	local iTimer = db.GetValue(sFullkey)

	-- return
	return iTimer
end

--------------------------------------------------------------
function setTimer(iFeatureType,iX,iY,iPlayer,iTurns)
	-- initiate
	local db = Modding.OpenSaveData()
	local sKey = ""
	if (iFeatureType == cFOC) then sKey="NWTB_FOC" end
	if (iFeatureType == cGEE) then sKey="NWTB_GEE" end
	if (iFeatureType == cGKS) then sKey="NWTB_GKS" end
	if (sKey == "") then return end
	local sFullkey = sKey.."_timer"

	-- execute
	db.SetValue(sFullkey, iTurns)
	db.SetValue(sKey.."_owner", iPlayer)
	db.SetValue(sKey.."_x",iX)
	db.SetValue(sKey.."_y",iY)

	-- Notify
	local sPlayer = ""
	if (iPlayer == nil) then sPlayer = "Nature" end
	if (iPlayer == -1) then sPlayer = "Resetting" end
	if ((iPlayer ~= nil) and (iPlayer ~= -1)) then
		local pPlayer = Players[iPlayer]
		sPlayer = Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescriptionKey())
	end
		
	local sTurns = ""
	if (iTurns == nil) then sTurns="nil" end
	if (iTurns ~=nil) then sTurns=iTurns end

	local sFeatureType = GameInfo.Features[iFeatureType].Description
	print ("setTimer: "..sPlayer.." : "..sFeatureType.." for "..sTurns)
end

--------------------------------------------------------------
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
	if ((iFeatureType ~= cFOC) and (iFeatureType ~= cGEE) and (iFeatureType ~= cGKS)) then return end
	local iTimer = getTimerActive(iFeatureType) 
	
	-- print("doUnitPositionChanged: Plot OK, Unit OK, Feature OK")
	local sResult = ""
	local sFeature = GameInfo.Features[iFeatureType].Description

	-- Execute
	if (iTimer ~= nil) then 
		-- there is an existing timer
		sResult = "Timer is on for "..sFeature.. ": "..iTimer
	else
		-- there is no existing timer
		local centerPlot = {}
		centerPlot.xPosition = iX
		centerPlot.yPosition = iY
		claimTerritoryAroundHex(centerPlot, iPlayer)
		setTimer(iFeatureType,iX,iY,iPlayer,cTURNS_TO_BOOST)
		sResult = "Hold "..sFeature.." for "..cTURNS_TO_BOOST.." turns"
	end
		
	-- Notify	
	if (sResult ~= "") then
		-- notify only if sResult has text
		local iNotifyType = NotificationTypes["NOTIFICATION_GOLDEN_AGE_BEGUN_ACTIVE_PLAYER"]
		pPlayer:AddNotification(iNotifyType, sResult, sResult, iX, iY)	
	end
end

--------------------------------------------------------------
function updateTimer(sKey,iPlayer)
	-- initialize
	local sFullkey = sKey.."_timer"
	local db = Modding.OpenSaveData()
	local iTimer = db.GetValue(sFullkey)
	if (iTimer == nil) then return end

	local iOwner = db.GetValue(sKey.."_owner")
	if (iOwner == nil) then return end

	local iX = db.GetValue(sKey.."_x")
	local iY = db.GetValue(sKey.."_y")
	if ((iX == nil) or (iY == nil)) then return end

	local pPlot = Map.GetPlot(iX,iY)
	if (pPlot == nil) then return end
	local iFeatureType = pPlot:GetFeatureType()	
		
	-- print("updateTimer: Timer OK, Owner OK, Position OK, Player: "..iTimer..","..iOwner..","..iX..","..iY..","..iPlayer)

	-- Execute
	local sResult = ""
	local pUnit = pPlot:GetUnit()
	local centerPlot = {}
	centerPlot.xPosition = iX
	centerPlot.yPosition = iY

	if (iOwner == iPlayer) then 
		-- if current player own the wonder
		if (pUnit == nil) then 
			-- if no unit on the plot releases the spot totally
			claimTerritoryAroundHex(centerPlot, -1)
			setTimer(iFeatureType,nil,nil,nil,nil)
			sResult = "Wonder Lost"
		else
			-- there is a unit holding the spot			
			if (iTimer == 0 ) then 
				-- time is up, reset spot, restart timer 
				claimTerritoryAroundHex(centerPlot, -1)
				setTimer(iFeatureType,iX,iY,-1,cTURNS_TO_BOOST)
				sResult = giveTimedBoost(iPlayer,iFeatureType)
			end
	
			if (iTimer > 0) then
				-- time is not yet up, count down the timer
				setTimer(iFeatureType,iX,iY,iPlayer,iTimer-1)
				-- sResult = "Counting down to Boost "..iTimer-1
			end
		end
	end

	if ((iPlayer == 0) and (iOwner == -1)) then
		-- If Owner is -1 then count down timer to reset it again
		-- but only once (for player 0), not any others
		if (iTimer == 0 ) then
			setTimer(iFeatureType,nil,nil,nil,nil)
			sResult = "A Wonder is released for recapture"
		end
		if (iTimer > 0 ) then
			setTimer(iFeatureType,iX,iY,-1,iTimer-1)
			-- sResult = "Counting down for reset "..iTimer-1
		end
	end 
		
	-- Notify
	if (sResult ~= "") then
		-- notify only if sResult has text
		local pPlayer = Players[iPlayer]
		local iNotifyType = NotificationTypes["NOTIFICATION_GOLDEN_AGE_ENDED_ACTIVE_PLAYER"]
		pPlayer:AddNotification(iNotifyType, sResult, sResult, iX, iY)	
	end
end

--------------------------------------------------------------
local function OnPlayerDoTurn(iPlayer)
	if (iPlayer == 63) then return end --skip for barbarians turn
	updateTimer("NWTB_FOC",iPlayer)
	updateTimer("NWTB_GEE",iPlayer)
	updateTimer("NWTB_GKS",iPlayer)
end

--------------------------------------------------------------
--------------------------------------------------------------
GameEvents.UnitSetXY.Add( doUnitPositionChanged )
GameEvents.PlayerDoTurn.Add(OnPlayerDoTurn)


