class InvestmentRequest {
  final String id;
  final String userName;
  final String userEmail;
  final String assetType;
  final String weightGrams;
  final String amount;
  final String yieldRate;
  final String paymentMode;
  final String utrNumber;
  final String submittedTime;
  final String receiptImageUrl;

  const InvestmentRequest({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.assetType,
    required this.weightGrams,
    required this.amount,
    required this.yieldRate,
    required this.paymentMode,
    required this.utrNumber,
    required this.submittedTime,
    required this.receiptImageUrl,
  });
}