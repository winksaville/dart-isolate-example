// Based on [this](https://codingwithjoe.com/dart-fundamentals-isolates/) from
// [Coding With Joe](codingwithjost.com).
//
// The way isolate's work when they are created the isolate aka
// client is give a ReceiverPort.sendPort. This allow it to send
// messages back to the creator aka the server. But the server can't
// send messages to the client. It is at the perogative of the
// client if and when to send a ReceivePort.senport back to the server.
//
// Another option is to use an IsolateChannel [1] with an example at [2].
//
// [1](https://api.flutter.dev/flutter/package-stream_channel_isolate_channel/IsolateChannel-class.html)
// [2](https://medium.com/@codinghive.dev/async-coding-with-dart-isolates-b09c5ec00f8b)

import 'dart:io';
import 'dart:isolate';
import 'package:args/args.dart';
import 'package:intl/intl.dart';
import 'client.dart';
import 'misc.dart';

class Arguments {
  ListenMode listenMode;
  MsgMode msgMode;
  int testTimeInSecs;
  int testRepeats;

  @override
  String toString() => '$listenMode $msgMode $testTimeInSecs';
}

Arguments parseArgs(List<String> args) {
  final ArgParser parser = ArgParser();
  parser.addOption('test',
      abbr: 't',
      defaultsTo: '0',
      help: 'Number of seconds to test each combination 0 is manual mode');
  parser.addOption('repeats',
      abbr: 'r', defaultsTo: '1', help: 'The number repeats of each test');
  parser.addOption('listenMode',
      abbr: 'l', allowed: <String>['local', 'isolate'], defaultsTo: 'isolate');
  parser.addOption('msgMode',
      abbr: 'm',
      allowed: <String>['asInt', 'asClass', 'asMap', 'asFb'],
      defaultsTo: 'asInt');
  parser.addFlag('help', abbr: 'h', negatable: false);

  final ArgResults argResults = parser.parse(args);
  if (argResults['help'] == true) {
    print(parser.usage);
    exit(0);
  }

  final Arguments arguments = Arguments();
  switch (argResults['listenMode'] as String) {
    case 'local':
      arguments.listenMode = ListenMode.local;
      break;
    case 'isolate':
      arguments.listenMode = ListenMode.isolate;
      break;
  }

  switch (argResults['msgMode'] as String) {
    case 'asInt':
      arguments.msgMode = MsgMode.asInt;
      break;
    case 'asClass':
      arguments.msgMode = MsgMode.asClass;
      break;
    case 'asMap':
      arguments.msgMode = MsgMode.asMap;
      break;
    case 'asFb':
      arguments.msgMode = MsgMode.asFb;
      break;
  }

  arguments.testTimeInSecs = int.parse(argResults['test'] as String);
  arguments.testRepeats = int.parse(argResults['repeats'] as String);

  //print('arguments=$arguments');
  return arguments;
}

// Start an isolate and return its Parameters
Future<Parameters> start(Parameters serverParams) async {
  // Create a port used to communicate with the isolate
  serverParams.receivePort = ReceivePort();

  // Create the client params
  final Parameters clientParams = Parameters(serverParams.receivePort.sendPort,
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
      final int now = DateTime.now().microsecondsSinceEpoch;
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

class ResultStrings {
  ResultStrings(this.totalTimeStr, this.msgsStr, this.rateStr);

  String totalTimeStr;
  String msgsStr;
  String rateStr;
}

class WorkResult {
  WorkResult(this.modes, this.msgs, this.totalSecs);

  Modes modes;
  int msgs;
  double totalSecs;

  ResultStrings resultString(int padding) {
    final NumberFormat f3digits = NumberFormat('###,###.000');
    final NumberFormat f0digit = NumberFormat('###,###');
    final double rate = msgs.toDouble() / totalSecs;
    return ResultStrings(
        f3digits.format(totalSecs).padLeft(padding),
        f0digit.format(msgs).padLeft(padding),
        f0digit.format(rate).padLeft(padding));
  }

  @override
  String toString() {
    final ResultStrings s = resultString(0);
    return 'time: ${s.totalTimeStr} msgs: ${s.msgsStr} rate: ${s.rateStr}';
  }

  static String header(int padding) {
    final String s1 = 'Time secs'.padLeft(padding);
    final String s2 = 'msg count'.padLeft(padding);
    final String s3 = 'rate msgs/sec'.padLeft(padding);
    return '$s1$s2$s3';
  }

  String toStringNoLabels(int padding) {
    final ResultStrings s = resultString(padding);
    return '${s.totalTimeStr}${s.msgsStr}${s.rateStr}';
  }
}

Future<WorkResult> doWork(Arguments arguments) async {
  final Stopwatch stopwatch = Stopwatch();
  stopwatch.start();

  // Start the server and client
  final int beforeStart = stopwatch.elapsedMicroseconds;
  final Parameters serverParams =
      Parameters(null, arguments.listenMode, arguments.msgMode);
  final Parameters clientParams = await start(serverParams);

  if (arguments.testTimeInSecs == 0) {
    // Tell the user to press a key
    print('${arguments.listenMode} ${arguments.msgMode} -- '
        'Press return and sometimes eny key to stop...');

    // Change stdin so it doesn't echo input and doesn't wait for enter key
    stdin.echoMode = false;
    stdin.lineMode = false;
    await stdin.first;
  } else {
    await delay(Duration(seconds: arguments.testTimeInSecs));
  }
  final int done = stopwatch.elapsedMicroseconds;

  // Print time
  final double totalSecs =
      (done.toDouble() - beforeStart.toDouble()) / 1000000.0;
  final WorkResult result = WorkResult(
      Modes(arguments.listenMode, arguments.msgMode),
      serverParams.counter * 2,
      totalSecs);

  // Stop the client
  stop(clientParams);

  // Stop the server
  serverParams.receivePort.close();

  return result;
}

class Modes {
  Modes(this.listenMode, this.msgMode);

  ListenMode listenMode;
  MsgMode msgMode;

  @override
  String toString() => '${listenMode.toString().padRight(18)} $msgMode';
}

Future<void> main(List<String> args) async {
  final Arguments arguments = parseArgs(args);

  final List<WorkResult> results = <WorkResult>[];
  if (arguments.testTimeInSecs > 0) {
    final List<Modes> listenAndMsgModes = <Modes>[
      Modes(ListenMode.local, MsgMode.asInt),
      Modes(ListenMode.local, MsgMode.asClass),
      Modes(ListenMode.local, MsgMode.asMap),
      Modes(ListenMode.local, MsgMode.asFb),
      Modes(ListenMode.isolate, MsgMode.asInt),
      Modes(ListenMode.isolate, MsgMode.asClass),
      Modes(ListenMode.isolate, MsgMode.asMap),
      Modes(ListenMode.isolate, MsgMode.asFb),
    ];
    for (final Modes modes in listenAndMsgModes) {
      arguments.listenMode = modes.listenMode;
      arguments.msgMode = modes.msgMode;
      WorkResult avgResult =
          WorkResult(Modes(modes.listenMode, modes.msgMode), 0, 0);
      for (int i = 1; i <= arguments.testRepeats; i++) {
        stdout.write('${i.toString().padLeft(4)}: '
            'time=${arguments.testTimeInSecs.toString().padLeft(5)} '
            '${modes.toString().padLeft(36)}\r');
        WorkResult result = await doWork(arguments);
        avgResult.msgs += result.msgs;
        avgResult.totalSecs += result.totalSecs;
      }
      results.add(avgResult);
    }
    print('');
    print('${"".padLeft(34)}${WorkResult.header(15)}');
    for (final WorkResult result in results) {
      print(
          '${result.modes.toString().padRight(34)}${result.toStringNoLabels(15)}');
    }
  } else {
    final WorkResult result = await doWork(arguments);
    print(result);
  }

  // Uses exit because main returns Future<void>, otherwise we hang
  exit(0);
}
