class ParsedReceiptLine {
  const ParsedReceiptLine({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String description;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
}

class ParsedReceipt {
  const ParsedReceipt({
    required this.lines,
    this.suggestedTotal,
    this.rawText,
  });

  final List<ParsedReceiptLine> lines;
  final double? suggestedTotal;
  final String? rawText;
}

class ReceiptParser {
  static final _pricePattern = RegExp(r'(\d{1,3}(?:[,\s]\d{3})*(?:\.\d{2})?|\d+\.\d{2})\s*$');
  static final _totalPattern = RegExp(
    r'(?:total|amount\s*paid|paid|balance)\D*(\d{1,3}(?:[,\s]\d{3})*(?:\.\d{2})?|\d+\.\d{2})',
    caseSensitive: false,
  );

  static ParsedReceipt parse(String rawText) {
    final lines = <ParsedReceiptLine>[];
    double? suggestedTotal;

    for (final rawLine in rawText.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final totalMatch = _totalPattern.firstMatch(line);
      if (totalMatch != null) {
        suggestedTotal = _parseAmount(totalMatch.group(1)!);
        continue;
      }

      final priceMatch = _pricePattern.firstMatch(line);
      if (priceMatch == null) continue;

      final amount = _parseAmount(priceMatch.group(1)!);
      final description = line.substring(0, priceMatch.start).trim();
      if (description.length < 2) continue;
      if (RegExp(r'^(sub\s*total|tax|vat|change)', caseSensitive: false).hasMatch(description)) {
        continue;
      }

      lines.add(ParsedReceiptLine(
        description: description,
        quantity: 1,
        unitPrice: amount,
        lineTotal: amount,
      ));
    }

    return ParsedReceipt(
      lines: lines,
      suggestedTotal: suggestedTotal ??
          (lines.isEmpty ? null : lines.fold<double>(0, (sum, l) => sum + l.lineTotal)),
      rawText: rawText,
    );
  }

  static double _parseAmount(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[,\s]'), '')) ?? 0;
  }
}
