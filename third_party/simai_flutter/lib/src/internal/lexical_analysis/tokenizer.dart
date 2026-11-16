import 'token.dart';
import 'token_type.dart';
import '../errors/unexpected_character_exception.dart';
import '../errors/unsupported_syntax_exception.dart';
import '../errors/unterminated_section_exception.dart';

class Tokenizer {
  static const int space = 0x0020;
  static const int enSpace = 0x2002;
  static const int punctuationSpace = 0x2008;
  static const int ideographicSpace = 0x3000;
  static const int lineSeparator = 0x2028;
  static const int paragraphSeparator = 0x2029;
  static const int endOfFileChar = 0x45; // 'E'

  static final Set<int> eachDividerChars = {
    '/'.codeUnitAt(0),
    '`'.codeUnitAt(0),
  };
  static final Set<int> decoratorChars = {
    'f',
    'b',
    'x',
    'h',
    'm',
    '!',
    '?',
    '@',
    '\$',
  }.map((c) => c.codeUnitAt(0)).toSet();

  static final Set<int> slideChars = {
    '-',
    '>',
    '<',
    '^',
    'p',
    'q',
    'v',
    'V',
    's',
    'z',
    'w',
  }.map((c) => c.codeUnitAt(0)).toSet();

  static final Set<int> separatorChars = {
    '\r'.codeUnitAt(0),
    '\t'.codeUnitAt(0),
    lineSeparator,
    paragraphSeparator,
    space,
    enSpace,
    punctuationSpace,
    ideographicSpace,
  };

  final String _sequence;
  int _current = 0;
  int _charIndex = 0;
  int _line = 1;
  int _start = 0;

  Tokenizer(this._sequence);

  bool get isAtEnd => _current >= _sequence.length;

  Iterable<Token> getTokens() sync* {
    while (!isAtEnd) {
      _start = _current;
      var nextToken = scanToken();
      if (nextToken != null) {
        yield nextToken;
      }
    }
  }

  Token? scanToken() {
    _charIndex++;
    var c = advance();

    // Switch equivalent
    if (c == ','.codeUnitAt(0)) {
      return compileToken(TokenType.timeStep);
    } else if (c == '('.codeUnitAt(0)) {
      return compileSectionToken(
        TokenType.tempo,
        '('.codeUnitAt(0),
        ')'.codeUnitAt(0),
      );
    } else if (c == '{'.codeUnitAt(0)) {
      return compileSectionToken(
        TokenType.subdivision,
        '{'.codeUnitAt(0),
        '}'.codeUnitAt(0),
      );
    } else if (c == '['.codeUnitAt(0)) {
      return compileSectionToken(
        TokenType.duration,
        '['.codeUnitAt(0),
        ']'.codeUnitAt(0),
      );
    }

    // Check for location
    // Since we consumed 'c', we need to check if 'c' plus potential next chars form a location.
    // But TryScanLocationToken checks PeekPrevious (which is c) and Peek.
    // Wait, ScanToken in C# calls Advance() first, so c is the character we just consumed.
    // PeekPrevious() is c.
    // So the logic matches.

    int length = 0;
    if (tryScanLocationToken(outLength: (l) => length = l)) {
      _current += length - 1; // -1 because we already consumed one char (c)
      return compileToken(TokenType.location);
    }

    if (decoratorChars.contains(c)) {
      return compileToken(TokenType.decorator);
    }

    if (isReadingSlideDeclaration(outLength: (l) => length = l)) {
      _current += length - 1;
      return compileToken(TokenType.slide);
    }

    if (c == '*'.codeUnitAt(0)) {
      return compileToken(TokenType.slideJoiner);
    }

    if (eachDividerChars.contains(c)) {
      return compileToken(TokenType.eachDivider);
    }

    if (separatorChars.contains(c)) {
      return null;
    }

    if (c == '\n'.codeUnitAt(0)) {
      _line++;
      _charIndex = 0;
      return null;
    }

    if (c == 'E'.codeUnitAt(0)) {
      return compileToken(TokenType.endOfFile);
    }

    if (c == '|'.codeUnitAt(0)) {
      if (peek() != '|'.codeUnitAt(0)) {
        throw UnexpectedCharacterException(_line, _charIndex, "|");
      }

      while (peek() != '\n'.codeUnitAt(0) && !isAtEnd) {
        advance();
      }
      return null;
    }

    throw UnsupportedSyntaxException(_line, _charIndex);
  }

  bool tryScanLocationToken({required Function(int) outLength}) {
    var firstLocationChar = peekPrevious();

    if (isButtonLocation(firstLocationChar)) {
      outLength(1);
      return true;
    }

    outLength(0);

    if (!isSensorLocation(firstLocationChar)) {
      return false;
    }

    var secondLocationChar = peek();

    if (isButtonLocation(secondLocationChar)) {
      outLength(2);
      return true;
    }

    if (firstLocationChar == 'C'.codeUnitAt(0)) {
      outLength(1);
      return true;
    }

    var secondCharIsEmpty =
        separatorChars.contains(secondLocationChar) ||
        secondLocationChar == '\n'.codeUnitAt(0) ||
        secondLocationChar == 0;

    // This is the notation for EOF.
    if (firstLocationChar == endOfFileChar && secondCharIsEmpty) {
      return false;
    }

    throw UnexpectedCharacterException(
      _line,
      _charIndex,
      "1, 2, 3, 4, 5, 6, 7, 8",
    );
  }

  bool isReadingSlideDeclaration({required Function(int) outLength}) {
    if (!slideChars.contains(peekPrevious())) {
      outLength(0);
      return false;
    }

    var nextChar = peek();

    outLength(
      (nextChar == 'p'.codeUnitAt(0) || nextChar == 'q'.codeUnitAt(0)) ? 2 : 1,
    );
    return true;
  }

  Token? compileSectionToken(
    TokenType tokenType,
    int initiator,
    int terminator,
  ) {
    _start++; // Skip the initiator
    while (peek() != terminator) {
      if (isAtEnd || peek() == initiator) {
        throw UnterminatedSectionException(_line, _charIndex);
      }
      advance();
    }

    var token = compileToken(tokenType);

    // The terminator.
    advance();

    return token;
  }

  Token compileToken(TokenType type) {
    var text = _sequence.substring(_start, _current);
    return Token(type, text, _line, _charIndex);
  }

  static bool isSensorLocation(int value) {
    return value >= 'A'.codeUnitAt(0) && value <= 'E'.codeUnitAt(0);
  }

  static bool isButtonLocation(int value) {
    return value >= '0'.codeUnitAt(0) && value <= '8'.codeUnitAt(0);
  }

  int advance() {
    return _sequence.codeUnitAt(_current++);
  }

  int peek() {
    return isAtEnd ? 0 : _sequence.codeUnitAt(_current);
  }

  int peekPrevious() {
    return _current == 0 ? 0 : _sequence.codeUnitAt(_current - 1);
  }
}
