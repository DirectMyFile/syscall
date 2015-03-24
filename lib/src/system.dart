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
    value = LibC.unmarshall(value, dtype);
  }

  return value;
}

@Compatibility("Linux Only")
LinuxSysInfo getSysInfo() {
  var instance = alloc("sysinfo");
  invoke("getsysinfo", [instance]);
  return instance;
}

@Compatibility("Mac Only")
class MacTimeVal {
  int tv_sec;
}

@Compatibility("Linux Only")
class LinuxSysInfo {
  int uptime;
  List<int> loads;
  int totalram;
  int freeram;
  int sharedram;
  int bufferram;
  int totalswap;
  int freeswap;
  int procs;
  int totalhigh;
  int freehigh;
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

/// Gets the Current User ID (uid)
int getUserId() {
  return invoke("getuid");
}

/// Sets the Current User ID (uid)
void setUserId(int id) {
  _checkResult(invoke("setuid", [id]));
}

/// Gets the Current Group ID (gid)
int getGroupId() {
  return invoke("getgid");
}

/// Sets the Current Group ID (gid)
void setGroupId(int id) {
  _checkResult(invoke("setgid", [id]));
}
