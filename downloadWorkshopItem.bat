@echo off
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

setlocal enabledelayedexpansion

:StartPrompt
:: ────────── Prompt for URL ──────────
set "URL="
set /p URL=Enter Steam Workshop Item URL:
echo.

:: If no URL entered, ask again
if "%URL%"=="" (
    echo ERROR: No URL entered. Please try again.
    echo.
    goto StartPrompt
)

:: ────────── Extract numeric ID ──────────
for /f "tokens=2 delims==&" %%I in ("!URL!") do set "ID=%%I"

if not defined ID (
    echo ERROR: Could not find a numeric id in that URL. Please try again.
    echo.
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

:: ────────── Show output ──────────
echo APPID=%APPID%
echo WorkshopID=%WorkshopID%
echo Title=%Title%
echo.

:: ────────── Download via steamcmd ──────────
echo Downloading Workshop item %WorkshopID% for AppID %APPID%...
steamcmd\steamcmd.exe +login anonymous +workshop_download_item %APPID% %WorkshopID% +quit > steamcmd\steamcmd.log

:: ────────── Post-download file operations ──────────
set "SRCFOLDER=steamcmd\steamapps\workshop\content\%APPID%\%WorkshopID%"
set "DESTFOLDER=.downloadedFiles\%Title%"

:: Wait briefly to ensure download completion
timeout /t 3 >nul

:: ────────── Ensure Download Folder Exists ──────────
if not exist ".downloadedFiles" mkdir ".downloadedFiles"

:: ────────── Move and Rename Download ──────────
if exist "%SRCFOLDER%" (
    if exist "%DESTFOLDER%" (
        rd /s /q "%DESTFOLDER%"  :: Delete existing destination folder if exists
    )
    move "%SRCFOLDER%" "%DESTFOLDER%" >nul
    echo Moved and renamed to: %DESTFOLDER%
) else (
    echo ERROR: Downloaded folder not found at %SRCFOLDER%
    goto :end
)

:: ────────── Cleanup: Remove Empty AppID Folder ──────────
set "APPID_FOLDER=steamcmd\steamapps\workshop\content\%APPID%"
if exist "%APPID_FOLDER%" (
    rd "%APPID_FOLDER%" 2>nul
)

:: ────────── Final Confirmation ──────────
if exist "%DESTFOLDER%" (
    echo.
    echo Cleanup complete. Files are now in: %DESTFOLDER%
) else (
    echo.
    echo ERROR: Final destination folder not found: %DESTFOLDER%
)

:end
:: ────────── Restart Prompt ──────────
goto StartPrompt
