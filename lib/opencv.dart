library syscall.opencv;

import "dart:io";

import "package:syscall/syscall.dart";
import "package:binary_interop/binary_interop.dart";

const String _HEADER_CORE = """
""";

const String _HEADER_HIGH = """
typedef struct CvCapture CvCapture;
CvCapture* cvCreateCameraCapture(int device);
void cvReleaseCapture(CvCapture** capture);
int cvGrabFrame(CvCapture* capture);
void cvReleaseCapture(CvCapture** capture);
""";

class LibOpenCV {
  static DynamicLibrary libcore;
  static DynamicLibrary libhigh;

  static void init() {
    libcore = DynamicLibrary.load(getLibName("core"), types: LibraryManager.types);
    LibraryManager.loadHeader("libopencv_core.h", _HEADER_CORE);
    libcore.link(["libopencv_core.h"]);
    LibraryManager.register("opencv_core", libcore);
    libhigh = DynamicLibrary.load(getLibName("highgui"), types: LibraryManager.types);
    LibraryManager.loadHeader("libopencv_highgui.h", _HEADER_HIGH);
    libhigh.link(["libopencv_highgui.h"]);
    LibraryManager.register("opencv_highgui", libhigh);
  }

  static String getLibName(String n) {
    if (Platform.isAndroid || Platform.isLinux) {
      return "libopencv_${n}.so";
    } else if (Platform.isMacOS) {
      return "libopencv_${n}.dylib";
    } else {
      throw new Exception("Your platform is not supported.");
    }
  }
}

VideoCapture openCamera(int id) {
  var box = invoke("opencv_highgui::cvCreateCameraCapture", [id]);
  return new VideoCapture(box);
}

class VideoCapture {
  final BinaryData blackBox;

  VideoCapture(this.blackBox);

  void grab() {
    checkSysCallResult(invoke("opencv_highgui::cvGrabFrame", [blackBox]));
  }

  void release() {
    invoke("opencv_highgui::cvReleaseCapture", [alloc("CvCapture*", blackBox)]);
  }
}
