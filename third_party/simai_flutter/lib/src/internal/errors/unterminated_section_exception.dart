import 'simai_exception.dart';

class UnterminatedSectionException extends SimaiException {
  UnterminatedSectionException(super.line, super.character);
}
