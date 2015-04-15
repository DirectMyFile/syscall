import "package:syscall/syscall.dart";

void main() {
  var info = getKernelInfo();
  
  print("Operating System: ${info.operatingSystemName}");
}
