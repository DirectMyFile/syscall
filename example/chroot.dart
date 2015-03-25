import "dart:io";

import "package:syscall/syscall.dart";

void main(List<String> args) {
  if (args.length == 0) {
    print("usage: chroot <path> [command]");
    exit(1);
  }

  chroot(args[0]);

  var cmd = args.skip(1).join(" ");

  if (cmd.isEmpty) {
    cmd = "bash";
  }

  system(cmd);
}
