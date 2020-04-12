import 'dart:isolate';
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
  Isolate isolate;
  ReceivePort receivePort;
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

Future<Duration> delay(Duration duration) async {
    return Future<Duration>.delayed(duration);
}
