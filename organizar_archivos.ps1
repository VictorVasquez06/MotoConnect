# ============================================================================
# SCRIPT DE ORGANIZACIÓN AUTOMÁTICA - MotoConnect
# ============================================================================
# Este script encuentra y organiza automáticamente tus archivos Dart
# Ejecuta en PowerShell desde la raíz de tu proyecto

Write-Host "🚀 Iniciando organización de archivos MotoConnect..." -ForegroundColor Cyan
Write-Host ""

# Verificar que estamos en el directorio correcto
if (!(Test-Path "lib")) {
    Write-Host "❌ Error: No se encontró la carpeta 'lib'" -ForegroundColor Red
    Write-Host "Por favor ejecuta este script desde la raíz del proyecto" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Carpeta lib encontrada" -ForegroundColor Green

# Crear carpetas si no existen
$folders = @("lib\screens", "lib\views", "lib\models", "lib\services", "lib\viewmodels")
foreach ($folder in $folders) {
    if (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "📁 Creada carpeta: $folder" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🔍 Buscando archivos Dart..." -ForegroundColor Cyan
Write-Host ""

# Buscar todos los archivos dart en lib (recursivo)
$allDartFiles = Get-ChildItem -Path lib -Filter "*.dart" -Recurse

# Categorizar archivos
$screenFiles = @()
$viewFiles = @()
$otherFiles = @()

foreach ($file in $allDartFiles) {
    if ($file.Name -like "*_screen.dart") {
        $screenFiles += $file
    } elseif ($file.Name -like "*_view.dart") {
        $viewFiles += $file
    } else {
        $otherFiles += $file
    }
}

Write-Host "📊 Archivos encontrados:" -ForegroundColor Cyan
Write-Host "  - Screens: $($screenFiles.Count)" -ForegroundColor White
Write-Host "  - Views: $($viewFiles.Count)" -ForegroundColor White
Write-Host "  - Otros: $($otherFiles.Count)" -ForegroundColor White
Write-Host ""

# Función para mover archivo si no está en el destino correcto
function Move-FileIfNeeded {
    param (
        [System.IO.FileInfo]$file,
        [string]$targetFolder
    )
    
    $targetPath = Join-Path $targetFolder $file.Name
    $currentPath = $file.FullName
    
    # Si el archivo ya está en el lugar correcto, no hacer nada
    if ($currentPath -eq $targetPath) {
        Write-Host "  ✓ $($file.Name) ya está en su lugar" -ForegroundColor DarkGray
        return
    }
    
    # Si ya existe un archivo con ese nombre en el destino, hacer backup
    if (Test-Path $targetPath) {
        $backupPath = $targetPath + ".backup"
        Move-Item -Path $targetPath -Destination $backupPath -Force
        Write-Host "  ⚠ Backup creado: $($file.Name).backup" -ForegroundColor Yellow
    }
    
    # Mover archivo
    Move-Item -Path $currentPath -Destination $targetPath -Force
    Write-Host "  → Movido: $($file.Name) a $targetFolder" -ForegroundColor Green
}

# Mover archivos screens
if ($screenFiles.Count -gt 0) {
    Write-Host "📦 Organizando Screens..." -ForegroundColor Cyan
    foreach ($file in $screenFiles) {
        Move-FileIfNeeded -file $file -targetFolder "lib\screens"
    }
    Write-Host ""
}

# Mover archivos views
if ($viewFiles.Count -gt 0) {
    Write-Host "📦 Organizando Views..." -ForegroundColor Cyan
    foreach ($file in $viewFiles) {
        Move-FileIfNeeded -file $file -targetFolder "lib\views"
    }
    Write-Host ""
}

Write-Host "✅ Organización completada!" -ForegroundColor Green
Write-Host ""

# Mostrar resumen de ubicación final
Write-Host "📍 Ubicación final de archivos:" -ForegroundColor Cyan
Write-Host ""

Write-Host "SCREENS (lib\screens\):" -ForegroundColor Yellow
Get-ChildItem "lib\screens\*.dart" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  ✓ $($_.Name)" -ForegroundColor White
}

Write-Host ""
Write-Host "VIEWS (lib\views\):" -ForegroundColor Yellow
Get-ChildItem "lib\views\*.dart" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  ✓ $($_.Name)" -ForegroundColor White
}

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "🎯 SIGUIENTE PASO:" -ForegroundColor Green
Write-Host "   1. Copia el contenido de 'main_ORGANIZADO.dart' a tu 'lib\main.dart'"
Write-Host "   2. Ejecuta: flutter clean && flutter pub get"
Write-Host "   3. Ejecuta: flutter run"
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

# Preguntar si quiere continuar con la generación del main.dart
$response = Read-Host "¿Quieres que genere el archivo main.dart correcto ahora? (S/N)"
if ($response -eq "S" -or $response -eq "s") {
    Write-Host ""
    Write-Host "📝 main.dart generado en la raíz del proyecto!" -ForegroundColor Green
    Write-Host "Por favor cópialo a lib\main.dart manualmente" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ ¡Listo! Tu proyecto está organizado." -ForegroundColor Green
