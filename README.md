# Simple isolate example in dart

Based on [this](https://codingwithjoe.com/dart-fundamentals-isolates/) from
[Coding With Joe](codingwithjost.com).

## Build main
Install newer dart with dart2native compiler
```
$ make
dart2native main.dart -o main
Generated: /home/wink/prgs/dart/isolate1/main
```

## Run

Build main if not already built then run it
```
$ make run
./main
Press any key to stop:
SEND: notification 1 - RECEIVE: notification 1
SEND: notification 2 - RECEIVE: notification 2
SEND: notification 3 - RECEIVE: notification 3
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
rm -f main
dart2native main.dart -o main
Generated: /home/wink/prgs/dart/isolate1/main
./main
Press any key to stop:
SEND: notification 1 - RECEIVE: notification 1
SEND: notification 2 - RECEIVE: notification 2
SEND: notification 3 - RECEIVE: notification 3
SEND: notification 4 - RECEIVE: notification 4
stopping
stopped
```
