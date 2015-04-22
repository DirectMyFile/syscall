library syscall;

import "dart:io";

import "package:binary_interop/binary_interop.dart";
import "package:binary_marshalling/binary_marshalling.dart";
import "package:binary_marshalling/annotations.dart";

import "package:system_info/system_info.dart";

import "darwin.dart" show getSysCtlValue;

part "src/core.dart";
part "src/system.dart";
part "src/env.dart";
part "src/files.dart";
part "src/utils.dart";
