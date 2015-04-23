library syscall.readline;

import "dart:io";

import "package:binary_interop/binary_interop.dart";
import "package:syscall/syscall.dart";

const String _HEADER = """
char *readline(const char* prompt);
int rl_initialize(void);
void using_history(void);
int add_history(const char* input);
void clear_history(void);
""";

class LibReadline {
  static DynamicLibrary libreadline;

  static void init() {
    if (libreadline != null) return;

    String name;

    if (Platform.isLinux || Platform.isAndroid) {
      name = "libreadline.so";
    } else if (Platform.isMacOS) {
      name = "libreadline.dylib";
    } else {
      throw new Exception("Your platform is not supported.");
    }

    libreadline = DynamicLibrary.load(name, types: LibraryManager.types);
    LibraryManager.register("readline", libreadline);
    LibraryManager.loadHeader("libreadline.h", _HEADER);
    libreadline.link(["libreadline.h"]);

    checkSysCallResult(invoke("readline::rl_initialize"));
  }
}

class Readline {
  static String readLine(String prompt, {bool addToHistory: false}) {
    LibReadline.init();

    var p = toNativeString(prompt);
    var result = readNativeString(invoke("readline::readline", [p]));
    if (addToHistory) {
      addLineToHistory(result);
    }
    return result;
  }

  static void clearHistory() {
    LibReadline.init();

    invoke("readline::clear_history");
  }

  static void addLineToHistory(String input) {
    LibReadline.init();

    var r = toNativeString(input);
    checkSysCallResult(invoke("readline::add_history", [r]));
  }
}
