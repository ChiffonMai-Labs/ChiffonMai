import 'simai_exception.dart';

class ScopeMismatchException extends SimaiException {
  final int correctScope;

  ScopeMismatchException(super.line, super.character, this.correctScope);
}

class ScopeType {
  static const int note = 1;
  static const int slide = 1 << 1;
  static const int global = 1 << 2;
}
