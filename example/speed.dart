import "package:syscall/syscall.dart";

main() async {
  LibraryManager.init();
  for (var i = 1; i <= 500; i++) {
    printf("${i}\n");
  }
  var watch = new Stopwatch();
  watch.start();
  for (var i = 1; i <= 500; i++) {
    printf("${i}\n");
  }
  watch.stop();
  var nt = watch.elapsedMilliseconds;
  watch.reset();
  watch.start();
  for (var i = 1; i <= 500; i++) {
    print("${i}");
  }
  watch.stop();
  var rt = watch.elapsedMilliseconds;
  print("Native Time: ${nt}, Dart Time: ${rt}");
}