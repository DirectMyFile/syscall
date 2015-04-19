/// Darwin Specific Functions
@Compatibility("Mac Only")
library syscall.darwin;

import "package:syscall/syscall.dart";

const String _HEADER = """
int sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
""";

/// Gets the value of [name] in the sysctl database.
/// [type] specifies the type of the value.
/// If [dtype] is specified, the value will be unmarshalled into this type.
dynamic getSysCtlValue(String name, [type = "char[]", Type dtype = String]) {
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
