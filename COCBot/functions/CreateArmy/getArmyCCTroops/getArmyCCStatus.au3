; #FUNCTION# ====================================================================================================================
; Name ..........: getArmyCCStatus
; Description ...: Updates global value of time reamining in mimutes for CC remaining time till can reques again - Army Overview window
; Syntax ........: getArmyCCStatus($bOpenArmyWindow = False, $bCloseArmyWindow = False)
; Parameters ....:
; Return values .:
; Author ........: MonkeyHunter (06-2016)
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2025
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func getArmyCCStatus($bOpenArmyWindow = False, $bCloseArmyWindow = False, $CheckWindow = True, $bSetLog = True, $bNeedCapture = True)

	If $g_bDebugSetLogTrain Or $g_bDebugSetLog Then SetLog("Begin getArmyCCStatus:", $COLOR_DEBUG1)

	If $CheckWindow Then
		If Not $bOpenArmyWindow And Not IsTrainPage() Then ; check for train page
			SetError(1)
			Return ; not open, not requested to be open - error.
		ElseIf $bOpenArmyWindow Then
			If Not OpenArmyOverview(True, "getArmyCCStatus()") Then
				SetError(2)
				Return ; not open, requested to be open - error.
			EndIf
			If _Sleep($DELAYCHECKARMYCAMP5) Then Return
		EndIf
	EndIf

	;verify can make requestCC and update global flag
	$g_bCanRequestCC = _ColorCheck(_GetPixelColor($aRequestTroopsAO[0], $aRequestTroopsAO[1], $bNeedCapture), Hex($aRequestTroopsAO[3], 6), $aRequestTroopsAO[5]) And _ColorCheck(_GetPixelColor($aRequestTroopsAO[0], $aRequestTroopsAO[1] + 30, $bNeedCapture), Hex($aRequestTroopsAO[4], 6), $aRequestTroopsAO[5])
	If $g_bDebugSetLogTrain Then SetLog("Can Request CC: " & $g_bCanRequestCC, $COLOR_DEBUG)

	If Not $g_bCanRequestCC Then
		If Not _ColorCheck(_GetPixelColor($aRequestTroopsAO[0], $aRequestTroopsAO[1], $bNeedCapture), Hex($aRequestTroopsAO[3], 6), $aRequestTroopsAO[5]) And  _ColorCheck(_GetPixelColor($aRequestTroopsAO[0], $aRequestTroopsAO[1] + 48, $bNeedCapture), Hex($aRequestTroopsAO[3], 6), $aRequestTroopsAO[5]) Then
			If $bSetLog Then SetLog(" - Clan Castle request already made.", $COLOR_INFO)
		EndIf
		If _ColorCheck(_GetPixelColor($aRequestTroopsAO[0], $aRequestTroopsAO[1], $bNeedCapture), Hex($aRequestTroopsAO[2], 6), $aRequestTroopsAO[5]) Then
			If $bSetLog Then SetLog("Clan Castle Full/No Clan.", $COLOR_INFO)
		EndIf
	EndIf

	If $bCloseArmyWindow Then
		CloseWindow()
		If _Sleep($DELAYCHECKARMYCAMP4) Then Return
	EndIf

EndFunc   ;==>getArmyCCStatus
