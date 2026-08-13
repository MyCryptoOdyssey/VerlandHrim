@echo off
rem Build TestBanner.dll against local Decal + Virindi View Service
cd /d "%~dp0"
set CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe
set DECAL=C:\Program Files (x86)\Decal 3.0
if not exist "%DECAL%\Decal.Adapter.dll" set DECAL=C:\Program Files\Decal 3.0
set VVS=C:\Games\VirindiPlugins\VirindiViewService
if not exist "%VVS%\VirindiViewService.dll" (
    echo Could not find VirindiViewService.dll - edit VVS= path in this file.
    pause & exit /b 1
)
"%CSC%" /nologo /target:library /platform:x86 /out:TestBanner.dll /res:view.xml,TestBanner.ViewXML.xml ^
  /r:"%DECAL%\Decal.Adapter.dll" /r:"%DECAL%\.NET 4.0 PIA\Decal.Interop.Inject.dll" ^
  /r:"%VVS%\VirindiViewService.dll" ^
  /r:System.Drawing.dll TestBannerPlugin.cs
if errorlevel 1 ( echo BUILD FAILED - paste the errors above to Claude. ) else ( echo BUILD OK: TestBanner.dll )
pause
