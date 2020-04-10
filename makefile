bin/main: lib/main.dart lib/client.dart lib/test1_generated.dart
	dart2native $< -o $@

run: bin/main
	$<

lib/test1_generated.dart: schema/test1.fbs
	flatc -o $(dir $@) --dart $<

.PHONY: vm
vm:
	dart lib/main.dart

.PHONY: clean
clean:
	rm -f bin/main lib/test1_generated.dart
