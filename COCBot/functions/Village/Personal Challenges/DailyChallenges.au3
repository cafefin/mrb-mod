; #FUNCTION# ====================================================================================================================
; Name ..........: DailyChallenges()
; Description ...: Daily Challenges
; Author ........: TripleM (04/2019), Demen (07/2019)
; Modified ......: Moebius14 (04-2024)
; Remarks .......: This file is part of MyBot Copyright 2015-2025
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: DailyChallenges()
; ===============================================================================================================================
#include-once

;[11:11:58 AM] Collecting Daily Rewards...
;[11:11:59 AM] Dragging back for more... [11:12:02 AM] Storage full. Cancelling to sell it
;[11:12:03 AM] Storage full. Cancelling to sell it


Func DailyChallenges()
	Local Static $asLastTimeChecked[8]
	If $g_bFirstStart Then $asLastTimeChecked[$g_iCurAccount] = ""

	checkMainScreen(False)
	Local $bGoldPass = _CheckPixel($aPersonalChallengeOpenButton2, $g_bCapturePixel) ; golden badge button at mainscreen

	; Check at least one pet upgrade is enabled
	Local $bUpgradePets = False
	For $i = 0 To $ePetCount - 1
		If $g_bUpgradePetsEnable[$i] Then
			$bUpgradePets = True
		EndIf
	Next

	Local $bCheckDiscount = $bGoldPass And ($g_bUpgradeKingEnable Or $g_bUpgradeQueenEnable Or $g_bUpgradePrinceEnable Or $g_bUpgradeWardenEnable Or $g_bUpgradeChampionEnable Or $g_bAutoUpgradeWallsEnable Or $bUpgradePets)

	If Not $g_bChkCollectRewards And Not $bCheckDiscount Then Return
	Local $bRedSignal = _CheckPixel($aPersonalChallengeOpenButton3, $g_bCapturePixel)

	If _DateIsValid($asLastTimeChecked[$g_iCurAccount]) Then
		Local $iLastCheck = _DateDiff('n', $asLastTimeChecked[$g_iCurAccount], _NowCalc()) ; elapse time from last check (minutes)
		SetDebugLog("LastCheck: " & $asLastTimeChecked[$g_iCurAccount] & ", Check DateCalc: " & $iLastCheck & ", $bRedSignal: " & $bRedSignal)
		If ($iLastCheck <= $bRedSignal ? 180 : 360) Then Return ; A check each 3 hours or 6 hours [6*60 = 360]
	EndIf

	If OpenPersonalChallenges() Then
		CollectDailyRewards($bGoldPass)
		If $bCheckDiscount Then CheckDiscountPerks()

		If _Sleep(1000) Then Return
		ClosePersonalChallenges()

		$asLastTimeChecked[$g_iCurAccount] = _NowCalc()
	EndIf
EndFunc   ;==>DailyChallenges

Func OpenPersonalChallenges()
	SetLog("Opening personal challenges", $COLOR_INFO)
	If _CheckPixel($aPersonalChallengeOpenButton1, $g_bCapturePixel) Then
		ClickP($aPersonalChallengeOpenButton1, 1, 120, "#0666")
	ElseIf _CheckPixel($aPersonalChallengeOpenButton2, $g_bCapturePixel) Then
		ClickP($aPersonalChallengeOpenButton2, 1, 120, "#0666")
	Else
		SetLog("Can't find button", $COLOR_ERROR)
		Return False
	EndIf

	Local $counter = 0
	While Not _CheckPixel($aPersonalChallengeCloseButton, $g_bCapturePixel) ; test for Personal Challenge Close Button
		SetDebugLog("Wait for Personal Challenge Close Button to appear #" & $counter)
		If _Sleep($DELAYRUNBOT6) Then Return
		$counter += 1
		If $counter > 40 Then Return False
	WEnd

	Local $OkayButton = decodeSingleCoord(FindImageInPlace2("OkayButton", $g_sImgOkayDailyChallenge, 370, 520 + $g_iMidOffsetY, 490, 590 + $g_iMidOffsetY, True))
	If IsArray($OkayButton) And UBound($OkayButton) = 2 Then
		SetDebugLog("Detected Okay Button", $COLOR_INFO)
		ClickP($OkayButton)
		If _Sleep(1000) Then Return
	EndIf

	Return True

EndFunc   ;==>OpenPersonalChallenges

Func CollectDailyRewards($bGoldPass = False)

	If Not $g_bChkCollectRewards Or Not _CheckPixel($aPersonalChallengeRewardsAvail, $g_bCapturePixel) Then Return ; no red badge on rewards tab

	SetLog("Collecting Daily Rewards...")

	ClickP($aPersonalChallengeRewardsTab, 1, 120, "Rewards tab") ; Click Rewards tab
	If _Sleep(1000) Then Return

	Local $IsWhiteAtRight = _ColorCheck(_GetPixelColor(773, 386 + $g_iMidOffsetY, True), Hex(0xFFFFFF, 6), 15) And _ColorCheck(_GetPixelColor(827, 386 + $g_iMidOffsetY, True), Hex(0xFFFFFF, 6), 15)
	Local $aMiniCupButton = decodeSingleCoord(FindImageInPlace2("MiniCupButton", $ImgMiniCupButton, 765, 355 + $g_iMidOffsetY, 830, 415 + $g_iMidOffsetY, True))
	If UBound($aMiniCupButton) < 2 And $IsWhiteAtRight Then
		Click(797, 386 + $g_iMidOffsetY)
		If _Sleep(1500) Then Return
	EndIf

	Local $sAllCoordsString, $aAllCoordsTemp, $aTempCoords
	Local $aAllCoords[0][2]
	Local $aAllCoordsBackup[0][2]

	Local $iClaim = 0
	For $i = 0 To 15
		If Not $g_bRunState Then Return
		Local $SearchArea = $bGoldPass ? GetDiamondFromRect("25,336(810,270)") : GetDiamondFromRect("25,550(810,60)")
		Local $aResult = findMultiple(@ScriptDir & "\imgxml\DailyChallenge\", $SearchArea, $SearchArea, 0, 1000, $bGoldPass ? 12 : 6, "objectname,objectpoints", True)
		If $aResult <> "" And IsArray($aResult) Then
			If $i > 0 Then $aAllCoords = $aAllCoordsBackup ; Empty Array
			For $t = 0 To UBound($aResult) - 1
				Local $aResultArray = $aResult[$t] ; ["Button Name", "x1,y1", "x2,y2", ...]
				SetDebugLog("Find Claim buttons, $aResultArray[" & $t & "]: " & _ArrayToString($aResultArray))
				If IsArray($aResultArray) And $aResultArray[0] = "ClaimBtn" Then
					$sAllCoordsString = _ArrayToString($aResultArray, "|", 1) ; "x1,y1|x2,y2|..."
					$aAllCoordsTemp = decodeMultipleCoords($sAllCoordsString, 50, 50) ; [{coords1}, {coords2}, ...]
					For $k = 0 To UBound($aAllCoordsTemp, 1) - 1
						$aTempCoords = $aAllCoordsTemp[$k]
						_ArrayAdd($aAllCoords, Number($aTempCoords[0]) & "|" & Number($aTempCoords[1]))
					Next
				EndIf
			Next
			RemoveDupXY($aAllCoords)
			_ArraySort($aAllCoords, 1, 0, 0, 0) ;sort by x from right to left
			For $j = 0 To UBound($aAllCoords) - 1
				Click($aAllCoords[$j][0], $aAllCoords[$j][1], 1, 120, "Claim " & $j + 1)         ; Click Claim button
				If WaitforPixel(329, 390 + $g_iMidOffsetY, 331, 392 + $g_iMidOffsetY, Hex(0xFFC877, 6), 20, 3) Then         ; wait for Cancel Button popped up in 1.5 second
					If $g_bChkSellRewards Then
						SetLog("Selling extra reward for gems", $COLOR_SUCCESS)
						ClickP($aPersonalChallengeOkBtn, 1, 120, "Okay Btn")         ; Click the Okay
						$iClaim += 1
					Else
						SetLog("Cancel. Not selling extra rewards.", $COLOR_SUCCESS)
						ClickP($aPersonalChallengeCancelBtn, 1, 120, "Cancel Btn")         ; Click Claim button
					EndIf
					If _Sleep(1000) Then ExitLoop
				Else
					$iClaim += 1
					If _Sleep(100) Then ExitLoop
				EndIf
			Next
		EndIf
		If _CheckPixel($aPersonalChallengeRewardsAvail, $g_bCapturePixel) And Not _CheckPixel($aPersonalChallengeLeftEdge, $g_bCapturePixel) Then ; far left edge
			If $i = 0 Then
				SetLog("Dragging back for more... ", Default, Default, Default, Default, Default, Default, False) ; no end line
			Else
				SetLog($i & ".. ", Default, Default, Default, Default, Default, 0, $i < 15 ? False : Default) ; no time
			EndIf
			ClickDrag(120, 400 + $g_iMidOffsetY, 740, 400 + $g_iMidOffsetY, 1000) ;x1 was 50. x2 was 810  Change for Dec '20 update
			If _Sleep(500) Then ExitLoop
		Else
			If $i > 0 Then SetLog($i & ".", Default, Default, Default, Default, Default, False) ; no time + end line
			ExitLoop
		EndIf
	Next
	SetLog($iClaim > 0 ? "Claimed " & $iClaim & " reward(s)!" : "Nothing to claim!", $COLOR_SUCCESS)
	If _Sleep(500) Then Return

EndFunc   ;==>CollectDailyRewards

Func CheckDiscountPerks()
	SetLog("Checking for builder boost...")
	If $g_bFirstStart Then $g_iBuilderBoostDiscount = 0

	ClickP($aPersonalChallengePerksTab, 1, 120, "PerksTab")

	If Not WaitforPixel($aPersonalChallengePerksTab[0] - 1, $aPersonalChallengePerksTab[1] - 1, $aPersonalChallengePerksTab[0] + 1, $aPersonalChallengePerksTab[1] + 1, _
			Hex($aPersonalChallengePerksTab[2], 6), $aPersonalChallengePerksTab[3], 2) Then Return        ; wait for Perks Tab completely loaded in 1 second

	If _Sleep(500) Then Return

	; find builder boost rate %
	Local $sDiscount = getOcrAndCapture("coc-builderboost", 110, 277 + $g_iMidOffsetY, 100, 40, True)
	SetDebugLog("Builder boost OCR: " & $sDiscount)
	If StringInStr($sDiscount, "%") Then
		Local $aDiscount = StringSplit($sDiscount, "%", $STR_NOCOUNT)
		$g_iBuilderBoostDiscount = Number($aDiscount[0])
		SetLog($g_iBuilderBoostDiscount > 0 ? "Current Builder boost: " & $g_iBuilderBoostDiscount & "%" : "Keep working hard on challenges", $COLOR_SUCCESS)
		cmbWalls()
		If ProfileSwitchAccountEnabled() Then SwitchAccountVariablesReload("Save")
	Else
		SetLog("Cannot read builder boost", $COLOR_ERROR)
	EndIf
EndFunc   ;==>CheckDiscountPerks

Func ClosePersonalChallenges()
	If $g_bDebugSetLog Then SetLog("Closing personal challenges", $COLOR_INFO)

	CloseWindow()

	Local $counter = 0
	While Not IsMainPage(1) ; test for Personal Challenge Close Button
		SetDebugLog("Wait for Personal Challenge Window to close #" & $counter)
		If _Sleep($DELAYRUNBOT6) Then ExitLoop
		$counter += 1
		If $counter > 40 Then ExitLoop
	WEnd

EndFunc   ;==>ClosePersonalChallenges
