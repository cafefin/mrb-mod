; #FUNCTION# ====================================================================================================================
; Name ..........: Switch Account
; Description ...: This file contains the Sequence that runs all MBR Bot
; Syntax ........:
; Parameters ....: None
; Return values .: None
; Author ........: chalicucu (6/2016), demen (4/2017)
; Modified ......: Moebius14 (08/2023)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2025
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
; Return True or False if Switch Account is enabled and current profile in configured list
Func ProfileSwitchAccountEnabled()
	If Not $g_bChkSwitchAcc Or Not aquireSwitchAccountMutex() Then Return False
	Return SetError(0, 0, _ArraySearch($g_asProfileName, $g_sProfileCurrentName) >= 0)
EndFunc   ;==>ProfileSwitchAccountEnabled

; Return True or False if specified Profile is enabled for Switch Account and controlled by this bot instance
Func SwitchAccountEnabled($IdxOrProfilename = $g_sProfileCurrentName)
	Local $sProfile
	Local $iIdx
	If IsInt($IdxOrProfilename) Then
		$iIdx = $IdxOrProfilename
		$sProfile = $g_asProfileName[$iIdx]
	Else
		$sProfile = $IdxOrProfilename
		$iIdx = _ArraySearch($g_asProfileName, $sProfile)
	EndIf

	If Not $sProfile Or $iIdx < 0 Or Not $g_abAccountNo[$iIdx] Then
		; not in list or not enabled
		Return False
	EndIf

	; check if mutex is or can be aquired
	Return aquireProfileMutex($sProfile) <> 0
EndFunc   ;==>SwitchAccountEnabled

; retuns copy of $g_abAccountNo validated with SwitchAccountEnabled
Func AccountNoActive()
	Local $a[UBound($g_abAccountNo)]

	For $i = 0 To UBound($g_abAccountNo) - 1
		$a[$i] = SwitchAccountEnabled($i)
	Next

	Return $a
EndFunc   ;==>AccountNoActive

Func InitiateSwitchAcc() ; Checking profiles setup in Mybot, First matching CoC Acc with current profile, Reset all Timers relating to Switch Acc Mode.
	If Not ProfileSwitchAccountEnabled() Or Not $g_bInitiateSwitchAcc Then Return
	UpdateMultiStats()
	$g_iNextAccount = -1
	SetLog("Switch Account enable for " & $g_iTotalAcc + 1 & " accounts")
	SetSwitchAccLog("Initiating: " & $g_iTotalAcc + 1 & " acc", $COLOR_SUCCESS)

	If Not $g_bRunState Then Return
	For $i = 0 To $g_iTotalAcc
		; listing all accounts
		Local $sBotType = "Idle"
		If $g_abAccountNo[$i] Then
			If SwitchAccountEnabled($i) Then
				$sBotType = "Active"
				If $g_abDonateOnly[$i] Then $sBotType = "Donate"
				If $g_iNextAccount = -1 Then $g_iNextAccount = $i
				If $g_asProfileName[$i] = $g_sProfileCurrentName Then $g_iNextAccount = $i
			Else
				$sBotType = "Other bot"
			EndIf
		EndIf
		SetLog("  - Account [" & $i + 1 & "]: " & $g_asProfileName[$i] & " - " & $sBotType)
		SetSwitchAccLog("  - Acc. " & $i + 1 & ": " & $sBotType)
	Next
	$g_iCurAccount = $g_iNextAccount ; make sure no crash
	SwitchAccountVariablesReload("Reset")
	SetLog("Let's start with Account [" & $g_iNextAccount + 1 & "]")
	SetSwitchAccLog("Start with Acc [" & $g_iNextAccount + 1 & "]")
	SwitchCOCAcc($g_iNextAccount)
EndFunc   ;==>InitiateSwitchAcc

Func CheckSwitchAcc()
	Local $abAccountNo = AccountNoActive()
	If Not $g_bRunState Then Return
	Local $aActiveAccount = _ArrayFindAll($abAccountNo, True)
	If UBound($aActiveAccount) <= 1 Then Return

	Local $aDonateAccount = _ArrayFindAll($g_abDonateOnly, True)
		Local $bReachAttackLimit = ($g_aiAttackedCountSwitch[$g_iCurAccount] <= $g_aiAttackedCount - Number($g_iCmbMaxInARow + 1))
	Local $bForceSwitch = $g_bForceSwitch
	Local $nMinRemainTrain, $iWaitTime

	SetLog("Start Switch Account!", $COLOR_INFO)

	If $g_iCommandStop = 0 Or $g_iCommandStop = 3 Then ; Forced to switch when in halt attack mode
		SetLog("This account is in halt attack mode, switching to another account", $COLOR_ACTION)
		SetSwitchAccLog(" - Halt Attack, Force switch")
		$bForceSwitch = True
	ElseIf $g_iCommandStop = 1 Then
		SetLog("This account is turned off, switching to another account", $COLOR_ACTION)
		SetSwitchAccLog(" - Turn idle, Force switch")
		$bForceSwitch = True
	ElseIf $g_iCommandStop = 2 Then
		SetLog("This account is out of Attack Schedule, switching to another account", $COLOR_ACTION)
		SetSwitchAccLog(" - Off Schedule, Force switch")
		$bForceSwitch = True
	ElseIf $g_bWaitForCCTroopSpell Then
		SetLog("Still waiting for CC Troops/Spells, switching to another Account", $COLOR_ACTION)
		SetSwitchAccLog(" - Waiting for CC")
		$bForceSwitch = True
	ElseIf $g_bAllBarracksUpgd Then ;Check if all barrack are upgrading, no army can be train --> Force Switch account
		SetLog("Seems all your barracks are upgrading", $COLOR_INFO)
		SetLog("No troops can be trained, let's switch account", $COLOR_INFO)
		SetSwitchAccLog(" - All Barracks Upgrading, Force switch")
		$bForceSwitch = True
	Else
		If $bReachAttackLimit Then
			SetLog("This account has attacked " & Number($g_iCmbMaxInARow + 1) & " time" & (Number($g_iCmbMaxInARow + 1) > 1 ? "s in a row" : "") & ", switching to another account", $COLOR_INFO)
			SetSwitchAccLog(" - Reach attack limit: " & $g_aiAttackedCount - $g_aiAttackedCountSwitch[$g_iCurAccount])
			$bForceSwitch = True
		EndIf
	EndIf

	Local $sLogSkip = ""
	If Not $g_abDonateOnly[$g_iCurAccount] And Not $bForceSwitch Then
		If Not $g_bRunState Then Return
		SetLog("Army is ready" & $sLogSkip & ", skip switching account", $COLOR_INFO)
		SetSwitchAccLog(" - Army is ready" & $sLogSkip)
		SetSwitchAccLog("Stay at [" & $g_iCurAccount + 1 & "]", $COLOR_SUCCESS)
		If _Sleep(500) Then Return

	Else

		If Not $bForceSwitch And Not $g_bDonateLikeCrazy Then ; Active (force switch shall give priority to Donate Account)
			If $g_bDebugSetLog Then SetDebugLog("Switch to or Stay at Active Account: " & $g_iNextAccount + 1, $COLOR_DEBUG)
			$g_iDonateSwitchCounter = 0
		Else
			If IsArray($aDonateAccount) Then
				If $g_iDonateSwitchCounter < UBound($aDonateAccount) Then     ; Donate
					$g_iNextAccount = $aDonateAccount[$g_iDonateSwitchCounter]
					$g_iDonateSwitchCounter += 1
					If $g_bDebugSetLog Then SetDebugLog("Switch to Donate Account " & $g_iNextAccount + 1 & ". $g_iDonateSwitchCounter = " & $g_iDonateSwitchCounter, $COLOR_DEBUG)
					SetSwitchAccLog(" - Donate Acc [" & $g_iNextAccount + 1 & "]")
				Else     ; Active
					$g_iDonateSwitchCounter = 0
				EndIf
			Else
				$g_iNextAccount = $g_iCurAccount + 1 ; Classic Switch in Order
				If $g_iNextAccount > $g_iTotalAcc Then $g_iNextAccount = 0
				While $abAccountNo[$g_iNextAccount] = False
					$g_iNextAccount += 1
					If $g_iNextAccount > $g_iTotalAcc Then $g_iNextAccount = 0     ; avoid idle Account
					SetDebugLog("- While Account: " & $g_asProfileName[$g_iNextAccount] & " number: " & $g_iNextAccount + 1)
				WEnd
			EndIf
		EndIf

		If Not $g_bRunState Then Return

		SetDebugLog("- Current Account: " & $g_asProfileName[$g_iCurAccount] & " number: " & $g_iCurAccount + 1)
		SetDebugLog("- Next Account: " & $g_asProfileName[$g_iNextAccount] & " number: " & $g_iNextAccount + 1)

		If UBound($aDonateAccount) = UBound($aActiveAccount) Then
			SetLog("All accounts set to Donate!", $COLOR_INFO)
			SetSwitchAccLog("All accounts in Donate:")
			; Just a Good User Log
			For $i = 0 To $g_iTotalAcc
				If $g_abDonateOnly[$i] Then SetSwitchAccLog(" - Donate Acc [" & $i + 1 & "]")
			Next
		EndIf

		If $g_iNextAccount <> $g_iCurAccount Then
			If $g_bRequestTroopsEnable And $g_bCanRequestCC Then
				If _Sleep(1000) Then Return
				SetLog("Try Request troops before switching account", $COLOR_INFO)
				RequestCC(True)
			EndIf
			If Not IsMainPage() Then checkMainScreen()
			SwitchCOCAcc($g_iNextAccount)
		Else
			SetLog("Staying in this account")
			SetSwitchAccLog("Stay at [" & $g_iCurAccount + 1 & "]", $COLOR_SUCCESS)
		EndIf
	EndIf
	If Not $g_bRunState Then Return

	$g_bForceSwitch = False ; reset the need to switch
EndFunc   ;==>CheckSwitchAcc

Func SwitchCOCAcc($NextAccount)
	Local $abAccountNo = AccountNoActive()
	If $NextAccount < 0 And $NextAccount > $g_iTotalAcc Then $NextAccount = _ArraySearch(True, $abAccountNo)
	Static $iRetry = 0
	Local $bResult
	If Not $g_bRunState Then Return

	SetLog("Switching to Account [" & $NextAccount + 1 & "]")

	Local $bSharedPrefs = $g_bChkSharedPrefs And HaveSharedPrefs($g_asProfileName[$g_iNextAccount])
	If $bSharedPrefs And $g_PushedSharedPrefsProfile = $g_asProfileName[$g_iNextAccount] Then
		; shared prefs already pushed
		$bResult = True
		$bSharedPrefs = False ; don't push again
		SetLog("Profile shared_prefs already pushed")
		If Not $g_bRunState Then Return
	Else
		If Not $g_bRunState Then Return
		If IsMainPage() Then Click($aButtonSetting[0], $aButtonSetting[1], 1, 120, "Click Setting")
		If _Sleep(500) Then Return
		While 1
			If Not IsSettingPage() Then ExitLoop

			If $g_bChkSharedPrefs Then
				Switch SwitchCOCAcc_DisconnectConnect($bResult, $bSharedPrefs)
					Case 0
						Return
					Case -1
						ExitLoop
				EndSwitch
				Switch SwitchCOCAcc_ClickAccount($bResult, $NextAccount, $bSharedPrefs)
					Case "OK"
						; all good
						If $g_bChkSharedPrefs Then
							If $bSharedPrefs Then
								CloseCoC(False)
								$bResult = True
								ExitLoop
							Else
								SetLog($g_asProfileName[$g_iNextAccount] & " missing shared_prefs, using normal switch account", $COLOR_WARNING)
							EndIf
						EndIf
					Case "Error"
						; some problem
						ExitLoop
					Case "Exit"
						; no $g_bRunState
						Return
				EndSwitch
			ElseIf $g_bChkSuperCellID Then
				Switch SwitchCOCAcc_ConnectedSCID($bResult)
					Case "OK"
						; all good
					Case "Error"
						; some problem
						ExitLoop
					Case "Exit"
						; no $g_bRunState
						Return
				EndSwitch
				Switch SwitchCOCAcc_ClickAccountSCID($bResult, $NextAccount, 2)
					Case "OK"
						; all good
					Case "Error"
						; some problem
						ExitLoop
					Case "Exit"
						; no $g_bRunState
						Return
				EndSwitch

			EndIf
			ExitLoop
		WEnd
		If _Sleep(500) Then Return
	EndIf

	If $bResult Then
		$iRetry = 0
		$g_bReMatchAcc = False
		If Not $g_bRunState Then Return
		If Not $g_bInitiateSwitchAcc Then SwitchAccountVariablesReload("Save")
		If $g_ahTimerSinceSwitched[$g_iCurAccount] <> 0 Then
			If Not $g_bReMatchAcc Then SetSwitchAccLog(" - Acc " & $g_iCurAccount + 1 & ", online: " & Int(__TimerDiff($g_ahTimerSinceSwitched[$g_iCurAccount]) / 1000 / 60) & "m")
			SetTime(True)
			$g_aiRunTime[$g_iCurAccount] += __TimerDiff($g_ahTimerSinceSwitched[$g_iCurAccount])
			$g_ahTimerSinceSwitched[$g_iCurAccount] = 0
		EndIf

		$g_iCurAccount = $NextAccount
		SwitchAccountVariablesReload()

		$g_ahTimerSinceSwitched[$g_iCurAccount] = __TimerInit()
		$g_bInitiateSwitchAcc = False
		If $g_sProfileCurrentName <> $g_asProfileName[$g_iNextAccount] Then
			saveConfig() ;Always save before switch in case of any user changes
			If $g_iGuiMode = 1 Then
				; normal GUI Mode
				_GUICtrlComboBox_SetCurSel($g_hCmbProfile, _GUICtrlComboBox_FindStringExact($g_hCmbProfile, $g_asProfileName[$g_iNextAccount]))
				cmbProfile()
				DisableGUI_AfterLoadNewProfile()
			Else
				; mini or headless GUI Mode
				; saveConfig()
				$g_sProfileCurrentName = $g_asProfileName[$g_iNextAccount]
				LoadProfile(False)
			EndIf
		EndIf
		If $bSharedPrefs Then
			SetLog("Please wait for loading CoC")
			PushSharedPrefs()
			OpenCoC()
			waitMainScreen()
		EndIf

		SetSwitchAccLog("Switched to Acc [" & $NextAccount + 1 & "]", $COLOR_SUCCESS)
		CreateLogFile() ; Cause use of the right log file after switch
		If Not $g_bRunState Then Return


		If $g_bChkSharedPrefs Then
			; disconnect account again for saving shared_prefs
			waitMainScreen()
			If IsMainPage() Then
				Click($aButtonSetting[0], $aButtonSetting[1], 1, 120, "Click Setting")
				If _Sleep(500) Then Return
				If SwitchCOCAcc_DisconnectConnect($bResult, $g_bChkSharedPrefs) = -1 Then Return ;Return if Error happend

				Switch SwitchCOCAcc_ClickAccount($bResult, $NextAccount, $g_bChkSharedPrefs, False)
					Case "OK"
						; all good
						PullSharedPrefs()
				EndSwitch
			EndIf
		EndIf
		If Not $g_bRunState Then Return
	Else
		$iRetry += 1
		$g_bReMatchAcc = True
		SetLog("Switching account failed!", $COLOR_ERROR)
		SetSwitchAccLog("Switching to Acc " & $NextAccount + 1 & " Failed!", $COLOR_ERROR)
		If $iRetry <= 3 Then
			Local $ClickPoint = $aCloseTabSCID
			ClickP($ClickPoint, 1, 500)
			If _Sleep(1500) Then Return
			CloseWindow2()
			If _Sleep(500) Then Return
			checkMainScreen()
		Else
			$iRetry = 0
			;HArchH Testing for close Android on repeated switch fail.
			SetLog("Switching account failed to many times!  Restart emulator.", $COLOR_ERROR)
			SetSwitchAccLog("Too many fails, restart Emulator.", $COLOR_ERROR)
			If _Sleep(2000) Then Return
			CloseAndroid("Restart Emulator")
			;UniversalCloseWaitOpenCoC()
		EndIf
		If Not $g_bRunState Then Return
	EndIf
	waitMainScreen()
	If Not $g_bRunState Then Return
	CheckObstacles()

	SetLog("Switch Account Load Town Hall Level : " & $g_iTownHallLevel)
	GUICtrlSetData($g_hGrpVillage, GetTranslatedFileIni("MBR Main GUI", "Tab_02", "Village") & "[TH" & $g_iTownHallLevel & "]" & ": " & $g_sProfileCurrentName)

	;Display Level TH in Stats
	GUICtrlSetData($g_hLblTHLevels, "")
	_GUI_Value_STATE("HIDE", $g_aGroupListTHLevels)
	GUICtrlSetState($g_ahPicTHLevels[$g_iTownHallLevel], $GUI_SHOW)
	GUICtrlSetData($g_hLblTHLevels, $g_iTownHallLevel)

	runBot()

EndFunc   ;==>SwitchCOCAcc

Func SwitchCOCAcc_DisconnectConnect(ByRef $bResult, $bDisconnectOnly = $g_bChkSharedPrefs)
	If Not $g_bRunState Then Return -1

	For $i = 0 To 20 ; Checking Green Connect Button continuously in 20sec
		; SupercellID
		Local $aSuperCellIDConnected = decodeSingleCoord(findImage("SupercellID Connected", $g_sImgSupercellIDConnected, GetDiamondFromRect("660,150,760,200"), 1, True, Default))
		If IsArray($aSuperCellIDConnected) And UBound($aSuperCellIDConnected, 1) >= 2 Then
			SetLog("Account connected to SuperCell ID")
			Return 1
		EndIf
		If $i = 20 Then
			$bResult = False
			Return -1
		EndIf
		If _Sleep(900) Then Return 0
		If Not $g_bRunState Then Return 0
	Next

	Return -1
EndFunc   ;==>SwitchCOCAcc_DisconnectConnect

Func SwitchCOCAcc_ClickAccount(ByRef $bResult, $iNextAccount, $bStayDisconnected = $g_bChkSharedPrefs, $bLateDisconnectButtonCheck = True)
	FuncEnter(SwitchCOCAcc_ClickAccount)

	Local $aSearchForAccount, $aCoordinates[0][2], $aTempArray

	For $i = 0 To 20 ; Checking Account List continuously in 20sec
		; SupercellID
		Local $aSuperCellIDConnected = decodeSingleCoord(findImage("SupercellID Connected", $g_sImgSupercellIDConnected, GetDiamondFromRect("660,150,760,200"), 1, True, Default))
		If IsArray($aSuperCellIDConnected) And UBound($aSuperCellIDConnected, 1) >= 2 Then
			SetLog("Account connected to SuperCell ID, cannot disconnect")
			If $bStayDisconnected Then
				ClickAway()
				Return FuncReturn("OK")
			EndIf
		EndIf
		If $i = 20 Then
			$bResult = False
			Return FuncReturn("Error")
		EndIf
		If _Sleep(900) Then Return FuncReturn("Exit")
		If Not $g_bRunState Then Return FuncReturn("Exit")
	Next
	Return FuncReturn("") ; should never get here
EndFunc   ;==>SwitchCOCAcc_ClickAccount

Func SwitchCOCAcc_ConnectedSCID(ByRef $bResult)
	For $i = 0 To 20 ; Checking Blue Reload button continuously in 20sec
		Local $aSuperCellIDReload = decodeSingleCoord(findImage("SupercellID Reload", $g_sImgSupercellIDReload, GetDiamondFromRect("560,145,635,200"), 1, True, Default))
		If IsArray($aSuperCellIDReload) And UBound($aSuperCellIDReload, 1) >= 2 Then
			Click($aSuperCellIDReload[0], $aSuperCellIDReload[1], 1, 120, "Click Reload SC_ID")
			SetLog("   1. Click Reload Supercell ID")
			If $g_bDebugSetLog Then SetSwitchAccLog("   1. Click Reload Supercell ID")
			If _Sleep(3000) Then Return "Exit"
			If Not $g_bRunState Then Return "Exit"
			Return "OK"
		EndIf

		If $i = 20 Then
			$bResult = False
			Return "Error"
		EndIf
		If _Sleep(900) Then Return "Exit"
		If Not $g_bRunState Then Return "Exit"
	Next
	Return "" ; should never get here
EndFunc   ;==>SwitchCOCAcc_ConnectedSCID

Func SwitchCOCAcc_ClickAccountSCID(ByRef $bResult, $NextAccount, $iStep = 2, $bVerifyAcc = True, $bDebuglog = $g_bDebugSetLog, $bDebugImageSave = $g_bDebugImageSave)
	Local $sAccountDiamond = GetDiamondFromRect2(540, 323 + $g_iMidOffsetY, 590, 695 + $g_iMidOffsetY)
	Local $aSuperCellIDWindowsUI
	Local $iIndexSCID = $NextAccount
	Local $aSearchForAccount, $aCoordinates[0][2], $aTempArray

	If Not $g_bRunState Then Return "Exit"

	For $i = 0 To 30 ; Checking "New SuperCellID UI" continuously in 30sec
		$aSuperCellIDWindowsUI = decodeSingleCoord(findImage("SupercellID Windows", $g_sImgSupercellIDWindows, GetDiamondFromRect2(670, 80, 810, 140 + $g_iMidOffsetY), 1, True, Default))
		If _Sleep(500) Then Return "Exit"
		If IsArray($aSuperCellIDWindowsUI) And UBound($aSuperCellIDWindowsUI, 1) >= 2 Then

			If $bVerifyAcc Then
				; verifiy SCID Account slots has not moved for accounts 0 to 3
				If $g_iTotalAcc < 4 Then

					If Not IsSCIDAccComplete($g_iTotalAcc) Then
						$bResult = False
						Return False
					EndIf

				Else

					If Not IsSCIDAccComplete() Then
						$bResult = False
						Return False
					EndIf

				EndIf
			EndIf

			; Make Drag only when SCID window is visible.
			If Not SCIDragIfNeeded($NextAccount, $bVerifyAcc) Then
				SetLog("SCIDragIfNeeded failed")
				$bResult = False
				Return "Error"
			EndIf

			If $g_bDebugSetLog Then SetSwitchAccLog("Switching to Account: " & $NextAccount + 1, $COLOR_DEBUG)

			If $bDebugImageSave Then SaveDebugDiamondImage("ClickAccountSCID", $sAccountDiamond)

			$aSearchForAccount = decodeMultipleCoords(findImage("Account Locations", $g_sImgSupercellIDSlots, $sAccountDiamond, 0, True, Default))
			If _Sleep(500) Then Return "Exit"
			If Not $g_bRunState Then Return "Exit"
			If IsArray($aSearchForAccount) And UBound($aSearchForAccount) > 0 Then
				SetDebugLog("SCID Accounts: " & UBound($aSearchForAccount), $COLOR_DEBUG)
				SetLog("SCID Accounts: " & UBound($aSearchForAccount), $COLOR_DEBUG)

				If $g_bDebugSetLog Then SetSwitchAccLog("SCID Accounts: " & UBound($aSearchForAccount), $COLOR_DEBUG)

				; Correct Index for Profile if needs to drag
				If $NextAccount >= 3 And UBound($aSearchForAccount) == 4 Then $iIndexSCID = 3 ; based on drag logic, the account will always be the bottom one

				; fixes weird issue with arrays after getting image info
				For $j = 0 To UBound($aSearchForAccount) - 1
					$aTempArray = $aSearchForAccount[$j]
					_ArrayAdd($aCoordinates, $aTempArray[0] & "|" & $aTempArray[1], 0, "|", @CRLF, $ARRAYFILL_FORCE_NUMBER)
				Next

				_ArraySort($aCoordinates, 0, 0, 0, 1) ; sort by column 1 [Y]... this is to keep them in order of actual list

				If IsArray($aCoordinates) And UBound($aCoordinates) > 1 And UBound($aCoordinates, $UBOUND_ROWS) > 1 Then

					; list all account see-able after drag on debug chat
					Local $iProfiles = UBound($g_asProfileName)

					For $j = 0 To UBound($aCoordinates) - 1
						SetDebugLog("[" & $j + 1 & "] Account coordinates: " & $aCoordinates[$j][0] & "," & $aCoordinates[$j][1] & " named: " & $g_asProfileName[$NextAccount - $iIndexSCID + $j])
						If $g_bDebugSetLog Then SetSwitchAccLog("[" & $j + 1 & "] A/C coord: " & $aCoordinates[$j][0] & "," & $aCoordinates[$j][1] & " Profile: " & $g_asProfileName[$NextAccount - $iIndexSCID + $j])
					Next

					SetLog("   " & $iStep & ". Click Account [" & $NextAccount + 1 & "] Supercell ID with Profile: " & $g_asProfileName[$NextAccount])

					Local $AccountX = Random($aCoordinates[$iIndexSCID][0] - 20, $aCoordinates[$iIndexSCID][0] + 190, 1)
					Local $AccountY = Random($aCoordinates[$iIndexSCID][1] - 20, $aCoordinates[$iIndexSCID][1] + 25, 1)
					Click($AccountX, $AccountY, 1, 120, "#0155") ;Click Account
					If _Sleep(750) Then Return "Exit"
					SetLog("   " & $iStep + 1 & ". Please wait for loading CoC!")
					$bResult = True
					Return "OK"

				EndIf

			EndIf
		EndIf

		If $i = 30 Then
			$bResult = False
			Return "Error"
		EndIf
		If _Sleep(900) Then Return "Exit"
		If Not $g_bRunState Then Return "Exit"
	Next
	Return "" ; should never get here
EndFunc   ;==>SwitchCOCAcc_ClickAccountSCID

#cs
Func CheckWaitHero() ; get hero regen time remaining if enabled
	Local $iActiveHero
	Local $aHeroResult[$eHeroSlots]
	$g_aiTimeTrain[2] = 0

	$aHeroResult = getArmyHeroTime("all")
	If UBound($aHeroResult) < $eHeroSlots Then Return ; OCR error

	If _Sleep($DELAYRESPOND) Then Return
	If Not $g_bRunState Then Return
	If $aHeroResult[0] > 0 Or $aHeroResult[1] > 0 Or $aHeroResult[2] > 0 Or $aHeroResult[3] > 0 Then ; check if hero is enabled to use/wait and set wait time
		Local $pTroopType
		For $i = 0 To $eHeroSlots - 1
			Switch $g_aiCmbCustomHeroOrder[$i]
				Case 0
					$pTroopType = $eKing
				Case 1
					$pTroopType = $eQueen
				Case 2
					$pTroopType = $ePrince
				Case 3
					$pTroopType = $eWarden
				Case 4
					$pTroopType = $eChampion
			EndSwitch
			For $pMatchMode = $DB To $g_iModeCount - 1 ; check all attack modes
				$iActiveHero = -1
				If IsUnitUsed($pMatchMode, $pTroopType) And _
						BitOR($g_aiAttackUseHeroes[$pMatchMode], $g_aiSearchHeroWaitEnable[$pMatchMode]) = $g_aiAttackUseHeroes[$pMatchMode] Then ; check if Hero enabled to wait
					$iActiveHero = $i ; compute array offset to active hero
				EndIf
				If $iActiveHero <> -1 And $aHeroResult[$iActiveHero] > 0 Then ; valid time?
					; check exact time & existing time is less than new time
					If $g_aiTimeTrain[2] < $aHeroResult[$iActiveHero] Then
						$g_aiTimeTrain[2] = $aHeroResult[$iActiveHero] ; use exact time
					EndIf
				EndIf
			Next
			If _Sleep($DELAYRESPOND) Then Return
			If Not $g_bRunState Then Return
		Next
	EndIf

EndFunc   ;==>CheckWaitHero

Func CheckTroopTimeAllAccount($bExcludeCurrent = False) ; Return the minimum remain training time
	If Not $g_bRunState Then Return
	Local $abAccountNo = AccountNoActive()
	Local $iMinRemainTrain = 999, $iRemainTrain, $bNextAccountDefined = False
	If Not $bExcludeCurrent Then
		$g_asTrainTimeFinish[$g_iCurAccount] = _DateAdd("n", Number(_ArrayMax($g_aiTimeTrain, 1, 0, 2)), _NowCalc())
		SetDebugLog("Army times: Troop = " & $g_aiTimeTrain[0] & ", Spell = " & $g_aiTimeTrain[1] & ", Hero = " & $g_aiTimeTrain[2] & ", $g_asTrainTimeFinish = " & $g_asTrainTimeFinish[$g_iCurAccount])
	EndIf

	SetSwitchAccLog(" - Train times: ")

	For $i = 0 To $g_iTotalAcc
		If $bExcludeCurrent And $i = $g_iCurAccount Then ContinueLoop
		If $abAccountNo[$i] And Not $g_abDonateOnly[$i] Then ;	Only check Active profiles
			If _DateIsValid($g_asTrainTimeFinish[$i]) Then
				Local $iRemainTrain = _DateDiff('n', _NowCalc(), $g_asTrainTimeFinish[$i])
				; if remaining time is negative and stop mode, force 0 to ensure other accounts will be picked
				If $iRemainTrain < 0 And SwitchAccountVariablesReload("$g_iCommandStop", $i) <> -1 Then
					; Account was last time in halt attack mode, set time to 0
					$iRemainTrain = 0
					SetLog("Account [" & $i + 1 & "]: " & $g_asProfileName[$i] & " halt mode detected, set negative remaining time to 0")
				EndIf
				SetLog("Account [" & $i + 1 & "]: " & $g_asProfileName[$i] & "'s train time: " & $g_asTrainTimeFinish[$i] & " (" & $iRemainTrain & " minutes)")
				If $iMinRemainTrain > $iRemainTrain Then
					If Not $bNextAccountDefined Then $g_iNextAccount = $i
					$iMinRemainTrain = $iRemainTrain
				EndIf
				SetSwitchAccLog("    Acc " & $i + 1 & ": " & $iRemainTrain & "m")
			Else ; for accounts first Run
				SetLog("Account [" & $i + 1 & "]: " & $g_asProfileName[$i] & " has not been read its remain train time")
				SetSwitchAccLog("    Acc " & $i + 1 & ": Unknown")
				If Not $bNextAccountDefined Then
					$g_iNextAccount = $i
					$bNextAccountDefined = True
				EndIf
			EndIf
		EndIf
	Next

	SetDebugLog("- Min Remain Train Time is " & $iMinRemainTrain)

	Return $iMinRemainTrain

EndFunc   ;==>CheckTroopTimeAllAccount
#ce

Func DisableGUI_AfterLoadNewProfile()
	$g_bGUIControlDisabled = True
	For $i = $g_hFirstControlToHide To $g_hLastControlToHide
		If IsAlwaysEnabledControl($i) Then ContinueLoop
		If $i >= $g_hClanGamesTV And $i < $g_hChkForceBBAttackOnClanGames Then ContinueLoop
		If $i >= $g_hChkForceBBAttackOnClanGames And $i <= $g_hBtnCGSettingsClose Then ContinueLoop
		If BitAND(GUICtrlGetState($i), $GUI_ENABLE) Then GUICtrlSetState($i, $GUI_DISABLE)
	Next
	ControlEnable("", "", $g_hCmbGUILanguage)
	$g_bGUIControlDisabled = False
EndFunc   ;==>DisableGUI_AfterLoadNewProfile

Func aquireSwitchAccountMutex($iSwitchAccountGroup = $g_iCmbSwitchAcc, $bReturnOnlyMutex = False, $bShowMsgBox = False)
	Local $sMsg = GetTranslatedFileIni("MBR GUI Design Child Bot - Profiles", "Msg_SwitchAccounts_InUse", "My Bot with Switch Accounts Group %s is already in use or active.", $iSwitchAccountGroup)
	If $iSwitchAccountGroup Then
		Local $hMutex_Profile = 0
		If $g_ahMutex_SwitchAccountsGroup[0] = $iSwitchAccountGroup And $g_ahMutex_SwitchAccountsGroup[1] Then
			$hMutex_Profile = $g_ahMutex_SwitchAccountsGroup[1]
		Else
			$hMutex_Profile = CreateMutex(StringReplace($g_sProfilePath & "\SwitchAccount.0" & $iSwitchAccountGroup, "\", "-"))
			$g_ahMutex_SwitchAccountsGroup[0] = $iSwitchAccountGroup
			$g_ahMutex_SwitchAccountsGroup[1] = $hMutex_Profile
		EndIf
		If $bReturnOnlyMutex Then
			Return $hMutex_Profile
		EndIf

		If $hMutex_Profile = 0 Then
			; mutex already in use
			SetLog($sMsg, $COLOR_ERROR)
			;SetLog($sMsg, "Cannot switch to profile " & $sProfile, $COLOR_ERROR)
			If $bShowMsgBox Then
				MsgBox(BitOR($MB_OK, $MB_ICONINFORMATION, $MB_TOPMOST), $g_sBotTitle, $sMsg)
			EndIf
		EndIf
		Return $hMutex_Profile <> 0
	EndIf
	Return False
EndFunc   ;==>aquireSwitchAccountMutex

Func releaseSwitchAccountMutex()
	If $g_ahMutex_SwitchAccountsGroup[1] Then
		ReleaseMutex($g_ahMutex_SwitchAccountsGroup[1])
		$g_ahMutex_SwitchAccountsGroup[0] = 0
		$g_ahMutex_SwitchAccountsGroup[1] = 0
		Return True
	EndIf
	Return False
EndFunc   ;==>releaseSwitchAccountMutex

; Checks if "Log in with Supercell ID" boot screen shows up and closes CoC and pushes shared_prefs to fix Or Click on Current account if SCID Connect Mode
Func CheckLoginWithSupercellIDScreen()

	Local $bResult = False

	If Not $g_bRunState Then Return

	; "Log in with Supercell ID" check be there, validate with imgloc
	Local $aiLogin = decodeSingleCoord(FindImageInPlace2("LoginWithSupercellID", $g_sImgLoginWithSupercellID, 100, 595 + $g_iBottomOffsetY, 425, 655 + $g_iBottomOffsetY, True))

	If IsArray($aiLogin) And UBound($aiLogin) = 2 Then
		Local $iAccount = 0 ; default first account on list

		SetLog("Verified Log in with Supercell ID boot screen for login")

		If $g_bChkSharedPrefs Then
			If HaveSharedPrefs($g_sProfileCurrentName) Then
				SetLog("Close CoC and push shared_prefs for Supercell ID screen")
				PushSharedPrefs()
				Return True
			Else
				SetLog("Shared_prefs not pulled.", $COLOR_ERROR)
				SetLog("Please pull shared_prefs in tab Bot/Profiles.", $COLOR_INFO)
				Click($aiLogin[0], $aiLogin[1], 1, 120, "Click Log in with SC_ID")
				If _Sleep(2000) Then Return
				$bResult = True
				If ProfileSwitchAccountEnabled() Then
					$iAccount = _ArraySearch($g_asProfileName, $g_sProfileCurrentName)
				Else
					If $g_bOnlySCIDAccounts Then $iAccount = $g_iWhatSCIDAccount2Use
				EndIf
				Switch SwitchCOCAcc_ClickAccountSCID($bResult, $iAccount, 1, False)
					Case "OK"
						; all good
						Return True
					Case "Error"
						; some problem
					Case "Exit"
						; no $g_bRunState
				EndSwitch
			EndIf
		EndIf

		If $g_bChkSuperCellID Then
			Click($aiLogin[0], $aiLogin[1], 1, 120, "Click Log in with SC_ID")
			If _Sleep(2000) Then Return
			$bResult = True
			If ProfileSwitchAccountEnabled() Then
				$iAccount = _ArraySearch($g_asProfileName, $g_sProfileCurrentName)
			Else
				If $g_bOnlySCIDAccounts Then $iAccount = $g_iWhatSCIDAccount2Use
			EndIf
			Switch SwitchCOCAcc_ClickAccountSCID($bResult, $iAccount, 1, False)
				Case "OK"
					; all good
					Return True
				Case "Error"
					; some problem
				Case "Exit"
					; no $g_bRunState
			EndSwitch
		EndIf
	EndIf
	Return False
EndFunc   ;==>CheckLoginWithSupercellIDScreen

Func SwitchAccountCheckProfileInUse($sNewProfile)
	; now check if profile is used in another group
	Local $sInGroups = ""
	For $g = 1 To 8
		If $g = $g_iCmbSwitchAcc Then ContinueLoop
		; find group this profile belongs to: no switch profile config is saved in config.ini on purpose!
		Local $sSwitchAccFile = $g_sProfilePath & "\SwitchAccount.0" & $g & ".ini"
		If FileExists($sSwitchAccFile) = 0 Then ContinueLoop
		Local $sProfile
		Local $bEnabled
		For $i = 1 To Int(IniRead($sSwitchAccFile, "SwitchAccount", "TotalCocAccount", 0)) + 1
			$bEnabled = IniRead($sSwitchAccFile, "SwitchAccount", "Enable", "") = "1"
			If $bEnabled Then
				$bEnabled = IniRead($sSwitchAccFile, "SwitchAccount", "AccountNo." & $i, "") = "1"
				If $bEnabled Then
					$sProfile = IniRead($sSwitchAccFile, "SwitchAccount", "ProfileName." & $i, "")
					If $sProfile = $sNewProfile Then
						; found profile
						If $sInGroups <> "" Then $sInGroups &= ", "
						$sInGroups &= $g
					EndIf
				EndIf
			EndIf
		Next
	Next

	If $sInGroups Then
		If StringLen($sInGroups) > 2 Then
			$sInGroups = "used in groups " & $sInGroups
		Else
			$sInGroups = "used in group " & $sInGroups
		EndIf
	EndIf

	; test if profile can be aquired
	Local $iAquired = aquireProfileMutex($sNewProfile)
	If $iAquired Then
		If $iAquired = 1 Then
			; ok, release again
			releaseProfileMutex($sNewProfile)
		EndIf

		If $sInGroups Then
			; write to log
			SetLog("Profile " & $sNewProfile & " not active, but " & $sInGroups & "!", $COLOR_ERROR)
			SetSwitchAccLog($sNewProfile & " " & $sInGroups & "!", $COLOR_ERROR)
			Return False
		EndIf

		Return True
	Else
		; write to log
		If $sInGroups Then
			SetLog("Profile " & $sNewProfile & " active and " & $sInGroups & "!", $COLOR_ERROR)
			SetSwitchAccLog($sNewProfile & " active & " & $sInGroups & "!", $COLOR_ERROR)
		Else
			SetLog("Profile " & $sNewProfile & " active in another bot instance!", $COLOR_ERROR)
			SetSwitchAccLog($sNewProfile & " active!", $COLOR_ERROR)
		EndIf
		Return False
	EndIf
EndFunc   ;==>SwitchAccountCheckProfileInUse

Func SCIDragIfNeeded($iSCIDAccount, $bVerifyAcc = True)
	If Not $g_bRunState Then Return

	If $iSCIDAccount < 4 Then Return True

	Local $x1 = Random(444, 748, 1) ; 444 ;
	Local $x2 = Random(444, 748, 1) ; 444 ;
	Local $y = Random(630, 634, 1)

	SetLog("ClickDrag SCID Window(" & $x1 & "," & $y & ")")
	SetLog("ClickDrag SCID Window(" & $x2 & "," & $y & ")")

	ClickDrag($x1, $y, $x2, $y - (94 * ($iSCIDAccount - 3)), 500, True) ; drag a multiple of 90 pixels up for how many accounts down it is

	If $bVerifyAcc Then
		If Not IsSCIDAccComplete($iSCIDAccount) Then Return False
	EndIf

	If _Sleep(1000) Then Return

	Return True
EndFunc   ;==>SCIDragIfNeeded

Func IsSCIDAccComplete($iAccounts = 3)
	SetLog("-----IsSCIDAccComplete----")
	Local $iDistanceBetweenAccounts = 96
	Local $aiHeadCoord
	Local $aiSearchArea[4] = [455, 347, 845, 437]
	Local $bSaveImage = False
	Local $bResult = True
	Local $iLoop = 3

	Local $sFolder = @ScriptDir & "\Profiles\SCID_Errors\"
	Local $j = 0

	; Profile Index offset
	SetDebugLog("$iAccounts : " & $iAccounts)
	If $iAccounts < 4 Then
		Local $j = 0
		$iLoop = $iAccounts
	Else
		Local $j = $iAccounts - 3
	EndIf

	; check the barbarians are in their expected location
	For $i = 0 To $iLoop
		Local $sProfileFolder = @ScriptDir & "\Profiles\" & $g_asProfileName[$i + $j] & "\"

		SetLog("Checking SCID Slot: " & $i)

		$aiHeadCoord = decodeSingleCoord(findImage("IsSCIDAccComplete", $g_sImgSupercellIDSlots, GetDiamondFromArray($aiSearchArea), 1, True))

		If Not IsArray($aiHeadCoord) Or UBound($aiHeadCoord, $UBOUND_ROWS) < 2 Then
			SetSwitchAccLog("Slot: " & $i & " Barbarian Head missing!")
			$bSaveImage = True
			$bResult = False
		Else
			Local $Oldfilename = String($g_asProfileName[$i + $j] & "_0_98.png")
			Local $filename = String($g_asProfileName[$i + $j] & "_0_92.png")
			If FileExists($sProfileFolder & $Oldfilename) Then
				FileMove($sProfileFolder & $Oldfilename, $sProfileFolder & $filename)
				If _Sleep($DELAYRESPOND) Then Return
				FileDelete($sProfileFolder & $Oldfilename)
			EndIf

			SetLog("Looking for " & $sProfileFolder & $filename)

			If FileExists($sProfileFolder & $filename) Then

				SetLog("Found file!")

				Local $aiVillageNameCoord = decodeSingleCoord(findImage("IsSCIDAccComplete", $sProfileFolder & $filename, GetDiamondFromArray($aiSearchArea), 1, True))

				If Not IsArray($aiVillageNameCoord) Or UBound($aiVillageNameCoord, $UBOUND_ROWS) < 2 Then
					SetSwitchAccLog("image: " & $g_asProfileName[$i + $j] & " - missing!")
					SetLog("SCID Account image: " & $g_asProfileName[$i + $j] & " - missing!")
					$bSaveImage = True
					$bResult = False
				Else
					SetSwitchAccLog("image: " & $g_asProfileName[$i + $j] & " - OK!")
					SetLog("SCID Account image: " & $g_asProfileName[$i + $j] & " - OK!")
				EndIf
			Else
				Local $x = $aiHeadCoord[0] - 10
				Local $y = $aiHeadCoord[1] - 24

				; now crop image to have only village name and put in $hClone
				Local $oBitmap = _GDIPlus_BitmapCreateFromHBITMAP($g_hHBitmap2)
				Local $hClone = _GDIPlus_BitmapCloneArea($oBitmap, $x, $y, 65, 18, $GDIP_PXF24RGB)

				_GDIPlus_ImageSaveToFile($hClone, $sProfileFolder & $filename)
				SetSwitchAccLog($g_asProfileName[$i + $j] & " image Stored: ")
				SetLog($g_asProfileName[$i + $j] & " image Stored: " & $filename, $COLOR_SUCCESS)
				_GDIPlus_BitmapDispose($hClone)
				_GDIPlus_BitmapDispose($oBitmap)
			EndIf
		EndIf

		$aiSearchArea[1] = ($aiSearchArea[1] + $iDistanceBetweenAccounts)
		$aiSearchArea[3] = ($aiSearchArea[3] + $iDistanceBetweenAccounts)

		If _Sleep(250) Then Return

		If $i = 3 Then ExitLoop
	Next

	If $bSaveImage = True Then
		If Not FileExists($sFolder) Then DirCreate($sFolder)
		SaveSCIDebugImage("SCID_Errors", False)
	EndIf

	Return $bResult
EndFunc   ;==>IsSCIDAccComplete
