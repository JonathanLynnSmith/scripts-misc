@echo off
setlocal

set "sourceDir=%~dp0"
set "targetDir=C:\scripts"
set "excludeFile=%temp%\exclude.txt"

(
  echo copy-to-drive.bat
) > "%excludeFile%"

echo Copying newer files from "%sourceDir%" to "%targetDir%"

if not exist "%targetDir%" mkdir "%targetDir%"

xcopy /s /e /d /y /i /h /EXCLUDE:%excludeFile% "%sourceDir%\*" "%targetDir%\"

del "%excludeFile%"

echo Copy completed.
