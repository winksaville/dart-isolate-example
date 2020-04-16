///
//  Generated code. Do not modify.
//  source: test1.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class Msg extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Msg', createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, 'microsecs', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aInt64(2, 'duration')
    ..hasRequiredFields = false
  ;

  Msg._() : super();
  factory Msg() => create();
  factory Msg.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Msg.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Msg clone() => Msg()..mergeFromMessage(this);
  Msg copyWith(void Function(Msg) updates) => super.copyWith((message) => updates(message as Msg));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Msg create() => Msg._();
  Msg createEmptyInstance() => create();
  static $pb.PbList<Msg> createRepeated() => $pb.PbList<Msg>();
  @$core.pragma('dart2js:noInline')
  static Msg getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Msg>(create);
  static Msg _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get microsecs => $_getI64(0);
  @$pb.TagNumber(1)
  set microsecs($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMicrosecs() => $_has(0);
  @$pb.TagNumber(1)
  void clearMicrosecs() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get duration => $_getI64(1);
  @$pb.TagNumber(2)
  set duration($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDuration() => $_has(1);
  @$pb.TagNumber(2)
  void clearDuration() => clearField(2);
}

