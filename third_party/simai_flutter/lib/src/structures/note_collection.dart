import 'dart:collection';
import 'note.dart';
import 'each_style.dart';

class NoteCollection extends ListBase<Note> {
  final List<Note> _inner = [];

  EachStyle eachStyle;
  double time;

  NoteCollection(this.time) : eachStyle = EachStyle.defaultStyle;

  @override
  int get length => _inner.length;

  @override
  set length(int newLength) => _inner.length = newLength;

  @override
  Note operator [](int index) => _inner[index];

  @override
  void operator []=(int index, Note value) => _inner[index] = value;

  @override
  void add(Note element) {
    _inner.add(element);
  }

  @override
  void addAll(Iterable<Note> iterable) {
    _inner.addAll(iterable);
  }

  void addNote(Note n) {
    n.parentCollection = this;
    add(n);
  }
}
