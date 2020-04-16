listenMode=isolate
msgMode=asInt
test=0

all: bin/main

bin/main: lib/main.dart lib/client.dart lib/misc.dart lib/test1_generated.dart lib/test1.pb.dart
	dart2native $< -o $@

run: bin/main
	@( if [[ ${test} == 0 ]]; then \
	    $< --listenMode=${listenMode} --msgMode=${msgMode}; \
	  else \
	    $< --test=${test}; \
	  fi \
	)


lib/test1_generated.dart: schema/test1.fbs
	flatc -o $(dir $@) --dart $<

lib/test1.pb.dart: schema/test1.proto
	protoc -I=$(dir $<) --dart_out=$(dir $@) $<

.PHONY: vm
vm: lib/test1_generated.dart lib/test1.pb.dart
	@( if [[ ${test} == 0 ]]; then \
	    dart lib/main.dart --listenMode=${listenMode} --msgMode=${msgMode}; \
	  else \
	    dart lib/main.dart --test=${test}; \
	  fi \
	)

.PHONY: clean
clean:
	rm -f bin/main lib/test1_generated.dart lib/test1.pb*
