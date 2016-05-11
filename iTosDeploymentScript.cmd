set dropFolder="\\FS\TFSBuild\iTos\Main\Main_20150223.2"
set version=2.0.109.0

set ex=-xr!Web.config -xr!Web.Debug.config -xr!Web.Release.config -xr!iTos.ApplicationServer.exe.config
set zip=C:\"Program Files"\7-Zip\7z.exe

%zip% a %ex% -sfx iTos.WebApp_%version%.exe %dropFolder%\iTos.WebApp\_PublishedWebsites\iTos.WebApp\
%zip% a %ex% -sfx iTos.WebAppHandheld_%version%.exe %dropFolder%\iTos.WebAppHandheld\_PublishedWebsites\iTos.WebAppHandheld\
%zip% a %ex% -sfx iTos.WebAPI_%version%.exe %dropFolder%\iTos.WebAPI\_PublishedWebsites\iTos.WebAPI\
%zip% a %ex% -sfx iTos.PublicWebAPI_%version%.exe %dropFolder%\iTos.PublicWebAPI\_PublishedWebsites\iTos.PublicWebAPI\
%zip% a %ex% -sfx iTos.AppServer_%version%.exe %dropFolder%\iTos.ApplicationServer\
