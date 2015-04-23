import "package:syscall/readline.dart";

void main() {
  LibReadline.init();

  var name = readLine("What is your name? ");
  print(name);
}
