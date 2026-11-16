import 'structures/mai_chart.dart';
import 'internal/lexical_analysis/tokenizer.dart';
import 'internal/lexical_analysis/token_type.dart';
import 'internal/syntactic_analysis/deserializer.dart';
import 'internal/syntactic_analysis/serializer.dart';

class SimaiConvert {
  static MaiChart deserialize(String value) {
    var tokens = Tokenizer(value).getTokens();
    var chart = Deserializer(tokens).getChart();
    chart.source = value;
    final statements = _sourceNoteStatements(value);
    if (statements.length == chart.noteCollections.length) {
      chart.sourceNoteStatements = List.unmodifiable(statements);
    }
    return chart;
  }

  static List<String> _sourceNoteStatements(String source) {
    final statements = <String>[];
    int start = 0;
    bool inComment = false;
    for (int i = 0; i < source.length; i++) {
      final char = source.codeUnitAt(i);
      if (inComment) {
        if (char == 0x0A || char == 0x0D) inComment = false;
        continue;
      }
      if (char == 0x7C &&
          i + 1 < source.length &&
          source.codeUnitAt(i + 1) == 0x7C) {
        inComment = true;
        i++;
      } else if (char == 0x2C) {
        _addSourceStatement(source.substring(start, i), statements);
        start = i + 1;
      }
    }
    _addSourceStatement(source.substring(start), statements);
    return statements;
  }

  static void _addSourceStatement(String segment, List<String> output) {
    final tokens = Tokenizer(segment).getTokens().toList();
    if (!tokens.any((token) => token.type == TokenType.location)) return;
    var statement = segment.trim();
    if (statement.endsWith('E')) {
      statement = statement.substring(0, statement.length - 1).trimRight();
    }
    output.add(statement);
  }

  static String serialize(MaiChart chart) {
    var serializer = Serializer();
    var buffer = StringBuffer();
    serializer.serialize(chart, buffer);
    return buffer.toString();
  }
}
