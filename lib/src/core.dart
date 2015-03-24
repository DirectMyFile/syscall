part of syscall;

const String HEADER = """
typedef unsigned int mode_t;
typedef unsigned int pid_t;
typedef unsigned int uid_t;
typedef unsigned int gid_t;
typedef unsigned int time_t;

int errno;

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

time_t time(time_t *t);

double sqrt(double x);

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

char **environ;
char *ttyname(int fd);

int getgrouplist(const char *user, gid_t group, gid_t *groups, int *ngroups);
struct passwd *getpwnam(const char *name);

int chmod(const char *path, mode_t mode);

#ifdef __LINUX__
int sysinfo(struct sysinfo *info);

struct sysinfo {
  long uptime;
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

class LibC {
  static BinaryTypeHelper typeHelper = (() {
    return new BinaryTypeHelper(types);
  })();

  static BinaryTypes types = (() {
    return new BinaryTypes();
  })();

  static DynamicLibrary libc = (() {
    String name;

    if (Platform.isAndroid || Platform.isLinux) {
      name = "libc.so.6";
    } else if (Platform.isMacOS) {
      name = "libSystem.dylib";
    } else {
      throw new Exception("Your platform is not supported.");
    }

    var lib = DynamicLibrary.load(name, types: types);
    var env = {};

    if (Platform.isMacOS) {
      env["__MAC__"] = "true";
    }

    if (Platform.isAndroid || Platform.isLinux) {
      env["__LINUX__"] = "true";
    }

    lib.declare(HEADER, environment: env);
    return lib;
  })();

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
}

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

BinaryData alloc(type, [value]) {
  BinaryType bt = _getBinaryType(type);
  return bt.alloc(value);
}

BinaryType getArrayType(type, int size) {
  BinaryType bt = _getBinaryType(type);
  return bt.array(size);
}

BinaryData allocArray(type, int size, [value]) {
  var bt = getArrayType(type, size);
  return bt.alloc(value);
}

BinaryType getType(String name) {
  return LibC.types[name];
}

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
  String toString() => "Failed to make system call. errno = ${code}";
}

int getErrorNumber() {
  return getVariable("errno", "int").value;
}

void _checkResult(int result) {
  if (result == -1) {
    throw new SystemCallException(getErrorNumber());
  }
}

BinaryData getVariable(String name, type) {
  return LibC.getVariable(name, type);
}

String readNativeString(input) {
  if (input is String) {
    return input;
  }

  if (input is! BinaryData) {
    throw new ArgumentError.value(input, "input", "should be an instance of BinaryData");
  }

  return LibC.typeHelper.readString(input);
}

dynamic invoke(String name, [List<dynamic> args = const [], List<BinaryType> vartypes]) {
  return LibC.invoke(name, args, vartypes);
}
