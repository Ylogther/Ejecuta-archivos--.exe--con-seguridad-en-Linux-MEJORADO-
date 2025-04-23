#!/bin/bash
   #
   # Smart Launcher - Ejecución segura de .exe en Linux
   # Copyright (C) 2025 YLOGTHER
   #
   # Este programa es software libre: puedes redistribuirlo y/o modificar
   # bajo los términos de la GNU General Public License publicada por
   # la Free Software Foundation, ya sea la versión 3 o cualquier versión posterior.

# ==============================================
# SMART LAUNCHER - Ejecución Segura de .exe en Linux
# Versión: 4.2
# Autor: YLOGTHER
# ==============================================

# Configuración
CONFIG_FILE="$HOME/.config/smart_launcher.conf"
VERSION="4.2"
DATE=$(date +%Y-%m-%d)

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Cargar configuración
load_config() {
    [ -f "$CONFIG_FILE" ] || {
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" <<EOL
WINE_GAME_PREFIX="\$HOME/wine-games"
WINE_SANDBOX_PREFIX="\$HOME/wine-sandbox"
LOG_DIR="\$HOME/wine-logs"
MAX_RUNTIME=600
#API_VIRUSTOTAL="your_key_here"
EOL
    }
    source "$CONFIG_FILE"
    
    [ -z "$WINE_GAME_PREFIX" ] && WINE_GAME_PREFIX="$HOME/wine-games"
    [ -z "$WINE_SANDBOX_PREFIX" ] && WINE_SANDBOX_PREFIX="$HOME/wine-sandbox"
    [ -z "$LOG_DIR" ] && LOG_DIR="$HOME/wine-logs"
    [ -z "$MAX_RUNTIME" ] && MAX_RUNTIME=600
}

# Inicialización
init() {
    clear
    if command -v figlet &> /dev/null; then
        figlet -w 120 "YLOGTHER v$VERSION" | sed 's/#/*/g'
    else
        echo -e "${BLUE}=== SMART LAUNCHER v$VERSION ===${NC}"
    fi
    echo -e "\n\tEjecución Segura de Aplicaciones Windows en Linux"
    echo -e "\t---------------------------------------------"
    echo -e "Fecha: $DATE\n"
    
    # Crear directorios necesarios
    mkdir -p "$WINE_GAME_PREFIX" "$WINE_SANDBOX_PREFIX" "$LOG_DIR"
}

# Verificar dependencias
check_dependencies() {
    local missing=0
    local deps=(wine winetricks inotifywait lsof xdotool xterm curl)
    
    echo -e "${YELLOW}[*] Verificando dependencias...${NC}"
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${RED}[!] Falta: $dep${NC}"
            missing=1
        fi
    done
    [ $missing -eq 1 ] && exit 1
}

# Analizar ejecutable (versión mejorada)
analyze_executable() {
    local file="$1"
    BASENAME="$(basename "$file")"
    HASH=$(sha256sum "$file" | cut -d ' ' -f1)
    SIZE=$(stat -c%s "$file")
    FILE_TYPE=$(file -b "$file")
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    LOG_FILE="$LOG_DIR/analysis_${BASENAME%.*}-$TIMESTAMP.log"
    REPORT_FILE="$LOG_DIR/report_${BASENAME%.*}-$TIMESTAMP.html"
    PCAP_FILE="$LOG_DIR/network_${BASENAME%.*}-$TIMESTAMP.pcap"
    ACTIVITY_LOG="$LOG_DIR/activity_${BASENAME%.*}-$TIMESTAMP.log"
    
    IS_SUSPICIOUS=0
    WARNINGS=()
    SCORE=0
    
    # Análisis básico
    [[ "${BASENAME##*.}" != "exe" ]] && {
        WARNINGS+=("Extensión no .exe")
        ((SCORE+=10))
    }
    
    ! [[ "$FILE_TYPE" =~ "PE32" ]] && {
        WARNINGS+=("No es PE válido")
        ((SCORE+=30))
    }
    
    # Análisis de strings
    local STRINGS_ANALYSIS=$(strings "$file")
    local MALICIOUS_PATTERNS=("CreateRemoteThread" "VirtualAlloc" "http://" "https://")
    for pattern in "${MALICIOUS_PATTERNS[@]}"; do
        if grep -iq "$pattern" <<< "$STRINGS_ANALYSIS"; then
            WARNINGS+=("Patrón sospechoso: $pattern")
            ((SCORE+=15))
        fi
    done
    
    # VirusTotal
    if [ -n "$API_VIRUSTOTAL" ]; then
        local VT_RESPONSE=$(curl -s "https://www.virustotal.com/api/v3/files/$HASH" -H "x-apikey: $API_VIRUSTOTAL")
        if [[ "$VT_RESPONSE" =~ '"malicious":' ]]; then
            local MALICIOUS_COUNT=$(grep -o '"malicious": [0-9]*' <<< "$VT_RESPONSE" | awk '{print $2}')
            WARNINGS+=("Detectado por $MALICIOUS_COUNT motores")
            ((SCORE+=$((MALICIOUS_COUNT*3))))
        fi
    fi
    
    # Evaluación final
    [ $SCORE -ge 50 ] && IS_SUSPICIOUS=2
    [ $SCORE -ge 20 ] && IS_SUSPICIOUS=1
    
    # Generar reporte HTML
    generate_report
    
    # Mostrar resumen
    echo -e "\n${GREEN}=== RESUMEN DE ANÁLISIS ===${NC}"
    echo -e "Archivo: $BASENAME"
    echo -e "SHA256: $HASH"
    echo -e "Tamaño: $((SIZE/1024)) KB"
    echo -e "Puntaje riesgo: $SCORE/100"
    
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}[!] Advertencias:${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo -e " - $warning"
        done
    fi
    
    if [ $IS_SUSPICIOUS -eq 2 ]; then
        echo -e "\n${RED}[!] ALTO RIESGO: No ejecutar${NC}"
        RECOMMENDATION="3"
    elif [ $IS_SUSPICIOUS -eq 1 ]; then
        echo -e "\n${YELLOW}[!] Riesgo moderado: Usar sandbox${NC}"
        RECOMMENDATION="1"
    else
        echo -e "\n${GREEN}[*] Parece seguro${NC}"
        RECOMMENDATION="2"
    fi
    
    echo -e "\n${BLUE}[i] Reportes generados en:${NC}"
    echo -e " - Log completo: $LOG_FILE"
    echo -e " - Reporte HTML: $REPORT_FILE"
    echo -e " - Captura red: $PCAP_FILE"
    echo -e " - Log actividad: $ACTIVITY_LOG"
}

# Generar reporte HTML
generate_report() {
    cat > "$REPORT_FILE" <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>SMART LAUNCHER Report - $BASENAME</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { background: #f5f5f5; padding: 15px; border-radius: 5px; }
        .warning { color: #d35400; }
        .danger { color: #c0392b; font-weight: bold; }
        .safe { color: #27ae60; }
    </style>
</head>
<body>
    <h1>Reporte de Análisis</h1>
    <div class="summary">
        <h2>Resumen</h2>
        <p><strong>Archivo:</strong> $BASENAME</p>
        <p><strong>SHA256:</strong> $HASH</p>
        <p><strong>Tamaño:</strong> $((SIZE/1024)) KB</p>
        <p><strong>Tipo:</strong> $FILE_TYPE</p>
        <p><strong>Puntaje Riesgo:</strong> <span class="$( [ $IS_SUSPICIOUS -eq 2 ] && echo danger || [ $IS_SUSPICIOUS -eq 1 ] && echo warning || echo safe )">$SCORE/100</span></p>
    </div>
    
    <h2>Detalles</h2>
    <ul>
HTML

    for warning in "${WARNINGS[@]}"; do
        echo "<li>$warning</li>" >> "$REPORT_FILE"
    done

    cat >> "$REPORT_FILE" <<HTML
    </ul>
    
    <h2>Archivos Generados</h2>
    <ul>
        <li><strong>Log completo:</strong> $LOG_FILE</li>
        <li><strong>Captura red:</strong> $PCAP_FILE</li>
        <li><strong>Actividad:</strong> $ACTIVITY_LOG</li>
    </ul>
</body>
</html>
HTML
}

# Ejecutar en sandbox con monitorización
run_sandbox() {
    local file="$1"
    local TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    local SANDBOX_DIR="$WINE_SANDBOX_PREFIX/$TIMESTAMP"
    mkdir -p "$SANDBOX_DIR"
    
    echo -e "${YELLOW}[*] Iniciando sandbox...${NC}"
    echo -e "${BLUE}[i] Prefijo Wine: $SANDBOX_DIR${NC}"
    
    # Iniciar captura de red
    echo -e "${BLUE}[i] Iniciando captura de red...${NC}"
    nohup tcpdump -i any -w "$PCAP_FILE" >/dev/null 2>&1 &
    local TCPDUMP_PID=$!
    
    # Iniciar registro de actividad
    echo -e "${BLUE}[i] Iniciando monitor de actividad...${NC}"
    echo "=== INICIO DE REGISTRO $(date) ===" > "$ACTIVITY_LOG"
    nohup inotifywait -r -m -e modify,create,delete "$SANDBOX_DIR" >> "$ACTIVITY_LOG" 2>&1 &
    local INOTIFY_PID=$!
    
    # Ejecutar en Xterm
    xterm -T "Sandbox: $BASENAME" -e "
        echo '=== SMART LAUNCHER SANDBOX ===';
        echo 'Ejecutando: $BASENAME';
        echo 'Prefijo Wine: $SANDBOX_DIR';
        echo 'Tiempo máximo: $MAX_RUNTIME segundos';
        echo '';
        echo 'Presione Enter para continuar...';
        read;
        env WINEPREFIX=\"$SANDBOX_DIR\" wine \"$file\";
        echo '';
        echo 'La aplicación ha terminado. Esta ventana se cerrará en 5 segundos.';
        sleep 5
    " &
    local WINE_PID=$!
    
    # Monitorear proceso
    echo -e "${BLUE}[i] Monitoreando proceso (PID: $WINE_PID)...${NC}"
    while ps -p $WINE_PID > /dev/null; do
        sleep 5
    done
    
    # Limpiar
    kill $TCPDUMP_PID $INOTIFY_PID 2>/dev/null
    echo -e "${GREEN}[*] Ejecución completada${NC}"
    
    # Mostrar ubicación de archivos
    echo -e "\n${BLUE}=== ARCHIVOS GENERADOS ===${NC}"
    echo -e "${GREEN}Reporte HTML:${NC} $REPORT_FILE"
    echo -e "${GREEN}Captura red:${NC} $PCAP_FILE"
    echo -e "${GREEN}Log actividad:${NC} $ACTIVITY_LOG"
    echo -e "${GREEN}Prefijo Wine:${NC} $SANDBOX_DIR"
    
    # Abrir reporte HTML si hay xdg-open
    if command -v xdg-open &> /dev/null; then
        read -p "¿Abrir reporte HTML ahora? [s/N]: " abrir
        [[ "$abrir" =~ [sSyY] ]] && xdg-open "$REPORT_FILE"
    fi
}

# Menú principal
show_menu() {
    echo -e "\n${BLUE}=== OPCIONES ===${NC}"
    echo "1) Ejecutar en sandbox (recomendado)"
    echo "2) Ejecutar normalmente"
    echo "3) Ver reporte completo"
    echo "4) Salir"
    echo -e "\nRecomendación: $RECOMMENDATION"
    
    read -p "Seleccione [1-4] (default: $RECOMMENDATION): " choice
    choice=${choice:-$RECOMMENDATION}
    
    case $choice in
        1) run_sandbox "$1" ;;
        2) wine "$1" ;;
        3) [ -f "$REPORT_FILE" ] && xdg-open "$REPORT_FILE" || echo -e "${RED}[!] Reporte no generado aún${NC}" ;;
        4) exit 0 ;;
        *) echo -e "${RED}[!] Opción inválida${NC}"; show_menu "$1" ;;
    esac
}
  

  
# Main
[ -z "$1" ] && {
    echo -e "${RED}Uso: $0 archivo.exe${NC}"
    exit 1
}

load_config
init
check_dependencies
analyze_executable "$1"
show_menu "$1"