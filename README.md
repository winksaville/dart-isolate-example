# Simple isolate example in dart

Based on [this](https://codingwithjoe.com/dart-fundamentals-isolates/) from
[Coding With Joe](codingwithjost.com).

Right now on my desktop I'm seeing about 225,000 msgs/sec, the client is
sending the integer counter between the two isolates. This quite a bit
faster than the 130,000 with the string and the int to string conversion.

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
client: doneRECEIVE: responsePort

Total time=7.773673 msgs=1772612 rate=228027.60033770395
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
Generated: /home/wink/prgs/dart/isolate-example/main
./main
Press any key to stop:
client: doneRECEIVE: responsePort

Total time=2.030922 msgs=460586 rate=226786.65157992282
stopping
stopped
```
