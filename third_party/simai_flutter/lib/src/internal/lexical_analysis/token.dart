import 'token_type.dart';

class Token {
  final TokenType type;
  final String lexeme;
  final int line;
  final int character;

  Token(this.type, this.lexeme, this.line, this.character);
}
