part of syscall;

class AddressFamily {
  static const int UNIX = 1;
  static const int LOCAL = 1;
  static const int INET = 2;
  static const int INET6 = 30;
}

class SocketType {
  static const int STREAM = 1;
  static const int DGRAM = 2;
  static const int RAW = 3;
  static const int RDM = 4;
  static const int SEQPACKET = 5;
}

class SocketAddress {
  @NativeName("sa_len")
  int length;

  @NativeName("sa_family")
  int family;

  @NativeName("sa_data")
  List<int> data;
}

int createSocket(int af, int type, int protocol) {
  return checkSysCallResult(invoke("socket", [af, type, protocol]));
}

int connectSocket(int fd, SocketAddress addr, int len) {
  var l = alloc("struct sockaddr");
  var data = new List<int>(14);
  data.setAll(0, addr.data);
  data.fillRange(addr.data.length, 14, 0);
  l.value = {
    "sa_len": addr.length,
    "sa_family": addr.family,
    "sa_data": data
  };
  return checkSysCallResult(invoke("connect", [fd, l, len]));
}