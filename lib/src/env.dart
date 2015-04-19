part of syscall;

/// Get the Current Environment
/// Returns a list of KEY=VALUE pairs
List<String> getEnvironment() {
  var data = getVariable("environ", "char**");
  var x = [];
  var l;
  var i = 0;

  while (!(l = data.getElementValue(i)).isNullPtr) {
    x.add(readNativeString(l));
    i++;
  }

  return x;
}

/// Gets the Current Environment as a Map
/// Calls [getEnvironment] and then converts it into a map
Map<String, String> getEnvironmentMap() {
  var map = <String, String>{};
  for (var pair in getEnvironment()) {
    var key = pair.substring(0, pair.indexOf("="));
    var value = pair.length > key.length + 1 ? pair.substring(key.length + 1) : "";
    map[key] = value;
  }
  return map;
}

/// Gets the value of [name] from the environment.
/// This is more efficient than using either [getEnvironment] or [getEnvironmentMap] when you only want one variable.
String getEnvironmentVariable(String name, [String defaultValue]) {
  var value = invoke("getenv", [toNativeString(name)]);
  if (value.isNullPtr) {
    return defaultValue;
  } else {
    return readNativeString(value);
  }
}

/// Sets the value of [name] in the environment to the specified [value].
/// If [overwrite] is true, when the variable already exists, it will be overwritten, otherwise it will not be changed.
void setEnvironmentVariable(String name, String value, {bool overwrite: true}) {
  checkSysCallResult(invoke("setenv", [toNativeString(name), toNativeString(value), overwrite ? 1 : 0]));
}

/// Remove the variable specified by [name] from the environment.
void removeEnvironmentVariable(String name) {
  checkSysCallResult(invoke("unsetenv", [toNativeString(name)]));
}
