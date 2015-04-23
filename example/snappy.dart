import "package:syscall/snappy.dart";

void main() {
  var result = Snappy.compress("1234567890" * 10);
  print("Compressed: ${result}");
  var original = Snappy.decompress(result);
  print("Decompressed: ${original}");
}
