listenMode=isolate
msgMode=asInt
test=0

bin/main: lib/main.dart lib/client.dart lib/misc.dart lib/test1_generated.dart
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

.PHONY: vm
vm:
	@( if [[ ${test} == 0 ]]; then \
	    dart lib/main.dart --listenMode=${listenMode} --msgMode=${msgMode}; \
	  else \
	    dart lib/main.dart --test=${test}; \
	  fi \
	)

.PHONY: clean
clean:
	rm -f bin/main lib/test1_generated.dart
