Sub AggregateData()
    Dim sendTo As Integer, getFrom As Integer, x As Integer, row As Integer, foulSpot As Integer, lastColumn As Integer, struggled As Integer, cards As Integer
    For row = 2 To numRows("Input") - 1
        'Starts With Team Number
        getFrom = 5
        sendTo = 1
        sendTo = copy(getFrom, sendTo, row)
        'Skip Two Spots For Points
        sendTo = sendTo + 2
        'Auto Scoring
        getFrom = getFrom + 1
        sendTo = gamePieces(getFrom, sendTo, row)
        'Exited Community
        getFrom = getFrom + 1
        sendTo = copy(getFrom, sendTo, row)
        'Auto Docking
        getFrom = getFrom + 1
        sendTo = docking(getFrom, sendTo, row, True)
        'Teleop Scoring
        getFrom = getFrom + 1
        sendTo = gamePieces(getFrom, sendTo, row)
        'Saving the position from which to grab fouls
        foulSpot = getFrom + 1
        getFrom = getFrom + 4
        'Final Status
        getFrom = getFrom + 1
        sendTo = docking(getFrom, sendTo, row, False)
        'Struggled
        getFrom = getFrom + 1
        struggled = sendTo
        sendTo = copy(getFrom, sendTo, row)
        'Total Docked Bots
        getFrom = getFrom + 1
        sendTo = copy(getFrom, sendTo, row)
        'Driver Skill
        getFrom = getFrom + 1
        sendTo = skill(getFrom, sendTo, row)
        'Defense Rating
        getFrom = getFrom + 1
        sendTo = skill(getFrom, sendTo, row)
        'Was Defended
        getFrom = getFrom + 1
        sendTo = copy(getFrom, sendTo, row)
        'Died
        getFrom = getFrom + 1
        sendTo = copy(getFrom, sendTo, row)
        'Tippy
        getFrom = getFrom + 1
        sendTo = copy(getFrom, sendTo, row)
        'Fouls
        getFrom = foulSpot
        sendTo = copy(getFrom, sendTo, row)
        'Tech Fouls
        getFrom = getFrom + 1
        sendTo = copy(getFrom, sendTo, row)
        'Yellow Cards
        getFrom = getFrom + 1
        cards = sendTo
        sendTo = copy(getFrom, sendTo, row)
        'Red Cards
        getFrom = getFrom + 1
        sendTo = copy(getFrom, sendTo, row)
        lastColumn = sendTo - 1
        'AutoPoints
        sendTo = 2
        sendTo = AutoPoints("Numerical", row, sendTo)
        'Points
        sendTo = Points("Numerical", row, sendTo)
    Next row
    writeTeams
    For x = 2 To sendTo - 1
        Select Case (x):
            Case struggled:
                getFrom = averageColumn(x, x - 1)
            Case cards:
                sumColumn (x)
            Case cards + 1:
                sumColumn (x)
            Case Else:
                getFrom = averageColumn(x, x)
            End Select
    Next x
End Sub
Sub checkErrors()
    checkScoring
    duplicateStations
    checkNumEntries
End Sub
Function sumColumn(column As Integer)
    Dim row As Integer, val As Double
    For row = 2 To numRows("Average") - 1
        val = 0
        team = Worksheets("Average").Range("A" & row).Value
        For x = 2 To numRows("Numerical")
            If Worksheets("Numerical").Range("A" & x).Value = team Then
                If Not Worksheets("Numerical").Range(columnLetter(column) & x).Value < 0 Then
                    If Not Worksheets("Numerical").Range(columnLetter(tiedToColumn) & x).Value < 0 Then
                        val = val + Worksheets("Numerical").Range(columnLetter(column) & x).Value
                    End If
                End If
            End If
        Next x
        Worksheets("Average").Range(columnLetter(column) & row).Value = val
    Next row
End Function
Sub syncPit()
    Dim rows As Integer, teamRow, hasTeam As Boolean, team, rng
    For rows = 2 To numRows("PitScouting")
        hasTeam = False
        team = Worksheets("PitScouting").Range("B" & rows).Value
        For teamRow = 2 To numRows("Average")
            If Worksheets("Average").Range("A" & teamRow).Value = team Then
                hasTeam = True
                Exit For
            End If
        Next teamRow
    If hasTeam Then
        rng = Sheets("PitScouting").Range("A" & rows & ":R" & rows)
        Sheets("Average").Range("AD" & teamRow) = rng
    End If
    Next rows
End Sub
Sub writeLinks()
    Dim links As Double, team As Integer, eventName As String, row As Integer, json As Object, x As Integer
    eventName = InputBox("What is the event key?(don't include a year)")
    For row = 2 To numRows("Average") - 1
        team = Worksheets("Average").Range("A" & row).Value
        links = GetPolarForecastData(eventName, team)("linkPoints")
        Worksheets("Average").Range("AD" & row).Value = links
        Worksheets("Average").Range("C" & row).Value = Worksheets("Average").Range("C" & row).Value + links
    Next row
End Sub
Function GetPolarForecastData(eventKey As String, team As Integer) As Object
    ' Define variables
    Dim requestUrl As String
    Dim http As New MSXML2.XMLHTTP
    Dim responseText As String
    Dim json As Object
    
    ' Construct request URL
    requestUrl = "https://polarforecast.azurewebsites.net/2023/" & eventKey & "/frc" & team & "/stats"
    
    ' Make HTTP request
    http.Open "GET", requestUrl, False
    http.send
    
    ' Get response text
    responseText = http.responseText
    'MsgBox responseText
    
    ' Parse response text as JSON object
    Set json = JsonConverter.ParseJson(responseText)
    
    ' Return JSON object
    Set GetPolarForecastData = json
End Function
Sub checkScoring()
    Dim tableexists As Boolean, max As Integer, tableName As String, table As ListObject, bluestr As String, redstr As String, redPos() As String, bluePos() As String, pos As Variant, checkPos As Variant, row As ListRow, tbl As ListObject, sht As Worksheet, x As Integer, y As Integer, z As Integer
    tableName = "ScoutingData"
    tableexists = False
    'Loop through each sheet and table in the workbook
    For Each sht In ThisWorkbook.Worksheets
        For Each tbl In sht.ListObjects
            If tbl.Name = tableName Then
                tableexists = True
                Set table = tbl
                Set ws = sht
            End If
        Next tbl
    Next sht
    If tableexists Then
        'Set table = ws.ListObjects(tableName)
    Else
        MsgBox ("No Table Found")
        Exit Sub
    End If
    max = Application.WorksheetFunction.max(table.ListColumns("matchNumber").Range)
    For Each row In table.ListRows
        bluestr = ""
        redstr = ""
        For Each checkRow In table.ListRows
            If row.Range(table.ListColumns("matchNumber").Index).Value = checkRow.Range(table.ListColumns("matchNumber").Index).Value Then
            If Not IsNull(checkRow) Then
                If InStr(row.Range(table.ListColumns("robot").Index).Value, "r") Then
                    If Not IsEmpty(checkRow.Range(table.ListColumns("autoScoring").Index).Value) Then
                        redstr = redstr & checkRow.Range(table.ListColumns("autoScoring").Index).Value & ","
                    End If
                    If Not IsEmpty(row.Range(table.ListColumns("teleopScoring").Index).Value) Then
                        redstr = redstr & checkRow.Range(table.ListColumns("teleopScoring").Index).Value & ","
                    End If
                Else
                    If Not IsEmpty(checkRow.Range(table.ListColumns("autoScoring").Index).Value) Then
                        bluestr = bluestr & checkRow.Range(table.ListColumns("autoScoring").Index).Value & ","
                    End If
                    If Not IsEmpty(checkRow.Range(table.ListColumns("teleopScoring").Index).Value) Then
                        bluestr = bluestr & checkRow.Range(table.ListColumns("teleopScoring").Index).Value & ","
                    End If
                End If
            End If
            End If
        Next checkRow
        If Not bluestr = "" Then
        z = Len(bluestr) - Len(Replace(bluestr, ",", ""))
        ReDim bluePos(z + 1)
        bluePos = Split(bluestr, ",")
        z = 0
        For Each pos In bluePos
            For Each checkPos In bluePos
                If Not pos = "" Or Not checkPos = "" Then
                    If pos = checkPos Then
                        z = z + 1
                    End If
                End If
            Next checkPos
        Next pos
        z = z - ArrayLen(bluePos) + 1
        z = z / 2
        If z > 0 Then
            row.Range(table.ListColumns("autoScoring").Index).Interior.Color = RGB(255, 49, 49)
            row.Range(table.ListColumns("teleopScoring").Index).Interior.Color = RGB(255, 49, 49)
            row.Range(table.ListColumns("autoScoring").Index).Borders.Color = RGB(255, 49, 49)
            row.Range(table.ListColumns("teleopScoring").Index).Borders.Color = RGB(255, 49, 49)
        End If
        End If
        If Not redstr = "" Then
        z = Len(redstr) - Len(Replace(redstr, ",", ""))
        ReDim redPos(z + 1)
        redPos = Split(redstr, ",")
        z = 0
        For Each pos In redPos
            For Each checkPos In redPos
                If Not pos = "" Or Not checkPos = "" Then
                    If pos = checkPos Then
                        z = z + 1
                    End If
                End If
            Next checkPos
        Next pos
        z = z - ArrayLen(redPos)
        If z > 0 Then
            row.Range(table.ListColumns("autoScoring").Index).Interior.Color = RGB(255, 49, 49)
            row.Range(table.ListColumns("teleopScoring").Index).Interior.Color = RGB(255, 49, 49)
            row.Range(table.ListColumns("autoScoring").Index).Borders.Color = RGB(255, 49, 49)
            row.Range(table.ListColumns("teleopScoring").Index).Borders.Color = RGB(255, 49, 49)
        End If
        End If
    Next row
End Sub
Sub highlightEntries()
    Dim tableexists As Boolean, max As Integer
    Dim tableName As String, table As ListObject
    Dim row As ListRow
    tableName = "ScoutingData"
    tableexists = False
    Dim tbl As ListObject
    Dim sht As Worksheet
    Dim x As Integer, y As Integer
    'Loop through each sheet and table in the workbook
    For Each sht In ThisWorkbook.Worksheets
        For Each tbl In sht.ListObjects
            If tbl.Name = tableName Then
                tableexists = True
                Set table = tbl
                Set ws = sht
            End If
        Next tbl
    Next sht
    If tableexists Then
        'Set table = ws.ListObjects(tableName)
    Else
        MsgBox ("No Table Found")
        Exit Sub
    End If
    For Each row In table.ListRows
        y = row.Range(table.ListColumns("matchNumber").Index).Value Mod 5
                Select Case (y)
                    Case 0:
                        row.Range.Borders.Color = RGB(255, 255, 102)
                        row.Range.Interior.Color = RGB(255, 255, 102)
                    Case 1:
                        row.Range.Borders.Color = RGB(255, 178, 102)
                        row.Range.Interior.Color = RGB(255, 178, 102)
                    Case 2:
                        row.Range.Borders.Color = RGB(102, 178, 255)
                        row.Range.Interior.Color = RGB(102, 178, 255)
                    Case 3:
                        row.Range.Borders.Color = RGB(102, 255, 102)
                        row.Range.Interior.Color = RGB(102, 255, 102)
                    Case 4:
                        row.Range.Borders.Color = RGB(255, 153, 255)
                        row.Range.Interior.Color = RGB(255, 153, 255)
                End Select
    Next row
End Sub
Sub duplicateStations()
    Dim tableexists As Boolean, max As Integer
    Dim tableName As String, table As ListObject
    Dim rows() As ListRow
    tableName = "ScoutingData"
    tableexists = False
    Dim tbl As ListObject
    Dim sht As Worksheet
    Dim x As Integer, y As Integer
    'Loop through each sheet and table in the workbook
    For Each sht In ThisWorkbook.Worksheets
        For Each tbl In sht.ListObjects
            If tbl.Name = tableName Then
                tableexists = True
                Set table = tbl
                Set ws = sht
            End If
        Next tbl
    Next sht
    If tableexists Then
        'Set table = ws.ListObjects(tableName)
    Else
        MsgBox ("No Table Found")
        Exit Sub
    End If
    Dim row As ListRow, checkRow As ListRow
    For Each row In table.ListRows
        For Each checkRow In table.ListRows
            If Not checkRow.Range.Address = row.Range.Address Then
                If checkRow.Range(table.ListColumns("matchNumber").Index).Value = row.Range(table.ListColumns("matchNumber").Index).Value Then
                    If checkRow.Range(table.ListColumns("robot").Index).Value = row.Range(table.ListColumns("robot").Index).Value Then
                        row.Range(table.ListColumns("robot").Index).Interior.Color = RGB(255, 49, 49)
                        row.Range(table.ListColumns("robot").Index).Borders.Color = RGB(255, 49, 49)
                    End If
                    If checkRow.Range(table.ListColumns("teamNumber").Index).Value = row.Range(table.ListColumns("teamNumber").Index).Value Then
                        row.Range(table.ListColumns("teamNumber").Index).Interior.Color = RGB(255, 49, 49)
                        row.Range(table.ListColumns("teamNumber").Index).Borders.Color = RGB(255, 49, 49)
                    End If
                End If
            End If
        Next checkRow
    Next row
End Sub
Sub checkNumEntries()
    Dim tableexists As Boolean, max As Integer, z As Range, a As Range
    Dim tableName As String, table As ListObject
    Dim rows() As ListRow
    tableName = "ScoutingData"
    tableexists = False
    Dim tbl As ListObject
    Dim sht As Worksheet
    Dim x As Integer, y As Integer
    'Loop through each sheet and table in the workbook
    For Each sht In ThisWorkbook.Worksheets
        For Each tbl In sht.ListObjects
            If tbl.Name = tableName Then
                tableexists = True
                Set table = tbl
                Set ws = sht
            End If
        Next tbl
    Next sht
    If tableexists Then
        'Set table = ws.ListObjects(tableName)
    Else
        MsgBox ("No Table Found")
        Exit Sub
    End If
    Dim row As ListRow, checkRow As ListRow
    max = Application.WorksheetFunction.max(table.ListColumns("matchNumber").Range)
    For Each row In table.ListRows
        For Each checkRow In table.ListRows
            If checkRow.Range(table.ListColumns("matchNumber").Index).Value = row.Range(table.ListColumns("matchNumber").Index).Value Then
                x = x + 1
            End If
        Next checkRow
        If Not x = 6 Then
            row.Range(table.ListColumns("matchNumber").Index).Interior.Color = RGB(255, 49, 49)
            row.Range(table.ListColumns("matchNumber").Index).Borders.Color = RGB(255, 49, 49)
        End If
        x = 0
    Next row
End Sub
Function writeTeams()
    Dim row As Integer, rows As Integer, team, checkRow As Integer, switches As Integer, hold As Variant, temp As Variant
    Worksheets("Numerical").Range("A2:A" & (numRows("Numerical") - 1)).copy Worksheets("Average").Range("A2")
    rows = numRows("Average") + 1
    For row = 2 To rows
        team = Worksheets("Average").Range("A" & row).Value
        For checkRow = row + 1 To rows
            If Worksheets("Average").Range("A" & checkRow).Value = team Then
                Worksheets("Average").Range("A" & checkRow).Value = Null
            End If
        Next checkRow
    Next row
    switches = 1
    Do While Not switches = 0
        switches = 0
        For row = 2 To rows
            If Worksheets("Average").Range("A" & row).Value < Worksheets("Average").Range("A" & (row + 1)).Value Then
                hold = Worksheets("Average").Range("A" & row).Value
                temp = Worksheets("Average").Range("A" & (row + 1)).Value
                Worksheets("Average").Range("A" & row).Value = temp
                Worksheets("Average").Range("A" & (row + 1)).Value = hold
                switches = switches + 1
            End If
        Next row
    Loop
End Function
Function Points(sheet As String, row As Integer, sendTo As Integer) As Integer
    Dim val As Double, x As Double, y As Double
    x = Worksheets(sheet).Range("F" & row).Value
    y = Worksheets(sheet).Range("D" & row).Value
    If x < 0 Then
        x = 0
    End If
    If y < 0 Then
        y = 0
    End If
    val = val + 6 * (x + y)
    x = Worksheets(sheet).Range("G" & row).Value
    y = Worksheets(sheet).Range("F" & row).Value
    If x < 0 Then
        x = 0
    End If
    If y < 0 Then
        y = 0
    End If
    val = val + 4 * (x + y)
    x = Worksheets(sheet).Range("I" & row).Value
    If x < 0 Then
        x = 0
    End If
    val = val + 3 * x
    x = Worksheets(sheet).Range("J" & row).Value
    If x < 0 Then
        x = 0
    End If
    val = val + 3 * x
    x = Worksheets(sheet).Range("K" & row).Value
    If x < 0 Then
        x = 0
    End If
    val = val + 8 * x
    x = Worksheets(sheet).Range("L" & row).Value
    y = Worksheets(sheet).Range("M" & row).Value
    If x < 0 Then
        x = 0
    End If
    If y < 0 Then
        y = 0
    End If
    val = val + 5 * (x + y)
    x = Worksheets(sheet).Range("N" & row).Value
    y = Worksheets(sheet).Range("O" & row).Value
    If x < 0 Then
        x = 0
    End If
    If y < 0 Then
        y = 0
    End If
    val = val + 3 * (x + y)
    x = Worksheets(sheet).Range("P" & row).Value
    If x < 0 Then
        x = 0
    End If
    val = val + 2 * x
    x = Worksheets(sheet).Range("U" & row).Value
    If x < 0 Then
        x = 0
    End If
    val = val + 6 * x
    Worksheets(sheet).Range(columnLetter(sendTo) & row).Value = val
    Points = sendTo + 1
End Function
Function AutoPoints(sheet As String, row As Integer, sendTo As Integer) As Integer
    Dim val As Double, x As Double, y As Double
    x = Worksheets(sheet).Range("F" & row).Value
    y = Worksheets(sheet).Range("D" & row).Value
    If x < 0 Then
        x = 0
    End If
    If y < 0 Then
        y = 0
    End If
    val = val + 6 * (x + y)
    x = Worksheets(sheet).Range("G" & row).Value
    y = Worksheets(sheet).Range("F" & row).Value
    If x < 0 Then
        x = 0
    End If
    If y < 0 Then
        y = 0
    End If
    val = val + 4 * (x + y)
    x = Worksheets(sheet).Range("I" & row).Value
    If x < 0 Then
        x = 0
    End If
    val = val + 3 * x
    x = Worksheets(sheet).Range("J" & row).Value
    If x < 0 Then
        x = 0
    End If
    val = val + 3 * x
    x = Worksheets(sheet).Range("K" & row).Value
    If x < 0 Then
        x = 0
    End If
    val = val + 8 * x
    Worksheets(sheet).Range(columnLetter(sendTo) & row).Value = val
    AutoPoints = sendTo + 1
End Function
Function averageColumn(column As Integer, tiedToColumn As Integer) As Integer
    Dim row As Integer, val As Double, div As Integer, team, x
    For row = 2 To numRows("Average") - 1
        val = 0
        div = 0
        team = Worksheets("Average").Range("A" & row).Value
        For x = 2 To numRows("Numerical")
            If Worksheets("Numerical").Range("A" & x).Value = team Then
                If Not Worksheets("Numerical").Range(columnLetter(column) & x).Value < 0 Then
                    If Not Worksheets("Numerical").Range(columnLetter(tiedToColumn) & x).Value < 0 Then
                        val = val + Worksheets("Numerical").Range(columnLetter(column) & x).Value
                        div = div + 1
                    End If
                End If
            End If
        Next x
        If div = 0 Then
            Worksheets("Average").Range(columnLetter(column) & row).Value = 0
        Else
            Worksheets("Average").Range(columnLetter(column) & row).Value = val / div
        End If
    Next row
End Function
Function numRows(Worksheet As String) As Integer
    Dim repeat As Boolean
    repeat = True
    numRows = 1
    Do While repeat
        If IsEmpty(Worksheets(Worksheet).Range("A" & numRows)) Then
            repeat = False
        Else
        numRows = numRows + 1
        End If
    Loop
End Function
Function gamePieces(getFrom As Integer, sendTo As Integer, row As Integer) As Integer
    Dim hiCo As Integer, hiCu As Integer, miCo As Integer, miCu As Integer, loPi As Integer, numPieces As Integer, pieces As Variant, piece As Variant, modNumber As Integer, cube As Boolean, high As Boolean, low As Boolean, mid As Boolean
    pieces = Split(Worksheets("Input").Range(columnLetter(getFrom) & row).Value, ",")
    numPieces = ArrayLen(pieces)
    For Each piece In pieces
        modNumber = (piece + 1) Mod 3
        cube = (modNumber = 0)
        If piece < 10 Then
            If cube Then
                hiCu = hiCu + 1
            Else
                hiCo = hiCo + 1
            End If
        Else
            If piece > 18 Then
                loPi = loPi + 1
            Else
                If cube Then
                    miCu = miCu + 1
                Else
                    miCo = miCo + 1
                End If
            End If
        End If
    Next piece
    Worksheets("Numerical").Range(columnLetter(sendTo) & row).Value = hiCo
    sendTo = sendTo + 1
    Worksheets("Numerical").Range(columnLetter(sendTo) & row).Value = hiCu
    sendTo = sendTo + 1
    Worksheets("Numerical").Range(columnLetter(sendTo) & row).Value = miCo
    sendTo = sendTo + 1
    Worksheets("Numerical").Range(columnLetter(sendTo) & row).Value = miCu
    sendTo = sendTo + 1
    Worksheets("Numerical").Range(columnLetter(sendTo) & row).Value = loPi
    sendTo = sendTo + 1
    Worksheets("Numerical").Range(columnLetter(sendTo) & row).Value = numPieces
    sendTo = sendTo + 1
    gamePieces = sendTo
End Function
Function copy(getFrom As Integer, sendTo As Integer, row As Integer) As Integer
    Dim val As Variant
    val = Worksheets("Input").Range(columnLetter(getFrom) & row).Value
    Worksheets("Numerical").Range(columnLetter(sendTo) & row).Value = val
    copy = sendTo + 1
End Function
Function docking(getFrom As Integer, sendTo As Integer, row As Integer, auto As Boolean) As Integer
    Dim Value As Variant
    Value = Worksheets("Input").Range(columnLetter(getFrom) & row).Value
    Select Case (Value)
        Case "p":
            Value = 1 / 3
        Case "e":
            If auto Then
                Value = 1.5
            Else
                Value = 5 / 3
            End If
        Case "d":
            Value = 1
        Case "x":
            Value = -1
        Case "a":
            Value = 0
    End Select
    Worksheets("Numerical").Range(columnLetter(sendTo) & row).Value = Value
    docking = sendTo + 1
End Function
Function skill(getFrom As Integer, sendTo As Integer, row As Integer) As Integer
    Dim val As Variant, x As Double
    val = Worksheets("Input").Range(columnLetter(getFrom) & row).Value
    Select Case (val)
        Case "x":
            x = -1
        Case "b":
            x = 0
        Case "a":
            x = 1
        Case "aa":
            x = 2
    End Select
    Worksheets("Numerical").Range(columnLetter(sendTo) & row).Value = x
    skill = sendTo + 1
End Function
Public Function ArrayLen(arr As Variant) As Integer
    ArrayLen = UBound(arr) - LBound(arr) + 1
End Function
Function columnLetter(columnNumber As Integer) As String
    columnLetter = Split(Cells(1, columnNumber).Address, "$")(1)
End Function
Sub prcss1QRCodeInput()
    saveData (getInput())
End Sub
Sub prcss6QRCodeInput()
    saveData (getInput())
    saveData (getInput())
    saveData (getInput())
    saveData (getInput())
    saveData (getInput())
    saveData (getInput())
    checkNumEntries
End Sub
Public Function getInput()
    getInput = InputBox("Scan QR Code", "Match Scouting Input")
End Function
Sub testSaveData()
    saveData ("s=fff;e=1234;l=qm;m=1234;r=r1;t=1234;as=;ae=Y;al=2;ao=2;ai=1;aa=Y;at=N;ax=Y;lp=2;op=1;ip=3;rc=pass;f=0;pc=pass;ss=;c=pass;b=N;ca=x;cb=x;cs=slow;p=N;ds=x;dr=x;pl=x;tr=N;wd=N;if=N;d=N;to=N;be=N;cf=N")
End Sub
Sub saveData(inp As String)
    Dim fields
    Dim par() As String
    Dim Value
    Dim Key
    Dim table As ListObject
    Dim ws As Worksheet
    Set ws = ActiveSheet
    Dim mapper
    Set mapper = CreateObject("Scripting.Dictionary")
    Dim data
    Set data = CreateObject("Scripting.Dictionary")
    Dim tableName As String
    tableName = "ScoutingData"
    ' Set up map
    ' Fields for every year
    mapper.Add "s", "scouter"
    mapper.Add "e", "eventCode"
    mapper.Add "l", "matchLevel"
    mapper.Add "m", "matchNumber"
    mapper.Add "r", "robot"
    mapper.Add "t", "teamNumber"
    mapper.Add "as", "autoStartPosition"
    mapper.Add "asg", "autoScoring"
    mapper.Add "ec", "exitedCommunity"
    mapper.Add "ad", "autoDocking"
    mapper.Add "agpa", "autoAttemptedPieces"
    mapper.Add "gph", "gamePiecesStillWithBot"
    mapper.Add "tct", "Cycles"
    mapper.Add "tsg", "teleopScoring"
    mapper.Add "dt", "dockingTimer"
    mapper.Add "fs", "finalStatus"
    mapper.Add "stg", "struggled"
    mapper.Add "dn", "totalDockedBots"
    mapper.Add "ds", "driverSkill"
    mapper.Add "dr", "defenseRating"
    mapper.Add "wd", "wasDefended"
    mapper.Add "die", "died/immobilized"
    mapper.Add "fl", "fouls"
    mapper.Add "tf", "techFouls"
    mapper.Add "yc", "yellow"
    mapper.Add "rc", "red"
    mapper.Add "tip", "Tippy?"
    mapper.Add "co", "Comments"
    ' Additional custom mapping
    'mapper.Add "f", "fouls"
    'mapper.Add "c", "climb"
    'mapper.Add "dr", "defenseRating"
    'mapper.Add "d", "died"
    'mapper.Add "to", "tippedOver"
    'mapper.Add "cf", "cardFouls"
    'mapper.Add "co", "comments"
    If inp = "" Then
        Exit Sub
    End If
    'MsgBox (inp)
    fields = Split(inp, ";")
    If ArrayLen(fields) > 0 Then
        Dim i As Integer
        Dim str
        i = 0
        For Each str In fields
            par = Split(str, "=")
            Key = par(0)
            Value = par(1)
            If mapper.Exists(Key) Then
                Key = mapper(Key)
            End If
            data.Add Key, Value
        Next
        tableexists = False
        Dim tbl As ListObject
        Dim sht As Worksheet
        'Loop through each sheet and table in the workbook
        For Each sht In ThisWorkbook.Worksheets
            For Each tbl In sht.ListObjects
                If tbl.Name = tableName Then
                    tableexists = True
                    Set table = tbl
                    Set ws = sht
                End If
            Next tbl
        Next sht
        If tableexists Then
            'Set table = ws.ListObjects(tableName)
        Else
            Dim tablerange As Range
            ws.ListObjects.Add(xlSrcRange, Range("A1:AO1"), , xlYes).Name = tableName
            i = 0
            Set table = ws.ListObjects(tableName)
            For Each Key In data.Keys
                table.Range(i + 1) = Key
                i = i + 1
            Next
        End If
        Dim newrow As ListRow
        Set newrow = table.ListRows.Add
        For Each str In data.Keys
            newrow.Range(table.ListColumns(str).Index) = data(str)
        Next
        Dim x As Integer
        x = newrow.Range(table.ListColumns("matchNumber").Index).Value Mod 5
        Select Case (x)
            Case 0:
                newrow.Range.Interior.Color = RGB(255, 255, 102)
            Case 1:
                newrow.Range.Interior.Color = RGB(255, 178, 102)
            Case 2:
                newrow.Range.Interior.Color = RGB(102, 178, 255)
            Case 3:
                newrow.Range.Interior.Color = RGB(102, 255, 102)
            Case 4:
                newrow.Range.Interior.Color = RGB(255, 153, 255)
        End Select
    End If
End Sub
Sub SecondPick()
    Dim sheet As String, row As Integer, sendTo As String, val As Double
    sheet = "average"
    sendTo = "AE"
    For row = 2 To numRows(sheet)
        val = val - 20 * Worksheets(sheet).Range("AC" & row).Value
        val = val + Worksheets(sheet).Range("C" & row).Value
        val = val + 2 * Worksheets(sheet).Range("AD" & row).Value
        val = val - 2 * Worksheets(sheet).Range("Z" & row).Value
        val = val - 5 * Worksheets(sheet).Range("AA" & row).Value
        val = val - 10 * Worksheets(sheet).Range("AB" & row).Value
        val = val - 3.5 * Worksheets(sheet).Range("X" & row).Value
        val = val + 2 * Worksheets(sheet).Range("R" & row).Value
        val = val + 5 * Worksheets(sheet).Range("J" & row).Value
        val = val + 5 * Worksheets(sheet).Range("K" & row).Value
        val = val + 5 * Worksheets(sheet).Range("V" & row).Value
        val = val + 5 * Worksheets(sheet).Range("W" & row).Value
        Worksheets(sheet).Range(sendTo & row).Value = val
    Next row
End Sub