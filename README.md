# System Calls

Make System Calls in Dart. You can rewrite almost any C program now in Dart!

## Example

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
