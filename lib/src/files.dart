part of syscall;

class FileModes {
  static final int SET_UID = 04000;
  static final int SET_GID = 02000;
  static final int STICKY = 01000;
  static final int READ_BY_OWNER = 00400;
  static final int WRITE_BY_OWNER = 00200;
  static final int EXECUTE_BY_OWNER = 00100;
  static final int READ_BY_GROUP = 00040;
  static final int WRITE_BY_GROUP = 00020;
  static final int EXECUTE_BY_GROUP = 00010;
  static final int READ_BY_OTHERS = 00004;
  static final int WRITE_BY_OTHERS = 00002;
  static final int EXECUTE_BY_OTHERS = 00001;

  static final int FULL_OWNER = READ_BY_OWNER | WRITE_BY_OWNER | EXECUTE_BY_OWNER;
  static final int FULL_GROUP = READ_BY_GROUP | WRITE_BY_GROUP | EXECUTE_BY_GROUP;
  static final int FULL_OTHERS = READ_BY_OTHERS | WRITE_BY_OTHERS | EXECUTE_BY_OTHERS;
  static final int ANYONE = FULL_OWNER | FULL_GROUP | FULL_OTHERS;
  static final int ANYONE_READ = READ_BY_OWNER | READ_BY_GROUP | READ_BY_OTHERS;
  static final int ANYONE_WRITE = WRITE_BY_OWNER | WRITE_BY_GROUP | WRITE_BY_OTHERS;
  static final int ANYONE_EXECUTE = EXECUTE_BY_OWNER | EXECUTE_BY_GROUP | EXECUTE_BY_OTHERS;
}

/// Change the mode of the file specified by [path] to [mode].
/// See [this page](http://man7.org/linux/man-pages/man2/chmod.2.html) to get an idea of how to create the [mode].
void chmod(String path, int mode) {
  var p = toNativeString(path);
  var m = alloc("mode_t", mode);
  _checkResult(invoke("chmod", [p, m]));
}


/// Change the current working directory.
void chdir(String path) {
  _checkResult(invoke("chdir", [toNativeString(path)]));
}

/// Change the root directory of this process.
/// This will change the working directory as well.
void chroot(String path) {
  chdir(path);
  _checkResult(invoke("chroot", [toNativeString(path)]));
}

/// Commits the buffer cache to disk.
void sync() {
  invoke("sync");
}

