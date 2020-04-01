// Based on [this](https://codingwithjoe.com/dart-fundamentals-isolates/) from
// [Coding With Joe](codingwithjost.com).

import 'dart:io';
import 'dart:async';
import 'dart:isolate';

// Start an isolate and return it
Future<Isolate> start() async {
  // Create a port used to communite with the isolate
  ReceivePort receivePort= ReceivePort();

  // Spawn runTimer in an isolate passing the sendPort so
  // it can send us messages
  Isolate isolate = await Isolate.spawn(runTimer, receivePort.sendPort);

  // Listen on the receive port passing a routine that accepts
  // the data and prints it.
  receivePort.listen((data) {
    stdout.writeln('RECEIVE: ' + data);
  });

  // Return the isolate that was created
  return isolate;
}

/// runTimer execptes to be in an isolate
void runTimer(SendPort sendPort) {
  int counter = 0;
  Timer.periodic(new Duration(seconds: 1), (Timer t) {
    counter++;
    String msg = 'notification ' + counter.toString();  
    stdout.write('SEND: ' + msg + ' - ');  
    sendPort.send(msg);
  });
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
