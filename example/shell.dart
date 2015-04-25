import "dart:async";
import "dart:convert";
import "dart:io";

import "package:syscall/readline.dart";
import "package:syscall/syscall.dart" as syscall;
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
  await loadSystemCommands();

  commands.addAll(builtInCommands);

  if (storage["prompt"] != null) {
    prompt = storage["prompt"];
  }

  if (storage["aliases"] != null) {
    for (var a in storage["aliases"].keys) {
      addAlias(a, storage["aliases"][a]);
    }
    await saveStorage();
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

loadSystemCommands() async {
  var c = {};
  var paths = Platform.environment["PATH"].split(Platform.isWindows ? ";" : ":");
  for (var path in paths) {
    var dir = new Directory(path);
    if (!(await dir.exists())) {
      continue;
    }

    await for (File file in dir.list().where((it) => it is File)) {
      FileStat stat = await file.stat();
      if (hasPermission(stat.mode, FilePermission.EXECUTE)) {
        var z = file.path;
        var name = z.split(Platform.pathSeparator).last;
        c[name] = z;
      }
    }
  }

  for (var name in c.keys) {
    commands[name] = (List<String> args) async {
      if (storage["spawn_using_syscall"] == false) {
        var result = await exec(c[name], args: args, inherit: true);
        return result.exitCode;
      } else {
        var result = syscall.executeSystem(([name]..addAll(args)).join(" "));
        return syscall.getExitCodeFromStatus(result);
      }
    };
  }
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

Map<String, dynamic> commands = {};

Map<String, dynamic> builtInCommands = {
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
  "alias": (List<String> args) async {
    if (args.length <= 1) {
      print("Usage: alias {your command} {target command}");
    }

    var m = args[0];
    var l = args.skip(1).toList();

    addAlias(m, l);
    await saveStorage();
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

void addAlias(String m, List<String> l) {
  commands[m] = (List<String> a) {
    var t = l[0];
    var r = l.skip(1).toList();
    var q = new List<String>.from(r)..addAll(a);
    return handleCommand(t, q);
  };

  if (!storage.containsKey("aliases")) {
    storage["aliases"] = {};
  }

  storage["aliases"][m] = l;
}

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

class FilePermission {

  final int index;
  final String _name;

  const FilePermission._(this.index, this._name);

  static const EXECUTE = const FilePermission._(0, 'EXECUTE');
  static const WRITE = const FilePermission._(1, 'WRITE');
  static const READ = const FilePermission._(2, 'READ');
  static const SET_UID = const FilePermission._(3, 'SET_UID');
  static const SET_GID = const FilePermission._(4, 'SET_GID');
  static const STICKY = const FilePermission._(5, 'STICKY');

  static const List<FilePermission> values = const [EXECUTE, WRITE, READ, SET_UID, SET_GID, STICKY];

  String toString() => 'FilePermission.$_name';
}

class FilePermissionRole {
  final int index;
  final String _name;

  const FilePermissionRole._(this.index, this._name);

  static const WORLD = const FilePermissionRole._(0, 'WORLD');
  static const GROUP = const FilePermissionRole._(1, 'GROUP');
  static const OWNER = const FilePermissionRole._(2, 'OWNER');

  static const List<FilePermissionRole> values = const [WORLD, GROUP, OWNER];

  String toString() => 'FilePermissionRole.$_name';
}

bool hasPermission(int fileStatMode, FilePermission permission, {FilePermissionRole role: FilePermissionRole.WORLD}) {
  var bitIndex = _getPermissionBitIndex(permission, role);
  return (fileStatMode & (1 << bitIndex)) != 0;
}

int _getPermissionBitIndex(FilePermission permission, FilePermissionRole role) {
  switch (permission) {
    case FilePermission.SET_UID:
      return 11;
    case FilePermission.SET_GID:
      return 10;
    case FilePermission.STICKY:
      return 9;
    default:
      return (role.index * 3) + permission.index;
  }
}

typedef void ProcessHandler(Process process);
typedef void OutputHandler(String str);

Stdin get _stdin => stdin;

class BetterProcessResult extends ProcessResult {
  final String output;

  BetterProcessResult(int pid, int exitCode, stdout, stderr, this.output) :
  super(pid, exitCode, stdout, stderr);
}

Future<BetterProcessResult> exec(
    String executable,
    {
    List<String> args: const [],
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment: true,
    bool runInShell: false,
    stdin,
    ProcessHandler handler,
    OutputHandler stdoutHandler,
    OutputHandler stderrHandler,
    OutputHandler outputHandler,
    bool inherit: false
    }) async {
  Process process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell
  );

  var buff = new StringBuffer();
  var ob = new StringBuffer();
  var eb = new StringBuffer();

  process.stdout.transform(UTF8.decoder).listen((str) {
    ob.write(str);
    buff.write(str);

    if (stdoutHandler != null) {
      stdoutHandler(str);
    }

    if (outputHandler != null) {
      outputHandler(str);
    }

    if (inherit) {
      stdout.write(str);
    }
  });

  process.stderr.transform(UTF8.decoder).listen((str) {
    eb.write(str);
    buff.write(str);

    if (stderrHandler != null) {
      stderrHandler(str);
    }

    if (outputHandler != null) {
      outputHandler(str);
    }

    if (inherit) {
      stderr.write(str);
    }
  });

  if (handler != null) {
    handler(process);
  }

  if (stdin != null) {
    if (stdin is Stream) {
      stdin.listen(process.stdin.add, onDone: process.stdin.close);
    } else if (stdin is List) {
      process.stdin.add(stdin);
    } else {
      process.stdin.write(stdin);
      await process.stdin.close();
    }
  } else if (inherit) {
    Stream<List<int>> a = await new File("/dev/stdin").openRead();
    a.listen(process.stdin.add, onDone: process.stdin.close);
  }

  var code = await process.exitCode;
  var pid = process.pid;

  return new BetterProcessResult(
      pid,
      code,
      ob.toString(),
      eb.toString(),
      buff.toString()
  );
}
