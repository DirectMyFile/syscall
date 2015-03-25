import "dart:io";
import "package:syscall/syscall.dart";

void main() {
  var file = new File("test.sh");
  file.writeAsStringSync('#!/usr/bin/env bash\necho "Hello World"');
  chmod(file.path, FileModes.ANYONE);
}
