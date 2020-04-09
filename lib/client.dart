import 'dart:isolate';

enum Cmd { microsecs, duration }
enum Mode { asInt, asClass, asMap }

class Message {
  int microsecs;
  int duration;

  Message(this.microsecs, this.duration);
}

class ClientParam {
  SendPort partnerPort;
  Mode mode;

  ClientParam(this.partnerPort, this.mode);
}

/// Client receives a Send port from our partner
/// so that messages maybe sent to it.
void client(ClientParam param) {
  // Create a port that will receive messages from our partner
  ReceivePort receivePort = ReceivePort();

  // Using the partnerPort send our sendPort so they
  // can send us messages.
  param.partnerPort.send(receivePort.sendPort);

  // Since we're the client we send the first data message
  int counter = 1;
  int now = DateTime.now().microsecondsSinceEpoch;

  switch (param.mode) {
    case Mode.asInt:
      // local=1.4m+ m/s, isolate=225k+ m/s
      param.partnerPort.send(now);
      break;
    case Mode.asClass:
      // local=430k+ m/s, isolate=120k+ m/s
      param.partnerPort.send(Message(now, 0));
      break;
    case Mode.asMap:
      // local=160k+ m/s isolate=50k+ m/s
      param.partnerPort.send({Cmd.microsecs: now, Cmd.duration: 0});
      break;
  }

  // Wait for response and send more messages as fast as we can
  receivePort.listen((dynamic message) {
    counter += 1;

    final now = DateTime.now().microsecondsSinceEpoch;
    if (message is SendPort) {
      print('client: Unexpected SendPort');
      exit(1);
    } else if (message is Message) {
      assert(param.partnerPort != null);

      Message msg = message as Message;

      // Use a Class
      // Reusing existing message didn't seem to make big difference.
      // About 430K+ msgs/sec.
      final int duration = now - msg.microsecs;
      if (true) {
        // Reuse existing Message
        msg.microsecs = now;
        msg.duration = duration;
        param.partnerPort.send(msg);
      } else {
        // Create new Message
        param.partnerPort.send(Message(now, duration));
      }
    } else if (message is int) {
      param.partnerPort.send(now);
    } else {
      final int duration = now - (message[Cmd.microsecs] as int);
      param.partnerPort.send({Cmd.microsecs: now, Cmd.duration: duration});
    }
  });

  print('client: done');
}
