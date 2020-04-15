// automatically generated by the FlatBuffers compiler, do not modify
// ignore_for_file: unused_import, unused_field, unused_local_variable

import 'dart:typed_data' show Uint8List;
import 'package:flat_buffers/flat_buffers.dart' as fb;


class Msg {
  Msg._(this._bc, this._bcOffset);
  factory Msg(List<int> bytes) {
    fb.BufferContext rootRef = new fb.BufferContext.fromBytes(bytes);
    return reader.read(rootRef, 0);
  }

  static const fb.Reader<Msg> reader = const _MsgReader();

  final fb.BufferContext _bc;
  final int _bcOffset;

  int get microsecs => const fb.Uint64Reader().vTableGet(_bc, _bcOffset, 4, 0);
  int get duration => const fb.Int64Reader().vTableGet(_bc, _bcOffset, 6, 0);

  @override
  String toString() {
    return 'Msg{microsecs: $microsecs, duration: $duration}';
  }
}

class _MsgReader extends fb.TableReader<Msg> {
  const _MsgReader();

  @override
  Msg createObject(fb.BufferContext bc, int offset) => 
    new Msg._(bc, offset);
}

class MsgBuilder {
  MsgBuilder(this.fbBuilder) {
    assert(fbBuilder != null);
  }

  final fb.Builder fbBuilder;

  void begin() {
    fbBuilder.startTable();
  }

  int addMicrosecs(int microsecs) {
    fbBuilder.addUint64(0, microsecs);
    return fbBuilder.offset;
  }
  int addDuration(int duration) {
    fbBuilder.addInt64(1, duration);
    return fbBuilder.offset;
  }

  int finish() {
    return fbBuilder.endTable();
  }
}

class MsgObjectBuilder extends fb.ObjectBuilder {
  final int _microsecs;
  final int _duration;

  MsgObjectBuilder({
    int microsecs,
    int duration,
  })
      : _microsecs = microsecs,
        _duration = duration;

  /// Finish building, and store into the [fbBuilder].
  @override
  int finish(
    fb.Builder fbBuilder) {
    assert(fbBuilder != null);

    fbBuilder.startTable();
    fbBuilder.addUint64(0, _microsecs);
    fbBuilder.addInt64(1, _duration);
    return fbBuilder.endTable();
  }

  /// Convenience method to serialize to byte list.
  @override
  Uint8List toBytes([String fileIdentifier]) {
    fb.Builder fbBuilder = new fb.Builder();
    int offset = finish(fbBuilder);
    return fbBuilder.finish(offset, fileIdentifier);
  }
}
