import "package:syscall/syscall.dart";

main() {
  var version = getSysCtlValue("kern.version");
  print("Kernel Version: ${version}");
}
