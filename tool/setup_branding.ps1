# Setup icono y splash - ejecuta después de poner tus PNGs
# Icono: assets/icon/app_icon.png (1024x1024)
# Splash logo: assets/splash/logo.png (512x512) o splash.png (1080x1920)

Write-Host "Generando icono..." -ForegroundColor Cyan
dart run flutter_launcher_icons

Write-Host "Generando splash..." -ForegroundColor Cyan
dart run flutter_native_splash:create

Write-Host "Listo. Haz flutter clean && flutter run" -ForegroundColor Green
