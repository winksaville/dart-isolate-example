// Based on [this](https://codingwithjoe.com/dart-fundamentals-isolates/) from
// [Coding With Joe](codingwithjost.com).
//
// The way isolate's work when they are created the isolate aka
// client is give a ReceiverPort.sendPort. This allow it to send
// messages back to the creator aka the server. But the server can't
// send messages to the client. It is at the perogative of the
// client if and when to send a ReceivePort.sneport back to the server.
//
// Another option is to use an IsolateChannel [1] with an example at [2].
//
// [1](https://api.flutter.dev/flutter/package-stream_channel_isolate_channel/IsolateChannel-class.html)
// [2](https://medium.com/@codinghive.dev/async-coding-with-dart-isolates-b09c5ec00f8b)

import 'dart:io';
import 'dart:async';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:intl/intl.dart';
import 'package:flat_buffers/flat_buffers.dart' as fb;

import 'client.dart';
import 'misc.dart';
import 'test1_generated.dart' as test1;

class Arguments {
  ListenMode listenMode;
  MsgMode msgMode;

  String toString() => '$listenMode $msgMode'.toString();
}

Arguments parseArgs(List<String> args) {
  final ArgParser parser = ArgParser();
  final List<String> validValues = <String>['local', 'isolate'];
  parser.addOption('listenMode', abbr: 'l', allowed: validValues,
    defaultsTo: 'isolate');
  parser.addOption('msgMode', abbr: 'm', allowed: <String>['asInt', 'asClass', 'asMap', 'asFb'],
    defaultsTo: 'asInt');
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
    case 'asInt': arguments.msgMode = MsgMode.asInt; break;
    case 'asClass': arguments.msgMode = MsgMode.asClass; break;
    case 'asMap': arguments.msgMode = MsgMode.asMap; break;
    case 'asFb': arguments.msgMode = MsgMode.asFb; break;
  }

  print('arguments=$arguments');
  return arguments;
}

// Start an isolate and return it
Future<Isolate> start(Parameters serverParams) async {
  // Create a port used to communite with the isolate
  ReceivePort receivePort = ReceivePort();

  // Create the client params
  Parameters clientParams = Parameters(receivePort.sendPort,
    serverParams.listenMode, serverParams.msgMode);

  // Start the client. If were listenMode is local local
  // we'll called the client directly other wise we'll spawn
  // it into its own isolate.
  Isolate isolate;
  switch (serverParams.listenMode) {
    case ListenMode.local:
      isolate = Isolate.current;
      client(clientParams);
      break;
    case ListenMode.isolate:
      isolate = await Isolate.spawn(client, clientParams);
      break;
  }

  // The initial listener expects a sendPort and then it resets
  // serverParams.listener to the "proper" listener based on msgMode.
  serverParams.listener = (Parameters serverParams, int now, dynamic message) {
    //print('server listener getting SendPort');
    serverParams.counter = 0;
    assert(message is SendPort);
    serverParams.partnerPort = message as SendPort;

    // Change the listener to the "proper" one.
    switch (serverParams.msgMode) {
      case MsgMode.asInt:
        serverParams.listener = processAsInt;
        break;
      case MsgMode.asMap:
        serverParams.listener = processAsMap;
        break;
      case MsgMode.asClass:
        serverParams.listener = processAsClass;
        break;
      case MsgMode.asFb:
        serverParams.listener = processAsFb;
        break;
    }
  };

  // Listen on the receive port passing a routine that accepts
  // the data and prints it.
  receivePort.listen((dynamic message) {
    final now = DateTime.now().microsecondsSinceEpoch;
    serverParams.counter += 1;
    serverParams.listener(serverParams, now, message);
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

Future<void> doWork(Arguments arguments) async {
  // Change stdin so it doesn't echo input and doesn't wait for enter key
  stdin.echoMode = false;
  stdin.lineMode = false;

  Stopwatch stopwatch = Stopwatch();
  stopwatch.start();

  // Tell the user to press a key
  print('Press any key to stop:');

  // Start the server and client
  int beforeStart = stopwatch.elapsedMicroseconds;
  Parameters serverParams = Parameters(null, arguments.listenMode,
    arguments.msgMode);
  Isolate isolate = await start(serverParams);

  // Wait for any key
  int afterStart = stopwatch.elapsedMicroseconds;
  await stdin.first;
  int done = stopwatch.elapsedMicroseconds;

  // Print time
  serverParams.counter *= 2; // Double the number of messages
  double totalSecs = (done.toDouble() - beforeStart.toDouble()) / 1000000.0;
  double rate = serverParams.counter.toDouble() / totalSecs;
  NumberFormat f3digits = NumberFormat('###,###.00#');
  NumberFormat f0digit = NumberFormat('###,###');
  print(
    'Total time=${f3digits.format(totalSecs)} secs '
    'msgs=${f0digit.format(serverParams.counter)} '
    'rate=${f0digit.format(rate)} msgs/sec');

  // Stop the isolate, we also verify a null "works"
  print('stopping');
  stop(null);
  isolate = stop(isolate); // return null
  print('stopped');

  // Because main is async use exit
  exit(0);
}

Future<void> main(List<String> args) async {
  final Arguments arguments = parseArgs(args);

  doWork(arguments);
}
