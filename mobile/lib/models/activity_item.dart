import 'package:flutter/material.dart';

enum ActivityType {
  sale,
  purchase,
  wastage,
  expense,
  initialStock,
  productCreated,
  productDeleted,
}

class BusinessActivityItem {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final double? amount;
  final String? amountPrefix;
  final Color? amountColor;
  final String? badgeText;
  final Color? badgeColor;
  final dynamic originalObject; // Invoice, Expense, WastageRecord, StockMovement

  const BusinessActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.amount,
    this.amountPrefix,
    this.amountColor,
    this.badgeText,
    this.badgeColor,
    this.originalObject,
  });
}
