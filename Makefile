# Makefile for the Text Classification Framework (Standard ML)

SML = sml
CM_FILE = sources.cm  # Update this if your CM file has a different name

all: compile

compile:
	@echo "Compiling Standard ML modules..."
	$(SML) -m $(CM_FILE)

clean:
	@echo "Cleaning up compiled files..."
	rm -rf CM  # Remove generated CM directories
	rm -f *~   # Remove backup files

run:
	@echo "Starting SML environment..."
	$(SML)

.PHONY: all compile clean run
