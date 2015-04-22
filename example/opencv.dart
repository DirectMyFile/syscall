import "package:syscall/syscall.dart";
import "package:syscall/opencv.dart";

void main() {
  LibC.init();
  LibOpenCV.init();

  var cam = openCamera(0);
  cam.grab();
}
