import "dart:io";

import "package:syscall/readline.dart";
import "dart:isolate";

worker(SendPort port) async {
  LibReadline.init();
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
    } else if (msg["method"] == "addLineToHistory") {
      var line = msg["line"];
      Readline.addLineToHistory(line);
    } else if (msg["method"] == "bindKey") {
      var key = msg["key"];
      var handler = msg["handler"];

      Readline.bindKey(key, handler);
    }
  }
}

String prompt = r"$ ";

SendPort mainPort;

main() async {
  var receiver = new ReceivePort();
  var msgs = receiver.asBroadcastStream();
  var isolate = await Isolate.spawn(worker, receiver.sendPort);
  mainPort = await msgs.first;

  while (true) {
    mainPort.send({
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
  line = line.trimLeft();

  mainPort.send({
    "method": "addLineToHistory",
    "line": line
  });

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
  } else if (cmd == "print") {
    print(args.join(" "));
  }
}
