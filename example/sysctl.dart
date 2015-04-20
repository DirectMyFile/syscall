import "package:syscall/syscall.dart";
import "package:syscall/darwin.dart";

main() {
  var version = getSysCtlValue("kern.version");
  print("Kernel Version: ${version}");
  var mib = [1, 8];
  var maxArgs = getSysCtlValueFromMib(mib, type: "int");
  print("Maximum Arguments: ${maxArgs}");
}
