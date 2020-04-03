import 'dart:io';
import 'dart:async';
import 'dart:isolate';

/// Client expects to be in an isolate
void client(SendPort sendPort) {
  // Send the "responsePort" to our partner
  ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  // Send the first data message
  int counter = 1;
  int msg = counter; //'notification ' + counter.toString();
  sendPort.send(msg);

  // Wait for response and send more messages as fast as we can
  receivePort.listen((data) {
    //stdout.writeln('RESP: ' + data);
    counter++;
    msg = counter; //'notification ' + counter.toString();
    //stdout.writeln('SEND: ' + msg);
    sendPort.send(msg);
  });

  stdout.writeln('client: done');
}
