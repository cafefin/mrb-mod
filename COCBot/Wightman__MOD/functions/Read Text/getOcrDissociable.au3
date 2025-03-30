; #FUNCTION# ====================================================================================================================
; Name ..........: getOcrDissociable
; Description ...: Gets complete value of gold/Elixir/DarkElixir/Trophy/Gem xxx,xxx
; Author ........: Dissociable (2020)
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2020
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
Global $g_bForceDocr = False

; Attack Screen
Func getArmyCamps($x_start, $y_start)
	If $g_bDebugSetLogTrain Then SetLog("getArmyCamps " & $g_sAOverviewTotals, $COLOR_DEBUG)
	Return getOcrAndCaptureDOCR($g_sAOverviewTotals, $x_start, $y_start, 82, 16, True, False)
EndFunc   ;==>getAttackScreenButtons
; End Attack Screen

;~ Func getArmyCampCap($x_start, $y_start, $bNeedCapture = True) ;  -> Gets army camp capacity --> train.au3, and used to read CC request time remaining
;~ 	Return getOcrAndCaptureDOCR($g_sAOverviewTotals, $x_start, $y_start, 82, 16, True, $bNeedCapture)
;~ EndFunc   ;==>getArmyCampCap

;~ Func SpecialOCRCut($sBundle, $iX_start, $iY_start, $iWidth, $iHeight, $bRemoveSpace = Default, $bForceCaptureRegion = Default)
;~ 	Return StringReplace(getOcrAndCaptureDOCR($sBundle, $iX_start, $iY_start, $iWidth, $iHeight, $bRemoveSpace, $bForceCaptureRegion), "#", "")
;~ EndFunc   ;==>getBuilders

#CS - OCR Betas.
Func _getTroopCountSmall($x_start, $y_start, $bNeedNewCapture = Default) ;  -> Gets troop amount on Attack Screen for non-selected troop kind
	If $g_bForceDocr = False Then 
		Return __getTroopCountSmall($x_start, $y_start, $bNeedNewCapture)
	EndIf

	Return SpecialOCRCut($g_sAttackBarDOCRB, $x_start, $y_start-8, 55, 17+8, True, $bNeedNewCapture)
EndFunc   ;==>_getTroopCountSmall

Func _getTroopCountBig($x_start, $y_start, $bNeedNewCapture = Default) ;  -> Gets troop amount on Attack Screen for selected troop kind
	If $g_bForceDocr = False Then 
		Return __getTroopCountBig($x_start, $y_start, $bNeedNewCapture)
	EndIf

	Return SpecialOCRCut($g_sAttackBarDOCRB, $x_start, $y_start-8, 55, 17+8, True, $bNeedNewCapture)
EndFunc   ;==>_getTroopCountBig

Func getArmyCampCap($x_start, $y_start, $bNeedCapture = True) ;  -> Gets army camp capacity --> train.au3, and used to read CC request time remaining
	Return getOcrAndCaptureDOCR($g_sAOverviewTotals, $x_start, $y_start, 82, 16, True, $bNeedCapture)
EndFunc   ;==>getArmyCampCap

Func getTroopCountSmall($x_start, $y_start, $bNeedNewCapture = Default) ;  -> Gets troop amount on Attack Screen for non-selected troop kind
	Return SpecialOCRCut($g_sAttackBarDOCRB, $x_start, $y_start-8, 55, 17+8, True, $bNeedNewCapture)
EndFunc   ;==>getTroopCountSmall

Func getTroopCountBig($x_start, $y_start, $bNeedNewCapture = Default) ;  -> Gets troop amount on Attack Screen for selected troop kind
	Return SpecialOCRCut($g_sAttackBarDOCRB, $x_start, $y_start-8, 55, 17+8, True, $bNeedNewCapture)
EndFunc   ;==>getTroopCountBig
#CE - OCR Betas.

Func getOcrAndCaptureDOCR($sBundle, $iX_start, $iY_start, $iWidth, $iHeight, $bRemoveSpace = Default, $bForceCaptureRegion = Default)
	If $bRemoveSpace = Default Then $bRemoveSpace = False
	If $bForceCaptureRegion = Default Then $bForceCaptureRegion = $g_bOcrForceCaptureRegion
	Static $_hHBitmap = 0
	If $bForceCaptureRegion = True Then
		_CaptureRegion2($iX_start, $iY_start, $iX_start + $iWidth, $iY_start + $iHeight)
	Else
		$_hHBitmap = GetHHBitmapArea($g_hHBitmap2, $iX_start, $iY_start, $iX_start + $iWidth, $iY_start + $iHeight)
		If $g_bDebugSetLogTrain Then SetLog("_hHBitmap Else " & $_hHBitmap, $COLOR_DEBUG)
	EndIf
	If $g_bDebugSetLogTrain Then SetLog("_hHBitmap o ngoai " & $g_bDebugSetLogTrain, $COLOR_DEBUG)

    ;If $g_bDebugOCR = True Then SaveDebugImage("OCRDissociable", $_hHBitmap)
	Local $aResult
	If $_hHBitmap <> 0 Then
		$aResult = getOcrDOCR($_hHBitmap, $sBundle)
		SetLog("getOcrAndCaptureDOCR $aResult IF = " & $aResult, $COLOR_DEBUG)
	Else
		$aResult = getOcrDOCR($g_hHBitmap2, $sBundle)
		SetLog("getOcrAndCaptureDOCR $aResult 2 Else = " & $aResult, $COLOR_DEBUG)

	EndIf
	If $_hHBitmap <> 0 Then
		GdiDeleteHBitmap($_hHBitmap)
	EndIf
	$_hHBitmap = 0
	If ($bRemoveSpace) Then
		$aResult = StringReplace($aResult, "|", "")
		$aResult = StringStripWS($aResult, $STR_STRIPALL)
	Else
		$aResult = StringStripWS($aResult, BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING, $STR_STRIPSPACES))
	EndIf
	SetLog("aResult END " & $aResult, $COLOR_DEBUG)

	Return $aResult
EndFunc   ;==>getOcrAndCaptureDOCR

Func getOcrDOCR(ByRef Const $_hHBitmap, $sBundle)
	Local $aResult = DllCallDOCR("Recognize", "str", "handle", $_hHBitmap, "str", $sBundle)
	If $g_bDOCRDebugImages Then
		DirCreate($g_sProfileTempDebugDOCRPath)
		Local $isBundleFile = StringRight($sBundle, 5) = ".docr"
		Local $sSubDirFolder = ""
		If $isBundleFile Then
			; Remove the Last Backslash from the directory path
			While (StringRight($sBundle, 1) = "\")
				$sBundle = StringTrimRight($sBundle, 1)
			WEnd
			Local $aSplittedPath = StringSplit($sBundle, "\")
			$sSubDirFolder = $aSplittedPath[UBound($aSplittedPath, 1) - 2] & "_" & StringReplace($aSplittedPath[UBound($aSplittedPath, 1) - 1], ".docr", "")
		Else
			Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
			Local $aPathSplit = _PathSplit($sBundle, $sDrive, $sDir, $sFileName, $sExtension)
			Local $aSplittedPath = StringSplit(StringTrimRight($sBundle, StringLen($sFileName & $sExtension) + 1), "\")
			$sSubDirFolder = $aSplittedPath[UBound($aSplittedPath, 1) - 1] & "_" & $sFileName
		EndIf
		Local $sDir
		If StringRight($g_sProfileTempDebugDOCRPath, 1) <> "\" Then
			$sDir = $g_sProfileTempDebugDOCRPath & "\"
		Else
			$sDir = $g_sProfileTempDebugDOCRPath
		EndIf
		$sDir &= $sSubDirFolder & "\"
		DirCreate($sDir)
		
		Local $sDateTime = @YEAR & "-" & @MON & "-" & @MDAY & "_" & @HOUR & "-" & @MIN & "-" & @SEC & "." & @MSEC
		Local $hBitmap_debug = _GDIPlus_BitmapCreateFromHBITMAP($_hHBitmap)
		Local $sFilePath = $sDir & StringRegExpReplace(StringReplace($aResult, "|", "-"), "[\[\]/\|\:\?""\*\\<>]", "") & ".png"
		SetDebugLog("Save DOCR Debug Image: " & $sFilePath)
		_GDIPlus_ImageSaveToFile($hBitmap_debug, $sFilePath)
		_GDIPlus_BitmapDispose($hBitmap_debug)
	EndIf
	Return $aResult
EndFunc   ;==>getOcrDOCR