import 'simai_exception.dart';

class InvalidSyntaxException extends SimaiException {
  InvalidSyntaxException(super.line, super.character);
}
