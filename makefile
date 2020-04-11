listenMode=isolate
msgMode=asInt

bin/main: lib/main.dart lib/client.dart lib/test1_generated.dart
	dart2native $< -o $@

run: bin/main
	$< --listenMode=${listenMode} --msgMode=${msgMode}

lib/test1_generated.dart: schema/test1.fbs
	flatc -o $(dir $@) --dart $<

.PHONY: vm
vm:
	dart lib/main.dart --listenMode=${listenMode} --msgMode=${msgMode}

.PHONY: clean
clean:
	rm -f bin/main lib/test1_generated.dart
