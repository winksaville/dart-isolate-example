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
  int testTimeInSecs;

  String toString() => '$listenMode $msgMode'.toString();
}

Arguments parseArgs(List<String> args) {
  final ArgParser parser = ArgParser();
  parser.addOption('test', abbr: 't',
    defaultsTo: '0', help: 'Number of seconds to test each combination 0 is manual mode');
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

  arguments.testTimeInSecs = int.parse(argResults['test']);

  print('arguments=$arguments');
  return arguments;
}

// Start an isolate and return its Parameters
Future<Parameters> start(Parameters serverParams) async {
  // Create a port used to communite with the isolate
  serverParams.receivePort = ReceivePort();

  // Create the client params
  Parameters clientParams = Parameters(serverParams.receivePort.sendPort,
    serverParams.listenMode, serverParams.msgMode);

  // Start the client. If were listenMode is local local
  // we'll called the client directly other wise we'll spawn
  // it into its own isolate.
  switch (serverParams.listenMode) {
    case ListenMode.local:
      clientParams.isolate = Isolate.current;
      client(clientParams);
      break;
    case ListenMode.isolate:
      clientParams.isolate = await Isolate.spawn(client, clientParams);
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
  serverParams.receivePort.listen(
    (dynamic message) {
      final now = DateTime.now().microsecondsSinceEpoch;
      serverParams.counter += 1;
      serverParams.listener(serverParams, now, message);
    },
    //onDone: () => print('server: listen onDone'),
  );

  // Return the clientParams
  return clientParams;
}

/// Stop the isolate immediately
void stop(Parameters clientParams) {
  assert(clientParams != null);
  assert(clientParams.isolate != null);

  // Handle isolate being null
  if (clientParams.isolate == Isolate.current) {
    assert(clientParams.receivePort != null);
    clientParams.receivePort.close();
  } else {
    clientParams.isolate.kill(priority: Isolate.immediate);
  }
}

class WorkResult {
  int msgs;
  double totalSecs;

  WorkResult(this.msgs, this.totalSecs);

  @override
  String toString() {
    NumberFormat f3digits = NumberFormat('###,###.00#');
    NumberFormat f0digit = NumberFormat('###,###');
    double rate = msgs.toDouble() / totalSecs;
    return
      'Total time=${f3digits.format(totalSecs)} secs '
      'msgs=${f0digit.format(msgs)} '
      'rate=${f0digit.format(rate)} msgs/sec'.toString();
  }
}

Future<WorkResult> doWork(Arguments arguments) async {

  Stopwatch stopwatch = Stopwatch();
  stopwatch.start();

  // Start the server and client
  int beforeStart = stopwatch.elapsedMicroseconds;
  Parameters serverParams = Parameters(null, arguments.listenMode,
    arguments.msgMode);
  Parameters clientParams = await start(serverParams);

  int afterStart;
  if (arguments.testTimeInSecs == 0) {
    // Tell the user to press a key
    print('Press any key to stop...');

    // Change stdin so it doesn't echo input and doesn't wait for enter key
    stdin.echoMode = false;
    stdin.lineMode = false;
    afterStart = stopwatch.elapsedMicroseconds;
    await stdin.first;
  } else {
    print('wait about ${arguments.testTimeInSecs} '
          'second${arguments.testTimeInSecs > 1 ? "s" : ""}...');
    afterStart = stopwatch.elapsedMicroseconds;
    await delay(Duration(seconds: arguments.testTimeInSecs));
  }
  int done = stopwatch.elapsedMicroseconds;

  // Print time
  double totalSecs = (done.toDouble() - beforeStart.toDouble()) / 1000000.0;
  WorkResult result = WorkResult(serverParams.counter * 2, totalSecs);

  // Stop the client
  stop(clientParams);

  // Stop the server
  serverParams.receivePort.close();

  return result;
}

Future<void> main(List<String> args) async {
  final Arguments arguments = parseArgs(args);

  if (arguments.testTimeInSecs > 0) {
    List<List<dynamic>> listenAndMsgModes = [
      [ ListenMode.local, MsgMode.asInt],
      [ ListenMode.local, MsgMode.asClass],
      [ ListenMode.local, MsgMode.asMap],
      [ ListenMode.local, MsgMode.asFb],
      [ ListenMode.isolate, MsgMode.asInt],
      [ ListenMode.isolate, MsgMode.asClass],
      [ ListenMode.isolate, MsgMode.asMap],
      [ ListenMode.isolate, MsgMode.asFb],
    ] as List<List<dynamic>>;
    for (List<dynamic> modes in listenAndMsgModes) {
      print('modes=${modes}');
      arguments.listenMode = modes[0];
      arguments.msgMode = modes[1];
      WorkResult result = await doWork(arguments);
      print(result.toString());
    }
  } else {
      WorkResult result = await doWork(arguments);
      print(result.toString());
  }

  // Uses exit because maing returns Future<void> otherwise we hang
  exit(0);
}
