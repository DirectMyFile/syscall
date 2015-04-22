/// Darwin Specific Functions
@Compatibility("Mac Only")
library syscall.darwin;

import "package:syscall/syscall.dart";
import "package:binary_interop/binary_interop.dart";

const String _HEADER = """
typedef unsigned int u_int;

int sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
int sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
""";

bool _initialized = false;

void _init() {
  if (!_initialized) {
    if (!LibraryManager.loaded) {
      LibraryManager.init();
    }
    LibraryManager.typeHelper.addHeader("libc_darwin.h", _HEADER);
    LibraryManager.typeHelper.declare("libc_darwin.h");
    LibraryManager.libc.link(["libc_darwin.h"]);
    _initialized = true;
  }
}

/// Sets the value of [name] in the sysctl database.
/// [type] specifies the type of the value.
/// If [dtype] is specified, the value will be unmarshalled into this type.
///
/// Returns the old value.
dynamic setSysCtlValue(String name, value, {type: "char[]", Type dtype}) {
  BinaryData val;
  if (value is BinaryData) {
    val = value;
  } else if (value is String) {
    val = toNativeString(value);
  } else if (value is int) {
    val = alloc("int", value);
  } else if (value is double) {
    val = alloc("double", value);
  }
  var old = getSysCtlValue(name, type: type, dtype: dtype);
  checkSysCallResult(invoke("sysctlbyname", [toNativeString(name), getType("void*").nullPtr, alloc("size_t", 0), val, val.type.size]));
  return old;
}

/// Gets the value of [name] in the sysctl database.
/// [type] specifies the type of the value.
/// If [dtype] is specified, the value will be unmarshalled into this type.
dynamic getSysCtlValue(String name, {type: "char[]", Type dtype, bool raw: true}) {
  if (type == "char[]" && dtype == null) {
    dtype = String;
  }

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

    return LibraryManager.unmarshall(value, dtype);
  } else {
    if (type.toString() == "int") {
      return value.value;
    }

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

    return LibraryManager.unmarshall(value, dtype);
  } else {
    if (type.toString() == "int") {
      return value.value;
    }

    return value;
  }
}
