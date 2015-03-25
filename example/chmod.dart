import "package:syscall/syscall.dart";

void main() {
  var path = "test.sh";
  var fd = open(path, OpenFlags.CREATE | OpenFlags.READ_WRITE);
  var b = write(fd, '#!/usr/bin/env bash\necho "Hello World"');
  close(fd);
  print("Wrote ${b} bytes.");
  chmod(path, stat(path).mode & toOctal("0777"));
}
