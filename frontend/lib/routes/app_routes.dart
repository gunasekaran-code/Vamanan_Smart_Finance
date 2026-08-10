class AppRoutes {
  AppRoutes._();

  // GENERAL

  static const String root = '/';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String unauthorized = '/unauthorized';

  // MANAGEMENT

  static const String dashboard = '/dashboard';
  static const String verify = '/verify';
  static const String security = '/security';
  static const String members = '/members';
  static const String payments = '/payments';
  static const String fieldCollection = '/field-collection';
  static const String dailyCollectionReport =
      '/daily-collection-report';
  static const String kycCompliance = '/kyc-compliance';

  // CHIT OPERATIONS

  static const String chits = '/chits';
  static const String auctions = '/auctions';
  static const String settlements = '/settlements';
  static const String branchHandovers = '/branch-handovers';
  static const String paymentVerifications =
      '/payment-verifications';
  static const String reports = '/reports';

  // LOAN MODULE

  static const String loanDashboard = '/loan-dashboard';
  static const String loans = '/loans';
  static const String loanCustomers = '/loan-customers';
  static const String emiCollections = '/emi-collections';
  static const String overdueEmis = '/overdue-emis';
  static const String loanVerifications =
      '/loan-verifications';
  static const String loanReports = '/loan-reports';

  // SYSTEM ENGINE

  static const String branches = '/branches';
  static const String analytics = '/analytics';
  static const String broadcastHub = '/broadcast-hub';
  static const String userManager = '/user-manager';
  static const String engineSettings = '/engine-settings';
  static const String auditControls = '/audit-controls';
  static const String notifications = 'notifications';

  // Existing profile
  static const String profile = '/profile';
}