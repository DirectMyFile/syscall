part of syscall;

/// Initial Header
const String HEADER = """
typedef unsigned int size_t;
typedef unsigned int mode_t;
typedef unsigned int pid_t;
typedef unsigned int uid_t;
typedef unsigned int gid_t;
typedef unsigned int suseconds_t;
typedef unsigned int time_t;
typedef unsigned int rlim_t;
typedef unsigned int ssize_t;
typedef unsigned int dev_t;
typedef unsigned int ino_t;
typedef unsigned int nlink_t;
typedef unsigned int off_t;
typedef unsigned int blksize_t;
typedef unsigned int blkcnt_t;

int errno;
char *strerror(int errnum);

int ioctl(int fd, unsigned long request, ...);

pid_t getpid(void);
pid_t getppid(void);
pid_t getpgrp(void);
int setpgid(pid_t pid, pid_t pgid);

pid_t getsid(pid_t pid);
pid_t setsid(void);

void sync(void);

void syslog(int priority, const char *message, ...);
void closelog(void);
void openlog(const char *ident, int logopt, int facility);
int setlogmask(int maskpri);

uid_t getuid(void);
uid_t geteuid(void);
int seteuid(uid_t uid);
int setuid(uid_t uid);
gid_t getgid(void);
int setgid(gid_t gid);
gid_t getegid(void);
int setegid(gid_t gid);

pid_t fork(void);
pid_t vfork(void);
pid_t wait(int *status);
pid_t waitpid(pid_t pid, int *status, int options);
int kill(pid_t pid, int sig);

int isatty(int fildes);
int ttyslot(void);

typedef void (*sighandler_t)(int);
sighandler_t signal(int signum, sighandler_t handler);

time_t time(time_t *t);

char *getlogin(void);
struct group *getgrnam(const char *name);
struct group *getgrgid(gid_t gid);
int getgrnam_r(const char *name, struct group *grp, char *buf, size_t buflen, struct group **result);
int getgrgid_r(gid_t gid, struct group *grp, char *buf, size_t buflen, struct group **result);
struct group {
  char   *gr_name;
  char   *gr_passwd;
  gid_t   gr_gid;
  char  **gr_mem;
};

int getloadavg(double loadavg[], int nelem);

char *getenv(const char *name);
int setenv(const char *name, const char *value, int overwrite);
int unsetenv(const char *name);

char **environ;
char *ttyname(int fd);

int getgrouplist(const char *user, gid_t group, gid_t *groups, int *ngroups);
struct passwd *getpwnam(const char *name);

int chmod(const char *path, mode_t mode);
int fchmod(int fd, mode_t mode);
int chown(const char *pathname, uid_t owner, gid_t group);
int fchown(int fd, uid_t owner, gid_t group);
int lchown(const char *pathname, uid_t owner, gid_t group);
char *getcwd(char *buf, size_t size);
char *getwd(char *buf);
int chdir(const char *path);
int fchdir(int fd);
int chroot(const char *path);

int gethostname(char *name, size_t len);
int sethostname(const char *name, size_t len);
int system(const char *command);

size_t strlen(const char *str);
char *strcpy(char *destination, const char *source);

struct stat {
  dev_t     st_dev;
  ino_t     st_ino;
  mode_t    st_mode;
  nlink_t   st_nlink;
  uid_t     st_uid;
  gid_t     st_gid;
  dev_t     st_rdev;
  off_t     st_size;
  blksize_t st_blksize;
  blkcnt_t  st_blocks;
};

int fsync(int fd);

#if !defined(__ARM__) && !defined(__DEBIAN__)
int stat(const char *pathname, struct stat *buf);
int fstat(int fd, struct stat *buf);
int lstat(const char *pathname, struct stat *buf);
#endif

struct rlimit {
  rlim_t rlim_cur;
  rlim_t rlim_max;
};

int getrlimit(int resource, struct rlimit *rlim);
int setrlimit(int resource, const struct rlimit *rlim);

struct timeval {
  time_t tv_sec;
  suseconds_t tv_usec;
};

int open(const char *pathname, int flags);
int creat(const char *pathname, mode_t mode);
int close(int fd);
int pipe(int pipefd[2]);
char *ptsname(int fd);

int chdir(const char *path);
int fchdir(int fd);

ssize_t write(int fd, const void *buf, size_t count);
ssize_t read(int fd, void *buf, size_t count);

int uname(void *buf);
char *ctermid(char *s);

struct utsname {
  char sysname[256];
  char nodename[256];
  char release[256];
  char version[256];
  char machine[256];
};

#ifdef __LINUX__
int sysinfo(struct sysinfo *info);

struct sysinfo {
  long uptime;
  unsigned long loads[3];
  unsigned long totalram;
  unsigned long freeram;
  unsigned long sharedram;
  unsigned long bufferram;
  unsigned long totalswap;
  unsigned long freeswap;
  unsigned short procs;
  unsigned long totalhigh;
  unsigned long freehigh;
  unsigned int mem_unit;
  char _f[20-2*sizeof(long)-sizeof(int)];
};

struct passwd {
  char   *pw_name;
  char   *pw_passwd;
  uid_t   pw_uid;
  gid_t   pw_gid;
  char   *pw_gecos;
  char   *pw_dir;
  char   *pw_shell;
};
#endif

#ifdef __MAC__
struct passwd {
  char *pw_name;
  char *pw_passwd;
  uid_t pw_uid;
  gid_t pw_gid;
  time_t pw_change;
  char *pw_class;
  char *pw_gecos;
  char *pw_dir;
  char *pw_shell;
  time_t pw_expire;
  int pw_fields;
};
#endif
""";

void _ensure() {
  if (LibC._libc == null) {
    LibC.load();
  }
}

/// C Library
class LibC {
  static BinaryTypeHelper typeHelper;

  static BinaryTypes get types => libc.types;

  static DynamicLibrary _libc;
  static DynamicLibrary get libc {
    if (_libc == null) {
      load();
    }
    return _libc;
  }

  static bool loaded = false;

  static void load() {
    loaded = true;
    String name;

    if (Platform.isAndroid || Platform.isLinux) {
      name = "libc.so.6";
    } else if (Platform.isMacOS) {
      name = "libSystem.dylib";
    } else {
      throw new Exception("Your platform is not supported.");
    }

    _libc = DynamicLibrary.load(name, types: new BinaryTypes());
    typeHelper = new BinaryTypeHelper(_libc.types);
    var env = {};

    if (Platform.isMacOS) {
      env["__MAC__"] = "true";
    }

    if (Platform.isAndroid || Platform.isLinux) {
      env["__LINUX__"] = "true";
    }

    if (SysInfo.kernelArchitecture.startsWith("arm")) {
      env["__ARM__"] = "true";
    }

    var os = SysInfo.operatingSystemName.toLowerCase();

    if (os.contains("ubuntu") || os.contains("debian")) {
      env["__DEBIAN__"] = "true";
    }
    
    _env = env;

    typeHelper.addHeader("libc.h", HEADER);
    typeHelper.declare("libc.h", environment: env);
    libc.link(["libc.h"]);
  }
  
  static void loadHeader(String name, String content) {
    typeHelper.addHeader(name, content);
    typeHelper.declare(name, environment: _env);
  } 
  
  static Map<String, dynamic> _env;

  static BinaryUnmarshaller unmarshaller = (() {
    return new BinaryUnmarshaller();
  })();
  
  static Map<String, DynamicLibrary> _libs = {};
  
  static void register(String name, DynamicLibrary lib) {
    _libs[name] = lib;
  }

  static dynamic invoke(String name, [List<dynamic> args = const [], List<BinaryType> vartypes]) {
    _ensure();
    var lib = libc;
    if (name.contains("::")) {
      var libname = name.substring(0, name.indexOf("::"));
      name = name.substring(libname.length + 2);
      if (_libs.containsKey(libname)) {
        lib = _libs[libname];
      } else {
        throw new SystemCallException("Library not found: ${libname}");
      }
    }
    return lib.invokeEx(name, args, vartypes);
  }

  static dynamic unmarshall(BinaryData data, Type type) {
    _ensure();
    return unmarshaller.unmarshall(data, type);
  }

  static dynamic getVariable(String name, type) {
    _ensure();
    type = getBinaryType(type);
    return type.extern(libc.symbol(name));
  }
}

/// Documents Compatibility of APIs
class Compatibility {
  final String message;

  const Compatibility(this.message);
}

BinaryType getBinaryType(type) {
  if (type is String) {
    type = LibC.types[type];
  }

  if (type is! BinaryType) {
    throw new ArgumentError.value(type, "type", "should be either a String or a BinaryType");
  }

  return type;
}

/// Allocate an object specified by [type] using the initial value specified by [value].
BinaryData alloc(type, [value]) {
  _ensure();
  BinaryType bt = getBinaryType(type);
  return bt.alloc(value);
}

/// Gets a binary array type for the type
/// specified by [type] with a size specified by [size].
BinaryType getArrayType(type, int size) {
  _ensure();
  BinaryType bt = getBinaryType(type);
  return bt.array(size);
}

/// Allocate an array of objects specified by [type]
/// with the size specified by [size]
/// using the initial value specified by [value].
BinaryData allocArray(type, int size, [value]) {
  _ensure();
  var bt = getArrayType(type, size);
  return bt.alloc(value);
}

/// Gets the binary type for [name].
BinaryType getType(String name) {
  _ensure();
  return LibC.types[name];
}

/// Turns the object specified by [input] into a native string.
BinaryData toNativeString(input) {
  _ensure();
  String str;

  if (input == null) {
    return toNativeString("").type.nullPtr;
  } else {
    str = input.toString();
  }

  return LibC.typeHelper.allocString(str);
}

class SystemCallException {
  final int code;

  SystemCallException(this.code);

  @override
  String toString() => "System Call Failed! ${getErrorInfo(code)}";
}

/// Gets the error number
int getErrorNumber() {
  _ensure();
  return getVariable("errno", "int").value;
}

String getErrorInfo([int errno]) {
  if (errno == null) {
    errno = getErrorNumber();
  }

  return readNativeString(invoke("strerror", [errno]));
}

int checkSysCallResult(int result) {
  if (result == -1) {
    throw new SystemCallException(getErrorNumber());
  }
  return result;
}

/// Gets the variable specified by [name] with the type specified by [type].
BinaryData getVariable(String name, type) {
  return LibC.getVariable(name, type);
}

/// Read a string from [input].
String readNativeString(input) {
  _ensure();
  if (input is String) {
    return input;
  }

  if (input is! BinaryData) {
    throw new ArgumentError.value(input, "input", "should be an instance of BinaryData");
  }

  if (input.isNullPtr) {
    return null;
  }

  return LibC.typeHelper.readString(input);
}

/// Invoke the system calls specified by [name] with the arguments specified by [args].
dynamic invoke(String name, [List<dynamic> args = const [], List<BinaryType> vartypes]) {
  _ensure();
  return LibC.invoke(name, args, vartypes);
}

/// Allocate an empty string.
BinaryData allocEmptyString() => toNativeString("");