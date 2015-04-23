import "dart:io";

import "package:syscall/readline.dart";
import "dart:isolate";

worker(SendPort port) async {
  var receiver = new ReceivePort();
  port.send(receiver.sendPort);

  await for (Map msg in receiver) {
    if (msg["method"] == "readline") {
      var prompt = msg["prompt"];
      var result = Readline.readLine(prompt);
      port.send({
        "type": "read",
        "data": result
      });
    }
  }
}

String prompt = r"$ ";

main() async {
  var receiver = new ReceivePort();
  var msgs = receiver.asBroadcastStream();
  var isolate = await Isolate.spawn(worker, receiver.sendPort);
  SendPort port = await msgs.first;

  msgs.listen(handleMessage);

  while (true) {
    port.send({
      "method": "readline",
      "prompt": prompt
    });
    var msg = await msgs.first;
    await handleMessage(msg);
  }
}

handleMessage(Map<String, dynamic> msg) async {
  if (msg["type"] == "read") {
    await handleLine(msg["data"]);
  }
}

handleLine(String line) async {
  if (line == null) {
    exit(1);
  }
  line = line.trim();
  Readline.addLineToHistory(line);
  var split = line.split(" ");
  if (split.length == 0) {
    return;
  }
  var cmd = split[0];
  var args = split.skip(1).toList();

  await handleCommand(cmd, args);
}

handleCommand(String cmd, List<String> args) async {
  if (cmd == "exit") {
    exit(0);
  } else if (cmd == "clear-history") {
    Readline.clearHistory();
  }
}
