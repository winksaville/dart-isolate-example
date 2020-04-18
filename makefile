listenMode=local
msgMode=all
time=2
repeats=1

all: bin/main

bin/main: bin/main.dart lib/client.dart lib/misc.dart lib/test1_generated.dart lib/test1.pb.dart lib/fb_msg_generated.dart
	dart2native $< -o $@

run: bin/main
	@$< --listenMode=${listenMode} --msgMode=${msgMode} --time=${time} --repeats=${repeats}

lib/fb_msg_generated.dart: schema/fb_msg.fbs
	flatc -o $(dir $@) --dart $<

lib/test1_generated.dart: schema/test1.fbs
	flatc -o $(dir $@) --dart $<

lib/test1.pb.dart: schema/test1.proto
	protoc -I=$(dir $<) --dart_out=$(dir $@) $<

.PHONY: vm
vm: bin/main.dart lib/test1_generated.dart lib/test1.pb.dart lib/fb_msg_generated.dart
	@dart $< --listenMode=${listenMode} --msgMode=${msgMode} --time=${time} --repeats=${repeats}

.PHONY: clean
clean:
	rm -f bin/main lib/test1_generated.dart lib/test1.pb*
