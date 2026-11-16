import 'dart:convert';
import 'dart:io';

/// A wrapper for parsing Simai files
///
/// This class extracts key-value data from a maidata file.
/// For simai chart serialization, use [SimaiConvert]
class SimaiFile {
  final List<String> _lines;

  SimaiFile(String text) : _lines = LineSplitter.split(text).toList();

  factory SimaiFile.fromFile(File file) {
    return SimaiFile(file.readAsStringSync());
  }

  Iterable<MapEntry<String, String>> toKeyValuePairs() sync* {
    var currentKey = "";
    var currentValue = StringBuffer();

    for (var line in _lines) {
      if (line.startsWith('&')) {
        if (currentKey.isNotEmpty) {
          yield MapEntry(currentKey, currentValue.toString().trimRight());
          currentValue.clear();
        }

        var keyValuePair = line.split('=');
        // Handle case where split might have more than 2 parts (if value contains =)
        // C# code: line.Split('=', 2);

        var keyPart = keyValuePair[0];
        var valuePart = "";
        if (keyValuePair.length > 1) {
          // Re-join the rest if split by all =?
          // split('=', 2) in Dart?
          // Dart split doesn't support limit.
          // We can use substring.
          var firstEq = line.indexOf('=');
          keyPart = line.substring(0, firstEq);
          valuePart = line.substring(firstEq + 1);
        } else {
          // No = found? C# assumes Split('=', 2)
          keyPart = line;
        }

        currentKey = keyPart.substring(1); // Skip &
        currentValue.writeln(valuePart);
      } else {
        currentValue.writeln(line);
      }
    }

    // Add the last entry
    if (currentKey.isNotEmpty) {
      yield MapEntry(currentKey, currentValue.toString().trimRight());
    }
  }

  String? getValue(String key) {
    var keyPart = "&$key=";
    var result = StringBuffer();
    var readingValue = false;

    for (var line in _lines) {
      if (line.startsWith('&')) {
        if (readingValue) {
          return result.toString().trimRight();
        }

        if (!line.toLowerCase().startsWith(keyPart.toLowerCase())) {
          continue;
        }

        readingValue = true;
        result.writeln(line.substring(keyPart.length));
      } else if (readingValue) {
        result.writeln(line);
      }
    }

    return readingValue ? result.toString().trimRight() : null;
  }
}
