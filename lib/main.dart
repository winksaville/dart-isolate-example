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
  Arguments();
  Arguments.init(this.listenMode, this.msgMode, this.timeInSecs, this.repeats);
  Arguments.clone(Arguments a)
      : this.init(a.listenMode, a.msgMode, a.timeInSecs, a.repeats);

  ListenMode listenMode;
  MsgMode msgMode;
  double timeInSecs;
  int repeats;

  @override
  String toString() => '$listenMode $msgMode $timeInSecs';
}

Arguments parseArgs(List<String> args) {
  final ArgParser parser = ArgParser();
  parser
    ..addOption('time',
        abbr: 't', defaultsTo: '2', help: 'Number of seconds to run')
    ..addOption('repeats',
        abbr: 'r', defaultsTo: '1', help: 'The number repeats of each test')
    ..addOption('listenMode',
        abbr: 'l', allowed: <String>['local', 'isolate'], defaultsTo: 'local')
    ..addOption('msgMode', abbr: 'm', defaultsTo: 'all', allowed: <String>[
      'all',
      'asInt',
      'asClass',
      'asMap',
      'asFb',
      'asProto',
      'asFbMsg'
    ])
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults argResults = parser.parse(args);
  if (argResults['help'] == true) {
    print(parser.usage);
    exit(0);
  }

  //print('argResults: test=${argResults['test']} '
  //      ' repeats=${argResults['repeats']}'
  //      ' listenMode=${argResults['listenMode']}'
  //      ' msgMode=${argResults['msgMode']}'
  //);

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
    case 'all':
      arguments.msgMode = MsgMode.all;
      break;
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
    case 'asProto':
      arguments.msgMode = MsgMode.asProto;
      break;
    case 'asFbMsg':
      arguments.msgMode = MsgMode.asFbMsg;
      break;
    default:
      print(parser.usage);
      exit(0);
  }

  arguments.timeInSecs = double.parse(argResults['time'] as String);
  arguments.repeats = int.parse(argResults['repeats'] as String);

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
      case MsgMode.all:
        throw 'BUG: msgMode is not valid';
        break;
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
      case MsgMode.asProto:
        serverParams.listener = processAsProto;
        break;
      case MsgMode.asFbMsg:
        serverParams.listener = processAsFbMsg;
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
    final NumberFormat f6digits = NumberFormat('###,##0.000000');
    final NumberFormat f0digit = NumberFormat('###,###');
    final double rate = msgs.toDouble() / totalSecs;
    return ResultStrings(
        f6digits.format(totalSecs).padLeft(padding),
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
  final int beforeStart = stopwatch.elapsedTicks;
  final Parameters serverParams =
      Parameters(null, arguments.listenMode, arguments.msgMode);
  final Parameters clientParams = await start(serverParams);

  if (arguments.timeInSecs <= 0) {
    // Tell the user to press a key
    print('${arguments.listenMode} ${arguments.msgMode} -- '
        'Press any key to stop...');

    // Change stdin so it doesn't echo input and doesn't wait for enter key
    stdin.echoMode = false;
    stdin.lineMode = false;
    await stdin.first;
  } else {
    final int delayInMicrosecs = (arguments.timeInSecs * 1000000.0).toInt();
    await delay(Duration(microseconds: delayInMicrosecs));
  }
  final int done = stopwatch.elapsedTicks;

  // Print time
  final double totalSecs = (done.toDouble() - beforeStart.toDouble()) /
      Stopwatch().frequency.toDouble();
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

Future<void> warmup(Arguments arguments, double timeInSecs) async {
  final Arguments warmupArgs = Arguments.clone(arguments);
  warmupArgs.repeats = 1;
  warmupArgs.timeInSecs = timeInSecs;
  await doWork(warmupArgs);
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
  if (arguments.msgMode == MsgMode.all) {
    if (arguments.timeInSecs <= 0) {
      arguments.timeInSecs = 1;
    }
    //print('Testing all listen and msg modes');
    final List<Modes> listenAndMsgModes = <Modes>[
      Modes(ListenMode.local, MsgMode.asInt),
      Modes(ListenMode.local, MsgMode.asClass),
      Modes(ListenMode.local, MsgMode.asMap),
      Modes(ListenMode.local, MsgMode.asFb),
      Modes(ListenMode.local, MsgMode.asProto),
      Modes(ListenMode.local, MsgMode.asFbMsg),
      Modes(ListenMode.isolate, MsgMode.asInt),
      Modes(ListenMode.isolate, MsgMode.asClass),
      Modes(ListenMode.isolate, MsgMode.asMap),
      Modes(ListenMode.isolate, MsgMode.asFb),
      Modes(ListenMode.isolate, MsgMode.asProto),
      Modes(ListenMode.isolate, MsgMode.asFbMsg),
    ];
    for (final Modes modes in listenAndMsgModes) {
      arguments.listenMode = modes.listenMode;
      arguments.msgMode = modes.msgMode;
      final WorkResult avgResult =
          WorkResult(Modes(modes.listenMode, modes.msgMode), 0, 0);
      await warmup(arguments, 0.5);
      for (int i = 1; i <= arguments.repeats; i++) {
        stdout.write('${i.toString().padLeft(4)}: '
            'time=${arguments.timeInSecs.toString().padLeft(5)} '
            '${modes.toString().padLeft(36)}\r');
        final WorkResult result = await doWork(arguments);
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
    await warmup(arguments, 0.5);
    final WorkResult avgResult =
        WorkResult(Modes(arguments.listenMode, arguments.msgMode), 0, 0);
    for (int i = 1; i <= arguments.repeats; i++) {
      final WorkResult result = await doWork(arguments);
      print('${i.toString().padLeft(3)}: $result');
      avgResult.msgs += result.msgs;
      avgResult.totalSecs += result.totalSecs;
    }
    if (arguments.repeats > 1) {
      print('avg: $avgResult');
    }
  }

  // Uses exit because main returns Future<void>, otherwise we hang
  exit(0);
}
