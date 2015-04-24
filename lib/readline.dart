library syscall.readline;

import "dart:io";

import "package:binary_interop/binary_interop.dart";
import "package:syscall/syscall.dart";

const String _HEADER = """
typedef int rl_command_func_t(int l, int z);

char *readline(const char* prompt);
int rl_initialize(void);
void using_history(void);
int add_history(const char* input);
void clear_history(void);
void rl_redisplay(void);
int rl_set_prompt(const char *prompt);
int rl_on_new_line(void);
int rl_insert_text(const char *text);
int rl_kill_text(int start, int end);
int rl_read_key(void);
int rl_bind_key(int key, rl_command_func_t *function);
int rl_unbind_key(int key);
int rl_catch_signals;
""";

class LibReadline {
  static DynamicLibrary libreadline;

  static void init() {
    if (libreadline != null) {
      return;
    }

    String name;
    bool isGnu = true;

    if (Platform.isLinux || Platform.isAndroid) {
      name = "libreadline.so";
    } else if (Platform.isMacOS) {
      if (new File("/usr/local/lib/libreadline.dylib").existsSync()) {
        name = "/usr/local/lib/libreadline.dylib";
      } else {
        name = "libreadline.dylib";
        isGnu = false;
      }
    } else {
      throw new Exception("Your platform is not supported.");
    }

    libreadline = DynamicLibrary.load(name, types: LibraryManager.types);
    LibraryManager.register("readline", libreadline);
    var e = {};
    if (isGnu) {
      e["__GNU__"] = "true";
    }
    LibraryManager.loadHeader("libreadline.h", _HEADER, e);
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

  static void bindKey(key, Function handler) {
    LibReadline.init();

    var functionType = getBinaryType("rl_command_func_t");

    var callback = new BinaryCallback(functionType, (args) {
      if (handler is ReadlineCommandRegularFunction) {
        return handler(args[0], args[1]);
      } else {
        return handler();
      }
    });

    checkSysCallResult(invoke("readline::rl_bind_key", [key is String ? key.codeUnitAt(0) : key, callback.functionCode]));
  }

  static void unbindKey(key) {
    LibReadline.init();

    checkSysCallResult(invoke("readline::rl_unbind_key", [key is String ? key.codeUnitAt(0) : key]));
  }
}

typedef int ReadlineCommandRegularFunction(int x, int y);
