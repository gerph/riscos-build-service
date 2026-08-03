PYTHON ?= python3
VENV ?= .venv
VENV_PYTHON = $(VENV)/bin/python
VENV_STAMP = $(VENV)/.requirements-installed

.PHONY: tests

tests: $(VENV_STAMP)
	$(VENV_PYTHON) -m unittest -v test_robuildyaml test_interfaces

$(VENV_STAMP): requirements.txt
	$(PYTHON) -m venv $(VENV)
	$(VENV_PYTHON) -m pip install -r requirements.txt
	touch $(VENV_STAMP)
