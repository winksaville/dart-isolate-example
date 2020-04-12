import 'dart:io';
import 'dart:isolate';
import 'package:flat_buffers/flat_buffers.dart' as fb;

import 'misc.dart';
import 'test1_generated.dart' as test1;

/// Client receives a Send port from our partner
/// so that messages maybe sent to it.
void client(Parameters params) {
  assert(params.partnerPort != null);

  // Create a port that will receive messages from our partner
  params.receivePort = ReceivePort();

  // Using the partnerPort send our sendPort so they
  // can send us messages.
  params.partnerPort.send(params.receivePort.sendPort);

  // Since we're the client we send the first data message
  params.counter = 1;
  int now = DateTime.now().microsecondsSinceEpoch;
  switch (params.msgMode) {
    case MsgMode.asInt:
      // local=1.4m+ m/s, isolate=225k+ m/s
      params.listener = processAsInt;
      params.listener(params, now, now);
      break;
    case MsgMode.asMap:
      // local=160k+ m/s isolate=50k+ m/s
      params.listener = processAsMap;
      params.listener(params, now, {Cmd.microsecs: now, Cmd.duration: 0});
      break;
    case MsgMode.asClass:
      // local=430k+ m/s, isolate=120k+ m/s
      params.listener = processAsClass;
      params.listener(params, now, Message(now, 0));
      break;
    case MsgMode.asFb:
      params.listener = processAsFb;
      params.listener( params, now,
        test1.MsgObjectBuilder(microsecs: now, duration: 0).toBytes());
  }

  // Wait for response and send more messages as fast as we can
  params.receivePort.listen(
    (dynamic message) {
      final now = DateTime.now().microsecondsSinceEpoch;
      params.counter += 1;
      params.listener(params, now, message);
    },
    //onDone: () => print('client: listen onDone'),
  );
}
