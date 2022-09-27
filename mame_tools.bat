@echo off
cd /d "%~dp0"
if "%~1"=="" echo Only drag and drop datafiles&pause&exit
if not exist "%~1" echo Change the name of the file and try agian&pause&exit
if not exist "_bin\xidel.exe" echo This script needs _bin\xidel.exe to work&pause&exit

set "_file=%~n1"
set "_file=%_file:(=%"
set "_file=%_file:)=%"

if not exist output md output
if not exist _bin md _bin
if not exist _temp (md _temp)else (del _temp\*.lst)

if "%~x1"==".ini" goto :catver_menu

if not "%~x1"==".dat" (
	if not "%~x1"==".xml" echo This file wasn't identified as a datafile&pause&exit
)

REM //remove this because it breaks xidel
_bin\xidel -s "%~1" -e "replace( $raw, '^<!DOCTYPE mame \[.+?\]>$', '', 'ms')" >_temp\temp.dat

set _tag=game
set _src=0
set _drv=0
set _drv_old=0
set "_sourcefile="
set "_device="
set "_device2="
set _dev=0

REM //test for <game??
for /f "delims=" %%g in ('_bin\xidel -s _temp\temp.dat -e "matches( $raw, '^\t*<machine name=.+$', 'm')"') do if "%%g"=="true" set _tag=machine
for /f "delims=" %%g in ('_bin\xidel -s _temp\temp.dat -e "matches( $raw, '^\t*<driver status=.+$', 'm')"') do if "%%g"=="true" set _drv=1
for /f "delims=" %%g in ('_bin\xidel -s _temp\temp.dat -e "matches( $raw, '^\t*<driver status=\""protection\"".+$', 'm')"') do if "%%g"=="true" set _drv_old=1
for /f "delims=" %%g in ('_bin\xidel -s _temp\temp.dat -e "matches( $raw, '^\t*<%_tag% name=\""\w+\"" sourcefile=.+$', 'm')"') do if "%%g"=="true" set _src=1&set "_sourcefile=@sourcefile and "
for /f "delims=" %%g in ('_bin\xidel -s _temp\temp.dat -e "matches( $raw, '^\t*<%_tag% name=\""\w+\"".+?isdevice=\""yes\"".+$', 'm')"') do if "%%g"=="true" set _dev=1

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
:list_menu2
if %_dev% equ 0 goto :list_menu
choice /m "filter devices?"
if %errorlevel% equ 1 (
	set "_device= and not(@isdevice='yes')"
	set "_device2=[%_sourcefile%not(@isdevice='yes')]"
)else (
	set "_device="
	set "_device2="
)


:list_menu
cls
echo. ================== List Options ================
echo.             
echo. =================================================
echo.
echo. 1. all games with titles
echo. 2. only parents with titles
echo. 3. games by cloneof
if %_src% equ 1 echo. 4. games by sourcefile
if %_src% equ 1 echo. 5. single list of sourcefiles
if %_drv% equ 1 echo. 6. games by overall driver status
echo. 7. games with CHD
echo. 8. games that need BIOS ^& all Bios
echo. 9. games marked as mechanical and devices
REM echo. 0. Go back
echo.
choice /n /c:1234567890 /m "Enter Option:"
echo.
if %errorlevel% equ 1 goto :list_all
if %errorlevel% equ 2 goto :list_parents
if %errorlevel% equ 3 goto :list_cloneof
if %_src% equ 1 if %errorlevel% equ 4 goto :list_src
if %_src% equ 1 if %errorlevel% equ 5 goto :list_src2
if %_drv% equ 1 if %errorlevel% equ 6 goto :list_status
if %errorlevel% equ 7 goto :list_chd
if %errorlevel% equ 8 goto :list_romof
if %errorlevel% equ 9 goto :list_devices
REM if %errorlevel% equ 0 goto :main_menu

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
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@isbios='yes']/(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	$2', 'm')" >_temp\bios.lst

echo. This may take a while...
for /f "tokens=1 delims=	" %%g in (_temp\bios.lst) do (
	_bin\xidel -s _temp\temp.dat -e "//%_tag%[@romof='%%g']/(@name|@romof|description)" >>_temp\temp.2
) 
_bin\xidel -s _temp\temp.2 -e "replace( $raw, '^(\w+)\r\n(\w+)\r\n(.+?)$', '$1	$2	$3', 'm')" >"output\%_file%_romof_bios.txt"

move /y _temp\bios.lst "output\%_file%_bios.txt"

del _temp\temp.1 _temp\temp.2
echo. All done! gamelist is in the OUTPUT folder&pause >nul
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

if %_drv_old% equ 1 (
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

REM //order matters
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	Preliminary	$2', 'm')" >_temp\status.lst
_bin\xidel -s _temp\temp.2 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	Imperfect	$2', 'm')" >>_temp\status.lst
if %_drv_old% equ 1 call :nodups_tab status.lst

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

:list_src2
cls&echo Building gamelist...
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@sourcefile%_device%]/@sourcefile" >_temp\temp.1
call :nodups temp.1 1

move /y _temp\temp.1 "output\%_file%_sourcefiles.txt"

echo. Finish, gamelist is in the output folder&pause
goto :list_menu

:list_src
cls&echo Building gamelist...
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@sourcefile%_device%]/(@sourcefile|@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n([\w./]+)\r\n(.+?)$', '$2	$1	$3', 'm')" >_temp\temp.2

sort _temp\temp.2 /o "output\%_file%_gamelist_src.txt"

del _temp\temp.1 _temp\temp.2

echo. Finish, gamelist is in the output folder&pause
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
if %_drv% equ 1 echo. 2. preliminary, imperfect and good
if %_src% equ 1 echo. 3. games by their sourcefile
echo. 4. games that need chd images
echo. 5. games by romof BIOS
echo. 6. Go back
echo.
choice /n /c:123456 /m "Enter Option:"
echo.
if %errorlevel% equ 1 goto :batch_type
if %_drv% equ 1 if %errorlevel% equ 2 goto :batch_status
if %_src% equ 1 if %errorlevel% equ 3 goto :batch_src
if %errorlevel% equ 4 goto :batch_chd
if %errorlevel% equ 5 goto :batch_romof
if %errorlevel% equ 6 goto :main_menu

goto :batch_menu

:batch_romof
REM //include bios and all games
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
	cls&echo Building batch file...
	call :make_batch bios_romof
	goto :batch_menu
)

for /f "delims=" %%g in ('_bin\xidel -s _temp\temp.dat -e "matches( $raw, ' romof=\""%_option%\""')"') do (
	if "%%g"=="false" (
		echo That game was not found...&timeout 3 >nul
		goto :batch_romof
	)
)

REM //add bios to list?
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@romof='%_option%']/@name" >"_temp\%_option%.lst"
(echo %_option%) >>"_temp\%_option%.lst"

echo All games were added&timeout 3 >nul
goto :batch_romof


:batch_chd
cls&echo. Building batch file...
_bin\xidel -s _temp\temp.dat -e "//%_tag%[disk]/@name" >_temp\chd_games.lst

call :make_batch chd_games
goto :batch_menu

:batch_type
cls&echo. Building batch file...

_bin\xidel -s _temp\temp.dat -e "//%_tag%[@isdevice='yes']/@name" >_temp\1_device.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@ismechanical='yes']/@name" >_temp\2_mechanical.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@isbios='yes']/@name" >_temp\3_bios.lst

REM //include @sourcefile to seperate from standalone samples
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%@cloneof and not(@isbios) and not(@isdevice) and not(@ismechanical)]/@name" >_temp\4_clones.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@cloneof) and not(@isbios) and not(@isdevice) and not(@ismechanical)]/@name" >_temp\5_parents.lst


call :make_batch ParentsClonesBios
goto :batch_menu

:batch_status
REM //includes bios and all games
cls&echo. Building batch file...

REM //no overall status
if %_drv_old% equ 1 (
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='preliminary' or @status='protection' or @graphic='preliminary' or @color='preliminary' or @sound='preliminary']/../@name" >_temp\1_preliminary.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@color='imperfect' or @sound='imperfect' or @graphic='imperfect']/../@name" >_temp\2_imperfect.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='good' and @color='good' and @sound='good' and @graphic='good']/../@name" >_temp\3_good.lst

)else (
REM //with overall status
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='preliminary']/../@name" >_temp\1_preliminary.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='imperfect']/../@name" >_temp\2_imperfect.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%/driver[@status='good']/../@name" >_temp\3_good.lst

)

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
	cls&echo Building batch file...
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

_bin\xidel -s _temp\temp.dat -e "//%_tag%[@sourcefile='%_option%']/@name" >"_temp\%_folder%.lst"

echo All games were added&timeout 3 >nul
goto :batch_src

REM // ==================================== end of batch scripts ===============================================

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
cls&set "_option="
echo. ==================================================================
echo. Type full category or part, then press 'Enter' to add another one
echo.           each entry will make its own folder
echo.          type 'finish' to build batch and go back
echo. ===================================================================
for %%g in (_temp\*.lst) do echo. %%~ng
echo. ====================================================================
echo.
set /p _option="Enter Category: " ||goto :catver_batch
echo.
if "%_option%"=="finish" (
	cls&echo Building batch file...
	call :make_batch catver_folders
	goto :catver_menu
)

REM // automaticaly escape characters
set "_option=%_option:'=''''%"
for /f "delims=" %%g in ('_bin\xidel -s -e "replace( '%_option%', '([*\\)(.])', '\\$1')"') do set "_option=%%g"

for /f "delims=" %%g in ('_bin\xidel -s _temp\catver.tmp -e "matches( $raw, '^\w+=.*?%_option%.*$', 'mi')"') do (
	if "%%g"=="false" (
		echo That category was not found...&timeout 3 >nul
		goto :catver_batch
	)
)

for /f "delims=" %%g in ('_bin\xidel -s -e "replace( '%_option%', '[&*\\/. ]', '')"') do set "_folder=%%g"
_bin\xidel -s _temp\catver.tmp -e "extract( $raw, '^(\w+)=.*?%_option%.*$', 1, 'mi*')" >"_temp\%_folder%.lst"

echo All games were added&timeout 3 >nul
goto :catver_batch


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
 
if not exist "_temp\*.lst" exit /b
(
	echo @echo off
	echo title Game Oraganizer ^^^| %_file% ^^^| Build: %DATE%
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

echo. Finish, batch script is in the outputfolder&pause
exit /b


