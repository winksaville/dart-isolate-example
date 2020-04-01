main: main.dart
	dart2native main.dart -o main

.PHONY: run
run: main
	./main


.PHONY: clean
clean:
	rm -f main
