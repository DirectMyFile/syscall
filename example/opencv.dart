import "package:syscall/syscall.dart";
import "package:syscall/opencv.dart";

void main() {
  LibOpenCV.init();
  
  var cam = openCamera(0);
  print(cam.blackBox);
}