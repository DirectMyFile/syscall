part of syscall;

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
