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

# >>> FIREJAIL: Generar perfil si no existe
generate_firejail_profile() {
    local profile_path="$HOME/.config/firejail/wine.profile"
    if [ ! -f "$profile_path" ]; then
        mkdir -p "$(dirname "$profile_path")"
        cat > "$profile_path" <<EOF
include /etc/firejail/wine.profile
whitelist \$WINE_SANDBOX_PREFIX
private-dev
nogroups
nosound
seccomp
caps.drop all
netfilter
net none
EOF
        echo -e "${GREEN}[+] Perfil Firejail generado: $profile_path${NC}"
    fi
}

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

    generate_firejail_profile # >>> FIREJAIL
}

init() {
    clear
    if command -v figlet &> /dev/null; then
        figlet -w 120 "YLOGTHERv$VERSION" | sed 's/#/*/g'
    else
        echo -e "${BLUE}=== SMART LAUNCHER v$VERSION ===${NC}"
    fi
    echo -e "\n\tEjecución Segura de Aplicaciones Windows en Linux"
    echo -e "\t---------------------------------------------"
    echo -e "Fecha: $DATE\n"
    
    mkdir -p "$WINE_GAME_PREFIX" "$WINE_SANDBOX_PREFIX" "$LOG_DIR"
}

check_dependencies() {
    local missing=0
    local deps=(wine winetricks inotifywait lsof xdotool xterm curl tcpdump firejail) # >>> FIREJAIL
    echo -e "${YELLOW}[*] Verificando dependencias...${NC}"
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${RED}[!] Falta: $dep${NC}"
            missing=1
        fi
    done
    [ $missing -eq 1 ] && exit 1
}

# (Resto del código del análisis se mantiene igual...)

# Ejecutar en sandbox con Firejail si aplica
run_sandbox() {
    local file="$1"
    local TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    local SANDBOX_DIR="$WINE_SANDBOX_PREFIX/$TIMESTAMP"
    mkdir -p "$SANDBOX_DIR"
    
    echo -e "${YELLOW}[*] Iniciando sandbox...${NC}"
    echo -e "${BLUE}[i] Prefijo Wine: $SANDBOX_DIR${NC}"
    
    echo -e "${BLUE}[i] Iniciando captura de red...${NC}"
    nohup tcpdump -i any -w "$PCAP_FILE" >/dev/null 2>&1 &
    local TCPDUMP_PID=$!

    echo -e "${BLUE}[i] Iniciando monitor de actividad...${NC}"
    echo "=== INICIO DE REGISTRO $(date) ===" > "$ACTIVITY_LOG"
    nohup inotifywait -r -m -e modify,create,delete "$SANDBOX_DIR" >> "$ACTIVITY_LOG" 2>&1 &
    local INOTIFY_PID=$!

    local firejail_cmd="env WINEPREFIX=\"$SANDBOX_DIR\" wine \"$file\""

    # >>> FIREJAIL: Forzar Firejail si riesgo >= 1
    if [ "$IS_SUSPICIOUS" -ge 1 ]; then
        echo -e "${YELLOW}[!] Modo Firejail activado por riesgo${NC}"
        firejail_cmd="firejail --profile=$HOME/.config/firejail/wine.profile --net=none --env=WINEPREFIX=\"$SANDBOX_DIR\" wine \"$file\""
    fi

    xterm -T "Sandbox: $BASENAME" -e "
        echo '=== SMART LAUNCHER SANDBOX ===';
        echo 'Ejecutando: $BASENAME';
        echo 'Prefijo Wine: $SANDBOX_DIR';
        echo 'Presione Enter para continuar...';
        read;
        $firejail_cmd;
        echo 'La aplicación ha terminado. Esta ventana se cerrará en 5 segundos.';
        sleep 5
    " &
    local WINE_PID=$!

    echo -e "${BLUE}[i] Monitoreando proceso (PID: $WINE_PID)...${NC}"
    while ps -p $WINE_PID > /dev/null; do
        sleep 5
    done

    kill $TCPDUMP_PID $INOTIFY_PID 2>/dev/null
    echo -e "${GREEN}[*] Ejecución completada${NC}"

    echo -e "\n${BLUE}=== ARCHIVOS GENERADOS ===${NC}"
    echo -e "${GREEN}Reporte HTML:${NC} $REPORT_FILE"
    echo -e "${GREEN}Captura red:${NC} $PCAP_FILE"
    echo -e "${GREEN}Log actividad:${NC} $ACTIVITY_LOG"
    echo -e "${GREEN}Prefijo Wine:${NC} $SANDBOX_DIR"

    if command -v xdg-open &> /dev/null; then
        read -p "¿Abrir reporte HTML ahora? [s/N]: " abrir
        [[ "$abrir" =~ [sSyY] ]] && xdg-open "$REPORT_FILE"
    fi
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
