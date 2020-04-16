import 'dart:async';
import 'dart:isolate';
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'test1.pb.dart' as t1_pb;
import 'test1_generated.dart' as test1;

enum Cmd { microsecs, duration }
enum MsgMode { asInt, asMap, asClass, asFb, asProto }
enum ListenMode { local, isolate }

class Message {
  Message(this.microsecs, this.duration);

  int microsecs;
  int duration;
}

// A Possible type for `Parameters.listener, but compiler rejects it.
//typedef MyListener = StreamSubscription<dynamic> Function(
//    void Function(dynamic message),
//    {Function onError,
//    void onDone(),
//    bool cancelOnError});

class Parameters {
  Parameters(this.partnerPort, this.listenMode, this.msgMode);

  Isolate isolate;
  ReceivePort receivePort;
  SendPort partnerPort;
  MsgMode msgMode;
  ListenMode listenMode;
  dynamic listener; // TODO(wink): Needs a type, it is a ReceivePort.listen
  int counter = 0;
}

/// Process int messages
void processAsInt(Parameters params, int now, dynamic data) {
  params.partnerPort.send(now);
}

/// Process Map messages
void processAsMap(Parameters params, int now, dynamic msg) {
  final int microsecs = msg[Cmd.microsecs] as int;
  final int duration = now - microsecs;
  params.partnerPort
      .send(<Cmd, int>{Cmd.microsecs: now, Cmd.duration: duration});
}

/// Process Message messages
void processAsClass(Parameters params, int now, Message msg) {
  // Use a Class
  // Reusing existing message didn't seem to make big difference.
  // About 430K+ messages/sec.
  final int duration = now - msg.microsecs;
  if (false) {
    // Reuse existing Message
    msg.microsecs = now;
    msg.duration = duration;
    params.partnerPort.send(msg);
  } else {
    // Create new Message
    params.partnerPort.send(Message(now, duration));
  }
}

/// Process Flat buffers messages which is a List<int>
void processAsFb(Parameters params, int now, List<int> msg) {
  // Deserialize msg from bytes and and calculate duration
  final test1.Msg m = test1.Msg(msg);
  final int duration = now - m.microsecs;

  final fb.Builder msgBb = fb.Builder(initialSize: 48);
  final test1.MsgBuilder msgBuilder = test1.MsgBuilder(msgBb);

  // Build the buffer
  msgBuilder.begin();
  msgBuilder.addMicrosecs(now);
  msgBuilder.addDuration(duration);
  final List<int> buffer = msgBb.finish(msgBuilder.finish());

  // Send the buffer
  params.partnerPort.send(buffer);
}

/// Process Protobuf messages which is a List<int>
void processAsProto(Parameters params, int now, List<int> msg) {
  // Deserialize msg from bytes and and calculate duration
  final t1_pb.Msg m = t1_pb.Msg.fromBuffer(msg);

  final fixnum.Int64 now64 = fixnum.Int64(now);
  m.duration = now64 - m.microsecs;
  m.microsecs = now64;

  params.partnerPort.send(m.writeToBuffer());
}

Future<Duration> delay(Duration duration) async {
  return Future<Duration>.delayed(duration);
}
