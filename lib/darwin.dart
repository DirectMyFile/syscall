/// Darwin Specific Functions
@Compatibility("Mac Only")
library syscall.darwin;

import "package:syscall/syscall.dart";

const String _HEADER = """
typedef unsigned int u_int;

int sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
int sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
""";

bool _initialized = false;

void _init() {
  if (!_initialized) {
    if (!LibC.loaded) {
      LibC.load();
    }
    LibC.typeHelper.addHeader("libc_darwin.h", _HEADER);
    LibC.typeHelper.declare("libc_darwin.h");
    LibC.libc.link(["libc_darwin.h"]);
    _initialized = true;
  }
}

/// Gets the value of [name] in the sysctl database.
/// [type] specifies the type of the value.
/// If [dtype] is specified, the value will be unmarshalled into this type.
dynamic getSysCtlValue(String name, [type = "char[]", Type dtype = String]) {
  _init();
  var len = alloc("size_t");
  var n = toNativeString(name);

  checkSysCallResult(invoke("sysctlbyname", [n, getType("void*").nullPtr, len, getType("void*").nullPtr, 0]));

  if (type.toString().endsWith("[]")) {
    type = getType(type.toString().substring(0, type.length - 2) + "[${len.value}]");
  } else {
    type = getBinaryType(type);
  }

  var value = alloc(type);

  checkSysCallResult(invoke("sysctlbyname", [n, value, len, getType("void*").nullPtr, 0]));

  if (dtype != null) {
    if (dtype == String) {
      return readNativeString(value);
    }

    return LibC.unmarshall(value, dtype);
  } else {
    return value;
  }
}

/// Gets the value of [mib] in the sysctl database.
/// [type] specifies the type of the value.
/// If [dtype] is specified, the value will be unmarshalled into this type.
dynamic getSysCtlValueFromMib(List<int> mib, {type: "char[]", Type dtype, bool raw: true}) {
  if (type == "char[]") {
    dtype = String;
  }

  _init();

  var len = alloc("size_t");
  var m = alloc("int[${mib.length}]");
  m.value = mib;

  checkSysCallResult(invoke("sysctl", [m, mib.length, getType("void*").nullPtr, len, getType("void*").nullPtr, 0]));

  if (type.toString().endsWith("[]")) {
    type = getType(type.toString().substring(0, type.length - 2) + "[${len.value}]");
  } else {
    type = getBinaryType(type);
  }

  var value = alloc(type);

  checkSysCallResult(invoke("sysctl", [m, mib.length, value, len, getType("void*").nullPtr, 0]));

  if (dtype != null) {
    if (dtype == String) {
      return readNativeString(value);
    }

    return LibC.unmarshall(value, dtype);
  } else {
    if (type.toString() == "int") {
      return value.value;
    }

    return value;
  }
}

String getArgumentsForProcessId(int id) {
}
