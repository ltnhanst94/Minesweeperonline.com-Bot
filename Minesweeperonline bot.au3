; Author: Lâm Thành Nhân
; Email: ltnhan.st.94@gmail.com

; Chơi trên web: http://minesweeperonline.com
; Zoom: 100%

#Include "..\HandleImgSearch\HandleImgSearch.au3"

HotKeySet("{Esc}", "_Exit")
Func _Exit()
    Exit
EndFunc

; Xác định toạ độ bãi mìn
Local $TopLeftFind = _HandleImgSearch("", @ScriptDir & "\Images\topleft.bmp")
If not @error Then
    Local $TopLeft[2] = [$TopLeftFind[1][0], $TopLeftFind[1][1]]
Else
    Exit MsgBox(16, "Minesweeperonline Bot Error", "Không xác định được cửa sổ game!")
EndIf
Local $BottomRightFind = _HandleImgSearch("", @ScriptDir & "\Images\bottomright.bmp")
If not @error Then
    Local $BottomRight[2] = [$BottomRightFind[1][0] + $BottomRightFind[1][2] - 1, $BottomRightFind[1][1] + $BottomRightFind[1][3] - 1]
Else
    Exit MsgBox(16, "Minesweeperonline Bot Error", "Không xác định được cửa sổ game!")
EndIf

; Khai báo biến
Global $SizeX = $TopLeftFind[1][2]
Global $SizeY = $TopLeftFind[1][3]
Global $Width = $BottomRight[0] - $TopLeft[0] - 3
Global $Height = $BottomRight[1] - $TopLeft[1] - 3
Global $NumberX = $Width/$SizeX
Global $NumberY = $Height/$SizeY

Global $CNum[9]
Global $CB[2], $CD[2], $CF[2], $CN[2], $CO[2]

; Load pixel vào mảng
_LoadPixel()

; Khởi tạo chụp ảnh Global
_GlobalImgInit("", $TopLeft[0] + 2, $TopLeft[1] + 2, $Width, $Height, False, False, 30, 1)

Global $Ar ; Mảng chứa toàn bộ thông tin bãi mìn
Global $IsBeTac = False ; Khi nào bế tắc với cách giải thông thường thì trả về True
Global $BeTacNum = 0 ; Số ô phân vân khi có bế tắc
While 1
    ; Khởi tạo giá trị
    $Ar = ""
    $IsBeTac = False
    $BeTacNum = 0

    ; Tìm ảnh mặt cười - khóc để chơi lại game
	Local $Pos = _HandleImgSearch("", @ScriptDir & "\Images\Cuoi.bmp")
	If @error Then
		$Pos = _HandleImgSearch("", @ScriptDir & "\Images\Thua.bmp")
		If @error Then Exit MsgBox(16, "Minesweeperonline Bot Error", "Không xác định được cửa sổ game!")
	EndIf
	MouseClick("left", $Pos[1][0], $Pos[1][1], 1, 1)
    
    ; Click ngẫu nhiên khi bắt đầu game
	For $i = 0 to 3
		_Click(Random(0, $SizeX - 1, 1), Random(0, $SizeY - 1, 1), "left")
    Next

    ; Bắt đầu vòng lặp chính
    While 1
        _Flag()
        If @error Then ExitLoop
            
        _Open()
        If @error Then ExitLoop
            
        If $IsBeTac = False Then 
            $BeTacNum = 0
        Else
            $BeTacNum += 1
        EndIf

        Sleep(1)
    WEnd
	Sleep(100)
WEnd

; Function đặt cờ
Func _Flag()
    $Ar = _ColorToArray()
    If @error Then Return SetError(1, 0, False)

    For $j = 0 to $NumberY - 1
        For $i = 0 to $NumberX - 1

            ; Kiểm tra boom
            If $Ar[$j][$i] = "b" or $Ar[$j][$i] = "d" Then
                Return SetError(1, 0, False)
            EndIf

            ; Kiểm tra số ô chưa mở xung quanh số đã mở để đặt cờ
            Local $Number = _Convert($Ar[$j][$i])
            If $Number > 0 Then
                Local $OpenCounts = _Count($i, $j, "o")
                Local $FlagCounts = _Count($i, $j, "f")
                
                If UBound($OpenCounts) > 0 and UBound($OpenCounts) = $Number - UBound($FlagCounts) + $BeTacNum Then
                    
                    ; Nếu có bế tắc sẽ click đặt cờ ngẫu nhiên vào 1 trong các ô chưa mở
                    ; Có thể đặt các patterns đặc biệt để xử lý ở đây
                    If $BeTacNum > 0 Then
                        Local $k = Random(0, UBound($OpenCounts) - 1, 1)
                        _Click($OpenCounts[$k][0], $OpenCounts[$k][1], "right")
                        $IsBeTac = True
                        ; Vì chỉ là dự đoán nên sẽ thoát vòng lặp ngay khi đặt được cờ
                        Return 
                    EndIf
                    
                    ; Nếu an toàn sẽ click đặt cờ vào tất cả các ô chưa mở
                    For $k = 0 to UBound($OpenCounts) - 1
                        _Click($OpenCounts[$k][0], $OpenCounts[$k][1], "right")

                        ; Tận dụng 1 lần chạy vòng lặp để đặt nhiều cờ nhất có thể
                        $Ar[$OpenCounts[$k][1]][$OpenCounts[$k][0]] = "f"
                    Next

                    $IsBeTac = False
                EndIf
            EndIf
        Next
    Next   
    
    $IsBeTac = True
EndFunc

; Function mở tất các các ô đủ cờ bao quanh nó
Func _Open()
    For $j = 0 to $NumberY - 1
        For $i = 0 to $NumberX - 1

            ; Kiểm tra boom
            If $Ar[$j][$i] = "b" or $Ar[$j][$i] = "d" Then
                Return SetError(1, 0, False)
            EndIf

            ; Kiểm tra xung quanh số đã đủ cờ và còn ô chưa mở => click
            Local $Number = _Convert($Ar[$j][$i])
            If $Number > 0 and Ubound(_Count($i, $j, "f")) == $Number and Ubound(_Count($i, $j, "o")) > 0 Then
                _Click($i, $j, "middle")
                $IsBeTac = False
            EndIf
        Next
    Next
EndFunc

; Đếm những ô xung quanh $x, $y theo mẫu
Func _Count($x, $y, $flag)
    Dim $Results[0][2]
    For $j = ($y > 0 ? -1 : 0) to ($y < $NumberY - 1 ? 1 : 0)
        For $i = ($x > 0 ? -1 : 0) to  ($x < $NumberX - 1 ? 1 : 0)
            If $Ar[$y + $j][$x + $i] == $flag or ($flag = "num" and _Convert($flag) > 0) Then
                Redim $Results[UBound($Results) + 1][2]
                $Results[UBound($Results) - 1][0]  = $x + $i
                $Results[UBound($Results) - 1][1]  = $y + $j
            EndIf
        Next
    Next
    Return $Results
EndFunc

; Chuyển chuỗi thành số
Func _Convert($Str)
    Local $Result = Number($Str)
    If @error Then 
        If $Str = "f" Then Return -1
        Return 0
    EndIf
    Return $Result
EndFunc

; Chuyển pixel bãi mìn sang mảng
Func _ColorToArray()
    Local $Result[$NumberY][$NumberX]
    _GlobalImgCapture()
    If @error Then Exit MsgBox(16, "Minesweeperonline Bot Error", "Không chụp được ảnh màn hình!")

    For $j = 0 to $NumberY - 1
        For $i = 0 to $NumberX - 1
            If IsArray($Ar) Then
                ; Chỉ lấy lại pixel khi ô đang duyệt chưa mở
                If $Ar[$j][$i] = "o" Then
                    $Result[$j][$i] = _ColorSum($i*$SizeX + $SizeX/2, $j*$SizeY + $SizeY/2)
                Else
                    $Result[$j][$i] = $Ar[$j][$i]
                EndIf
            Else
                ; Nếu là lần duyệt đầu tiên sẽ duyệt lại toàn bộ ô
                ; Sẽ hỗ trợ tìm vị trí có thể mở được cho những phiên bản sau
                $Result[$j][$i] = _ColorSum($i*$SizeX + $SizeX/2, $j*$SizeY + $SizeY/2)
            EndIf
        Next
    Next
    Return $Result
EndFunc

; Chuyển màu thành kí tự
; Hỗ trợ tolerance -> tốc độ sẽ chậm lại
Func _ColorSum1($MiddleX, $MiddleY)
    Local $ColorMiddle = _GlobalGetPixel($MiddleX, $MiddleY)
    Local $ColorTopLeft = _GlobalGetPixel($MiddleX - $SizeX/2 + 1, $MiddleY - $SizeY/2 + 1)
    If _Compare($ColorMiddle, $ColorTopLeft, $CO) Then Return "o"
    If _Compare($ColorMiddle, $ColorTopLeft, $CN) Then Return "n"
    If _Compare($ColorMiddle, $ColorTopLeft, $CF) Then Return "f"
    For $i = 1 to 8
        If _Compare($ColorMiddle, $ColorTopLeft, ($CNum[$i])) Then Return String($i)
    Next
    If _Compare($ColorMiddle, $ColorTopLeft, $CB) Then Return "b"
    If _Compare($ColorMiddle, $ColorTopLeft, $CD) Then Return "d"
    Return "n"
EndFunc

; Chuyển màu thành kí tự
; Tốc độ tối ưu nhất
Func _ColorSum($MiddleX, $MiddleY)
    Local $ColorMiddle = _GlobalGetPixel($MiddleX, $MiddleY)
    Local $ColorTopLeft = _GlobalGetPixel($MiddleX - $SizeX/2 + 1, $MiddleY - $SizeY/2 + 1)
    Local $Result = $ColorMiddle + $ColorTopLeft
    Switch $ColorMiddle + $ColorTopLeft
        Case 24869754
            $Result = "n" ;none
        Case 29212092
            $Result = "o" ;open
        Case 16777215
            $Result = "f" ;flag
        Case 12435132
            $Result = "1"
        Case 12466365
            $Result = "2"
        Case 29146557
            $Result = "3"
        Case 12435000
            $Result = "4"
        Case 20495805
            $Result = "5"
        Case 12466488
            $Result = "6"
        ;~ Case 00000000
        ;~     $Result = "7"
        ;~ Case 00000000
        ;~     $Result = "8"
        Case 12434877
            $Result = "b" ;boom
        Case 16711680
            $Result = "d" ;die
    EndSwitch
        
    Return $Result; + $ColorBottomRight
EndFunc

; Click chuột theo $i, $j
Func _Click($i, $j, $button = "middle")
    MouseClick($button,  $TopLeft[0] + 2 + $i*$SizeX, $TopLeft[1] + 2 + $j*$SizeY, 1, 0)
EndFunc

; So sánh màu
Func _Compare($MidColor, $ConColor, $Array)
    If not _ColorInBounds($MidColor, $Array[0], 20) Then Return False
    If _ColorInBounds($ConColor, $Array[1], 20) Then Return True
    Return False
EndFunc

; Load toàn bộ ảnh thành pixel
Func _LoadPixel()
    For $i = 1 to 8
        $CNum[$i] = _LoadImgToPixel(@ScriptDir & "\Images\" & $i & ".bmp")
    Next
    $CN = _LoadImgToPixel(@ScriptDir & "\Images\none.bmp")
    $CO = _LoadImgToPixel(@ScriptDir & "\Images\open.bmp")
    $CB = _LoadImgToPixel(@ScriptDir & "\Images\boom.bmp")
    $CD = _LoadImgToPixel(@ScriptDir & "\Images\die.bmp")
    $CF = _LoadImgToPixel(@ScriptDir & "\Images\flag.bmp")
EndFunc

; Load pixel từ hình
Func _LoadImgToPixel($Path)
    Local $Bitmap = _GDIPlus_BitmapCreateFromFile($Path)
    Local $Width = _GDIPlus_ImageGetWidth($Bitmap)
    Local $Height = _GDIPlus_ImageGetHeight($Bitmap)

    Local $Mid = _GDIPlus_BitmapGetPixel($Bitmap, $Width/2, $Height/2)
    Local $Con = _GDIPlus_BitmapGetPixel($Bitmap, 1, 1)
    
    Local $Results[2] = ["0x" & Hex($Mid, 6), "0x" & Hex($Con, 6)]

    _GDIPlus_BitmapDispose($Bitmap)
    Return $Results
EndFunc