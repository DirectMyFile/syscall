import "package:syscall/syscall.dart";
import "package:syscall/opencv.dart";

void main() {
  LibraryManager.init();
  LibOpenCV.init();

  var cam = openCamera(0);
  cam.grab();
}
