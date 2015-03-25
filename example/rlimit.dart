import "package:syscall/syscall.dart";

void main() {
  var proc = getResourceLimit(ResourceLimit.NPROC).rlim_cur;

  print("Maximum Number of Processes: ${proc}");
}
