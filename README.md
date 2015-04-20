# System Calls

Make System Calls in Dart. You can rewrite almost any C program now in Dart!

Currently this library supports Linux and Mac OSX.
In the future, there will be partial support for Windows.

Note that the name is slightly misleading. System Calls include both pure C functions and actual System Calls.

## Examples

This is just a few examples of what is possible.

### fork

```dart
import "package:syscall/syscall.dart";

void main() {
  print("Prepare to be forked!");
  var pid = fork();
  
  if (pid == 0) {
    print("I am the original process.");
    wait();
  } else {
    print("I am the child process.");
  }
}
```

### chroot

```dart
import "dart:io";

import "package:syscall/syscall.dart";

void main(List<String> args) {
  if (args.length == 0) {
    print("usage: chroot <path> [command]");
    exit(1);
  }

  chroot(args[0]);

  var cmd = args.skip(1).join(" ");

  if (cmd.isEmpty) {
    cmd = "bash";
  }

  system(cmd);
}
```

### setuid

```dart
import "package:syscall/syscall.dart";

void main() {
  print("Attempting to Gain Superuser.");
  try {
    setUserId(0);
    print("Success.");
  } catch (e) {
    print(e);
  }
}
```
