import "package:syscall/darwin.dart";

main() {
  var version = getSysCtlValue("kern.version");
  print("Kernel Version: ${version}");

  var mib = [1, 8];
  var maxArgs = getSysCtlValueFromMib(mib, type: "int");
  print("Maximum Arguments: ${maxArgs}");

  var result = setSysCtlValue("kern.maxproc", 2048, type: "int");
  print("Old Maximum Processes: ${result}");
}
