# System Calls

Make System Calls in Dart

## Example

```dart
import "package:syscall/syscall.dart";

void main() {
  print("pid: ${getProcessId()}");
  print("ppid: ${getParentProcessId()}");
  print("uid: ${getUserId()}");
  print("gid: ${getGroupId()}");
  print("group name: ${getGroupInfo(getGroupId()).gr_name}");
}
```
