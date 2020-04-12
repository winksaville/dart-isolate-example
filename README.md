# Simple isolate example in dart

Based on [this](https://codingwithjoe.com/dart-fundamentals-isolates/) from
[Coding With Joe](codingwithjost.com).

A very simple program that uses SendPorts and ReceivePort's to
send/receive messages between listeners. They maybe in the same
isolate or different isloates. The higest performance is seen
when running in the same isolate, i.e. ListenMode is "local" and
passing a single integer as the message, i.e. MsgMode is "int".

## Prerequisites

- Newer version of dart with [dart2native](https://dart.dev/tools/dart2native)
- flatc the [Flatbuffer compiler](https://google.github.io/flatbuffers/)

## Build
```
$ make
flatc -o lib/ --dart schema/test1.fbs
dart2native lib/main.dart -o bin/main
Generated: /home/wink/prgs/dart/isolate-example/bin/main
```

## Help
```
$ ./bin/main -h
-t, --test          Number of seconds to test each combination 0 is manual mode
                    (defaults to "0")
-l, --listenMode    [local, isolate (default)]
-m, --msgMode       [asInt (default), asClass, asMap, asFb]
-h, --help    
```

## Run

Using the run target to build if necessary and then run:
```
$ make run
flatc -o lib/ --dart schema/test1.fbs
dart2native lib/main.dart -o bin/main
Generated: /home/wink/prgs/dart/isolate-example/bin/main
arguments=ListenMode.isolate MsgMode.asInt
Press any key to stop...
Total time=3.677 secs msgs=572,616 rate=155,727 msgs/sec
```

Run listenMode `local` and the various msgModes:
```
(base) wink@wink-desktop:~/prgs/dart/isolate-example (master)
$ ./bin/main -l local -m asInt
arguments=ListenMode.local MsgMode.asInt
Press any key to stop...
Total time=1.954 secs msgs=1,016,244 rate=520,089 msgs/sec
(base) wink@wink-desktop:~/prgs/dart/isolate-example (master)
$ ./bin/main -l local -m asClass
arguments=ListenMode.local MsgMode.asClass
Press any key to stop...
Total time=2.451 secs msgs=676,282 rate=275,896 msgs/sec
(base) wink@wink-desktop:~/prgs/dart/isolate-example (master)
$ ./bin/main -l local -m asMap
arguments=ListenMode.local MsgMode.asMap
Press any key to stop...
Total time=1.605 secs msgs=188,534 rate=117,467 msgs/sec
(base) wink@wink-desktop:~/prgs/dart/isolate-example (master)
$ ./bin/main -l local -m asFb
arguments=ListenMode.local MsgMode.asFb
Press any key to stop...
Total time=2.323 secs msgs=546,562 rate=235,332 msgs/sec
```

A more convenient way to run the various modes is --test=N
where N is the number of seconds to run each combination of
listenMode and msgMode. Here is an example where each
combination is run for 3 seconds:
```
$ make run test=3
arguments=ListenMode.isolate MsgMode.asInt
modes=[ListenMode.local, MsgMode.asInt]
wait about 3 seconds...
Total time=3.00 secs msgs=1,734,574 rate=578,100 msgs/sec
modes=[ListenMode.local, MsgMode.asClass]
wait about 3 seconds...
Total time=3.001 secs msgs=855,536 rate=285,104 msgs/sec
modes=[ListenMode.local, MsgMode.asMap]
wait about 3 seconds...
Total time=3.001 secs msgs=368,088 rate=122,658 msgs/sec
modes=[ListenMode.local, MsgMode.asFb]
wait about 3 seconds...
Total time=3.001 secs msgs=716,408 rate=238,728 msgs/sec
modes=[ListenMode.isolate, MsgMode.asInt]
wait about 3 seconds...
Total time=3.005 secs msgs=502,402 rate=167,192 msgs/sec
modes=[ListenMode.isolate, MsgMode.asClass]
wait about 3 seconds...
Total time=3.002 secs msgs=309,922 rate=103,241 msgs/sec
modes=[ListenMode.isolate, MsgMode.asMap]
wait about 3 seconds...
Total time=3.004 secs msgs=135,288 rate=45,038 msgs/sec
modes=[ListenMode.isolate, MsgMode.asFb]
wait about 3 seconds...
Total time=3.003 secs msgs=224,396 rate=74,725 msgs/sec
```

It is also important to run the tests with the dart
virtual machine as the performance can be different.
This can be done with makefile using `vm` target such
as `make vm test=3`. Or directly with `dart lib/main.dart --test=3`:
```
$ dart lib/main.dart --test=3
lib/main.dart: Warning: Interpreting this as package URI, 'package:isolate_exmaple/main.dart'.
arguments=ListenMode.isolate MsgMode.asInt
modes=[ListenMode.local, MsgMode.asInt]
wait about 3 seconds...
Total time=3.012 secs msgs=3,857,090 rate=1,280,505 msgs/sec
modes=[ListenMode.local, MsgMode.asClass]
wait about 3 seconds...
Total time=3.001 secs msgs=1,212,630 rate=404,137 msgs/sec
modes=[ListenMode.local, MsgMode.asMap]
wait about 3 seconds...
Total time=3.002 secs msgs=141,408 rate=47,107 msgs/sec
modes=[ListenMode.local, MsgMode.asFb]
wait about 3 seconds...
Total time=3.006 secs msgs=1,319,946 rate=439,163 msgs/sec
modes=[ListenMode.isolate, MsgMode.asInt]
wait about 3 seconds...
Total time=3.037 secs msgs=677,090 rate=222,960 msgs/sec
modes=[ListenMode.isolate, MsgMode.asClass]
wait about 3 seconds...
Total time=3.032 secs msgs=337,158 rate=111,218 msgs/sec
modes=[ListenMode.isolate, MsgMode.asMap]
wait about 3 seconds...
Total time=3.035 secs msgs=48,840 rate=16,094 msgs/sec
modes=[ListenMode.isolate, MsgMode.asFb]
wait about 3 seconds...
Total time=3.04 secs msgs=324,408 rate=106,725 msgs/sec
```

## Clean
```
$ make clean
rm -f main
```

You can compbine them too
```
$ make clean run
rm -f bin/main
dart2native lib/main.dart -o bin/main
Generated: /home/wink/prgs/dart/isolate-example/bin/main
bin/main
Press any key to stop:
client: done
RECEIVE: responsePort
Total time=2.693 secs msgs=585,980 rate=217,592 msgs/sec
stopping
stopped
```
