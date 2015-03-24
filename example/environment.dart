import "package:syscall/syscall.dart";

main() {
  var pairs = getEnvironment();
  var map = getEnvironmentMap();

  print("Pairs: ${pairs}");
  print("Map: ${map}");
}
