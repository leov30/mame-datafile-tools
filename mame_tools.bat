@echo off

cd /d "%~dp0"
if "%~1"=="" echo Only drag and drop datafiles&pause&exit
if not exist "%~1" echo Change the name of the file and try agian&pause&exit
if not exist "_bin\xidel.exe" echo This script needs _bin\xidel.exe to work&pause&exit

set "_file=%~n1"

if not exist output md output
if not exist _bin md _bin
if not exist _temp (md _temp)else (del _temp\*.lst 2>nul)

if "%~x1"==".ini" goto :catver_menu

if not "%~x1"==".dat" (
	if not "%~x1"==".xml" echo This file wasn't identified as a datafile&pause&exit
)

REM //mamediff, still check the 1st datafile 
if not "%~2"=="" (
	if not exist "_bin\mamediff.exe" echo. _bin\mamediff.exe was not found&pause&exit
	if not exist "_bin\datutil.exe" echo. _bin\datutil.exe was not found&pause&exit 
	goto :mamediff_menu
)

cls&echo. Getting datafile information... 

REM //remove this because it breaks xidel
_bin\xidel -s "%~1" -e "replace( $raw, '^<!DOCTYPE mame \[.+?\]>$', '', 'ms')" >_temp\temp.dat

for /f "delims=" %%g in ('_bin\xidel -s --output-format=cmd _temp\temp.dat 
		-e "_tag:=matches( $raw, '<machine name=\""\w+\""')"
		-e "_drv:=matches( $raw, '<driver status=\""\w+\""')"
		-e "_drv_old:=matches( $raw, '<driver status=\""protection\""')"
		-e "_src:=matches( $raw, 'sourcefile=\""[\w./-]+\""')"
		-e "_dev:=matches( $raw, 'isdevice=\""yes\""')"
		-e "_isbios:=matches( $raw, 'isbios=\""yes\""')"') do %%g

set "_sourcefile="
if %_tag%==true (set "_tag=machine")else (set "_tag=game")
if %_isbios%==true (set "_isbios=@isbios='yes'")else (set "_isbios=@runnable='no'")
if %_src%==true set "_sourcefile=@sourcefile and "

REM //cloneof table for the current datafile
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@cloneof]/(@name|@cloneof)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(\w+)$', '$1=$2', 'm')" >_temp\cloneof.1
del _temp\temp.1

REM //bios plain list
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_isbios%]/@name" >_temp\bios.1


:main_menu
cls
echo. ====== Datafile Options =============
echo.
echo. 1. Make Gamelist form the datafile
echo. 2. Make Batch scrip from the datafile
echo. 3. Cleanup and exit script
echo.
choice /n /c:123 /m "Enter Option:"
echo.
if %errorlevel% equ 1 goto :list_menu2
if %errorlevel% equ 2 goto :batch_menu
if %errorlevel% equ 3 (
	del _temp\temp.dat & rd _temp
	exit

)
goto :main_menu

REM ================================== endof main menu ====================================

:build_html

(echo ^<^!DOCTYPE html^>
echo ^<html^>
echo ^<head^>
echo    ^<title^>"test"^</title^>
echo 	^<style^>
echo 		body { background-color:powderblue; }
echo 	^</style^>
echo ^</head^>
echo ^<body^>) >_temp\main.html


_bin\xidel -s _temp\temp.dat -e "//%_tag%[year and manufacturer and not(@cloneof) and not(@isdevice) and not(@isbios)]/(@name|description|year|manufacturer)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+?)\r\n(.+?)\r\n(.+)$', '$1	$2	$3	$4', 'm')" >_temp\temp.2
REM _bin\xidel -s _temp\temp.dat -e "//%_tag%[@cloneof and not(@isdevice) and not(@isbios)]/(@name|@cloneof|description)" >_temp\temp.1
REM _bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(\w+)\r\n(.+)$', '$2[c]	$1	$3', 'm')" >>_temp\temp.2
sort _temp\temp.2 /o _temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\t(.+?)\t(.+?)\t(.+)$', '<p>$2 [$1] * $4 | $3</p>', 'm')" >>_temp\main.html



(echo ^</body^>
echo ^</html^>) >>_temp\main.html

pause



goto :main_menu

:list_menu2
set "_device="
set "_device2="
REM // skip devices filter
if %_dev%==false goto :list_menu

choice /m "filter devices?"
if %errorlevel% equ 1 (
	set "_device= and not(@isdevice='yes')"
	set "_device2=[%_sourcefile%not(@isdevice='yes')]"
)

:list_menu
set "_option="
cls
echo. ================== List Options ================
echo.             
echo. =================================================
echo.
echo. 1. all games with titles
echo. 2. only parents with titles
echo. 3. games by cloneof
echo. 4. by sourcefile ^& single list of sourcefiles
echo. 5. games marked as mechanical and devices
echo. 6. games by overall driver status
echo. 7. games with CHD
echo. 8. games that need BIOS ^& all Bios
echo. 9. by manufacturer ^& year
echo. 10. preliminary parents with good clones
echo. 11. go back
echo.
set /p _option="Type option number, and Enter: " || goto :list_menu
echo.
set /a "_option=%_option%"
if %_option% equ 1 goto :list_all
if %_option% equ 2 goto :list_parents
if %_option% equ 3 goto :list_cloneof
if %_option% equ 4 goto :list_src
if %_option% equ 5 goto :list_devices
if %_option% equ 6 goto :list_status
if %_option% equ 7 goto :list_chd
if %_option% equ 8 goto :list_romof
if %_option% equ 9 goto :list_manuf
if %_option% equ 10 goto :list_xclones
if %_option% equ 11 goto :main_menu

echo INVALID OPTION!!&timeout 3 >nul
goto :list_menu

:list_xclones
set "_option=" & set "_option2="
echo. 1. include imperfect clones
echo. 2. include imperfect parensts
echo. 3. no include imperfect games
echo.
choice /n /c:123 /m "Enter Option:"
if %errorlevel% equ 1 set "_option=@status='imperfect' or "
if %errorlevel% equ 2 set "_option2=@status='imperfect' or "

cls&echo. Building gamelist...
REM //include imperfect option

if %_drv_old%==true (
_bin\xidel -s _temp\temp.dat -e "//%_tag%[not(@cloneof)]/driver[@status='preliminary' or @status='protection' or @graphic='preliminary' or @color='preliminary' or @sound='preliminary']/../(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@cloneof]/driver[@status='good' and @color='good' and @sound='good' and @graphic='good']/../(@name|@cloneof|description)" >_temp\temp.2

)else (
_bin\xidel -s _temp\temp.dat -e "//%_tag%[not(@cloneof)]/driver[%_option2%@status='preliminary']/../(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@cloneof]/driver[%_option%@status='good']/../(@name|@cloneof|description)" >_temp\temp.2

)

_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+)$', '$1[p]	$1	$2', 'm')" >_temp\parents.lst
_bin\xidel -s _temp\temp.2 -e "replace( $raw, '^(\w+)\r\n(\w+)\r\n(.+)$', '$2	$1	$3', 'm')" >_temp\clones.lst

type nul >_temp\xclones.lst
for /f "delims=[" %%g in (_temp\parents.lst) do (
	for /f "delims=" %%h in ('_bin\xidel -s _temp\clones.lst -e "matches( $raw, '^%%g\t', 'm')"') do (
		if %%h==true (
			_bin\xidel -s _temp\clones.lst -e "extract( $raw, '^%%g\t.+$', 0,'m*')" >>_temp\xclones.lst
			_bin\xidel -s _temp\parents.lst -e "extract( $raw, '^%%g\[p\]\t.+$', 0,'m*')" >>_temp\xclones.lst
		)
	
	)
) 

sort _temp\xclones.lst /o "output\%_file%_xclones.txt"
del _temp\temp.1 _temp.2
del /q _temp\*.lst

cls&echo. All done! gamelist is in the OUTPUT folder&timeout 5 >nul
goto :list_menu


:list_manuf
cls&echo. Building gamelist...
REM //devices don't have year, manufacturer fiels
REM //extraction its in the order it appears in the datafile
_bin\xidel -s _temp\temp.dat -e "//%_tag%[manufacturer]/(@name|description|manufacturer)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+?)\r\n(.+)$', '$3	$1	$2', 'm')" >_temp\temp.2
sort _temp\temp.2 /o output\manufacturer.txt

_bin\xidel -s _temp\temp.dat -e "//%_tag%[year]/(@name|description|year)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+?)\r\n(.+)$', '$3	$1	$2', 'm')" >_temp\temp.2
sort _temp\temp.2 /o output\year.txt

del _temp\temp.1 _temp\temp.2
cls&echo. All done! gamelist is in the OUTPUT folder&timeout 5 >nul
goto :list_menu

:list_devices
cls&echo. Building gamelist...

_bin\xidel -s _temp\temp.dat -e "//%_tag%[@ismechanical='yes']/(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@isdevice='yes']/(@name|description)" >_temp\temp.2

_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	$2', 'm')" >"output\%_file%_mechanical.txt"
_bin\xidel -s _temp\temp.2 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	$2', 'm')" >"output\%_file%_device.txt"

del _temp\temp.1 _temp\temp.2
echo. All done! gamelist is in the OUTPUT folder&pause >nul
goto :list_menu


:list_romof
cls&echo. Building gamelist...

_bin\xidel -s _temp\temp.dat -e "//%_tag%[@romof]/(@name|@romof|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(\w+)\r\n(.+)$', '$2	$1	$3', 'm')" >_temp\temp.2

_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_isbios%]/@name" >_temp\index.1

del _temp\temp.1
for /f "delims=" %%g in (_temp\index.1) do (
	_bin\xidel -s _temp\temp.2 -e "extract( $raw, '^%%g\t.+$', 0, 'm*')" >>_temp\temp.1
) 

_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_isbios%]/(@name|description)" >_temp\temp.2
_bin\xidel -s _temp\temp.2 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1[b]	$1	$2', 'm')" >>_temp\temp.1
_bin\xidel -s _temp\temp.2 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	$2', 'm')" >"output\%_file%_bios.txt"

sort _temp\temp.1 /o "output\%_file%_romof_bios.txt"

del _temp\temp.1 _temp\temp.2 _temp\index.1

cls&echo. All done! gamelist is in the OUTPUT folder&pause >nul
goto :list_menu

:list_chd
cls&echo. Building gamelist...
_bin\xidel -s _temp\temp.dat -e "//%_tag%[disk]/(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	$2', 'm')" >"output\%_file%_chd.txt"

del _temp\temp.1
echo. Finish, gamelist is in the output folder&pause >nul
goto :list_menu

:list_status
cls&echo. Building gamelist...
REM //bios, samples, and devices dont have driver status info
REM // will only include games with <driver status

if %_drv_old%==true (
REM //no overall status
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='preliminary' or @status='protection' or @graphic='preliminary' or @color='preliminary' or @sound='preliminary']/../(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@color='imperfect' or @sound='imperfect' or @graphic='imperfect']/../(@name|description)" >_temp\temp.2
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='good' and @color='good' and @sound='good' and @graphic='good']/../(@name|description)" >_temp\temp.3

)else (
REM //overall status
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='preliminary']/../(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='imperfect']/../(@name|description)" >_temp\temp.2
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='good']/../(@name|description)" >_temp\temp.3

)

REM //order matters, keep preliminary, mame2003 will have dupliplicates in predliminary and inperfect lists 
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	Preliminary	$2', 'm')" >_temp\status.lst
_bin\xidel -s _temp\temp.2 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	Imperfect	$2', 'm')" >>_temp\status.lst
if %_drv_old%==true call :nodups_tab status.lst

_bin\xidel -s _temp\temp.3 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	Good	$2', 'm')" >>_temp\status.lst

sort _temp\status.lst /o "output\%_file%_status.txt"

del _temp\temp.1 _temp\temp.2 _temp\temp.3 _temp\status.lst
echo. Finish, gamelist is in the output folder&pause
goto :list_menu

:list_cloneof

REM //clone of its self choice?? include parents?
REM //fist column should be cloneof
set _choice=0
choice /m "include parents? "
if %errorlevel% equ 1 set _choice=1

cls&echo. Building gamelist...

_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%@cloneof%_device%]/(@name|@cloneof|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(\w+)\r\n(.+?)$', '$2	$1	$3', 'm')" >_temp\temp.3

if %_choice% equ 1 (
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@cloneof)%_device%]/(@name|description)" >_temp\temp.2
_bin\xidel -s _temp\temp.2 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1[p]	$1	$2', 'm')" >>_temp\temp.3
)

sort _temp\temp.3 /o "output\%_file%_cloneof.txt"

del _temp\temp.1 _temp\temp.2 _temp\temp.3

cls&echo. All done! gamelist is in the OUTPUT folder&pause >nul
goto :list_menu


:list_parents
cls&echo. Building gamelist...
REM //include bios option??
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@cloneof)%_device%]/(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	$2', 'm')" >"output\%_file%_parents.txt"
del _temp\temp.1

echo. Finish, gamelist is in the output folder&pause
goto :list_menu

:list_all
cls&echo. Building gamelist...

REM //full gamelist with bios and description
_bin\xidel -s _temp\temp.dat -e "//%_tag%%_device2%/(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	$2', 'm')" >"output\%_file%_full.txt"
del _temp\temp.1

echo. Finish, gamelist is in the output folder&pause
goto :list_menu

:list_src
cls&echo Building gamelist...
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@sourcefile%_device%]/(@sourcefile|@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n([\w./]+)\r\n(.+?)$', '$2	$1	$3', 'm')" >_temp\temp.2
sort _temp\temp.2 /o "output\%_file%_gamelist_sourcefile.txt"

REM //single list
cls&echo This may take a while...
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@sourcefile%_device%]/@sourcefile" >_temp\temp.1
call :nodups temp.1 1
move /y _temp\temp.1 "output\%_file%_sourcefiles.txt"

del _temp\temp.1 _temp\temp.2
cls&echo. ALL done! gamelist is in the OUTPUT folder&timeout 5 >nul
goto :list_menu


REM // =========================  end of list menu =====================================

:batch_menu
REM //games with chd, samples, bios
cls
echo. ============ Batch script Options ================
echo.    move all matched files to individual folders
echo. =================================================
echo.
echo. 1. clones, parents, bios, mechanical and devices
if %_drv%==true echo. 2. preliminary, imperfect and good
if %_src%==true echo. 3. games by their sourcefile
echo. 4. games that need chd images
echo. 5. games by romof BIOS
echo. 6. Go back
echo.
choice /n /c:123456 /m "Enter Option:"
echo.
if %errorlevel% equ 1 goto :batch_type
if %_drv%==true if %errorlevel% equ 2 goto :batch_status
if %_src%==true if %errorlevel% equ 3 goto :batch_src
if %errorlevel% equ 4 goto :batch_chd
if %errorlevel% equ 5 goto :batch_romof
if %errorlevel% equ 6 goto :main_menu

goto :batch_menu

:batch_romof
REM //include bios and all games
REm //romof=BIOS only in parents, clones uses romof=parent
cls
set "_option="
echo. ====================================================================
echo.         Type romof BIOS then press 'Enter' to add another one
echo.             type 'finish' to build batch and go back
echo. ====================================================================
for %%g in (_temp\*.lst) do echo. %%~ng
echo. ====================================================================
echo.
set /p _option="Enter bios: " ||goto :batch_romof
echo.
if "%_option%"=="finish" (
	call :make_batch bios_romof
	goto :batch_menu
)

REM // check if its a bios
findstr /xc:"%_option%" _temp\bios.1 >nul
if %errorlevel% equ 1 (
	echo. That BIOS was not found in the datafile&timeout 3 >nul
	goto :batch_romof
)

echo. Addding matching games to the list...
REM //this will add only parents
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@romof='%_option%']/@name" >_temp\%_option%.lst

REM //add all clones
for /f "delims=" %%g in (_temp\%_option%.lst) do ( 
	for /f "delims==" %%h in ('findstr /rc:"^.*=%%g$" _temp\cloneof.1') do (echo %%h) >>_temp\%_option%.lst
	
)

REM //add bios
(echo %_option%) >>_temp\%_option%.lst


echo. All games were added!!&timeout 3 >nul
goto :batch_romof


:batch_chd
cls&echo. Making list of games...
_bin\xidel -s _temp\temp.dat -e "//%_tag%[disk]/@name" >_temp\chd_games.lst

call :make_batch chd_games
goto :batch_menu

:batch_type
cls&echo. Making list of games...

_bin\xidel -s _temp\temp.dat -e "//%_tag%[@isdevice='yes']/@name" >_temp\1_device.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@ismechanical='yes']/@name" >_temp\2_mechanical.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_isbios%]/@name" >_temp\3_bios.lst

REM //include @sourcefile to seperate from standalone samples
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%@cloneof and not(%_isbios%) and not(@isdevice) and not(@ismechanical)]/@name" >_temp\4_clones.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@cloneof) and not(%_isbios%) and not(@isdevice) and not(@ismechanical)]/@name" >_temp\5_parents.lst


call :make_batch ParentsClonesBios
goto :batch_menu

:batch_status
REM //includes bios and all games
cls&echo. Making list of games...

REM //no overall status
if %_drv_old%==true (
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='preliminary' or @status='protection' or @graphic='preliminary' or @color='preliminary' or @sound='preliminary']/../@name" >_temp\1_preliminary.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@color='imperfect' or @sound='imperfect' or @graphic='imperfect']/../@name" >_temp\2_imperfect.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='good' and @color='good' and @sound='good' and @graphic='good']/../@name" >_temp\3_good.lst

)else (
REM //with overall status
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='preliminary']/../@name" >_temp\1_preliminary.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='imperfect']/../@name" >_temp\2_imperfect.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='good']/../@name" >_temp\3_good.lst

)
REM //no need to look for clones in good.lst, since this would be the leftovers
REM call :add_clones_lst

call :add_clones 1_preliminary.lst
call :add_clones 2_imperfect.lst

call :make_batch GoodImperfectPreliminary
goto :batch_menu

:batch_src
REM //include bios and all games
cls
set "_option="
echo. ====================================================================
echo.        Type sourcefile then press 'Enter' to add another one
echo.      sourcefile names should be as they appear in the datafile
echo.             type 'finish' to build batch and go back
echo. ====================================================================
for %%g in (_temp\*.lst) do echo. %%~ng
echo. ====================================================================
echo.
set /p _option="Enter Sourcefile: " ||goto :batch_src
echo.
if "%_option%"=="finish" (
	call :add_clones_lst
	call :make_batch sourcefiles
	goto :batch_menu
)

for /f "delims=" %%g in ('_bin\xidel -s _temp\temp.dat -e "matches( $raw, ' sourcefile=\""%_option%\""')"') do (
	if "%%g"=="false" (
		echo That sourcefile was not found...&timeout 3 >nul
		goto :batch_src
	)
)
for /f "delims=" %%g in ('_bin\xidel -s -e "replace( '%_option%', '[&*\\/. ]', '')"') do set "_folder=%%g"

REM //get parents then add the clones??
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@sourcefile='%_option%']/@name" >"_temp\%_folder%.lst"

echo All games were added&timeout 3 >nul
goto :batch_src

REM // ==================================== end of batch menu ===============================================

:catver_menu
REM //remove this because breaks xidel
_bin\xidel -s --input-format=html "%~1" -e "replace( $raw, '^\[VerAdded\].+', '', 'mis')" >_temp\temp.1
_bin\xidel -s --input-format=html _temp\temp.1 -e "replace( $raw, '^\[\w+\]$', '', 'm')" >_temp\catver.tmp

cls
echo.========= Catver.ini Options ==========
echo.
echo. 1. Generate list from catver.ini
echo. 2. Make Batch script from catver.ini folders
echo. 3. Cleanup and exit
echo.
choice /n /c:123 /m "Enter Option:"
if %errorlevel% equ 1 goto :catver_list
if %errorlevel% equ 2 goto :catver_batch
if %errorlevel% equ 3 exit
goto :catver_menu

:catver_list
cls&echo Building list...
_bin\xidel -s _temp\catver.tmp -e "extract( $raw, '^\w+=(.+)$', 1, 'm*')" >_temp\catver.txt

call :nodups catver.txt 1
move /y _temp\catver.txt output

echo Finish, the list is in the output folder&pause
goto :catver_menu

:catver_batch

set /a _count=0
:catver_batch2
cls&set "_option="
echo. ==================================================================
echo. Type full category or part, then press 'Enter' to add another one
echo.           each entry will make its own folder
echo. ====================================================================
echo. 1. finish list and build batch
echo. 2. clear list and restart
echo. 3. go back
echo. ===================================================================
for %%g in (_temp\*.lst) do echo. %%~ng
echo. ====================================================================
echo.
set /p _option="Enter Category, or Option: " ||goto :catver_batch2
echo.
if "%_option%"=="1" (
	call :add_clones_lst
	call :make_batch catver_folders
	goto :catver_menu
)
if "%_option%"=="2" (
	del /q _temp\*.lst
	goto :catver_batch
)
if "%_option%"=="3" (
	del /q _temp\*.lst
	goto :catver_menu

)

REM // automaticaly escape characters
set "_option=%_option:'=''''%"
for /f "delims=" %%g in ('_bin\xidel -s -e "replace( '%_option%', '([*\\)(.])', '\\$1')"') do set "_option=%%g"

for /f "delims=" %%g in ('_bin\xidel -s _temp\catver.tmp -e "matches( $raw, '^\w+=.*?%_option%.*$', 'mi')"') do (
	if "%%g"=="false" (
		echo That category was not found...&timeout 3 >nul
		goto :catver_batch2
	)
)

set /a _count+=1
for /f "delims=" %%g in ('_bin\xidel -s -e "replace( '%_option%', '[&*\\/. ]', '')"') do set "_folder=%%g"
_bin\xidel -s _temp\catver.tmp -e "extract( $raw, '^(\w+)=.*?%_option%.*$', 1, 'mi*')" >"_temp\%_count%_%_folder%.lst"

echo All games were added&timeout 3 >nul
goto :catver_batch2

REM // ================================= end of catver.ini options =========================================

:mamediff_menu

set "_dat1=%~1"
set "_dat2=%~2"
set "_file1=%~n1"
set "_file2=%~n2"
set "_dummy="

:diff_menu2
cls
echo.
echo. =============== MAMEdiff Options ================
echo.
echo. "%_file1%" ------^> "%_file2%"
echo.
echo. ================================================
echo. 1. cross reference both datafiles
echo. 2. switch around datafiles
echo. 3. cleanup and exit
echo.
choice /n /c:123 /m "Enter Option:"
echo.
if %errorlevel% equ 1 goto :diff_cross
if %errorlevel% equ 2 goto :diff_switch
if %errorlevel% equ 2 exit

goto :diff_menu2

:diff_switch

set "_dummy=%_dat2%"
set "_dat2=%_dat1%"
set "_dat1=%_dummy%"

set "_dummy=%_file2%"
set "_file2=%_file1%"
set "_file1=%_dummy%"

goto :diff_menu2

:diff_cross

REM //compare only the parenst from the first datafiles vs all the games of the second datafile
choice /m "Use only parents?:"
if %errorlevel% equ 1 (
	_bin\datutil -r -o _temp\temp1.dat -f generic "%_dat1%" >nul
	
)else (
	_bin\datutil -o _temp\temp1.dat -f generic "%_dat1%" >nul

)

_bin\datutil -o _temp\temp2.dat -f generic "%_dat2%" >nul

_bin\mamediff -s _temp\temp1.dat _temp\temp2.dat >nul
del mamediff.log&move mamediff.out _temp\

REM //maybe remove devices from here?
_bin\xidel -s _temp\temp1.dat -e "//game/(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+)$', '$1|$2', 'm')" >_temp\titles1.lst

_bin\xidel -s _temp\temp2.dat -e "//game/(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+)$', '$1|$2', 'm')" >_temp\titles2.lst

_bin\xidel -s _temp\mamediff.out -e "extract( $raw, '^\w+\t\w+$', 0, 'm*')" >_temp\index.1
_bin\xidel -s _temp\mamediff.out -e "extract( $raw, '^(\w+)\t$', 1, 'm*')" >_temp\index.2

REM //both
type nul >_temp\temp.1
for /f "tokens=1,2 delims=	" %%g in (_temp\index.1) do (
	echo %%g %%h
	_bin\xidel -s _temp\titles1.lst -e "extract( $raw, '^%%g\|.+$', 0, 'm')" >>_temp\temp.1
	_bin\xidel -s _temp\titles2.lst -e "extract( $raw, '^%%h\|.+$', 0, 'm')" >>_temp\temp.1

)
(echo "%_file1%" -----^> "%_file2%") >_temp\cross.txt
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(.+?)\r\n(.+)$', '$1 -----> $2', 'm')" >>_temp\cross.txt

REM //only in the first
type nul >_temp\temp.1
for /f "delims=" %%g in (_temp\index.2) do (
	echo %%g
	_bin\xidel -s _temp\titles1.lst -e "extract( $raw, '^%%g\|.+$', 0, 'm')" >>_temp\temp.1

)
(echo "%_file1%") >_temp\cross2.txt
type _temp\temp.1 >>_temp\cross2.txt

del /q _temp\*.lst _temp\temp.1 _temp\index.1 _temp\index.2

move /y _temp\cross.txt output
move /y _temp\cross2.txt output
goto :diff_menu2

REM // ============================== end of mamediff options =================================================


:add_clones
setlocal enabledelayedexpansion
cls&echo. Looking for orphan clones, this may take a while...

copy /y _temp\%1 _temp\temp.1 >nul

for /f "delims=" %%h in (_temp\%1) do (
	for /f "delims==" %%i in ('findstr /rc:"^.*=%%h$" _temp\cloneof.1') do (
		findstr /xc:"%%i" _temp\%1 >nul
		if !errorlevel! equ 1 (echo %%i) >>_temp\temp.1
	)
)
	
move /y _temp\temp.1 _temp\%1 >nul

setlocal disabledelayedexpansion
exit /b

:add_clones_lst
setlocal enabledelayedexpansion
REM //clones cant run without parents, so add all the clones when moving parents... 
REM //no need to check if parent?? because of 'for' behaviour
cls&echo. Looking for orphan clones, this may take a while...
for %%g in (_temp\*.lst) do (
	copy /y %%g _temp\temp.1 >nul

	for /f "delims=" %%h in (%%g) do (
		for /f "delims==" %%i in ('findstr /rc:"^.*=%%h$" _temp\cloneof.1') do (
			findstr /xc:"%%i" %%g >nul
			if !errorlevel! equ 1 (echo %%i) >>_temp\temp.1
		)
	)
		
	move /y _temp\temp.1 %%g >nul
)

setlocal disabledelayedexpansion
exit /b


:nodups_tab
REM // filter by fist string, TAB as delimiter

type nul >_temp\nodups.1
for /f "tokens=1 delims=	" %%g in (_temp\%1) do (
	for /f "delims=" %%h in ('_bin\xidel -s _temp\nodups.1 -e "matches( $raw, '^%%g\t.+$', 'm')"') do (
		if "%%h"=="false" _bin\xidel -s _temp\%1 -e "extract( $raw, '^%%g\t.+$', 0, 'm')" >>_temp\nodups.1
	)
)
del _temp\%1 & ren _temp\nodups.1 %1
exit /b

:nodups
setlocal enabledelayedexpansion
type nul >_temp\nodups.1
for /f "usebackq delims=" %%g in ("_temp\%~1") do (
	set /a _con=0
	for /f "delims=" %%h in (_temp\nodups.1) do if "%%g"=="%%h" set /a _con+=1
	if !_con! equ 0 (echo %%g) >>_temp\nodups.1

)

REM //count and adds occurances to output
if %2 equ 1 (
	type nul >_temp\nodups.2
	for /f "delims=" %%g in (_temp\nodups.1) do (
		set /a _con=0
		for /f "usebackq delims=" %%h in ("_temp\%~1") do if "%%g"=="%%h" set /a _con+=1
		(echo %%g ^(!_con!^)) >>_temp\nodups.2
	)
	del _temp\nodups.1 & ren _temp\nodups.2 nodups.1
)
sort _temp\nodups.1 /o "_temp\%~1"
del _temp\nodups.1

setlocal disabledelayedexpansion
exit /b

:make_batch
REM //may have duplicate entries, dosen't matter becuase of list position
REM // add copy, move option

cls&echo. Building batch script...
if not exist "_temp\*.lst" exit /b
(
	echo @echo off
	echo title "%_file%" ^^^| Build: %date%
	echo echo.==================================================
	echo echo. This script will MOVE matched .zip to
	echo echo.       The following folders:
	echo echo.==================================================
	for %%g in (_temp\*.lst) do echo echo. %%~ng
	echo echo.==================================================
	echo choice /m "Continue?"
	echo if %%errorlevel%% equ 2 exit
	echo cls^&echo. Creating folders and Moving files...
	for %%g in (_temp\*.lst) do (
		echo md %%~ng
		for /f "delims=" %%h in (%%g) do (	
				echo move /y "%%h.zip" "%%~ng" ^>nul
		)
	)
)>"_temp\%_file%_%1.bat"

del /q _temp\*.lst
move /y "_temp\%_file%_%1.bat" output\

cls&echo. All done!! batch script is in the OUTPUT folder&timeout 5 >nul
exit /b


