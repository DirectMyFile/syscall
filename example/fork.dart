import "package:syscall/syscall.dart";

void main() {
  fork();

  print("My PID is ${getProcessId()}");
}
