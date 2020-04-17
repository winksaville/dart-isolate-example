import 'dart:async';
import 'dart:isolate';
import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'fb_msg_generated.dart' as fb_msg;
import 'test1.pb.dart' as t1_pb;
import 'test1_generated.dart' as test1;

enum Cmd { microsecs, duration }
enum MsgMode { asInt, asMap, asClass, asFb, asProto, asFbMsg }
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

class FbDate {
    FbDate(this.year, this.month, this.day);

    int year;
    int month;
    int day;
}

class FbPerson {
    FbPerson(this.firstName, this.lastName, this.telephone, this.birthDate, this.height);

    int addToBuilder(fb.Builder builder) {
      final fb_msg.PersonBuilder pb = fb_msg.PersonBuilder(builder);
      final int firstNameOffset = builder.writeString(firstName);
      final int lastNameOffset = builder.writeString(firstName);
      final int telephoneOffset = builder.writeString(telephone);

      final fb_msg.DateBuilder db = fb_msg.DateBuilder(builder);
      final int dateOffset = db.finish(birthDate.year, birthDate.month, birthDate.day);

      pb.begin();
      pb.addFirstNameOffset(firstNameOffset);
      pb.addLastNameOffset(lastNameOffset);
      pb.addTelephoneOffset(telephoneOffset);
      pb.addBirthDate(dateOffset);
      pb.addHeight(height);
      return pb.finish();
    }

    String firstName;
    String lastName;
    String telephone;
    FbDate birthDate;
    double height;
}

class FbMsgHeader {
  FbMsgHeader(this.cmd, this.status, this.timestamp);

  int addToBuilder(fb.Builder builder) {
    final fb_msg.MsgHeaderBuilder b = fb_msg.MsgHeaderBuilder(builder);
    b.begin();
    b.addCmd(cmd);
    b.addStatus(status);
    b.addTimestamp(timestamp);
    return b.finish();
  }

  int cmd;
  int status;
  int timestamp;
}

class FbPeopleMessage {
  FbPeopleMessage(this._builder, FbMsgHeader header) :
    _headerOffset = header.addToBuilder(_builder);
 
  void addPerson(FbPerson person) {
    final int personOffset = person.addToBuilder(_builder);
    _people.add(personOffset);
  }

  List<int> finish() {
    final int peopleArrayOffset = _builder.writeList(_people);
    fb_msg.PeopleBuilder pb = fb_msg.PeopleBuilder(_builder);
    pb.begin();
    pb.addArrayOffset(peopleArrayOffset);
    final int pbOffset = pb.finish();

    final fb_msg.FbMsgBuilder mb = fb_msg.FbMsgBuilder(_builder);
    mb.begin();
    mb.addHeaderOffset(_headerOffset);
    mb.addBodyType(fb_msg.MsgBodyTypeId.People);
    mb.addBodyOffset(pbOffset);
    final int msgOffset = mb.finish();

    final List<int> result = _builder.finish(msgOffset);
    return result;
  }

  final fb.Builder _builder;
  final int _headerOffset;
  final List<int> _people = <int>[];
}

/// Process Flat buffers messages which is a List<int>
void processAsFbMsg(Parameters params, int now, List<int> msg) {
  // Deserialize msg from bytes and and calculate duration
  final fb_msg.FbMsg m = fb_msg.FbMsg(msg);
  final fb_msg.People people = m.body as fb_msg.People;

  if (m.header.cmd == 1) {
    final fb.Builder builder = fb.Builder(initialSize: 1024);

    final FbPeopleMessage pm = FbPeopleMessage(builder, FbMsgHeader(1, 0, now));

    pm.addPerson(FbPerson('Wink', 'Saville', '831-234-2134', FbDate(1949, 12, 17), 71.5));
    pm.addPerson(FbPerson('Yvette', 'Saville', '831-234-2133', FbDate(1954, 7, 11), 63.0));

    final List<int> buffer = pm.finish();

    params.partnerPort.send(buffer);
  } else {
    // TODO(wink): How to include line number in a string?
    throw 'processAsFbMsg: Unexpected m.header.cmd=${m.header.cmd} ${people.array[0].firstName}';
  }
}

Future<Duration> delay(Duration duration) async {
  return Future<Duration>.delayed(duration);
}
