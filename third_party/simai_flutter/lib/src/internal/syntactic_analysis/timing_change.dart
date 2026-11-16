class TimingChange {
  double time;
  double tempo;
  double subdivisions;

  TimingChange({this.time = 0, this.tempo = 0, this.subdivisions = 0});

  /// Used in duration parsing.
  double get secondsPerBar => tempo == 0 ? 0 : 60.0 / tempo;

  double get secondsPerBeat =>
      secondsPerBar / ((subdivisions == 0 ? 4 : subdivisions) / 4);

  void setSeconds(double value) {
    tempo = 60.0 / value;
    subdivisions = 4;
  }

  TimingChange clone() {
    return TimingChange(time: time, tempo: tempo, subdivisions: subdivisions);
  }
}
