library syscall.snappy;

import "dart:convert";
import "dart:io";

import "package:binary_interop/binary_interop.dart";
import "package:syscall/syscall.dart";

const String _HEADER = """
size_t snappy_max_compressed_length(size_t source_length);

int snappy_compress(const char* input,
                              size_t input_length,
                              char* compressed,
                              size_t* compressed_length);

int snappy_uncompress(const char* compressed,
                                size_t compressed_length,
                                char* uncompressed,
                                size_t* uncompressed_length);

int snappy_uncompressed_length(const char* compressed,
                                         size_t compressed_length,
                                         size_t* result);
""";

class LibSnappy {
  static DynamicLibrary libsnappy;

  static void init() {
    if (libsnappy != null) {
      return;
    }

    String name;

    if (Platform.isLinux || Platform.isAndroid) {
      name = "libsnappy.so";
    } else if (Platform.isMacOS) {
      name = "libsnappy.dylib";
    } else {
      throw new Exception("Your platform is not supported.");
    }

    libsnappy = DynamicLibrary.load(name, types: LibraryManager.types);
    LibraryManager.register("snappy", libsnappy);
    LibraryManager.loadHeader("libsnappy.h", _HEADER);
    libsnappy.link(["libsnappy.h"]);
  }
}

enum SnappyStatus {
  OK,
  INVALID_INPUT,
  BUFFER_TOO_SMALL
}

class Snappy {
  static Utf8Decoder _decoder = new Utf8Decoder(allowMalformed: true);
  static String compress(String input) {
    var inputString = toNativeString(input);
    var maxOutputSize = alloc("size_t", getMaxCompressedLength(inputString.type.size));
    var rs = allocArray("char", maxOutputSize.value);
    var status = getStatus(invoke("snappy::snappy_compress", [inputString, inputString.type.size, rs, maxOutputSize]));
    if (status != SnappyStatus.OK) {
      throw new SnappyException(status);
    }
    List<int> bytes = rs.value.take(maxOutputSize.value).toList();
    return _decoder.convert(bytes);
  }

  static String decompress(String input) {
    var inputString = toNativeString(input);
    var uncompressedSize = alloc("size_t", getUncompressedLength(inputString));
    var rs = allocArray("char", uncompressedSize.value);
    var status = getStatus(invoke("snappy::snappy_uncompress", [inputString, inputString.type.size, rs, uncompressedSize]));
    if (status != SnappyStatus.OK) {
      throw new SnappyException(status);
    }
    List<int> bytes = rs.value.take(uncompressedSize.type.size).toList();
    return _decoder.convert(bytes.take(uncompressedSize.value).toList(), 0, uncompressedSize.value);
  }

  static SnappyStatus getStatus(int id) {
    if (id == 0) {
      return SnappyStatus.OK;
    } else if (id == 1) {
      return SnappyStatus.INVALID_INPUT;
    } else if (id == 2) {
      return SnappyStatus.BUFFER_TOO_SMALL;
    }
    return null;
  }

  static int getUncompressedLength(BinaryData input) {
    var result = alloc("size_t");
    var status = getStatus(invoke("snappy::snappy_uncompressed_length", [input, input.type.size, result]));
    if (status != SnappyStatus.OK) {
      throw new SnappyException(status);
    }
    return result.value;
  }

  static int getMaxCompressedLength(int size) {
    return invoke("snappy::snappy_max_compressed_length", [size]);
  }
}

class SnappyException {
  final SnappyStatus status;

  SnappyException(this.status);

  @override
  String toString() => status.toString();
}
