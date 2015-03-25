part of syscall;

int toOctal(x) {
  return int.parse("${x}", radix: 8);
}

class FileModes {
  static final int SET_UID = toOctal(4000);
  static final int SET_GID = Platform.isMacOS ? 0002000 : 02000;
  static final int READ_BY_OWNER = Platform.isMacOS ? 0000400 : 00400;
  static final int WRITE_BY_OWNER = Platform.isMacOS ? 0000200 : 00200;
  static final int EXECUTE_BY_OWNER = Platform.isMacOS ? 0000100 : 00100;
  static final int READ_BY_GROUP = Platform.isMacOS ? 0000040 : 00040;
  static final int WRITE_BY_GROUP = Platform.isMacOS ? 0000020 : 00020;
  static final int EXECUTE_BY_GROUP = Platform.isMacOS ? 0000010 : 00010;
  static final int READ_BY_OTHERS = Platform.isMacOS ? 0000004 : 00004;
  static final int WRITE_BY_OTHERS = Platform.isMacOS ? 0000002 : 00002;
  static final int EXECUTE_BY_OTHERS = Platform.isMacOS ? 0000001 : 00001;

  static final int FULL_OWNER = toOctal(Platform.isMacOS ? "0000700" : "00700");
  static final int FULL_GROUP = Platform.isMacOS ? 0000070 : 00070;
  static final int FULL_OTHERS = Platform.isMacOS ? 0000007 : 00007;
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

/// Change Ownership of a file
void chown(String path, int uid, int gid) {
  _checkResult(invoke("chown", [toNativeString(path), uid, gid]));
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

Stat stat(String path) {
  var d = alloc("struct stat");
  _checkResult(invoke("stat", [toNativeString(path), d]));
  return LibC.unmarshall(d, Stat);
}

class Stat {
  @NativeName("st_dev")
  int deviceId;
  @NativeName("st_ino")
  int inode;
  @NativeName("st_mode")
  int mode;
  @NativeName("st_nlink")
  int hardLinkCount;
  @NativeName("st_uid")
  int uid;
  @NativeName("st_gid")
  int gid;
  @NativeName("st_rdev")
  int specialDeviceFile;
  @NativeName("st_size")
  int size;
  @NativeName("st_blksize")
  int blockSize;
  @NativeName("st_blocks")
  int blocks;
}

/// Open the file at [path] with the specified [flags].
/// Returns a file descriptor.
int open(String path, int flags, [int mode]) {
  var p = toNativeString(path);
  return _checkResult(
    invoke("open", mode != null ? [p, flags, mode] : [p, flags], mode != null ? [getType("mode_t")] : [])
  );
}

/// Close the specified file descriptor.
void close(int fd) {
  _checkResult(invoke("close", [fd]));
}

/// Writes the data by [data] to the file descriptor specified by [fd].
/// [data] can be a List<int> or a String.
/// If [count] is specified, then only that amount of data will be written.
int write(int fd, data, [int count]) {
  BinaryData d;
  int fc;

  if (data is String) {
    d = toNativeString(data);
    fc = d.type.size;
  } else if (data is List<int>) {
    d = allocArray("int", data.length, data);
    fc = data.length;
  } else {
    throw new ArgumentError.value(data, "data", "should be a String or a List<int>");
  }

  if (count == null) {
    count = fc;
  }

  return _checkResult(invoke("write", [fd, d, count]));
}

/// Gets the length of the string specified by [input].
int strlen(String input) {
  return invoke("strlen", [toNativeString(input)]);
}

class OpenFlags {
  static final int APPEND = Platform.isMacOS ? 0x0008 : toOctal("00002000");
  static final int READ = 0x0000;
  static final int WRITE = 0x0001;
  static final int READ_WRITE = 0x0002;
  static final int NONBLOCK = Platform.isMacOS ? 0x0004 : 00004000;
  static final int CREATE = Platform.isMacOS ? 0x0200 : toOctal("00000100");
  static final int TRUNCATE = Platform.isMacOS ? 0x0400 : 00001000;
  static final int NOFOLLOW = Platform.isMacOS ? 0x0100 : 00400000;
  static final int CLOSE_ON_EXEC = Platform.isMacOS ? 0x1000000 : 02000000;
  static final int NO_CTTY = Platform.isMacOS ? 0x20000 : 00000400;
  static final int DIRECTORY = Platform.isMacOS ? 0x100000 : 00200000;
  static final int ERROR_IF_EXISTS = Platform.isMacOS ? 0x0800 : 00000200;
  static final int SYNC = Platform.isMacOS ? 0x400000 : 00010000;
  static final int ASYNC = Platform.isMacOS ? 0x0040 : 020000;
}
