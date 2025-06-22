@echo off
chcp 65001 >nul
powershell -NoProfile -Command "exit"
rem -----------------------------------------------------------------------------
rem MIT License
rem
rem Copyright (c) 2025 AlchemistChief
rem
rem Permission is hereby granted, free of charge, to any person obtaining a copy
rem of this software and associated documentation files (the "Software"), to deal
rem in the Software without restriction, including without limitation the rights
rem to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
rem copies of the Software, and to permit persons to whom the Software is
rem furnished to do so, subject to the following conditions:
rem
rem The above copyright notice and this permission notice shall be included in all
rem copies or substantial portions of the Software.
rem
rem THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
rem IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
rem FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
rem AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
rem LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
rem OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
rem SOFTWARE.
rem -----------------------------------------------------------------------------

:: =======================================================================
:: Define ANSCI escape sequences for colors
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "RESET=%ESC%[0m"
set "GOLDCOLOR=%ESC%[1;38;5;220m"
set "REDCOLOR=%ESC%[1;38;5;196m"
set "BLUECOLOR=%ESC%[1;38;5;75m"
set "GREENCOLOR=%ESC%[1;38;5;46m"
:: =======================================================================

setlocal enabledelayedexpansion

:: ────────── Prompt for URL ──────────
:StartPrompt
echo █████████████████████████████████████████████████████████████████
echo.
del /f /q "steamcmd\steamapps\workshop\*.acf" >nul 2>&1
rd /s /q "steamcmd\steamapps\workshop\downloads" >nul 2>&1
rd /s /q "steamcmd\steamapps\workshop\temp" >nul 2>&1
set "URL="
echo %GOLDCOLOR%Enter Steam Workshop Item URL:%RESET%
set /p "URL=> "

:: If no URL entered, ask again
if "%URL%"=="" (
    echo %REDCOLOR%[ERROR]%RESET% No URL entered. Please try again.
    goto StartPrompt
)

:: ────────── Extract numeric ID ──────────
for /f "tokens=2 delims==&" %%I in ("!URL!") do set "ID=%%I"

if not defined ID (
    echo %REDCOLOR%[ERROR]%RESET% Could not find a numeric ID in that URL. Please try again.
    goto StartPrompt
)

:: ────────── Run exact working PowerShell line, output to temp.txt ──────────
powershell -NoProfile -Command "$body=@{itemcount=1;'publishedfileids[0]'=%ID%}; $r=Invoke-RestMethod -Uri 'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/' -Method POST -Body $body; $d=$r.response.publishedfiledetails[0]; Write-Host 'APPID=' $d.creator_app_id.ToString().Trim(); Write-Host 'WorkshopID=' $d.publishedfileid.ToString().Trim(); Write-Host 'Title=' $d.title.Trim()" > temp.txt

:: ────────── Read output into batch variables ──────────
for /f "tokens=1,* delims==" %%A in (temp.txt) do (
    set "%%A=%%B"
)

:: ────────── Trim variables ──────────
for %%V in (APPID WorkshopID Title) do (
    set "value=!%%V!"
    for /f "tokens=* delims= " %%T in ("!value!") do set "%%V=%%T"
    for /f "tokens=* delims= " %%T in ("!%%V!") do set "%%V=%%T"
)

:: Optional: cleanup
del temp.txt >nul 2>&1

:: ────────── Sanitize Title ──────────
set "TitleSanitized=!Title!"
set "TitleSanitized=!TitleSanitized:(=[!"
set "TitleSanitized=!TitleSanitized:)=]!"

:: ────────── Show output ──────────
echo %BLUECOLOR%[INFO]%RESET% APPID=!APPID!
echo %BLUECOLOR%[INFO]%RESET% WorkshopID=!WorkshopID!
echo %BLUECOLOR%[INFO]%RESET% Title=!TitleSanitized!

:: ────────── Download via steamcmd ──────────
echo %BLUECOLOR%[INFO]%RESET% Downloading Workshop item !WorkshopID! for AppID !APPID!...
steamcmd\steamcmd.exe +login anonymous +workshop_download_item %APPID% %WorkshopID% +quit > steamcmd\steamcmd.log

:: ────────── Post-download file operations ──────────
set "SRCFOLDER=steamcmd\steamapps\workshop\content\%APPID%\%WorkshopID%"
set "DESTFOLDER=.downloadedFiles\%TitleSanitized%"

:: Wait briefly to ensure download completion
timeout /t 3 >nul

:: Create .downloadedFiles folder if it doesn't exist
if not exist ".downloadedFiles" mkdir ".downloadedFiles"

:: Move and rename (force overwrite if folder exists)
if exist "%SRCFOLDER%" (
    if exist "%DESTFOLDER%" (
        rd /s /q "%DESTFOLDER%"
    )
    move "%SRCFOLDER%" "%DESTFOLDER%" >nul
    echo %GREENCOLOR%[SUCCESS]%RESET% Moved and renamed to: %DESTFOLDER%
) else (
    echo %REDCOLOR%[ERROR]%RESET% Downloaded folder not found at %SRCFOLDER%
)

:: Remove empty APPID folder if it exists
set "APPID_FOLDER=steamcmd\steamapps\workshop\content\%APPID%"
if exist "%APPID_FOLDER%" (
    rd "%APPID_FOLDER%" 2>nul
)

:: Confirm final destination exists before saying complete
if exist "%DESTFOLDER%" (
    echo %GREENCOLOR%[SUCCESS]%RESET% Cleanup complete. %GOLDCOLOR%Files are now in: %DESTFOLDER%%RESET%
) else (
    echo %REDCOLOR%[ERROR]%RESET% Final destination folder not found: %DESTFOLDER%
)
echo.

:: Ask to download another item
goto StartPrompt
