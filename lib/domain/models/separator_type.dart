enum SeparatorType { newLine, emptyLine, dash, dot, custom }

extension SeparatorTypeExtension on SeparatorType {
  String get label {
    switch (this) {
      case SeparatorType.newLine:
        return 'New Line';
      case SeparatorType.emptyLine:
        return 'Empty Line';
      case SeparatorType.dash:
        return 'Dash';
      case SeparatorType.dot:
        return 'Dot';
      case SeparatorType.custom:
        return 'Custom...';
    }
  }

  String get value {
    switch (this) {
      case SeparatorType.newLine:
        return '\n';
      case SeparatorType.emptyLine:
        return '\n\n';
      case SeparatorType.dash:
        return '-';
      case SeparatorType.dot:
        return '.';
      case SeparatorType.custom:
        return '';
    }
  }
}
