
```markdown
# 🚀 Smart Launcher - Ejecución Segura de .exe en Linux

**Repositorio Oficial**: [https://github.com/Ylogther/Ejecuta-archivos--.exe--con-seguridad-en-Linux-MEJORADO-](https://github.com/Ylogther/Ejecuta-archivos--.exe--con-seguridad-en-Linux-MEJORADO-)  
**Versión**: 4.2 | **Licencia**: GPLv3  
![Estado](https://img.shields.io/badge/estado-estable-brightgreen)
![Licencia](https://img.shields.io/github/license/Ylogther/Ejecuta-archivos--.exe--con-seguridad-en-Linux-MEJORADO-?color=blue)

Herramienta profesional para ejecutar aplicaciones Windows (.exe) en Linux con análisis de seguridad avanzado y entorno aislado.
```
## 📦 Instalación

### Requisitos previos:

# Arch Linux/Manjaro:
```bash
sudo pacman -S --needed wine winetricks inotify-tools lsof xdotool xterm curl tcpdump figlet bubblewrap firejail pev manalyze yad scrot wrestool jq
```

### Explicación de las dependencias:

1. *Básicas* (esenciales para el funcionamiento):
   - wine, winetricks: Entorno para ejecutables Windows
   - inotify-tools, lsof: Monitorización de archivos
   - xdotool, xterm: Interfaz gráfica
   - curl, tcpdump: Análisis de red

2. *Recomendadas* (funcionalidad extendida):
   - figlet: Para el banner ASCII
   - bubblewrap, firejail: Sandboxing avanzado
   - pev, manalyze: Análisis de binarios
   - yad: Diálogos gráficos
   - scrot: Capturas de pantalla
   - wrestool: Análisis de recursos
   - jq: Procesamiento de JSON (para VirusTotal)

### Si prefieres instalarlas por categorías:

*Mínimas requeridas*:
```bash
sudo pacman -S --needed wine winetricks inotify-tools lsof xdotool xterm curl
```

*Para análisis avanzado*:
```bash
sudo pacman -S --needed tcpdump pev manalyze wrestool jq
```

*Para sandboxing mejorado*:
```bash
sudo pacman -S --needed bubblewrap firejail
```

*Para interfaz gráfica*:
```bash 
sudo pacman -S --needed yad figlet scrot

```

# Debian/Ubuntu:
```bash
sudo apt update && sudo apt install wine winetricks inotify-tools lsof xdotool xterm curl tcpdump
```
# Fedora:
```bash
sudo dnf install wine winetricks inotify-tools lsof xdotool xterm curl tcpdump
```

### Instalar desde el repositorio
```bash
git clone https://github.com/Ylogther/Ejecuta-archivos--.exe--con-seguridad-en-Linux-MEJORADO-.git
cd Ejecuta-archivos--.exe--con-seguridad-en-Linux-MEJORADO-
chmod +x smart_launcher.sh
```

## 🛠️ Características Principales

- 🔍 **Análisis heurístico mejorado** con 50+ patrones maliciosos
- 🛡️ **Doble modo de ejecución**: Sandbox (aislado) y Normal
- 📂 **Sistema de reportes completo**:
  - Reporte HTML interactivo
  - Captura de red en formato PCAP
  - Log de actividad detallado
  - Análisis técnico completo
- ⚡ **Integración con VirusTotal** (opcional)

## 🖥️ Uso Básico

```bash
./smart_launcher.sh aplicacion.exe
```

**Opciones del menú**:
1. 🛡️ Modo Sandbox (recomendado)
2. ⚡ Modo Normal (solo para software confiable)
3. 📄 Ver reporte completo
4. 🚪 Salir

## 📂 Estructura de Archivos

```
~/wine-logs/
├── analysis_[nombre]_[fecha-hora].log    # Log completo
├── report_[nombre]_[fecha-hora].html     # Reporte visual
├── network_[nombre]_[fecha-hora].pcap    # Captura de red
└── activity_[nombre]_[fecha-hora].log    # Registro de actividad
```

## 🛡️ Niveles de Seguridad

| Nivel       | Color  | Puntaje | Acción Recomendada               |
|-------------|--------|---------|-----------------------------------|
| Alto Riesgo | 🔴     | 50+     | No ejecutar - Eliminar archivo    |
| Riesgo Medio| 🟡     | 20-49   | Usar solo en sandbox estricto     |
| Bajo Riesgo | 🟢     | 0-19    | Ejecución normal con supervisión  |

## ⚙️ Configuración Avanzada

Edite `~/.config/smart_launcher.conf`:
```ini
# Directorios base
WINE_GAME_PREFIX="$HOME/wine-games"
WINE_SANDBOX_PREFIX="$HOME/wine-sandbox"

# Configuración de logs
LOG_DIR="$HOME/wine-logs"
MAX_RUNTIME=600  # Tiempo máximo en segundos

# Integración VirusTotal (opcional)
#API_VIRUSTOTAL="tu_clave_aqui"
```

## 📌 Ejemplo Práctico

```bash
$ ./smart_launcher juego.exe

=== SMART LAUNCHER v4.2 ===
[*] Analizando juego.exe...
[!] 3 patrones maliciosos detectados
[✓] VirusTotal: 2/70 detecciones

=== ARCHIVOS GENERADOS ===
📄 Reporte: /home/user/wine-logs/report_juego-20230815-1423.html
🌐 Red: /home/user/wine-logs/network_juego-20230815-1423.pcap
📝 Actividad: /home/user/wine-logs/activity_juego-20230815-1423.log
```

## 📜 Licencia

Este proyecto está bajo la licencia [GPLv3](https://www.gnu.org/licenses/gpl-3.0.html).

---
**Nota importante**: Ningún sistema de análisis es 100% efectivo. Siempre ejerza precaución con archivos desconocidos.

   
**Licencia**: GPLv3  
**Autor**: YLOGTHER  
**Contacto**: github.com/Ylogther/Ejecuta-archivos--.exe--con-seguridad-en-Linux-MEJORADO-.git



