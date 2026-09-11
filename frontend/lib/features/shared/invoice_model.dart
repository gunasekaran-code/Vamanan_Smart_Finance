class InvoiceModel {
  final String invoiceId;
  final String dateDay;
  final String dateMonthYear;
  final String customerName;
  final String customerCode;
  final String productDetails;
  final String taxableValue;
  final String gstRate;
  final String cgst;
  final String sgst;
  final String total;
  final String status;

  const InvoiceModel({
    required this.invoiceId,
    required this.dateDay,
    required this.dateMonthYear,
    required this.customerName,
    required this.customerCode,
    required this.productDetails,
    required this.taxableValue,
    required this.gstRate,
    required this.cgst,
    required this.sgst,
    required this.total,
    required this.status,
  });
}

const List<InvoiceModel> sampleInvoices = [
  InvoiceModel(
    invoiceId: 'INV-000045',
    dateDay: '26',
    dateMonthYear: 'Aug 26',
    customerName: 'Nandha Kumar.M',
    customerCode: 'VEV065',
    productDetails: '40 Gram(s) 24K Gold',
    taxableValue: '₹8,15,540.00',
    gstRate: '3%',
    cgst: '₹12,233.10',
    sgst: '₹12,233.10',
    total: '₹8,40,006.20',
    status: 'ACTIVE',
  ),
  InvoiceModel(
    invoiceId: 'INV-000044',
    dateDay: '26',
    dateMonthYear: 'Aug 26',
    customerName: 'Prakash.A',
    customerCode: 'VEV020',
    productDetails: '8 Gram(s) 24K Gold',
    taxableValue: '₹1,63,108.00',
    gstRate: '3%',
    cgst: '₹2,446.62',
    sgst: '₹2,446.62',
    total: '₹1,68,001.24',
    status: 'ACTIVE',
  ),
  InvoiceModel(
    invoiceId: 'INV-000043',
    dateDay: '25',
    dateMonthYear: 'Aug 26',
    customerName: 'Somasundaram.S',
    customerCode: 'VEV022',
    productDetails: '8 Gram(s) 24K Gold',
    taxableValue: '₹1,63,108.00',
    gstRate: '3%',
    cgst: '₹2,446.62',
    sgst: '₹2,446.62',
    total: '₹1,68,001.24',
    status: 'ACTIVE',
  ),
  InvoiceModel(
    invoiceId: 'INV-000042',
    dateDay: '25',
    dateMonthYear: 'Aug 26',
    customerName: 'Kanagaraj K',
    customerCode: 'VEV094',
    productDetails: '32 Gram(s) 24K Gold',
    taxableValue: '₹6,52,432.00',
    gstRate: '3%',
    cgst: '₹9,786.48',
    sgst: '₹9,786.48',
    total: '₹6,72,004.96',
    status: 'ACTIVE',
  ),
  InvoiceModel(
    invoiceId: 'INV-000041',
    dateDay: '25',
    dateMonthYear: 'Aug 26',
    customerName: 'Kumaran Thangav...',
    customerCode: 'VEV012',
    productDetails: '8 Gram(s) 24K Gold',
    taxableValue: '₹1,63,108.00',
    gstRate: '3%',
    cgst: '₹2,446.62',
    sgst: '₹2,446.62',
    total: '₹1,68,001.24',
    status: 'ACTIVE',
  ),
];