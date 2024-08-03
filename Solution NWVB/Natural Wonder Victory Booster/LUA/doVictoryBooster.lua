-- doVictoryBooster
-- Author: yepzer
-- Original PlotMath and Timers by connan.morris
-- DateCreated: 7/29/2024 10:19:46 AM
--------------------------------------------------------------

local cFOP = GameInfoTypes.FEATURE_NWVB_FOP
local cGEE = GameInfoTypes.FEATURE_NWVB_GEE
local cTURNS_TO_BOOST = 10 * Game.CountCivPlayersAlive()
local cMAX_CITY_DISTANCE = 5
local cBOOSTER = 25

print("Loaded OK: "..cTURNS_TO_BOOST.." turns to boost "..cBOOSTER.." times")


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
--				print("!!!!owner is nil!!!")
				return
			end
		else
			iOwner = iOriginalOwner
		end
		
		-- Dont retake land if plot is close enough to a city owned by the owner
		for pCity in Players[iOwner]:Cities() do
			local pCityPlot = pCity:Plot()
			if(Map.PlotDistance(pCityPlot:GetX(), pCityPlot:GetY(), pPlot:GetX(), pPlot:GetY()) < cMAX_CITY_DISTANCE) then
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
end

--------------------------------------------------------------
function giveVictoryBoost(iPlayer,iFeatureType)
	-- initiate
	local sResult = ""
	local pPlayer = Players[iPlayer]

	local r = 1+Game.Rand(cBOOSTER, "NWVB: gold factor")
	local more = r*1000
	local eGold = pPlayer:GetGold()
	pPlayer:SetGold(eGold+more)

	-- execute
	if (iFeatureType == cGEE) then
		sResult = cBOOSTER.." more Golden Ages and "
		pPlayer:ChangeGoldenAgeTurns(cBOOSTER)
	end
	if (iFeatureType == cFOP) then
		sResult = cBOOSTER.." Free Policies and "
		pPlayer:ChangeNumFreePolicies(cBOOSTER)
		--pPlayer:SetPolicyBranchUnlocked(GameInfo.PolicyBranchTypes["POLICY_BRANCH_AUTOCRACY"].ID, true)
	end
	
	-- return
	return sResult..more.." Gold"
end

--------------------------------------------------------------
function IsTimerActive(iFeatureType) 
	-- initiate
	local sKey = ""
	if (iFeatureType == cFOP) then sKey="NWVB_FOP" end
	if (iFeatureType == cGEE) then sKey="NWVB_GEE" end
	if (sKey == "") then return false end
	local sFullkey = sKey.."_timer"

	-- execute
	local db = Modding.OpenSaveData()
	local iTimer = db.GetValue(sFullkey)
	if (iTimer == nil) then return false end
	
	return true
end

--------------------------------------------------------------
function setPlotOwnershipTimer(iFT,iX,iY,iPlayer,iTurns)
	-- initiate
	local db = Modding.OpenSaveData()
	local sKey = ""
	if (iFT == cFOP) then sKey="NWVB_FOP" end
	if (iFT == cGEE) then sKey="NWVB_GEE" end
	if (sKey == "") then return end
	local sFullkey = sKey.."_timer"

	local sPlayer = ""
	if (iPlayer == nil) then sPlayer = "nil" end
	if (iPlayer == -1) then sPlayer = "-1" end
	if ((iPlayer ~= nil) and (iPlayer ~= -1)) then
		local pPlayer = Players[iPlayer]
		sPlayer = Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescriptionKey())
	end
		
	local sTurns = ""
	if (iTurns == nil) then sTurns="nil" end
	if (iTurns ~=nil) then sTurns=iTurns end
	
	print ("setPlotOwnershipTimer: "..sPlayer..": "..sTurns)

	-- execute
	db.SetValue(sFullkey, iTurns)
	db.SetValue(sKey.."_owner", iPlayer)
	db.SetValue(sKey.."_x",iX)
	db.SetValue(sKey.."_y",iY)
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
	if ((iFeatureType ~= cFOP) and (iFeatureType ~= cGEE)) then return end
	local bIsTimerOn = IsTimerActive(iFeatureType) 
	
	if (bIsTimerOn) then return end
	-- print("doUnitPositionChanged: Plot OK, Unit OK, Feature OK, Timer not Active")

	-- Execute
	local centerPlot = {}
	centerPlot.xPosition = iX
	centerPlot.yPosition = iY
	local iPlotOwner = pPlot:GetOwner()
		
	claimTerritoryAroundHex(centerPlot, iPlayer, iPlotOwner)
	setPlotOwnershipTimer(iFeatureType,iX,iY,iPlayer,cTURNS_TO_BOOST)
	
	-- Notify	
	local sFeature = GameInfo.Features[iFeatureType].Description
	local sText = "Hold "..sFeature.." for "..cTURNS_TO_BOOST.." turns"
	pPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, sText, sText, iX, iY)	
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
			claimTerritoryAroundHex(centerPlot, -1, nil)
			setPlotOwnershipTimer(iFeatureType,nil,nil,nil,nil)
			sResult = "Wonder Lost"
		else
			-- there is a unit holding the spot			
			if (iTimer == 0 ) then 
				-- time is up, reset spot, restart timer 
				claimTerritoryAroundHex(centerPlot, -1, nil)
				setPlotOwnershipTimer(iFeatureType,iX,iY,-1,cTURNS_TO_BOOST)
				sResult = giveVictoryBoost(iPlayer,iFeatureType)
			end
	
			if (iTimer > 0) then
				-- time is not yet up, count down the timer
				setPlotOwnershipTimer(iFeatureType,iX,iY,iPlayer,iTimer-1)
				-- sResult = "Counting down to Boost "..iTimer-1
			end
		end
	end

	if ((iPlayer == 0) and (iOwner == -1)) then
		-- If Owner is -1 then count down timer to reset it again
		-- but only once (for player 0), not any others
		if (iTimer == 0 ) then
			setPlotOwnershipTimer(iFeatureType,nil,nil,nil,nil)
			sResult = "A Wonder is released for recapture"
		end
		if (iTimer > 0 ) then
			setPlotOwnershipTimer(iFeatureType,iX,iY,-1,iTimer-1)
			-- sResult = "Counting down for reset "..iTimer-1
		end
	end 
		
	-- Notify
	if (sResult ~= "") then
		local pPlayer = Players[iPlayer]
		pPlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, sResult, sResult, iX, iY)	
	end
end

--------------------------------------------------------------

local function OnPlayerDoTurn(iPlayer)
	if (iPlayer == 63) then return end
	updateTimer("NWVB_FOP",iPlayer)
	updateTimer("NWVB_GEE",iPlayer)
end

--------------------------------------------------------------
--------------------------------------------------------------
GameEvents.UnitSetXY.Add( doUnitPositionChanged )
GameEvents.PlayerDoTurn.Add(OnPlayerDoTurn)


