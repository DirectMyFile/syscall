part of syscall;

/// Gets the value of [name] in the sysctl database.
/// [type] specifies the type of the value.
/// If [dtype] is specified, the value will be unmarshalled into this type.
@Compatibility("Mac Only")
dynamic getSysCtlValue(String name, [type = "char[]", Type dtype]) {
  type = _getBinaryType(type);

  var len = alloc("size_t");
  var n = toNativeString(name);

  _checkResult(invoke("sysctlbyname", [n, getType("void*").nullPtr, len, getType("void*").nullPtr, 0]));

  if (type.toString().endsWith("[]")) {
    type = getType(type.toString().substring(0, type.length - 2) + "[${len.value}]");
  }


  var value = alloc(type);

  _checkResult(invoke("sysctlbyname", [n, value, len, getType("void*").nullPtr, 0]));

  if (dtype != null) {
    return LibC.unmarshall(value, dtype);
  } else {
    return value;
  }
}

/// Get System Information
@Compatibility("Linux Only")
LinuxSysInfo getSysInfo() {
  var instance = alloc("sysinfo");
  invoke("getsysinfo", [instance]);
  return instance;
}

/// Time Value
@Compatibility("Mac Only")
class MacTimeVal {
  int tv_sec;
}

/// Linux System Information
@Compatibility("Linux Only")
class LinuxSysInfo {
  /// Uptime in Seconds
  int uptime;

  /// Load Times
  /// This is a list of 3 doubles.
  List<double> loads;

  /// Total RAM
  int totalram;

  /// Free RAM
  int freeram;

  /// Shared RAM
  int sharedram;

  /// Buffer RAM
  int bufferram;

  /// Total Swap
  int totalswap;

  /// Free Sawap
  int freeswap;

  /// Number of Processes
  int procs;

  /// Total High Memory
  int totalhigh;

  /// Free High Memory
  int freehigh;

  /// Memory Unit
  int mem_unit;
}

/// Gets the System Uptime
Duration getSystemUptime() {
  int seconds;

  if (Platform.isMacOS) {
    var sse = new DateTime.now().millisecondsSinceEpoch ~/ 1000;
    seconds = sse - getSysCtlValue("kern.boottime", "struct timeval", MacTimeVal).tv_sec;
  } else {
    seconds = getSysInfo().uptime;
  }

  return new Duration(seconds: seconds);
}

/// Get load averages for the system.
/// [count] specifies how many averages to get.
/// [count] defaults to 3, and should always be between 0 and 3
List<double> getLoadAverages([int count = 3]) {
  var averages = allocArray("double", 3);
  _checkResult(invoke("getloadavg", [averages, count]));
  return averages.value.toList();
}

/// Gets the Current User ID (uid)
int getUserId() {
  return invoke("getuid");
}

/// Gets the Effective User ID (euid)
int getEffectiveUserId() {
  return invoke("geteuid");
}

/// Sets the Current User ID (uid)
void setUserId(int id) {
  _checkResult(invoke("setuid", [id]));
}

/// Sets the Effective User ID (euid)
void setEffectiveUserId(int id) {
  _checkResult(invoke("seteuid", [id]));
}

/// Gets the Current Group ID (gid)
int getGroupId() {
  return invoke("getgid");
}

/// Sets the Current Group ID (gid)
void setGroupId(int id) {
  _checkResult(invoke("setgid", [id]));
}

/// Gets the Effective Group ID (egid)
int getEffectiveGroupId() {
  return invoke("getegid");
}

/// Sets the Effective Group ID (egid)
void setEffectiveGroupId(int id) {
  _checkResult(invoke("setegid", [id]));
}

/// Gets the password file entry for [user].
Map<String, dynamic> getPasswordFileEntry(String user) {
  var u = toNativeString(user);
  var result = invoke("getpwnam", [u]);

  if (result.isNullPtr) {
    throw new ArgumentError.value(user, "user", "Unknown User");
  }

  var it = result.value;

  var map = {
    "name": readNativeString(it["pw_name"]),
    "password": readNativeString(it["pw_passwd"]),
    "uid": it["pw_uid"],
    "gid": it["pw_gid"],
    "full name": it["pw_gecos"].isNullPtr ? null : readNativeString(it["pw_gecos"]),
    "home": readNativeString(it["pw_dir"]),
    "shell": readNativeString(it["pw_shell"])
  };

  if (Platform.isMacOS) {
    map["class"] = readNativeString(it["pw_class"]);
    map["password changed"] = it["pw_change"];
    map["expiration"] = it["pw_expire"];
  }

  return map;
}

/// Get a list of users on the system.
/// If [showHidden] is true, then users with a _ in front of their name will be shown.
List<String> getUsers({bool showHidden: false}) {
  if (Platform.isMacOS) {
    String out = Process.runSync("dscacheutil", ["q", "user"]).stdout.toString().trim();
    return out
      .split("\n")
      .where((it) => it.startsWith("name: ") && (showHidden ? true : !it.startsWith("name: _")))
      .map((it) => it.substring(6))
      .toList();
  } else {
    var passwd = new File("/etc/passwd").readAsLinesSync().where((it) => !it.startsWith("#")).toList();
    var users = [];
    for (var line in passwd) {
      if (!showHidden && line.startsWith("_")) {
        continue;
      }
      users.add(line.split(":").first);
    }
    return users;
  }
}

/// Gets the group ids for all the groups that the user specified by [name] is in.
List<int> getUserGroups(String name) {
  var n = toNativeString(name);
  var gid = getPasswordFileEntry(name)["gid"];
  var lastn = 10;
  var count = alloc("int", lastn);
  var results = allocArray("gid_t", lastn);
  var times = 0;

  while (true) {
    var c = invoke("getgrouplist", [n, gid, results, count]);

    if (c == -1 || lastn != count.value) {
      if (times >= 8) {
        throw new Exception("Failed to get groups.");
      } else {
        count.value = count.value * 2;
        results = allocArray("gid_t", count.value);
        lastn = count.value;
      }
    } else {
      break;
    }

    times++;
  }

  return results.value;
}

/// Gets information for the group specified by [gid].
Group getGroupInfo(int gid) {
  return LibC.unmarshall(invoke("getgrgid", [gid]), Group);
}

/// Represents a Group
class Group {
  /// Group Name
  String gr_name;

  /// Group Password
  String gr_passwd;

  /// Group ID
  int gr_gid;

  /// Group Members
  List<String> gr_mem;
}

/// Gets the current process id.
int getProcessId() {
  return invoke("getpid");
}

/// Gets the parent process id.
int getParentProcessId() {
  return invoke("getppid");
}

/// Gets the Process Group ID for the process specified by [pid].
/// If [pid] is not specified, then it returns the process group id for the current process.
int getProcessGroupId([int pid]) {
  if (pid == null) {
    pid = getProcessId();
  }

  return invoke("getpgid", [pid]);
}
