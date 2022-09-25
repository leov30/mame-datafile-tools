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

REM //test for <game??
for /f "delims=" %%g in ('_bin\xidel -s _temp\temp.dat -e "matches( $raw, '^\t*<machine name=.+$', 'm')"') do if "%%g"=="true" set _tag=machine
for /f "delims=" %%g in ('_bin\xidel -s _temp\temp.dat -e "matches( $raw, '^\t*<.+?sourcefile=.+$', 'm')"') do if "%%g"=="true" set _src=1&set "_sourcefile=@sourcefile and "
for /f "delims=" %%g in ('_bin\xidel -s _temp\temp.dat -e "matches( $raw, '^\t*<driver status=.+$', 'm')"') do if "%%g"=="true" set _drv=1
for /f "delims=" %%g in ('_bin\xidel -s _temp\temp.dat -e "matches( $raw, '^\t*<driver status=\""protection\"".+$', 'm')"') do if "%%g"=="true" set _drv_old=1


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
if %errorlevel% equ 1 goto :list_menu
if %errorlevel% equ 2 goto :batch_menu
if %errorlevel% equ 3 (
	del _temp\temp.dat & rd _temp
	exit

)

goto :main_menu
REM ================================== endof main menu ====================================
:list_menu
cls
echo. ================== List Options ================
echo.  mechanical and devices are filter by default
echo. =================================================
echo.
echo. 1. gamelist, all with titles
echo. 2. gamelist, just parents
echo. 3. gamelist, all with cloneof
if %_src% equ 1 echo. 4. gamelist by sourcefile
if %_src% equ 1 echo. 5. just list sourcefiles
if %_drv% equ 1 echo. 6. gamelist, all with status
echo. 7. Go back
echo.
choice /n /c:1234567 /m "Enter Option:"
echo.
if %errorlevel% equ 1 goto :list_all
if %errorlevel% equ 2 goto :list_parents
if %errorlevel% equ 3 goto :list_cloneof
if %_src% equ 1 if %errorlevel% equ 4 goto :list_src
if %_src% equ 1 if %errorlevel% equ 5 goto :list_src2
if %_drv% equ 1 if %errorlevel% equ 6 goto :list_status
if %errorlevel% equ 7 goto :main_menu

goto :list_menu

:list_status
cls&echo. Building gamelist...

if %_drv_old% equ 1 (
REM //no overall status
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@isbios) and not(@isdevice) and not(@ismechanical)]/driver[@status='preliminary' or @status='protection' or @graphic='preliminary' or @color='preliminary' or @sound='preliminary']/../(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@isbios) and not(@isdevice) and not(@ismechanical)]/driver[@color='imperfect' or @sound='imperfect' or @graphic='imperfect']/../(@name|description)" >_temp\temp.2
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@isbios) and not(@isdevice) and not(@ismechanical)]/driver[@status='good' and @color='good' and @sound='good' and @graphic='good']/../(@name|description)" >_temp\temp.3


)else (
REM //overall status
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@isbios) and not(@isdevice) and not(@ismechanical)]/driver[@status='preliminary']/../(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@isbios) and not(@isdevice) and not(@ismechanical)]/driver[@status='imperfect']/../(@name|description)" >_temp\temp.2
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@isbios) and not(@isdevice) and not(@ismechanical)]/driver[@status='good']/../(@name|description)" >_temp\temp.3

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

REM //clone of its self choice
cls&echo. Building gamelist...

_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%@cloneof and not(@isbios) and not(@isdevice) and not(@ismechanical)]/(@name|@cloneof|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@cloneof) and not(@isbios) and not(@isdevice) and not(@ismechanical)]/(@name|description)" >_temp\temp.2


_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(\w+)\r\n(.+?)$', '$1	$2	$3', 'm')" >_temp\temp.3
_bin\xidel -s _temp\temp.2 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	none	$2', 'm')" >>_temp\temp.3

sort _temp\temp.3 /o _temp\temp.1

move /y _temp\temp.1 "output\%_file%_gamelist_cloneof.txt"
del _temp\temp.1 _temp\temp.2 _temp\temp.3

echo. Finish, gamelist is in the output folder&pause
goto :list_menu


:list_parents
cls&echo. Building gamelist...

_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@cloneof) and not(@isbios) and not(@isdevice) and not(@ismechanical)]/(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	$2', 'm')" >"output\%_file%_parents.txt"
del _temp\temp.1

echo. Finish, gamelist is in the output folder&pause
goto :list_menu

:list_all
cls&echo. Building gamelist...

REM //full gamelist with bios and description
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@isdevice) and not(@ismechanical)]/(@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	$2', 'm')" >"output\%_file%_full.txt"
del _temp\temp.1

echo. Finish, gamelist is in the output folder&pause
goto :list_menu

:list_src2
cls&echo Building gamelist...
_bin\xidel -s _temp\temp.dat -e "//%_tag%[not(@isdevice) and not(@ismechanical)]/@sourcefile" >_temp\temp.1
call :nodups temp.1
move /y _temp\temp.1 "output\%_file%_sourcefiles.txt"
del _temp\temp.1
echo. Finish, gamelist is in the output folder&pause
goto :list_menu

:list_src
cls&echo Building gamelist...
_bin\xidel -s _temp\temp.dat -e "//%_tag%[not(@isdevice) and not(@ismechanical)]/(@sourcefile|@name|description)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n([\w./]+)\r\n(.+?)$', '$2	$1	$3', 'm')" >_temp\temp.2
sort _temp\temp.2 /o _temp\temp.1
move /y _temp\temp.1 "output\%_file%_gamelist_src.txt"
del _temp\temp.1 _temp\temp.2

echo. Finish, gamelist is in the output folder&pause
goto :list_menu


REM // =========================  end of list menu =====================================

:batch_menu
REM //games with chd, samples, bios
cls
echo. ============ Batch script Options ================
echo.  mechanical and devices are filter by default
echo. =================================================
echo.
echo. 1. Move Clones, parents and bios to folders
if %_drv% equ 1 echo. 2. Move Preliminary, Imperfect to folders
if %_src% equ 1 echo. 3. Move games by sourcefile to folders
echo. 4. Go back
echo.
choice /n /c:1234 /m "Enter Option:"
echo.
if %errorlevel% equ 1 goto :batch_type
if %_drv% equ 1 if %errorlevel% equ 2 goto :batch_status
if %_src% equ 1 if %errorlevel% equ 3 goto :batch_src
if %errorlevel% equ 4 goto :main_menu

goto :batch_menu

:batch_type
cls&echo. Building batch file...

_bin\xidel -s _temp\temp.dat -e "//%_tag%[@ismechanical='yes']/@name" >_temp\mechanical.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@isdevice='yes']/@name" >_temp\device.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%[@isbios='yes']/@name" >_temp\bios.lst

REM //include @sourcefile to seperate from standalone samples
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@cloneof) and not(@isbios) and not(@isdevice) and not(@ismechanical)]/@name" >_temp\parents.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%@cloneof and not(@isbios) and not(@isdevice) and not(@ismechanical)]/@name" >_temp\clones.lst

call :make_batch ParentsClonesBios
goto :batch_menu

:batch_status
cls&echo. Building batch file...

if %_drv_old% equ 1 (
REM //no overall status
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@isbios) and not(@isdevice) and not(@ismechanical)]/driver[@status='preliminary' or @status='protection' or @graphic='preliminary' or @color='preliminary' or @sound='preliminary']/../@name" >_temp\1_preliminary.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@isbios) and not(@isdevice) and not(@ismechanical)]/driver[@color='imperfect' or @sound='imperfect' or @graphic='imperfect']/../@name" >_temp\2_imperfect.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@isbios) and not(@isdevice) and not(@ismechanical)]/driver[@status='good' and @color='good' and @sound='good' and @graphic='good']/../@name" >_temp\3_good.lst

)else (
REM //overall status
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@isbios) and not(@isdevice) and not(@ismechanical)]/driver[@status='preliminary']/../@name" >_temp\1_preliminary.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@isbios) and not(@isdevice) and not(@ismechanical)]/driver[@status='imperfect']/../@name" >_temp\2_imperfect.lst
_bin\xidel -s _temp\temp.dat -e "//%_tag%[%_sourcefile%not(@isbios) and not(@isdevice) and not(@ismechanical)]/driver[@status='good']/../@name" >_temp\3_good.lst

)

call :make_batch GoodImperfectPreliminary
goto :batch_menu

:batch_src
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

REM // automaticaly escape characters
REM set "_option=%_option:'=''''%"
REM for /f "delims=" %%g in ('_bin\xidel -s -e "replace( '%_option%', '([*\\)(.])', '\\$1')"') do set "_option=%%g"


for /f "delims=" %%g in ('_bin\xidel -s _temp\temp.dat -e "matches( $raw, ' sourcefile=\""%_option%\""')"') do (
	if "%%g"=="false" (
		echo That sourcefile was not found...&timeout 3 >nul
		goto :batch_src
	)
)

for /f "delims=" %%g in ('_bin\xidel -s -e "replace( '%_option%', '[&*\\/. ]', '')"') do set "_folder=%%g"


_bin\xidel -s _temp\temp.dat -e "//%_tag%[@sourcefile='%_option%' and not(@isdevice) and not(@ismechanical)]/@name" >"_temp\%_folder%.lst"

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

call :nodups catver.txt
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
set /p _option="Enter Category: " ||goto :batch_src
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
REM SORT /unique
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
	echo cls
	echo echo. Creating folders and Moving files...
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


