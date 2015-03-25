import "package:syscall/syscall.dart";

void main() {
  var pid = fork();

  print("My PID is ${getProcessId()}");

  if (pid == 0) {
    wait();
  }
}
