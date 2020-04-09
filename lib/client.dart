import 'dart:isolate';

/// Client receives a Send port from our partner
/// so that messages maybe sent to it.
void client(SendPort partnerPort) {
  // Create a port that will receive messages from our partner
  ReceivePort receivePort = ReceivePort();

  // Using the partnerPort send our sendPort so they
  // can send us messages.
  partnerPort.send(receivePort.sendPort);

  // Since we're the client we send the first data message
  int counter = 1;
  partnerPort.send(counter);

  // Wait for response and send more messages as fast as we can
  receivePort.listen((data) {
    //print('RESP: $data');
    counter++;
    //print('SEND: $counter');
    partnerPort.send(counter);
  });

  print('client: done');
}
