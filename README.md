# Simple isolate example in dart

Based on [this](https://codingwithjoe.com/dart-fundamentals-isolates/) from
[Coding With Joe](codingwithjost.com).

A very simple program that uses SendPorts and ReceivePort's to
send/receive messages between listeners. They maybe in the same
isolate or different isloates. The higest performance is seen
when running in the same isolate, i.e. ListenMode is "local" and
passing a single integer as the message, i.e. MsgMode is "asInt".

## Prerequisites

- Newer version of dart with [dart2native](https://dart.dev/tools/dart2native)
- flatc the [Flatbuffer compiler](https://google.github.io/flatbuffers/)
- protoc the [Protobuf compiler](https://developers.google.com/protocol-buffers)

## Build
```
$ make
flatc -o lib/ --dart schema/test1.fbs
protoc -I=schema/ --dart_out=lib/ schema/test1.proto
dart2native lib/main.dart -o bin/main
Generated: /home/wink/prgs/dart/isolate-example/bin/main
```

## Help
```
$ ./bin/main -h
-t, --time          Number of seconds to run
                    (defaults to "2")
-r, --repeats       The number repeats of each test
                    (defaults to "1")
-l, --listenMode    [local (default), isolate]
-m, --msgMode       [all (default), asInt, asClass, asMap, asFb, asProto, asFbMsg]
-h, --help
```

## Run

Using the run target to build if necessary and then run.
This defaults to have msgMode=all and time=2:
```
$ make run
flatc -o lib/ --dart schema/test1.fbs
protoc -I=schema/ --dart_out=lib/ schema/test1.proto
dart2native lib/main.dart -o bin/main
Generated: /home/wink/prgs/dart/isolate-example/bin/main
   1: time=  2.0   ListenMode.isolate MsgMode.asFbMsg
                                        Time secs      msg count  rate msgs/sec
ListenMode.local   MsgMode.asInt         2.000830      1,253,066        626,273
ListenMode.local   MsgMode.asClass       2.000969        574,454        287,088
ListenMode.local   MsgMode.asMap         2.000974        239,680        119,782
ListenMode.local   MsgMode.asFb          2.000958        462,656        231,217
ListenMode.local   MsgMode.asProto       2.001011        416,112        207,951
ListenMode.local   MsgMode.asFbMsg       2.000978        141,680         70,805
ListenMode.isolate MsgMode.asInt         2.002897        300,032        149,799
ListenMode.isolate MsgMode.asClass       2.004032        161,928         80,801
ListenMode.isolate MsgMode.asMap         2.002960         78,372         39,128
ListenMode.isolate MsgMode.asFb          2.004967        128,884         64,282
ListenMode.isolate MsgMode.asProto       2.002925        131,172         65,490
ListenMode.isolate MsgMode.asFbMsg       2.003947         56,946         28,417
```

Run listenMode `local` and the various msgModes:
```
$ ./bin/main -l local -m asInt
  1: time: 2.000961 msgs: 1,153,792 rate: 576,619

$ ./bin/main -l local -m asInt -t 0
ListenMode.local MsgMode.asInt -- Press any key to stop...
  1: time: 0.596833 msgs: 358,348 rate: 600,416

$ dart lib/main.dart -l isolate -m asFb
lib/main.dart: Warning: Interpreting this as package URI, 'package:isolate_example/main.dart'.
  1: time: 2.027375 msgs: 251,610 rate: 124,106
```

It is also deseriable to run the msgMode=all with the dart
virtual machine as the performance can be different.
This can be done with makefile using `vm` target such
as `make vm test=3`. Or directly with `dart lib/main.dart --test=3`.
Also, the time is a floating point value and can have a
fractional value, such as 0.5:
```
$ make vm msgMode=all time=0.5
lib/main.dart: Warning: Interpreting this as package URI, 'package:isolate_example/main.dart'.
   1: time=  0.5   ListenMode.isolate MsgMode.asFbMsg
                                        Time secs      msg count  rate msgs/sec
ListenMode.local   MsgMode.asInt         0.500909        666,942      1,331,463
ListenMode.local   MsgMode.asClass       0.500875        204,458        408,201
ListenMode.local   MsgMode.asMap         0.500908         21,344         42,611
ListenMode.local   MsgMode.asFb          0.500875        252,116        503,351
ListenMode.local   MsgMode.asProto       0.500825        234,576        468,380
ListenMode.local   MsgMode.asFbMsg       0.500903         96,252        192,157
ListenMode.isolate MsgMode.asInt         0.523618        108,474        207,162
ListenMode.isolate MsgMode.asClass       0.532884         60,390        113,327
ListenMode.isolate MsgMode.asMap         0.537802          7,266         13,511
ListenMode.isolate MsgMode.asFb          0.529875         50,230         94,796
ListenMode.isolate MsgMode.asProto       0.528759         48,832         92,352
ListenMode.isolate MsgMode.asFbMsg       0.530787         22,656         42,684
```

## Clean
```
$ make clean
rm -f bin/main lib/test1_generated.dart lib/test1.pb*
```

You can compbine them too
```
$ make clean vm msgMode=asInt time=0.1
rm -f bin/main lib/test1_generated.dart lib/test1.pb*
flatc -o lib/ --dart schema/test1.fbs
protoc -I=schema/ --dart_out=lib/ schema/test1.proto
lib/main.dart: Warning: Interpreting this as package URI, 'package:isolate_example/main.dart'.
  1: time: 0.100936 msgs: 132,020 rate: 1,307,958
```
