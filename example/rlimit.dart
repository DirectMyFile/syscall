import "package:syscall/syscall.dart";

void main() {
  var proc = getResourceLimit(ResourceLimit.NPROC).current;

  print("Maximum Number of Processes: ${proc}");
}
