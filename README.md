# CertBlitz

**Languages:** 🇺🇸 [English](https://github.com/rzme/CertBlitz-English) • 🇷🇺 [Русский](https://github.com/rzme/CertBlitz-Russian) • 🇩🇪 [Deutsch](https://github.com/rzme/CertBlitz-Deutsch)

Automatisierte SSL-Zertifikat-Einrichtung ohne Konfigurationsdateien-Kopfschmerzen.

## Was macht es

Richtet nginx ein und bezieht SSL-Zertifikate von Let's Encrypt. Sie führen das Skript aus und beantworten einige Fragen zu Ihrer Domain und dem Speicherort der Dateien.

Ich habe das erstellt, weil ich es leid war, immer wieder dieselbe nginx + certbot Konfiguration durchzuführen. Jetzt ist es automatisiert.

## Verwendung

Herunterladen und ausführen:

**Mit wget:**
```bash
wget https://raw.githubusercontent.com/rzme/CertBlitz-Deutsch/main/ssl-setup.sh
chmod +x ssl-setup.sh
sudo ./ssl-setup.sh
```

**Mit curl:**
```bash
curl -O https://raw.githubusercontent.com/rzme/CertBlitz-Deutsch/main/ssl-setup.sh
chmod +x ssl-setup.sh
sudo ./ssl-setup.sh
```

Das Skript fragt Sie nach:
- Ihrem Domain-Namen
- E-Mail für Let's Encrypt Benachrichtigungen  
- Wo die Website-Dateien gespeichert werden sollen (Standard `/var/www/` oder benutzerdefinierter Pfad)

Das war's. Dauert etwa 2-3 Minuten je nach Internetverbindung.

## Voraussetzungen

- Domain, die auf Ihren Server zeigt
- Root-Zugriff
- Internetverbindung

Das Skript prüft, ob nginx und certbot installiert sind. Falls nicht, fragt es nach der Installation.

## Funktioniert auf

- Debian/Ubuntu (verwendet apt)
- RHEL/CentOS/Fedora (verwendet dnf/yum)
- Arch Linux (verwendet pacman)

Könnte auf anderen Systemen funktionieren, wurde aber nicht getestet.

## Nach der Ausführung

Ihre Website ist unter `https://ihredomain.com` mit funktionierendem SSL verfügbar. Das Zertifikat erneuert sich automatisch per cron-Job.

Die Dateistruktur sieht etwa so aus:
```
/var/www/ihreseite/index.html   # Ersetzen Sie dies durch Ihre echte Website
/etc/nginx/sites-available/     # Nginx-Konfiguration wird hier erstellt
```

## Bei Problemen

**Domain funktioniert nicht?**
Prüfen Sie, ob DNS auf Ihren Server zeigt und die Ports 80/443 geöffnet sind.

**Zertifikat fehlgeschlagen?**  
Normalerweise bedeutet das, dass das Domain-DNS nicht richtig eingerichtet ist oder ein anderer Webserver läuft.

**Weitere Domains hinzufügen?**
Führen Sie das Skript einfach erneut aus.

## Hinweise

Dieses Skript modifiziert nginx-Konfigurationen und installiert Software als root. Ich habe es getestet, aber Server sind unterschiedlich. Testen Sie es eventuell zuerst auf einem Testserver, wenn Sie unsicher sind.

Haftungsausschluss: Ich bin nicht verantwortlich, wenn etwas kaputt geht. Verwenden Sie gesunden Menschenverstand.

## Beitragen

Haben Sie einen Bug gefunden oder eine Verbesserungsidee? Pull Requests sind willkommen. Halten Sie es jedoch einfach.

---

Erstellt von [rzztked](https://github.com/rzme), weil manuelle SSL-Einrichtung langweilig ist.
