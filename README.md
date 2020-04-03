# Simple isolate example in dart

Based on [this](https://codingwithjoe.com/dart-fundamentals-isolates/) from
[Coding With Joe](codingwithjost.com).

Right now on my desktop I'm seeing about 130,000 msgs/sec, the client is
creating a string with an int to string conversion as the message contents.

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
RECEIVE: responsePort
client: done
Total time=2.223331 msgs=283086 rate=127325.17110587673
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
client: done
RECEIVE: responsePort
Total time=3.75927 msgs=493446 rate=131261.12250516724
stopping
stopped
```
