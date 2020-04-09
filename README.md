# Simple isolate example in dart

Based on [this](https://codingwithjoe.com/dart-fundamentals-isolates/) from
[Coding With Joe](codingwithjost.com).

A very simple program that uses SendPorts and ReceivePort's to
send/receive messages between listeners. They maybe in the same
isolate or different isloates. The higest performance is seen
when running in the same isolate, i.e. ListenMode is "local" and
passing a single integer as the message, i.e. MsgMode is "int".

## Build main
Install newer dart with dart2native compiler
```
$ make
dart2native lib/main.dart -o bin/main
Generated: /home/wink/prgs/dart/isolate-example/bin/main
```

## Help
```
$ ./bin/main --help
-l, --listenMode    [local, isolate (default)]
-m, --msgMode       [int (default), class, map]
-h, --help
```

## Run

Build main if not already built then run it
```
$ make run
bin/main
Press any key to stop:
client: done
RECEIVE: responsePort
Total time=4.398 secs msgs=990,734 rate=225,275 msgs/sec
stopping
stopped
```

Run listenMode `local` and the various msgModes:
```
(base) wink@wink-desktop:~/prgs/dart/isolate-example (master)
$ ./bin/main -l local -m int
Press any key to stop:
client: done
Total time=3.772 secs msgs=5,499,692 rate=1,458,067 msgs/sec
stopping
stopped
(base) wink@wink-desktop:~/prgs/dart/isolate-example (master)
$ ./bin/main -l local -m class
Press any key to stop:
client: done
Total time=2.882 secs msgs=1,208,028 rate=419,192 msgs/sec
stopping
stopped
(base) wink@wink-desktop:~/prgs/dart/isolate-example (master)
$ ./bin/main -l local -m map
Press any key to stop:
client: done
Total time=1.954 secs msgs=288,002 rate=147,418 msgs/sec
stopping
stopped
```

Run listenMode `isolate` and the various msgModes:
```
(base) wink@wink-desktop:~/prgs/dart/isolate-example (master)
$ ./bin/main -l isolate -m int
Press any key to stop:
client: done
Total time=3.515 secs msgs=784,712 rate=223,240 msgs/sec
stopping
stopped
(base) wink@wink-desktop:~/prgs/dart/isolate-example (master)
$ ./bin/main -l isolate -m class
Press any key to stop:
client: done
Total time=2.299 secs msgs=257,894 rate=112,188 msgs/sec
stopping
stopped
(base) wink@wink-desktop:~/prgs/dart/isolate-example (master)
$ ./bin/main -l isolate -m map
Press any key to stop:
client: done
Total time=4.474 secs msgs=232,994 rate=52,079 msgs/sec
stopping
stopped
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
