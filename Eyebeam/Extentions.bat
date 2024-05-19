@echo off
setlocal

REM Get the current username
set "current_user=%USERNAME%"



REM Set the path to the remote server folder containing user settings
set "remote_folder=\\192.168.1.251\extentions$\Kolkata"


:check

REM Check if eyebeam.exe is running
tasklist /FI "IMAGENAME eq eyebeam.exe" 2>NUL | find /I /N "eyebeam.exe">NUL
if "%ERRORLEVEL%"=="0" (
    REM Eyebeam.exe is running, so terminate the process
	REM taskkill /F /IM eyebeam.exe >NUL
	cscript //nologo \\192.168.1.251\extentions$\close.vbs
    
	goto :check
)
	

REM Check if the folder exists for the current user
if exist "%remote_folder%\%current_user%\" (
    REM Copy the setting file to the user's desktop
    set "settings_dir="
    for /D %%A in ("%remote_folder%\%current_user%\*") do (
        if exist "%%~A\settings.cps" (
            set "settings_dir=%%~A"
            goto :found_settings
        )
    )
    echo Unable to find settings.cps in the specified directory.
	
    goto :not_found

    :found_settings
    echo Found settings.cps in %settings_dir%
    copy "%settings_dir%\settings.cps" "%USERPROFILE%\AppData\Local\CounterPath\RegNow Enhanced\default_user"
    REM Restart eyebeam.exe
    start "" "C:\Program Files (x86)\CounterPath\eyeBeam 1.5\eyeBeam.exe"
    goto :end

    :not_found
    echo Settings.cps not found for user %current_user%.
	cscript //nologo \\192.168.1.251\extentions$\registration.vbs
	goto :end


) else (
    echo Folder for user %current_user% not found on the remote server.
	cscript //nologo \\192.168.1.251\extentions$\userwarning.vbs

)

:end
endlocal