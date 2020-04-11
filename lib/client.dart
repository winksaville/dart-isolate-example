import 'dart:io';
import 'dart:isolate';
import 'package:flat_buffers/flat_buffers.dart' as fb;

import 'test1_generated.dart' as test1;

enum Cmd { microsecs, duration }
enum MsgMode { asInt, asMap, asClass, asFb }
enum ListenMode { local, isolate }

class Message {
  int microsecs;
  int duration;

  Message(this.microsecs, this.duration);
}

class Parameters {
  SendPort partnerPort;
  MsgMode msgMode;
  ListenMode listenMode;
  var listener;
  int counter = 0;

  Parameters(this.partnerPort, this.listenMode, this.msgMode);
}

/// Process int messages
void processAsInt(Parameters params, int now, dynamic data) {
  params.partnerPort.send(now);
}

/// Process Map messages
void processAsMap(Parameters params, int now, dynamic msg) {
  final int duration = now - (msg[Cmd.microsecs] as int);
  params.partnerPort.send({Cmd.microsecs: now, Cmd.duration: duration});
}

/// Process Message messages
void processAsClass(Parameters params, int now, Message msg) {
  // Use a Class
  // Reusing existing message didn't seem to make big difference.
  // About 430K+ msgs/sec.
  final int duration = now - msg.microsecs;
  if (true) {
    // Reuse existing Message
    msg.microsecs = now;
    msg.duration = duration;
    params.partnerPort.send(msg);
  } else {
    // Create new Message
    params.partnerPort.send(Message(now, duration));
  }
}

/// Process Flatbuffer messages which is a List<int>
void processAsFb(Parameters params, int now, List<int> msg) {
  // Deserialize msg from bytes and and calculate duration
  test1.Msg m = test1.Msg(msg);
  final int duration = now - m.microsecs;

  // Create our new MsgObjectBuilder
  final test1.MsgObjectBuilder mob =
    test1.MsgObjectBuilder(microsecs: now, duration: duration);

  // Serialize
  List<int> buffer = mob.toBytes();

  // Send the buffer
  params.partnerPort.send(buffer);
}

/// Client receives a Send port from our partner
/// so that messages maybe sent to it.
void client(Parameters params) {
  assert(params.partnerPort != null);

  // Create a port that will receive messages from our partner
  ReceivePort receivePort = ReceivePort();

  // Using the partnerPort send our sendPort so they
  // can send us messages.
  params.partnerPort.send(receivePort.sendPort);

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
  receivePort.listen((dynamic message) {
    final now = DateTime.now().microsecondsSinceEpoch;
    params.counter += 1;
    params.listener(params, now, message);
  });

  print('client: done');
}
