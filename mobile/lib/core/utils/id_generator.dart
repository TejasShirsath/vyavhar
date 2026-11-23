import 'package:uuid/uuid.dart';

class IdGenerator {
  IdGenerator._();

  static const _uuid = Uuid();

  static String uuid() => _uuid.v4();

  /// Generates a human-readable SKU, e.g. "VYV-1042"
  static String sku(int sequenceNumber) {
    return 'VYV-${(1000 + sequenceNumber).toString().padLeft(4, '0')}';
  }

  /// Generates an Invoice Number, e.g. "INV-1048"
  static String invoiceNumber(int sequenceNumber) {
    return 'INV-${(1000 + sequenceNumber).toString().padLeft(4, '0')}';
  }
}
