part of syscall;

/// Open System Log
void openSystemLog(String ident, int logopt, int facility) {
  var lident = toNativeString(ident);
  invoke("openlog", [lident, logopt, facility]);
}

/// Close System Log
void closeSystemLog() {
  invoke("closelog");
}

/// Write a message to the system log.
void writeToSystemLog(int priority, String message) {
  invoke("syslog", [priority, toNativeString(message)]);
}

/// Get System Information
@Compatibility("Linux Only")
LinuxSysInfo getSysInfo() {
  var instance = alloc("sysinfo");
  invoke("getsysinfo", [instance]);
  return instance;
}

/// Time Value
class TimeVal {
  @NativeName("tv_sec")
  int seconds;

  @NativeName("tv_usec")
  int milliseconds;
}

/// Linux System Information
@Compatibility("Linux Only")
class LinuxSysInfo {
  /// Uptime in Seconds
  int uptime;

  /// Load Times
  /// This is a list of 3 doubles.
  List<double> loads;

  /// Total Memory
  @NativeName("totalram")
  int totalMemory;

  /// Free Memory
  @NativeName("freeram")
  int freeMemory;

  /// Shared Memory
  @NativeName("sharedram")
  int sharedMemory;

  /// Buffer RAM
  @NativeName("bufferram")
  int bufferMemory;

  /// Total Swap
  @NativeName("totalswap")
  int totalSwap;

  /// Free Swap
  @NativeName("freeswap")
  int freeSwap;

  /// Number of Processes
  @NativeName("procs")
  int processCount;

  /// Total High Memory
  @NativeName("totalhigh")
  int totalHighMemory;

  /// Free High Memory
  @NativeName("freehigh")
  int freeHighMemory;

  /// Memory Unit
  @NativeName("mem_unit")
  int memoryUnit;
}

/// Represents a User
class User {
  /// Username
  String name;

  /// Full User Name
  String fullName;

  /// Home Directory
  String home;

  /// Shell
  String shell;

  /// Password
  String password;

  /// User ID
  int uid;

  /// Group ID
  int gid;

  /// Get Group IDs
  List<int> get groups => getUserGroups(name);
}

/// uname information
class KernelInfo {
  /// Operating System Name
  @NativeName("sysname")
  String operatingSystemName;

  /// Network Name (Probably Hostname)
  @NativeName("nodename")
  String networkName;

  /// Kernel Release
  @NativeName("release")
  String release;

  /// Kernel Version
  @NativeName("version")
  String version;

  /// Machine
  @NativeName("machine")
  String machine;
}

/// Gets the System Uptime
Duration getSystemUptime() {
  int seconds;

  if (Platform.isMacOS) {
    var sse = new DateTime.now().millisecondsSinceEpoch ~/ 1000;
    seconds = sse - getSysCtlValue("kern.boottime", type: "struct timeval", dtype: TimeVal).tv_sec;
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
  checkSysCallResult(invoke("getloadavg", [averages, count]));
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
  checkSysCallResult(invoke("setuid", [id]));
}

/// Sets the Effective User ID (euid)
void setEffectiveUserId(int id) {
  checkSysCallResult(invoke("seteuid", [id]));
}

/// Gets the Current Group ID (gid)
int getGroupId() {
  return invoke("getgid");
}

/// Sets the Current Group ID (gid)
void setGroupId(int id) {
  checkSysCallResult(invoke("setgid", [id]));
}

/// Gets the Effective Group ID (egid)
int getEffectiveGroupId() {
  return invoke("getegid");
}

/// Sets the Effective Group ID (egid)
void setEffectiveGroupId(int id) {
  checkSysCallResult(invoke("setegid", [id]));
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

/// Get a User
User getUser(String name) {
  var info = getPasswordFileEntry(name);
  var user = new User();
  user.name = info["name"];
  user.password = info["password"];
  user.uid = info["uid"];
  user.fullName = info["full name"];
  user.home = info["home"];
  user.shell = info["shell"];
  return user;
}

/// Gets the Current Username
String getCurrentUsername() =>
  readNativeString(invoke("getlogin"));

/// Gets the Current User
User getCurrentUser() => getUser(getCurrentUsername());

/// Get a list of users on the system.
/// If [showHidden] is true, then users with a _ in front of their name will be shown.
List<String> getUsernames({bool showHidden: false}) {
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
  return LibraryManager.unmarshall(invoke("getgrgid", [gid]), Group);
}

/// Represents a Group
class Group {
  /// Group Name
  @NativeName("gr_name")
  String name;

  /// Group Password
  @NativeName("gr_passwd")
  String password;

  /// Group ID
  @NativeName("gr_gid")
  int gid;

  /// Group Members
  @NativeName("gr_mem")
  List<String> members;
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

/// Gets the Session ID for the specified [pid].
/// If [pid] is not specified, it defaults to the current
int getSessionId([int pid]) {
  if (pid == null) {
    pid = getProcessId();
  }

  return invoke("getsid", [pid]);
}

/// Gets the System Hostname
String getHostname() {
  // TODO(kaendfinger): Currently we use a workaround with uname, since gethostname acts weird.
  return getKernelInfo().networkName;
  // var name = allocEmptyString();
  // checkSysCallResult(invoke("gethostname", [name, 255]));
  // return readNativeString(name);
}

/// Sets the System Hostname
void setHostname(String host) {
  checkSysCallResult(invoke("sethostname", [toNativeString(host), host.length]));
}

/// Gets the TTY Name
String getTtyName([int fd = 0]) =>
  readNativeString(invoke("ttyname", [fd]));

/// Gets the PTS name for the file descriptor [fd].
String getPtsName(int fd) =>
  readNativeString(invoke("ptsname", [fd]));

/// Fork this Process
/// Not Recommended, but it seems to work.
int fork() {
  return invoke("fork");
}

/// Fork this Process while Copying Memory
int vfork() {
  return invoke("vfork");
}

/// Wait for a child process to terminate.
WaitResult wait() {
  var status = alloc("int");
  var pid = invoke("wait", [status]);
  return new WaitResult(pid, status.value);
}

/// Wait for a process.
WaitResult waitpid(int pid, [int options = 0]) {
  var status = alloc("int");
  var rp = invoke("waitpid", [pid, status, options]);
  return new WaitResult(rp, status.value);
}

/// Results for [wait] and [waitpid]
class WaitResult {
  /// PID of Process that Exited
  final int pid;

  /// Exit Status
  final int status;

  WaitResult(this.pid, this.status);
}

/// Kill a Process
void kill(int pid, int signal) {
  checkSysCallResult(invoke("kill", [pid, signal]));
}

/// Resource Limit
class ResourceLimit {
  static final int CPU = 0;
  static final int FSIZE = 1;
  static final int DATA = 2;
  static final int STACK = 3;
  static final int CORE = 4;
  static final int NPROC = Platform.isMacOS ? 7 : 6;
  static final int NOFILE = Platform.isMacOS ? 8 : 7;
  static final int MEMLOCK = Platform.isMacOS ? 6 : 8;
  static final int AS = Platform.isMacOS ? 5 : 9;

  @NativeName("rlim_cur")
  int current;
  @NativeName("rlim_max")
  int max;

  ResourceLimit([this.current, this.max]);

  BinaryData asNative() {
    var l = alloc("struct rlimit");
    l["rlim_cur"] = current;
    l["rlim_max"] = max;
    return l;
  }
}

/// Gets the resource limit specified by [resource].
ResourceLimit getResourceLimit(int resource) {
  var l = alloc("struct rlimit");
  checkSysCallResult(invoke("getrlimit", [resource, l]));
  return LibraryManager.unmarshall(l, ResourceLimit);
}

/// Sets the resource limit specified by [resource].
void setResourceLimit(int resource, ResourceLimit limit) {
  checkSysCallResult(invoke("setrlimit", [resource, limit]));
}

/// Get the System Time in Milliseconds since the Epoch
int getSystemTime() {
  return invoke("time", [getType("time_t").nullPtr]);
}

/// Sets the System Time using Milliseconds since the Epoch
void setSystemTime(int time) {
  checkSysCallResult(invoke("stime", [time]));
}

/// Execute the Given Command
int executeSystem(String command) {
  return checkSysCallResult(invoke("system", [toNativeString(command)]));
}

int getExitCodeFromStatus(int status) {
  return (status >> 8) & 0x000000ff;
}

/// Gets the path to the controlling terminal.
String getControllingTerminal() {
  return readNativeString(invoke("ctermid", [getType("char").nullPtr]));
}

/// Manipulate Device Specific Parameters
void ioctl(int fd, int request, msg) {
  var x = alloc("int", fd);
  var y = alloc("int", request);
  if (msg is String) {
    msg = toNativeString(msg);
  } else if (msg is int) {
    msg = alloc("int", msg);
  } else if (msg is double) {
    msg = alloc("double", msg);
  } else if (msg is bool) {
    msg = alloc("bool", msg);
  }
  checkSysCallResult(invoke("ioctl", [x, y, msg]));
}

/// Get Kernel Information (uname)
KernelInfo getKernelInfo() {
  var l = alloc("struct utsname");
  checkSysCallResult(invoke("uname", [l]));
  return LibraryManager.unmarshall(l, KernelInfo);
}

int printf(String format) {
  var frmt = toNativeString(format);
  var ins = [frmt];
  return checkSysCallResult(invoke("printf", ins));
}
