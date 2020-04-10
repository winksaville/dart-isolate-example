// Based on [this](https://codingwithjoe.com/dart-fundamentals-isolates/) from
// [Coding With Joe](codingwithjost.com).

import 'dart:io';
import 'dart:async';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:intl/intl.dart';
import 'package:flat_buffers/flat_buffers.dart' as fb;

import 'client.dart';
import 'test1_generated.dart' as test1;

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

enum ListenMode { local, isolate }

class Arguments {
  ListenMode listenMode;
  MsgMode msgMode;
}

Arguments parseArgs(List<String> args) {
  final ArgParser parser = ArgParser();
  final List<String> validValues = <String>['local', 'isolate'];
  parser.addOption('listenMode', abbr: 'l', allowed: validValues,
    defaultsTo: 'isolate');
  parser.addOption('msgMode', abbr: 'm', allowed: <String>['int', 'class', 'map'],
    defaultsTo: 'int');
  parser.addFlag('help', abbr: 'h', negatable: false);

  final ArgResults argResults = parser.parse(args);
  if (argResults['help'] == true) {
    print(parser.usage);
    exit(0);
  }

  Arguments arguments = Arguments();
  switch (argResults['listenMode']) {
    case 'local': arguments.listenMode = ListenMode.local; break;
    case 'isolate': arguments.listenMode = ListenMode.isolate; break;
  }

  switch (argResults['msgMode']) {
    case 'int': arguments.msgMode = MsgMode.asInt; break;
    case 'class': arguments.msgMode = MsgMode.asClass; break;
    case 'map': arguments.msgMode = MsgMode.asMap; break;
  }

  return arguments;
}

// These Globals are separate instances in each isolate.
SendPort responsePort = null;
int msgCounter = 0;

// Start an isolate and return it
Future<Isolate> start(Arguments args) async {
  // Create a port used to communite with the isolate
  ReceivePort receivePort = ReceivePort();

  ClientParam clientParam = ClientParam(receivePort.sendPort, args.msgMode);

  // Spawn client in an isolate passing the sendPort so
  // it can send us messages
  Isolate isolate;
  switch (args.listenMode) {
    case ListenMode.local:
      isolate = Isolate.current;
      client(clientParam);
      break;
    case ListenMode.isolate:
      isolate = await Isolate.spawn(client, clientParam);
      break;
  }

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
  //print('Got the responsePort');


  // Listen on the receive port passing a routine that accepts
  // the data and prints it.
  receivePort.listen((dynamic message) {
    //print('server: $message');
    msgCounter += 1;

    final now = DateTime.now().microsecondsSinceEpoch;
    if (message is SendPort) {
      //print('server: is SendPort');
      responsePort = message;
    } else if (message is Message) {
      assert(responsePort != null);

      Message msg = message as Message;

      // Use a Class
      // Reusing existing message didn't seem to make big difference.
      // About 430K+ msgs/sec.
      final now = DateTime.now().microsecondsSinceEpoch;
      final int duration = now - msg.microsecs;
      if (true) {
        // Reuse existing Message
        msg.microsecs = now;
        msg.duration = duration;
        responsePort.send(msg);
      } else {
        // Create new Message
        responsePort.send(Message(now, duration));
      }
    } else if (message is int) {
      responsePort.send(now);
    } else {
      final int duration = now - (message[Cmd.microsecs] as int);
      responsePort.send({Cmd.microsecs: now, Cmd.duration: duration});
    }
  });

  // Return the isolate that was created
  return isolate;
}

/// Stop the isolate immediately and return null
Isolate stop(Isolate isolate) {
  // Handle isolate being null
  if (isolate != Isolate.current) {
    isolate?.kill(priority: Isolate.immediate);
  }
  return null;
}

Future<void> main(List<String> args) async {
  final Arguments arguments = parseArgs(args);

  // Flatbuffer builder
  fb.Builder builder = fb.Builder(initialSize: 1024);

  // Create a MsgObjectBuilder
  final test1.MsgObjectBuilder mob =
    test1.MsgObjectBuilder(microsecs: 1, duration: 2);

  // Serialize to bytes
  List<int> buffer = mob.toBytes();
  print('buffer=${buffer}');

  // Deserialize from bytes and print contents
  test1.Msg m = test1.Msg(buffer);
  print('microsecs=${m.microsecs} duration=${m.duration}');

  // Change stdin so it doesn't echo input and doesn't wait for enter key
  stdin.echoMode = false;
  stdin.lineMode = false;

  Stopwatch stopwatch = Stopwatch();
  stopwatch.start();

  // Tell the user to press a key
  print('Press any key to stop:');

  // Start an isolate
  int beforeStart = stopwatch.elapsedMicroseconds;
  Isolate isolate = await start(arguments);

  // Wait for any key
  int afterStart = stopwatch.elapsedMicroseconds;
  await stdin.first;
  int done = stopwatch.elapsedMicroseconds;

  // Print time
  msgCounter *= 2;
  double totalSecs = (done.toDouble() - beforeStart.toDouble()) / 1000000.0;
  double rate = msgCounter.toDouble() / totalSecs;
  NumberFormat f3digits = NumberFormat('###,###.00#');
  NumberFormat f0digit = NumberFormat('###,###');
  print(
    'Total time=${f3digits.format(totalSecs)} secs '
    'msgs=${f0digit.format(msgCounter)} '
    'rate=${f0digit.format(rate)} msgs/sec');

  // Stop the isolate, we also verify a null "works"
  print('stopping');
  stop(null);
  isolate = stop(isolate); // return null
  print('stopped');

  // Because main is async use exit
  exit(0);
}
