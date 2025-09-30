ELMDEBUGAPP=static/main-debug.js
ELMPRODAPP=static/main.js

.PHONY: review test frontend-test backend-test

elm: $(ELMDEBUGAPP) 
$(ELMDEBUGAPP): elm.json $(shell fd . -e elm src/)
	elm make src/Main.elm --debug --output=$(ELMDEBUGAPP) 

$(ELMPRODAPP): elm.json $(shell fd . -e elm src/)
	elm make src/Main.elm --optimize --output=$(ELMPRODAPP) 

review:
	elm-review

.PHONY: venv
venv:
	@echo "Setting up virtual environment..."
	@if [ ! -d "venv" ]; then \
		python -m venv venv; \
	fi
	@. venv/bin/activate && pip install -r requirements.txt
	@echo "You will now need to 'source venv/bin/activate.fish"

GEN_TESTS_MODULES_DIR = ./tests/Generated
SIMULATE_MODULE = $(GEN_TESTS_MODULES_DIR)/Simulate.elm
PORTS_MODULE = $(GEN_TESTS_MODULES_DIR)/Ports.elm

$(SIMULATE_MODULE) $(PORTS_MODULE): src/Perform.elm src/Ports.elm perform-to-simulate.toml
	mkdir -p $(GEN_TESTS_MODULES_DIR)
	cp src/Perform.elm $(SIMULATE_MODULE)
	cp src/Ports.elm $(PORTS_MODULE)
	comby -config perform-to-simulate.toml -d $(GEN_TESTS_MODULES_DIR) -in-place -matcher .elm

# Frontend tests (Elm)
frontend-test: $(SIMULATE_MODULE) $(PORTS_MODULE)
	@echo "Running frontend tests..."
	elm-test

# Backend tests (Python)
backend-test:
	@echo "Running backend tests..."
	@if [ -d "venv" ]; then \
		echo "Using virtual environment..."; \
		. venv/bin/activate && python -m pytest tests/ -v; \
	else \
		echo "No virtual environment found, running with system Python..."; \
		python -m pytest tests/ -v; \
	fi

# Run both frontend and backend tests
test: frontend-test backend-test
	@echo "All tests completed!"

watch-frontend:
	@watchexec -w src -e elm "echo 'Elm file changed, rebuilding frontend...' && make elm" 

watch-backend:
	@watchexec -r -e py "echo 'Python file changed, rebuilding backend...' && python app.py config.dev.json"

static/styles.min.css: static/styles.css
	@echo "Minifying styles..."
	lightningcss --minify $< -o $@

deploy: app.py $(ELMPRODAPP) static/styles.min.css
	@echo "Deploying application..."
	elm make src/Main.elm --optimize --output=$(ELMPRODAPP)
	python app.py config.prod.json
