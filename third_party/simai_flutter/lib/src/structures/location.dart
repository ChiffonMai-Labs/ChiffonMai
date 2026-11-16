import 'note_group.dart';

class Location {
  /// Describes which button / sensor in the [group] this element is pointing to.
  int index;

  NoteGroup group;

  Location(this.index, this.group);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          group == other.group;

  @override
  int get hashCode => Object.hash(index, group);

  @override
  String toString() {
    switch (group) {
      case NoteGroup.tap:
        return (index + 1).toString();
      case NoteGroup.cSensor:
        return "C";
      case NoteGroup.aSensor:
        return "A${index + 1}";
      case NoteGroup.bSensor:
        return "B${index + 1}";
      case NoteGroup.dSensor:
        return "D${index + 1}";
      case NoteGroup.eSensor:
        return "E${index + 1}";
    }
  }
}
