LANGUAGE_PRIMARY:      Python 3.11+
FRAMEWORK_FRONTEND:    None
FRAMEWORK_BACKEND:     Click (argument parsing)
DATABASE:              SQLite (optional, for stateful CLIs)
ORM:                   sqlite3 stdlib or SQLAlchemy if complex
AUTH:                  None (CLIs run as the local user)
AI_ORCHESTRATION:      None

FRONTEND_PLATFORM:     N/A
BACKEND_PLATFORM:      pip / pipx for distribution
FRONTEND_PORT_LOCAL:   N/A
BACKEND_PORT_LOCAL:    N/A
DATABASE_PORT:         N/A

UNIT:                  pytest
COMPONENT:             N/A
E2E:                   pytest with click.testing.CliRunner
