import "package:syscall/syscall.dart";

void main() {
  var host = getHostname();
  print(host);
}
