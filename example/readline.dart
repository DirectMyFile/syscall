import "package:syscall/readline.dart";

void main() {
  var name = Readline.readLine("What is your name? ");
  print(name);
}
