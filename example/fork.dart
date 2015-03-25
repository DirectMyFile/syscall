import "package:syscall/syscall.dart";

void main() {
  print("Current PID: ${getProcessId()}");

  var pid = fork();

  print("PID: ${getProcessId()}");

  if (pid == 0) {
    wait();
  }
}
