; #FUNCTION# ====================================================================================================================
; Name ..........: getArmySiegeMachines
; Description ...: Obtain the current trained Siege Machines
; Syntax ........: getArmySiegeMachines()
; Parameters ....:
; Return values .:
; Author ........: Fliegerfaust(06-2018)
; Modified ......: Moebius14 (03-2025)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2025
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func getArmySiegeMachines($bOpenArmyWindow = False, $bCloseArmyWindow = False, $bCheckWindow = False, $bSetLog = True, $bNeedCapture = True)

	If $g_bDebugSetLogTrain Then SetLog("getArmySiegeMachines():", $COLOR_DEBUG)

	If Not $bOpenArmyWindow Then
		If $bCheckWindow And Not IsTrainPage() Then ; check for train page
			SetError(1)
			Return ; not open, not requested to be open - error.
		EndIf
	ElseIf $bOpenArmyWindow Then
		If Not OpenArmyOverview(True, "getArmySiegeMachines()") Then
			SetError(2)
			Return ; not open, requested to be open - error.
		EndIf
		If _Sleep($DELAYCHECKARMYCAMP5) Then Return
	EndIf

	WaitForClanMessage("ArmyOverview")

	Local $sSiegeDiamond = GetDiamondFromRect2(660, 342 + $g_iMidOffsetY, 782, 400 + $g_iMidOffsetY) ; Contains iXStart, $iYStart, $iXEnd, $iYEnd
	Local $bSiegeExtended = False

	If _ColorCheck(_GetPixelColor(795, 370 + $g_iMidOffsetY, True), Hex(0x6AB5ED, 6), 20) Then
		If Not IsTrainPageGrayed(False, 3) Then OpenSiegeMachinesTab()
		$bSiegeExtended = True
	EndIf

	If $g_bDebugFuncTime Then StopWatchStart("findMultiple, \imgxml\ArmyOverview\SiegeMachines")
	Local $aCurrentSiegeMachines = findMultiple(@ScriptDir & "\imgxml\ArmyOverview\SiegeMachines", $sSiegeDiamond, $sSiegeDiamond, 0, 1000, 0, "objectname,objectpoints", $bNeedCapture) ; Returns $aCurrentSiegeMachines[index] = $aArray[2] = ["Siege M Shortname", CordX,CordY]
	If $g_bDebugFuncTime Then StopWatchStopLog()

	Local $aTempSiegeArray, $aSiegeCoords
	Local $sSiegeName = ""
	Local $iSiegeIndex = -1
	Local $aCurrentTroopsEmpty[$eSiegeMachineCount] = [0, 0, 0, 0, 0, 0, 0, 0] ; Local Copy to reset Siege Machine Array

	; Get Siege Capacities
	Local $sSiegeInfo = getSiegeCampCap(673, 321 + $g_iMidOffsetY, $bNeedCapture) ; OCR read Siege built and total
	If $g_bDebugSetLogTrain Then SetLog("OCR $sSiegeInfo = " & $sSiegeInfo, $COLOR_DEBUG)
	Local $aGetSiegeCap = StringSplit($sSiegeInfo, "#", $STR_NOCOUNT) ; split the built Siege number from the total Siege number
	If UBound($aGetSiegeCap) = 2 Then
		If $aGetSiegeCap[1] >= 10 Then $aGetSiegeCap[1] = StringTrimRight($aGetSiegeCap[1], 1)
		If $bSetLog Then SetLog("Total Siege Workshop Capacity: " & $aGetSiegeCap[0] & "/" & $aGetSiegeCap[1])
		$g_aiCurrentSiegeMachines = $aCurrentTroopsEmpty ; Reset Current Siege Machine Array
		If Number($aGetSiegeCap[0]) = 0 Then Return
	Else
		Return
	EndIf

	If UBound($aCurrentSiegeMachines, 1) >= 1 Then
		For $i = 0 To UBound($aCurrentSiegeMachines, 1) - 1 ; Loop through found Troops
			$aTempSiegeArray = $aCurrentSiegeMachines[$i] ; Declare Array to Temp Array

			$iSiegeIndex = TroopIndexLookup($aTempSiegeArray[0], "getArmySiegeMachines()") - $eWallW ; Get the Index of the Siege M from the ShortName

			$aSiegeCoords = StringSplit($aTempSiegeArray[1], ",", $STR_NOCOUNT) ; Split the Coordinates where the Troop got found into X and Y

			If $iSiegeIndex < 0 Then ContinueLoop
			
			$g_aiCurrentSiegeMachines[$iSiegeIndex] = Number(getBarracksNewTroopQuantity(Slot($aSiegeCoords[0], $aSiegeCoords[1]), 346 + $g_iMidOffsetY, $bNeedCapture)) ; Get The Quantity of the Troop, Slot() Does return the exact spot to read the Number from

			If $iSiegeIndex = 3 Then
				$sSiegeName = $g_asSiegeMachineNames[$iSiegeIndex]
			Else
				$sSiegeName = $g_aiCurrentSiegeMachines[$iSiegeIndex] >= 2 ? $g_asSiegeMachineNames[$iSiegeIndex] & "s" : $g_asSiegeMachineNames[$iSiegeIndex] & ""
			EndIf

			If $g_bDebugSetLogTrain Then SetLog($sSiegeName & " Coord: (" & $aSiegeCoords[0] & "," & $aSiegeCoords[1] & ") Quant :" & $g_aiCurrentSiegeMachines[$iSiegeIndex])
			If $g_bDebugSetLogTrain Then SetLog($sSiegeName & " Slot (" & Slot($aSiegeCoords[0], $aSiegeCoords[1]) & "," & 346 + $g_iMidOffsetY & ")")

			If $bSetLog Then SetLog(" - " & $g_aiCurrentSiegeMachines[$iSiegeIndex] & " " & $sSiegeName & " Available", $COLOR_SUCCESS)
		Next
	EndIf

	If $bSiegeExtended Then
		ClickDrag(765, 376 + $g_iMidOffsetY, 690, 376 + $g_iMidOffsetY)
		If _Sleep(1000) Then Return
		$sSiegeDiamond = GetDiamondFromRect2(742, 342 + $g_iMidOffsetY, 802, 400 + $g_iMidOffsetY)
		$aCurrentSiegeMachines = findMultiple(@ScriptDir & "\imgxml\ArmyOverview\SiegeMachines", $sSiegeDiamond, $sSiegeDiamond, 0, 1000, 0, "objectname,objectpoints", $bNeedCapture)
		
		If UBound($aCurrentSiegeMachines, 1) >= 1 Then
			For $i = 0 To UBound($aCurrentSiegeMachines, 1) - 1 ; Loop through found Troops
				$aTempSiegeArray = $aCurrentSiegeMachines[$i] ; Declare Array to Temp Array
				
				$iSiegeIndex = TroopIndexLookup($aTempSiegeArray[0], "getArmySiegeMachines()") - $eWallW ; Get the Index of the Siege M from the ShortName

				$aSiegeCoords = StringSplit($aTempSiegeArray[1], ",", $STR_NOCOUNT) ; Split the Coordinates where the Troop got found into X and Y
			
				$g_aiCurrentSiegeMachines[$iSiegeIndex] = Number(getBarracksNewTroopQuantity(Slot($aSiegeCoords[0], $aSiegeCoords[1], $bSiegeExtended), 346 + $g_iMidOffsetY, $bNeedCapture)) ; Get The Quantity of the Troop, Slot() Does return the exact spot to read the Number from

				If $iSiegeIndex = 3 Then
					$sSiegeName = $g_asSiegeMachineNames[$iSiegeIndex]
				Else
					$sSiegeName = $g_aiCurrentSiegeMachines[$iSiegeIndex] >= 2 ? $g_asSiegeMachineNames[$iSiegeIndex] & "s" : $g_asSiegeMachineNames[$iSiegeIndex] & ""
				EndIf

				If $g_bDebugSetLogTrain Then SetLog($sSiegeName & " Coord: (" & $aSiegeCoords[0] & "," & $aSiegeCoords[1] & ") Quant :" & $g_aiCurrentSiegeMachines[$iSiegeIndex])
				If $g_bDebugSetLogTrain Then SetLog($sSiegeName & " Slot (" & Slot($aSiegeCoords[0], $aSiegeCoords[1]) & "," & 346 + $g_iMidOffsetY & ")")

				If $bSetLog Then SetLog(" - " & $g_aiCurrentSiegeMachines[$iSiegeIndex] & " " & $sSiegeName & " Available", $COLOR_SUCCESS)
			Next
		EndIf
	EndIf

	If IsTrainPageGrayed(False, 3) Then
		Click(Random(240, 360, 1), Random(190 + $g_iMidOffsetY, 210 + $g_iMidOffsetY, 1), 1, 120)
		If _Sleep(250) Then Return
	EndIf

	If $bCloseArmyWindow Then CloseWindow()

EndFunc   ;==>getArmySiegeMachines
