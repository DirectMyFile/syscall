import "dart:io";
import "package:syscall/syscall.dart";

void main() {
  chroot(".");
  print("Current Directory: ${Directory.current.path}");
  print("Files: ${Directory.current.listSync().map((it) => it.path.split("/").last).join(", ")}");
}
