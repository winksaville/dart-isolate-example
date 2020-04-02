// Based on [this](https://codingwithjoe.com/dart-fundamentals-isolates/) from
// [Coding With Joe](codingwithjost.com).

import 'dart:io';
import 'dart:async';
import 'dart:isolate';

// **********************************************
// Added bidirectional communication, but this is
// really ugly. Because start is a function that
// creates an isolate and we can't listen on a
// ReceivePort twice make the repsone port global.
// Obviously, we should create a new object that has
// a responsePort field. But this is simplest for
// now and the "correct" way looks to be using an
// IsolateChannel [1] and here is an example [2].
//
// [1](https://api.flutter.dev/flutter/package-stream_channel_isolate_channel/IsolateChannel-class.html)
// [2](https://medium.com/@codinghive.dev/async-coding-with-dart-isolates-b09c5ec00f8b)
// **********************************************

SendPort responsePort = null;

// Start an isolate and return it
Future<Isolate> start() async {
  // Create a port used to communite with the isolate
  ReceivePort receivePort = ReceivePort();

  // Spawn runTimer in an isolate passing the sendPort so
  // it can send us messages
  Isolate isolate = await Isolate.spawn(runTimer, receivePort.sendPort);

  // The first message on the receive port will be
  // the sendPort that we can issue our responses to runTime
  //   This doesn't work because wen listen here and
  //   then again below, which leads to:
  //      Unhanded exception:
  //      Bad state: Stream has already been listened to.
  // So we can't listen twice. Instead we have to make the
  // responsePort "global" and in the listener function we
  // use "if (data is SendPort)" to initialize the responsePort
  //SendPort responsePort = await receivePort.first;
  //stdout.writeln('Got the responsePort');


  // Listen on the receive port passing a routine that accepts
  // the data and prints it.
  receivePort.listen((dynamic data) {
    if (data is SendPort) {
      stdout.writeln('RECEIVE: responsePort');
      responsePort = data;
    } else {
      assert(responsePort != null);
      responsePort.send('RESPONSE: ' + data);
      stdout.writeln('RECEIVE: ' + data);
    }
  });

  // Return the isolate that was created
  return isolate;
}

/// runTimer execptes to be in an isolate
void runTimer(SendPort sendPort) {
  // Send the "responsePort" to our partner
  ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  int counter = 0;
  Timer.periodic(new Duration(seconds: 1), (Timer t) {
    counter++;
    String msg = 'notification ' + counter.toString();  
    stdout.writeln('SEND: ' + msg);
    sendPort.send(msg);
  });

  receivePort.listen((data) {
    stdout.writeln('RESP: ' + data);
  });

  stdout.writeln('runTimer: done');
}

/// Stop the isolate immediately and return null
Isolate stop(Isolate isolate) {  
  // Handle isolate being null
  isolate?.kill(priority: Isolate.immediate);
  return null;
}

void main() async {
  // Change stdin so it doesn't echo input and doesn't wait for enter key
  stdin.echoMode = false;
  stdin.lineMode = false;

  // Tell the user to press a key
  stdout.writeln('Press any key to stop:');

  // Start an isolate
  Isolate isolate = await start();

  // Get the first elememnt
  await stdin.first;

  // Stop the isolate, we also verity a null "works"
  stdout.writeln('stopping');
  stop(null);
  isolate = stop(isolate); // return null
  stdout.writeln('stopped');

  // Because main is async use exit
  exit(0);
}
