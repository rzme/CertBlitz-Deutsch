#!/bin/bash

# SSL-Zertifikat Automatisches Setup-Skript
# Autor: rzztked
# GitHub: https://github.com/rzme/CertBlitz-German
# Konfiguriert automatisch SSL-Zertifikate mit Let's Encrypt und Nginx

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funktionen
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[FEHLER] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNUNG] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Root-Berechtigung prüfen
if [ "$EUID" -ne 0 ]; then
    error "Bitte führen Sie das Skript mit sudo aus"
fi

# Betriebssystem erkennen
detect_os() {
    if [ -f /etc/debian_version ]; then
        OS="debian"
        DISTRO=$(lsb_release -si 2>/dev/null || echo "Debian")
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"
        DISTRO=$(cat /etc/redhat-release | awk '{print $1}')
    elif [ -f /etc/arch-release ]; then
        OS="arch"
        DISTRO="Arch"
    else
        OS="unknown"
        DISTRO="Unknown"
    fi
    info "Erkanntes System: $DISTRO ($OS)"
}

# Pakete je nach System installieren
install_package() {
    local package=$1
    case $OS in
        "debian")
            apt update && apt install -y $package
            ;;
        "rhel")
            if command -v dnf &> /dev/null; then
                dnf install -y $package
            else
                yum install -y $package
            fi
            ;;
        "arch")
            pacman -Sy --noconfirm $package
            ;;
        *)
            error "Nicht unterstütztes System. Bitte installieren Sie $package manuell."
            ;;
    esac
}

# Nginx prüfen und installieren
check_nginx() {
    if ! command -v nginx &> /dev/null; then
        warning "Nginx nicht gefunden"
        read -p "Nginx installieren? (j/N): " install_nginx
        if [[ "$install_nginx" =~ ^[JjYy]$ ]]; then
            log "Installiere nginx..."
            install_package nginx
            systemctl enable nginx
            systemctl start nginx
        else
            error "Nginx ist erforderlich. Beende Vorgang."
        fi
    else
        log "Nginx ist installiert"
    fi
}

# Certbot prüfen und installieren
check_certbot() {
    if ! command -v certbot &> /dev/null; then
        warning "Certbot nicht gefunden"
        read -p "Certbot installieren? (j/N): " install_certbot
        if [[ "$install_certbot" =~ ^[JjYy]$ ]]; then
            log "Installiere certbot..."
            
            # Zuerst snap versuchen
            if command -v snap &> /dev/null; then
                snap install core && snap refresh core
                snap install --classic certbot
                ln -sf /snap/bin/certbot /usr/bin/certbot
            else
                # Fallback auf Paketmanager
                case $OS in
                    "debian")
                        install_package snapd || install_package certbot
                        ;;
                    "rhel")
                        install_package snapd || install_package certbot
                        ;;
                    "arch")
                        install_package certbot
                        ;;
                esac
            fi
        else
            error "Certbot ist erforderlich. Beende Vorgang."
        fi
    else
        log "Certbot ist installiert"
    fi
}

# Hauptskript
echo -e "${GREEN}"
echo "================================================"
echo "             CertBlitz v1.0"
echo "    https://github.com/rzme/CertBlitz-German"
echo "              by rzztked"
echo "================================================"
echo -e "${NC}"

# Betriebssystem erkennen
detect_os

# Benutzereingaben
read -p "Domain-Name eingeben: " DOMAIN
if [[ -z "$DOMAIN" ]]; then
    error "Domain-Name ist erforderlich"
fi

read -p "E-Mail für Let's Encrypt eingeben: " EMAIL
if [[ -z "$EMAIL" ]]; then
    error "E-Mail ist erforderlich"
fi

echo ""
echo "Installationspfad wählen:"
echo "1) Standard (/var/www/)"
echo "2) Benutzerdefinierter Pfad"
read -p "Option wählen (1/2): " path_option

case $path_option in
    1)
        read -p "Ordnername eingeben (z.B. 'meineseite'): " FOLDER_NAME
        if [[ -z "$FOLDER_NAME" ]]; then
            error "Ordnername ist erforderlich"
        fi
        WEBROOT="/var/www/$FOLDER_NAME"
        ;;
    2)
        read -p "Vollständigen Pfad eingeben: " CUSTOM_PATH
        if [[ -z "$CUSTOM_PATH" ]]; then
            error "Pfad ist erforderlich"
        fi
        WEBROOT="$CUSTOM_PATH"
        ;;
    *)
        error "Ungültige Option"
        ;;
esac

NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
NGINX_ENABLED="/etc/nginx/sites-enabled/$DOMAIN"

log "Konfiguration:"
log "Domain: $DOMAIN"
log "E-Mail: $EMAIL"
log "Webroot: $WEBROOT"

# Systemprüfungen
check_nginx
check_certbot

# Website-Verzeichnis erstellen
log "Erstelle Website-Verzeichnis..."
mkdir -p "$WEBROOT"

# Testseite erstellen
cat > "$WEBROOT/index.html" << EOF
<!DOCTYPE html>
<html lang="de">
<head>
    <title>$DOMAIN</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; text-align: center; }
        .container { max-width: 600px; margin: 0 auto; }
        .success { color: #28a745; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="success">Willkommen auf $DOMAIN</h1>
        <p>SSL-Zertifikat erfolgreich konfiguriert!</p>
        <p>Setup abgeschlossen am: $(date)</p>
        <hr>
        <small>Konfiguriert mit <a href="https://github.com/rzme/CertBlitz-German">CertBlitz</a> by rzztked</small>
    </div>
</body>
</html>
EOF

# Nginx-Konfiguration erstellen
log "Erstelle nginx-Konfiguration..."
cat > "$NGINX_CONF" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    root $WEBROOT;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ /.well-known/acme-challenge {
        allow all;
        root $WEBROOT;
    }
}
EOF

# Seite aktivieren
log "Aktiviere Website..."
ln -sf "$NGINX_CONF" "$NGINX_ENABLED"

# Nginx-Konfiguration testen
log "Teste nginx-Konfiguration..."
if ! nginx -t; then
    error "Fehler in nginx-Konfiguration"
fi

# Nginx neu laden
log "Lade nginx neu..."
systemctl reload nginx

# Domain-Erreichbarkeit prüfen
log "Prüfe Domain-Erreichbarkeit..."
if ! curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN" | grep -q "200"; then
    warning "Domain $DOMAIN ist möglicherweise nicht erreichbar. Stellen Sie sicher, dass DNS korrekt konfiguriert ist."
    read -p "Mit SSL-Zertifikat fortfahren? (j/N): " continue_ssl
    if [[ ! "$continue_ssl" =~ ^[JjYy]$ ]]; then
        exit 1
    fi
fi

# SSL-Zertifikat beziehen
log "Beziehe SSL-Zertifikat von Let's Encrypt..."
if certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL" --redirect; then
    log "SSL-Zertifikat erfolgreich bezogen und konfiguriert!"
else
    error "SSL-Zertifikat konnte nicht bezogen werden"
fi

# Auto-Erneuerung einrichten
log "Richte automatische Zertifikat-Erneuerung ein..."
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

# Abschlusstests
log "Abschließender nginx-Test..."
nginx -t && systemctl reload nginx

# SSL testen
log "Teste SSL-Verbindung..."
sleep 2
if curl -s -I "https://$DOMAIN" | grep -q "HTTP/"; then
    log "✅ SSL-Zertifikat funktioniert korrekt!"
    log "🌐 Ihre Website ist verfügbar unter: https://$DOMAIN"
else
    warning "Mögliche SSL-Probleme. Prüfen Sie die Konfiguration."
fi

# Zertifikat-Informationen anzeigen
log "Zertifikat-Informationen:"
certbot certificates -d "$DOMAIN"

# Erfolgsmeldung
echo -e "${GREEN}"
echo "==========================================="
echo "🎉 SETUP ERFOLGREICH ABGESCHLOSSEN!"
echo "==========================================="
echo "Domain: https://$DOMAIN"
echo "Nginx-Konfiguration: $NGINX_CONF"
echo "Webroot: $WEBROOT"
echo "Auto-Erneuerung: Aktiviert"
echo "==========================================="
echo -e "${NC}"

# Empfehlungen
echo -e "${YELLOW}Empfehlungen:${NC}"
echo "1. Testen Sie Ihre Website: https://$DOMAIN"
echo "2. Firewall konfigurieren: ufw allow 'Nginx Full'"
echo "3. Logs prüfen: tail -f /var/log/nginx/error.log"
echo "4. SSL-Test: https://www.ssllabs.com/ssltest/"
echo ""
echo -e "${BLUE}CertBlitz by rzztked${NC}"
echo -e "${BLUE}https://github.com/rzme/CertBlitz-German${NC}"
