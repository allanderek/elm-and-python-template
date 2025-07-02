# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

- **Backend**: Python 3 with Bottle framework, SQLite database, JWT authentication
- **Frontend**: Elm 0.19.1 single-page application
- **Testing**: elm-test for frontend, with generated test modules using comby transformations

## Architecture

### Backend (Python)
- `app.py`: Main Flask/Bottle application with JWT authentication using argon2 password hashing
- Configuration loaded from JSON files (`config.dev.json`, `config.prod.json`)
- SQLite database with user authentication system
- SQL migrations in `sql/migrations/`

### Frontend (Elm)
- **Main.elm**: Application entry point using Browser.application pattern
- **Model.elm**: Central application state with navigation, forms, and HTTP status tracking
- **Update.elm**: Message handling and state updates
- **Effect.elm**: Side effect definitions
- **Perform.elm**: Effect execution (transforms to Simulate.elm for testing)
- **Route.elm**: Client-side routing
- **Pages/**: Individual page modules (Login, Register, Profile)
- **Types/**: Data type definitions
- **Helpers/**: Utility modules for HTTP, HTML, decoding, etc.

### Testing Strategy

#### Frontend Testing
- Uses `perform-to-simulate.toml` with comby to transform `Perform.elm` into `Generated/Simulate.elm` for testing
- Ports module also gets transformed to `Generated/Ports.elm`
- This allows testing effects in isolation using elm-program-test

#### Backend Testing
- `tests/` directory contains Python tests using pytest
- `tests/conftest.py` provides test fixtures and configuration
- `tests/test_auth.py` contains authentication endpoint tests
- Tests use temporary SQLite databases that are created and destroyed for each test
- `config.test.json` provides test-specific configuration
- Backend tests cover:
  - User registration (success, validation, duplicate username)
  - User login (success, invalid password, non-existent user)
  - User logout
  - Password hashing and verification
  - Protected route access

## Development Commands

### Backend
```bash
# Setup virtual environment (first time)
python3 -m venv venv
source venv/bin/activate.fish  # or activate for bash
pip install -r requirements.txt

# Run development server
python app.py config.dev.json

# Watch backend files for changes
make watch-backend
```

### Frontend
```bash
# Build Elm frontend (debug version)
make elm
# Or directly: elm make src/Main.elm --debug --output=static/main-debug.js

# Build production version
elm make src/Main.elm --optimize --output=static/main.js

# Watch frontend files for changes
make watch-frontend
```

### Testing
```bash
# Run all tests (frontend + backend)
make test

# Run only frontend tests (Elm)
make frontend-test

# Run only backend tests (Python)
make backend-test

# Run elm-review for linting
make review
```

#### Advanced Backend Testing
```bash
# Install all dependencies including test requirements (first time)
pip install -r requirements.txt

# Run with coverage
python -m pytest tests/ -v --cov=app --cov-report=term-missing

# Run specific test file
python -m pytest tests/test_auth.py -v

# Run specific test
python -m pytest tests/test_auth.py::TestAuthentication::test_login_success -v
```

### CSS
```bash
# Minify CSS for production
lightningcss --minify static/styles.css -o static/styles.min.css
```

## Key Development Patterns

### Elm Architecture
- Uses custom Effect pattern instead of direct Cmd messages
- All side effects go through `Perform.perform` which handles HTTP requests, navigation, ports
- Forms use dedicated Type modules (Types.Login, Types.Register, Types.Profile)
- HTTP requests use custom `Helpers.Http.Status` type for loading states

### Authentication Flow
- JWT tokens stored in HTTP-only cookies
- Backend validates JWT on protected routes
- Frontend tracks user state in Model.userStatus

### Testing
- Effects are tested by transforming Perform.elm to Simulate.elm using comby rules
- This allows unit testing of business logic without actual HTTP calls or navigation
