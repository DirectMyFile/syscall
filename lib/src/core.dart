part of syscall;

/// Initial Header
const String HEADER = """
typedef unsigned int mode_t;
typedef unsigned int pid_t;
typedef unsigned int uid_t;
typedef unsigned int gid_t;
typedef unsigned int time_t;

int errno;
char *strerror(int errnum);

pid_t getpid(void);
pid_t getppid(void);
pid_t getpgrp(void);
int setpgid(pid_t pid, pid_t pgid);

pid_t getsid(pid_t pid);
pid_t setsid(void);

void sync(void);

uid_t getuid(void);
uid_t geteuid(void);
int seteuid(uid_t uid);
int setuid(uid_t uid);
gid_t getgid(void);
int setgid(gid_t gid);
gid_t getegid(void);
int setegid(gid_t gid);

pid_t fork(void);
pid_t wait(int *status);
pid_t waitpid(pid_t pid, int *status, int options);
int kill(pid_t pid, int sig);

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

int chown(const char *pathname, uid_t owner, gid_t group);
int chmod(const char *path, mode_t *mode);

int gethostname(char *name, size_t *len);
int sethostname(const char *name, size_t *len);

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
typedef unsigned int suseconds_t;

int sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen);

struct timeval {
  time_t tv_sec;
  suseconds_t tv_usec;
};

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

/// C Library
class LibC {
  static BinaryTypeHelper typeHelper = (() {
    return new BinaryTypeHelper(types);
  })();

  static BinaryTypes types = (() {
    if (_libc == null) {
      load();
    }

    return libc.types;
  })();

  static DynamicLibrary _libc;
  static DynamicLibrary get libc {
    if (_libc == null) {
      load();
    }
    return _libc;
  }

  static void load() {
    String name;

    if (Platform.isAndroid || Platform.isLinux) {
      name = "libc.so.6";
    } else if (Platform.isMacOS) {
      name = "libSystem.dylib";
    } else {
      throw new Exception("Your platform is not supported.");
    }

    _libc = DynamicLibrary.load(name, types: new BinaryTypes());
    var env = {};

    if (Platform.isMacOS) {
      env["__MAC__"] = "true";
    }

    if (Platform.isAndroid || Platform.isLinux) {
      env["__LINUX__"] = "true";
    }

    libc.declare(HEADER, environment: env);
  }

  static BinaryUnmarshaller unmarshaller = (() {
    return new BinaryUnmarshaller();
  })();

  static dynamic invoke(String name, [List<dynamic> args = const [], List<BinaryType> vartypes]) {
    return libc.invokeEx(name, args, vartypes);
  }

  static dynamic unmarshall(BinaryData data, Type type) {
    return unmarshaller.unmarshall(data, type);
  }

  static dynamic getVariable(String name, type) {
    type = _getBinaryType(type);
    return type.extern(libc.symbol(name));
  }

  static void addStruct(String name, Map<String, String> members) {
    var x = "struct ${name} {\n";
    for (var k in members.keys) {
      x += "${members[k]} ${k};\n";
    }
    x += "};";
    libc.declare(x);
  }
}

/// Documents Compatibility of APIs
class Compatibility {
  final String message;

  const Compatibility(this.message);
}

BinaryType _getBinaryType(type) {
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
  BinaryType bt = _getBinaryType(type);
  return bt.alloc(value);
}

/// Gets a binary array type for the type
/// specified by [type] with a size specified by [size].
BinaryType getArrayType(type, int size) {
  BinaryType bt = _getBinaryType(type);
  return bt.array(size);
}

/// Allocate an array of objects specified by [type]
/// with the size specified by [size]
/// using the initial value specified by [value].
BinaryData allocArray(type, int size, [value]) {
  var bt = getArrayType(type, size);
  return bt.alloc(value);
}

/// Gets the binary type for [name].
BinaryType getType(String name) {
  return LibC.types[name];
}

/// Turns the object specified by [input] into a native string.
BinaryData toNativeString(input) {
  String str;

  if (input == null) {
    str = "null";
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
  return getVariable("errno", "int").value;
}

String getErrorInfo([int errno]) {
  if (errno == null) {
    errno = getErrorNumber();
  }

  return readNativeString(invoke("strerror", [errno]));
}

void _checkResult(int result) {
  if (result == -1) {
    throw new SystemCallException(getErrorNumber());
  }
}

/// Gets the variable specified by [name] with the type specified by [type].
BinaryData getVariable(String name, type) {
  return LibC.getVariable(name, type);
}

/// Read a string from [input].
String readNativeString(input) {
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
  return LibC.invoke(name, args, vartypes);
}
