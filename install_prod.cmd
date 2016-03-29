:: copy deployment packs and extract (by running)
:: SET THE NUMBER OF THE OLD VERSION BELLOW (used when backing up)
@echo off
set oldVersion=2.7003.15008.0

:: double check all of the following paths
set webAppPath=itos.vanmoergroup.com
set webApiPath=itos-papi.vanmoergroup.com
set pubApiPath=itos-api.vanmoergroup.com
set hndHldPath=itos-hh.vanmoergroup.com
set appSvrPath=itos.application.server

:: The rest of the script needs no modifications
call :initialCheck

:webapp
call :deploy iTos.WebApp %webAppPath%

:webapi - private
call :deploy iTos.WebAPI %webApiPath%
move %bakPath%\App_Data %webApiPath%

:pubapi
call :deploy iTos.PublicWebAPI %pubApiPath%

:handHeld
call :deploy iTos.WebAppHandheld %hndHldPath%

:appserver
call :deploy iTos.ApplicationServer %appSvrPath%

:end
pause
goto :eof

:: SUBROUTINES
:initialCheck
@IF NOT EXIST iTos.WebApp (
  echo.Path iTos.WebApp does not exist
  pause
  exit
)
@IF EXIST iTos.WebAppGate (
  echo.UI Environment does not have a gate app yet! Check if you are using the correct deployment packages and bakup script!
  pause
  exit
)
@IF NOT EXIST iTos.ApplicationServer (
  echo.Path iTos.ApplicationServer does not exist
  pause
  exit
)
goto :eof

:deploy
@set bakPath=Backup\%2_%oldVersion%
@IF EXIST %bakPath% (
  echo.Backup: Path %bakPath% - already used!
  pause
  exit
)
echo.%bakPath%
move %2 %bakPath% >nul
@IF EXIST %2 (
  echo.Make sure you have stopped websites
  pause
  exit
)
ren %1 %2
echo.copying deploy.config scripts to %2
copy %bakPath%\deploy.connectionStrings.config %2 >nul
copy %bakPath%\deploy.iTos.appServer.config %2 >nul
copy %bakPath%\deploy.system.net.smpt.config %2 >nul
copy %bakPath%\deploy.unicorn.http.config %2 >nul
copy %bakPath%\deploy.unicorn.network.mail.config %2 >nul
copy %bakPath%\deploy.unicorn.serviceModel.client.config %2 >nul
copy %bakPath%\deploy.unicorn.serviceModel.service.config %2 >nul
move %bakPath%\Logs %2
goto :eof