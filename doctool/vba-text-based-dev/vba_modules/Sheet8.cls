(empty macro)
+----------+--------------------+---------------------------------------------+
|Type      |Keyword             |Description                                  |
+----------+--------------------+---------------------------------------------+
|AutoExec  |CbAdjustCmntPos_Clic|Runs when the file is opened and ActiveX     |
|          |k                   |objects trigger events                       |
|Suspicious|Open                |May open a file                              |
|Suspicious|output              |May write to a file (if combined with Open)  |
|Suspicious|FileCopy            |May copy a file                              |
|Suspicious|Call                |May call a DLL using Excel 4 Macros (XLM/XLF)|
|Suspicious|CreateObject        |May create an OLE object                     |
|Suspicious|ExecuteExcel4Macro  |May run an Excel 4 Macro (aka XLM/XLF) from  |
|          |                    |VBA                                          |
|Suspicious|Hex Strings         |Hex-encoded strings were detected, may be    |
|          |                    |used to obfuscate strings (option --decode to|
|          |                    |see all)                                     |
|Suspicious|Base64 Strings      |Base64-encoded strings were detected, may be |
|          |                    |used to obfuscate strings (option --decode to|
|          |                    |see all)                                     |
|Hex String|'\x00\x02\x08\x19'  |00020819                                     |
|Hex String|'\x00\x00\x00\x00\x0|000000000046                                 |
|          |0F'                 |                                             |
|Hex String|'\x00\x02\x08 '     |00020820                                     |
|Base64    |',0]'            |yyyyMMdd                                     |
|String    |                    |                                             |
+----------+--------------------+---------------------------------------------+
