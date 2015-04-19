import "package:syscall/darwin.dart";

main() {
  var version = getSysCtlValue("kern.version");
  print("Kernel Version: ${version}");
}
