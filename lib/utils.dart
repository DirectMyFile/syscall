library syscall.utils;

import "dart:io";

Directory _headerDir = _getHeaderDirectory();

Directory _getHeaderDirectory() {
  return new Directory("/usr/include");
}

/// Get the content of a header with a given name.
/// Returns null if the header was not found.
String findHeader(String name) {
  var toTry = [
    "i386-linux-gnu/${name}",
    "x86_64-linux-gnu/${name}",
    "i386-linux-gnu/sys/${name}",
    "i386-linux-gnu/bits/${name}",
    "x86_64-linux-gnu/bits/${name}",
    "x86_64-linux-gnu/sys/${name}",
    "sys/${name}",
    "linux/${name}",
    "${name}"
  ].map((it) => joinPath([_headerDir.path, it])).toList();
  
  for (var p in toTry) {
    var file = new File(p);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  
  return null;
}

/// Join every element in [parts] by [Platform.pathSeparator]
String joinPath(List<String> parts) => parts.join(Platform.pathSeparator);
