import "dart:convert";
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
    } else if (msg["method"] == "clearHistory") {
      Readline.clearHistory();
    } else if (msg["method"] == "bulkLoadHistory") {
      var history = msg["history"];
      for (var line in history) {
        Readline.addLineToHistory(line);
      }
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
  await loadStorage();

  if (storage["prompt"] != null) {
    prompt = storage["prompt"];
  }

  env.addAll(Platform.environment);
  env["BULLET_VERSION"] = "1.0";

  var receiver = new ReceivePort();
  var msgs = receiver.asBroadcastStream();
  var isolate = await Isolate.spawn(worker, receiver.sendPort);
  mainPort = await msgs.first;

  if (storage["history"] != null) {
    /// Load History
    mainPort.send({
      "method": "bulkLoadHistory",
      "history": storage["history"]
    });
  }

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

RegExp VAR_REGEX = new RegExp(r"\$\{(.+)\}");

String processEnvironmentVars(String input) {
  if (!VAR_REGEX.hasMatch(input)) {
    return input;
  }

  return input.replaceAllMapped(VAR_REGEX, (match) {
    var name = match.group(1);
    if (env.containsKey(name)) {
      return env[name];
    } else {
      return "";
    }
  });
}

Map<String, String> env = {};

handleLine(String line) async {
  if (line == null) {
    exit(1);
  }

  line = line.trimLeft();

  if (line.trim().isEmpty) {
    return;
  }

  line = processEnvironmentVars(line);

  mainPort.send({
    "method": "addLineToHistory",
    "line": line
  });

  var history = storage["history"];

  if (history == null) {
    history = storage["history"] = [];
  }

  history.add(line);

  await saveStorage();

  var split = line.split(" ");
  if (split.length == 0) {
    return;
  }
  var cmd = split[0];
  var args = split.skip(1).toList();

  await handleCommand(cmd, args);
}

handleCommand(String cmd, List<String> args) async {
  if (commands.containsKey(cmd)) {
    var c = commands[cmd];
    if (c is String) {
      return await handleCommand(c, args);
    }
    var result = await c(args);
    if (result is int) {
      env["?"] = result.toString();
    } else {
      env["?"] = "0";
    }
  } else {
    print("Unknown Command: ${cmd}");
    env["?"] = "1";
  }
}

Map<String, dynamic> commands = {
  "exit": (List<String> args) {
    int code = 0;
    if (args.length > 1) {
      print("Usage: exit [code = 0]");
      return 1;
    } else {
      if (args.length == 1) {
        var m = int.parse(args[0], onError: (source) => null);
        if (m == null) {
          print("Invalid Exit Code");
          return 1;
        }
        code = m;
      }
    }
    exit(code);
  },
  "clear-history": (List<String> args) async {
    mainPort.send({
      "method": "clearHistory"
    });
    storage["history"] = [];
    await saveStorage();
  },
  "print": (List<String> args) {
    print(args.join(" "));
  },
  "echo": "print",
  "alias": (List<String> args) {
    if (args.length <= 1) {
      print("Usage: alias {your command} {target command}");
    }

    var m = args[0];
    var l = args.skip(1).toList();
    commands[m] = (List<String> a) {
      var t = l[0];
      var r = l.skip(1).toList();
      var q = new List<String>.from(r)..addAll(a);
      return handleCommand(t, q);
    };
  },
  "set": (List<String> args) {
    if (args.length < 2) {
      print("Usage: set {variable} {value}");
      return 1;
    }

    var n = args[0];
    var v = args.skip(1).join(" ");
    env[n] = v;
  },
  "unset": (List<String> args) {
    for (var n in args) {
      env.remove(n);
    }
  }
};

loadStorage() async {
  var file = new File("${Platform.environment["HOME"]}/.bullet/storage.json");
  if (!(await file.exists())) {
    await file.create(recursive: true);
    await file.writeAsString("{}\n");
  }
  var content = await file.readAsString();
  storage = JSON.decode(content);
}

saveStorage() async {
  var file = new File("${Platform.environment["HOME"]}/.bullet/storage.json");
  if (!(await file.exists())) {
    await file.create(recursive: true);
  }
  await file.writeAsString(jsonEncoder.convert(storage) + "\n");
}

JsonEncoder jsonEncoder = new JsonEncoder.withIndent("  ");

Map<String, dynamic> storage = {};

typedef CommandHandler(List<String> args);
