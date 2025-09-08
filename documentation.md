# Foody Projekt Dokumentation

## 3.1 Management Summary

Foody ist eine umfassende Webanwendung zur Verwaltung und zum Austausch von Kochrezepten. Ziel des Projekts ist es, Hobbyköche und Profi‑Küchen gleichermaßen zu vernetzen, Rezepte mit strukturierten Daten zu erfassen und über eine moderne Weboberfläche oder eine REST‑API zu verbreiten. Die Lösung basiert auf Python und dem Microframework Flask. Persistente Daten werden mit SQLAlchemy verwaltet und in einer PostgreSQL‑Datenbank gespeichert. Zur Erhöhung der Performance und Skalierbarkeit kommen zusätzlich Redis als Cache sowie Elasticsearch als Suchindex zum Einsatz.

Die Infrastruktur ist containerbasiert realisiert: Eine lokale Entwicklungsumgebung lässt sich mit Docker Compose starten, während für die Produktion ein automatisiertes Deployment‑Skript bereitsteht. Der Webserver Gunicorn bedient die Flask‑Applikation hinter einem Nginx‑Reverse‑Proxy. Durch Health‑Checks, strukturierte Logs und optionale Mail‑Benachrichtigungen ist der Betrieb über mehrere Wochen hinweg stabil zu gewährleisten.

Im Mittelpunkt steht die Rezept‑ und Bewertungsverwaltung: Nutzer können Rezepte anlegen, sie über Kategorien und Schwierigkeitsgrade strukturieren und ein 1‑5‑Sterne‑Bewertungssystem verwenden. Eine leistungsfähige Volltextsuche hilft beim Auffinden von Rezepten. Die REST‑API erlaubt es Drittänwendungen, dieselben Funktionen abzurufen oder automatisierte Workflows aufzubauen. Als größter Vorteil erweist sich die modulare Architektur; größten Risiken liegen in der Komplexität der Multi‑Container‑Umgebung und der Korrektheit der Authentisierungslogik.

Das Projekt wurde in mehreren Iterationen nach agilen Prinzipien umgesetzt. Ein kleines Entwicklerteam koordinierte sich über Git und Issues, wobei jede Iteration einen klar definierten Funktionsumfang hatte. Wirtschaftlich betrachtet ermöglicht Foody den Aufbau einer Community‑Plattform, die sich perspektivisch über Premium‑Funktionen oder Werbepartner monetarisieren ließe. Als Erfolgskriterien gelten eine hohe Verfügbarkeit, geringe Latenzzeiten und eine wachsende Nutzerbasis.

## 3.2 Anwendung

### 3.2.1 Wichtige Anwendungsfunktionen

Foody deckt den kompletten Lebenszyklus eines Rezepts ab:

* **Erstellen und Bearbeiten** – Neue Rezepte werden mit Titel, Beschreibung, Zutatenliste, Arbeitsschritten sowie optionalen Metadaten wie Kategorie, Schwierigkeitsgrad, Portionen oder Bildern angelegt. 
* **Bewerten und Kommentieren** – Ein 1‑5‑Sterne‑System erlaubt differenzierte Bewertungen. Nutzer können ihre Bewertungen jederzeit anpassen oder entfernen.
* **Folgen und Entdecken** – Anwender folgen anderen Köchen und erhalten so eine personalisierte Rezeptübersicht. Eine Volltextsuche über Titel, Beschreibung und Zutaten unterstützt beim Auffinden bestimmter Gerichte.
* **Benachrichtigungen und Aufgaben** – Hintergrundaufgaben (z. B. E‑Mail‑Versand) werden über RQ gesteuert; Benachrichtigungen informieren über neue Interaktionen.

### 3.2.2 Benutzerhandbuch ("User Manual")

#### Installation und Start

1. **Repository klonen**
   ```bash
   git clone <your-repo-url>
   cd foody
   ```
2. **Virtuelle Umgebung einrichten**
   ```bash
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```
3. **Datenbank initialisieren**
   ```bash
   flask db upgrade
   ```
4. **Anwendung starten**
   ```bash
   python foody.py
   ```
5. **Zugriff**
   * Weboberfläche: http://localhost:5002
   * REST‑API: http://localhost:5002/api

#### Docker‑basierte Testumgebung

1. **Automatisiertes Testing**
   ```bash
   ./test-local.sh
   ```
2. **Container‑Endpunkte**
   * Web: http://localhost:5001
   * Health Check: http://localhost:5001/health
   * API: http://localhost:5001/api

#### Wichtige Benutzeraktionen

* Registrierung über das Web‑Frontend oder die API
* Anmelden und Token‑Verwaltung zur abgesicherten API‑Nutzung
* Rezept anlegen, bearbeiten, löschen
* Rezepte bewerten (1‑5 Sterne)
* Andere Benutzer folgen oder entfolgen

### 3.2.3 API‑Kurzbeschreibung

Die REST‑API folgt klaren, RESTful Prinzipien. Wichtige Endpunkte:

| Methode | Endpoint | Beschreibung |
|---------|----------|--------------|
| GET | `/api/recipes` | Liste paginierter Rezepte, optional gefiltert nach Kategorie, Schwierigkeit oder Autor |
| POST | `/api/recipes` | Neues Rezept anlegen (authentifiziert) |
| GET | `/api/recipes/<id>` | Einzelnes Rezept anzeigen |
| PUT | `/api/recipes/<id>` | Rezept aktualisieren (nur Autor) |
| DELETE | `/api/recipes/<id>` | Rezept löschen (nur Autor) |
| GET | `/api/recipes/search?q=...` | Volltextsuche über Titel, Beschreibung, Zutaten |
| GET | `/api/recipes/<id>/ratings` | Bewertungen eines Rezepts abrufen |
| POST | `/api/recipes/<id>/ratings` | Rezept bewerten (authentifiziert) |
| DELETE | `/api/recipes/<id>/ratings` | Eigene Bewertung entfernen |

Antworten enthalten standardisierte JSON‑Strukturen mit Hypermedia Links für einfache Navigation.

### 3.2.4 Architektur und Datenmodell

#### Systemarchitektur

```text
[Browser/Client]
      |
[Flask + Gunicorn] — REST/HTML
      |
[PostgreSQL]   [Redis]   [Elasticsearch]
      |          |            |
   persistente  Cache    Volltextsuche
```

* **Flask/Gunicorn** bildet das Backend und bedient HTTP‑Anfragen.
* **PostgreSQL** speichert Nutzer, Rezepte, Bewertungen und Nachrichten.
* **Redis** dient als Cache und Message Queue für Hintergrundaufgaben.
* **Elasticsearch** stellt eine leistungsfähige Suche bereit.
* **Nginx** (im Deployment) agiert als Reverse Proxy und liefert statische Dateien.

#### Datenmodell (Auszug)

```text
User 1—N Recipe
User 1—N Rating
Recipe 1—N Rating
User N—M User (Follower)
```

* **User**: Enthält Login‑Informationen, Profildaten und Beziehungen zu Rezepten, Bewertungen sowie Followern.
* **Recipe**: Repräsentiert Kochrezepte mit Texten und Metadaten.
* **Rating**: Verknüpft Nutzer und Rezepte mit einer 1‑5‑Sterne‑Bewertung.
* **Follower‑Tabelle**: Ermöglicht wechselseitige Nutzerverbindungen.

### 3.2.5 Evaluationsübersicht

Zur Qualitätssicherung kommen Unit‑Tests für zentrale Modellfunktionen zum Einsatz. Die Tests prüfen u. a. Passwort‑Hashing, Generierung von Avatar‑URLs, Follow‑Mechanismen und das Zusammenstellen personalisierter Rezeptlisten. In der aktuellen Revision schlugen drei Tests erfolgreich an, während ein Test aufgrund veralteter Modellbezeichnungen fehlschlug (Details im Testprotokoll).

### 3.2.6 Testprotokoll

| Nr. | Testfall | Kategorie | Ergebnis |
|----:|----------|-----------|----------|
| 1 | `test_password_hashing` – Prüft, ob falsches Passwort abgewiesen und korrektes akzeptiert wird | Unit‑Test | Bestanden |
| 2 | `test_avatar` – Validiert die Generierung der Gravatar‑URL | Unit‑Test | Bestanden |
| 3 | `test_follow` – Testet Folgen und Entfolgen von Nutzern | Unit‑Test | Bestanden |
| 4 | `test_follow_posts` – Stellt sicher, dass gefolgte Rezepte korrekt aggregiert werden | Unit‑Test | Fehlgeschlagen (Model‑Refactoring erforderlich) |
| 5 | Registrierung über Weboberfläche | Manuell | Erfolgreich |
| 6 | Rezept anlegen, bearbeiten und löschen | Manuell | Erfolgreich |
| 7 | 1‑5‑Sterne‑Bewertung abgeben | Manuell | Erfolgreich |
| 8 | Volltextsuche nach Zutaten | Manuell | Erfolgreich |
| 9 | API‑Authentifizierung via Token | Manuell | Erfolgreich |
|10 | Health‑Check über `/health` | Manuell | Erfolgreich |

Die Unit‑Tests lassen sich mit `python tests.py` ausführen; für manuelle Tests sind Browser und `curl` die bevorzugten Werkzeuge. Eine kontinuierliche Integration ist vorgesehen und kann in einer CI/CD‑Pipeline eingebunden werden.

## 3.3 Technologie‑Stack und eingesetzte Tools

Foody kombiniert bewährte Open‑Source‑Komponenten zu einer modernen, wartbaren Plattform.

### Programmiersprachen und Bibliotheken

| Komponente | Zweck |
|------------|-------|
| **Python 3.11** | Zentrale Programmiersprache, unterstützt Typannotationen und aktuelle Sprachfeatures |
| **Flask** | Microframework für Routing, Templating und Request‑Handling |
| **Jinja2** | Template‑Engine für die HTML‑Ausgabe |
| **SQLAlchemy 2.0** | Objekt‑Relationale Abbildung, nutzt moderne ``Mapped``‑Typisierung |
| **Flask‑Login** | Sitzungsverwaltung und Benutzer‑Authentifizierung |
| **Flask‑WTF** | Formularverarbeitung mit CSRF‑Schutz |
| **Flask‑Migrate/Alembic** | Datenbank‑Migrationen und Schema‑Versionierung |
| **Flask‑Babel** | Internationalisierung und Lokalisierung |
| **RQ** | Warteschlange für Hintergrundaufgaben |

### Infrastrukturkomponenten

* **PostgreSQL** – Relationale Datenbank, optimiert für ACID‑konforme Transaktionen.
* **Redis** – In‑Memory‑Store für Caching und als Backend für RQ.
* **Elasticsearch** – Volltextsuche mit hoher Performanz.
* **Docker & Docker Compose** – Isolation der Dienste und reproduzierbare Entwicklungsumgebungen.
* **Gunicorn & Nginx** – Produktionsfertiger WSGI‑Server hinter einem Reverse‑Proxy.
* **GitHub Actions (optional)** – Automatisierung von Tests und Linting in CI/CD‑Pipelines.

## 3.4 Entwicklungsprozess und Qualitätsstandards

Der Entwicklungsprozess folgt einer schlanken, iterativen Vorgehensweise:

1. **Versionsverwaltung** – Jede Änderung erfolgt über Git‑Branches mit aussagekräftigen Commit‑Nachrichten.
2. **Code‑Reviews** – Pull‑Requests werden geprüft, um Stilrichtlinien und Architekturvorgaben sicherzustellen.
3. **Tests** – Unit‑Tests decken zentrale Modelle und Geschäftslogik ab; zukünftige Erweiterungen sind geplant.
4. **Dokumentation** – Alle Features werden in `documentation.md` und im Quellcode mittels Docstrings erläutert.

## 3.5 Sicherheits‑ und Datenschutzkonzept

* **Passwortsicherheit** – Passwörter werden mit `generate_password_hash` gehasht und nie im Klartext gespeichert.
* **Token‑Authentifizierung** – Zeitlich begrenzte Tokens sichern API‑Anfragen; ein Revoke‑Mechanismus verhindert Missbrauch.
* **CSRF‑Schutz** – Formulare nutzen Flask‑WTF, um Cross‑Site‑Request‑Forgery zu verhindern.
* **HTTPS‑Betrieb** – In der Produktion wird Nginx so konfiguriert, dass sämtliche Kommunikation verschlüsselt erfolgt.
* **Datensparsamkeit** – Gespeicherte Benutzerinformationen werden auf das notwendige Minimum reduziert.
* **Backups** – Regelmäßige Datenbank‑Backups sowie Export der Docker‑Volumes sichern den Datenbestand.

## 3.6 Deployment und Betrieb

Der Betrieb kann lokal, per Docker Compose oder auf Cloud‑Plattformen erfolgen.

1. **Konfiguration** – Sämtliche Einstellungen wie `SECRET_KEY`, Mail‑Server oder Datenbank‑URL werden über Umgebungsvariablen definiert.
2. **Container‑Build** – `docker-compose.yml` orchestriert Web, Datenbank, Redis und Elasticsearch.
3. **Logging & Monitoring** – Strukturierte Logs in JSON‑Form erleichtern die Auswertung; `/health`‑Endpunkte dienen als einfache Monitoring‑Schnittstelle.
4. **Skalierung** – Gunicorn lässt sich über die Anzahl der Worker skalieren, Redis kann als zentraler Cache horizontal erweitert werden.
5. **Recovery** – Backup‑Strategien und Versionsverwaltung ermöglichen eine schnelle Wiederherstellung bei Fehlern.

## 3.7 Risikoanalyse und Gegenmaßnahmen

| Risiko | Auswirkung | Gegenmaßnahme |
|--------|------------|---------------|
| Komplexe Multi‑Container‑Umgebung | Fehler beim Deployment oder in der Kommunikation zwischen Diensten | Einsatz von Compose‑Profiles, automatisierte Integrationstests |
| Veraltete Abhängigkeiten | Sicherheitslücken, Inkompatibilitäten | Regelmäßige Updates und Dependabot‑Überwachung |
| Fehlende Tests für neue Features | Regressionen im Produktivbetrieb | Ausbau der Testabdeckung und CI‑Pflicht für Merges |
| Fehlkonfiguration von Tokens | Unautorisierter Zugriff | Klare Ablaufzeiten und Protokollierung von Token‑Ausgaben |

## 3.8 Fazit und Ausblick

Foody demonstriert, wie sich mit überschaubarem Aufwand eine funktionsreiche Webplattform realisieren lässt. Die Kombination aus klarer REST‑API, responsiver Oberfläche und durchdachter Architektur ermöglicht eine flexible Weiterentwicklung. Geplante Erweiterungen betreffen eine mobile App, ein Rollen‑ und Rechtekonzept sowie zusätzliche Analysen über Nutzerinteraktionen. Ebenso steht die Behebung des fehlgeschlagenen Unit‑Tests sowie der Ausbau automatisierter End‑to‑End‑Tests auf der Roadmap.

---

Diese Dokumentation bündelt Management Summary, Benutzerhandbuch, Technologieübersicht, Sicherheitskonzept, Architektur‑Darstellung sowie Testnachweis und dient als umfassende Grundlage für die schriftliche Ausarbeitung der Arbeit.

