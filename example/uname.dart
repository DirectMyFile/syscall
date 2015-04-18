import "package:syscall/syscall.dart";

void main() {
  var info = getKernelInfo();

  print("Operating System: ${info.operatingSystemName}");
  print("Kernel Version: ${info.version}");
  print("Kernel Release: ${info.release}");
  print("Network Name: ${info.networkName}");
  print("Machine: ${info.machine}");
}
