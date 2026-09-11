class InvestmentHistoryRecord {
  final String id;
  final String processDate;
  final String processTime;
  final String customerName;
  final String customerEmail;
  final String assetType;
  final String assetWeight;
  final String capitalAmount;
  final String dailyAmount;
  final String paymentMethod;
  final String utrNumber;
  final String statusCode;
  final String receiptUrl;

  const InvestmentHistoryRecord({
    required this.id,
    required this.processDate,
    required this.processTime,
    required this.customerName,
    required this.customerEmail,
    required this.assetType,
    required this.assetWeight,
    required this.capitalAmount,
    required this.dailyAmount,
    required this.paymentMethod,
    required this.utrNumber,
    required this.statusCode,
    required this.receiptUrl,
  });
}