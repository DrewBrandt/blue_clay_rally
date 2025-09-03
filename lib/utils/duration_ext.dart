extension DurationPrint on Duration {
  String toFormattedString() {
    return (isNegative ? '- ' : '+ ') + toString().split('.').first.split('-').last.padLeft(8, "0");
  }
}
