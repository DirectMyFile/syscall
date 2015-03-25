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
