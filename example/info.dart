import "package:syscall/syscall.dart";

void main() {
  print("pid: ${getProcessId()}");
  print("ppid: ${getParentProcessId()}");
  print("uid: ${getUserId()}");
  print("gid: ${getGroupId()}");
  print("group name: ${getGroupInfo(getGroupId()).name}");
}
