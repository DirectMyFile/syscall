import "package:syscall/snappy.dart";

void main() {
  LibSnappy.init();
  var result = Snappy.compress("1234567890" * 10);
  print(result);
}