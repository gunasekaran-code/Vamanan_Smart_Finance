import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const String _defaultPort = '8888';
  static const String _apiPath = '/vamanan/api';

  // static String get baseUrl {
  //   if (_override.isNotEmpty) return _stripTrailingSlash(_override);
  //   return 'http://$_host:$_defaultPort$_apiPath';
  // }

  static String get baseUrl {
    if (_override.isNotEmpty) return _stripTrailingSlash(_override);
    return 'https://www.vamananenterprisesv.com/api';
  }

  /// Site root (the API base minus its trailing `/api` segment).
  ///
  /// Uploaded files (receipts, KYC docs, avatars, product images) are stored by
  /// the PHP endpoints relative to the document root, e.g.
  /// `uploads/payments/pay_123.jpg`, so they must be joined to this, not to
  /// [baseUrl].
  static String get siteBaseUrl => baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  /// Builds an absolute URL for a server-stored upload path.
  /// Returns [path] unchanged when it is already absolute (rewriting localhost to [siteBaseUrl]).
  static String fileUrl(String path) {
    var raw = path.trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') return '';
    raw = raw.replaceAll('\\', '/');

    // Rewrite localhost/127.0.0.1/10.0.2.2 URLs from dev environments to current siteBaseUrl
    if (raw.startsWith('http://localhost') ||
        raw.startsWith('http://127.0.0.1') ||
        raw.startsWith('http://10.0.2.2')) {
      final uri = Uri.tryParse(raw);
      if (uri != null) {
        final pathOnly = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
        return '$siteBaseUrl/$pathOnly';
      }
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final clean = raw.startsWith('/') ? raw.substring(1) : raw;

    // Bare filename with no directory separator (e.g. 1785129934_6a66ebce25612.png)
    if (!clean.contains('/')) {
      return '$siteBaseUrl/api/uploads/products/$clean';
    }

    return '$siteBaseUrl/$clean';
  }

  static String get _host {
    if (kIsWeb) return '127.0.0.1';
    try {
      if (Platform.isAndroid) return '10.0.2.2';
    } catch (_) {}
    return '127.0.0.1';
  }

  static String _stripTrailingSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;

  static Uri endpoint(String path) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseUrl/$clean');
  }

  static const Duration timeout = Duration(seconds: 20);
}

class AuthEndpoints {
  AuthEndpoints._();
  static const String login = 'auth/login.php';
  static const String register = 'auth/register.php';
  static const String forgotPassword = 'auth/forgot_password.php';
  static const String verifyOtp = 'auth/verify_otp.php';
  static const String resetPassword = 'auth/reset_password.php';
}

class AdminEndpoints {
  AdminEndpoints._();

  static const String dashboardStats = 'admin/stats.php';
  static const String cashbackApplications = 'admin/cashback_applications.php';
  static const String allUsers = 'admin/all_users.php';
  static const String updateUser = 'admin/update_user.php';
  static const String genealogyTree = 'admin/get_genealogy.php';
  static const String processMonthlyYield = 'admin/run_daily_payout.php';
  static const String wallets = 'admin/wallets.php';
  static const String adjustWallet = 'admin/adjust_wallet.php';
  static const String userPayoutPlan = 'admin/get_user_daily_payout.php';
  static const String payoutReports = 'admin/payout_reports.php';
  static const String reports = 'admin/reports.php';
  static const String payoutHistory = 'admin/payout_history.php';
  static const String withdrawals = 'admin/withdrawals.php';
  static const String processWithdrawal = 'admin/process_withdrawal.php';
  static const String exportPayouts = 'admin/export_payouts.php';
  static const String reconcilePayouts = 'admin/reconcile_payouts.php';
  static const String tallyExport = 'admin/tally_export.php';
  //Investment endpoints
  static const String pendingInvestments = 'admin/investments.php';
  static const String investmentHistory = 'admin/investment_history.php';
  static const String approveInvestment = 'admin/approve_investment.php';

  static const String toggleReferral = 'admin/toggle_referral.php';

  // Product (asset) purchase requests — GET list, POST update status/note
  static const String productRequests = 'admin/product_requests.php';
}

class TallyEndpoints {
  TallyEndpoints._();
  static const String data = 'admin/tally/data.php';
  static const String export = 'admin/tally/export.php';
  static const String sync = 'admin/tally/sync.php';
  static const String vouchers = 'admin/tally/vouchers.php';
  static const String syncMarketRate = 'admin/sync_market_rate.php';
}

/// KYC endpoints.
///
/// There is no dedicated admin KYC service on the server — `kyc_requests.php`
/// and `update_kyc_status.php` were never deployed and both answer 404. KYC
/// lives as columns on the `users` table, so the register is assembled from
/// the user endpoints instead.
class KycEndpoints {
  KycEndpoints._();

  /// GET — every user, carrying `kyc_status` and `kyc_document`. There is no
  /// server-side status filter, so the register filters client-side.
  static const String list = 'admin/all_users.php';

  /// GET `?user_id=N` — phone, address, aadhar_no, pan_no and the bank fields.
  /// POST (multipart) — creates or updates those same fields, optionally with
  /// a `document` file, and resets `kyc_status` to 'pending'.
  static const String details = 'customer/kyc.php';

  /// POST `{"id": N, "kyc_status": "verified|rejected|pending"}` — the
  /// approve / reject / reopen action.
  static const String updateStatus = 'admin/update_user.php';
}

class NotificationEndpoints {
  NotificationEndpoints._();
  static const String list = 'admin/get_all_notifications.php';
  static const String dispatch = 'admin/send_notification.php';
  static const String update = 'admin/edit_notification.php';
  static const String delete = 'admin/delete_notification.php';
}

class TransactionEndpoints {
  TransactionEndpoints._();
  static const String summary = 'admin/check_transactions.php';
  static const String updateStatus = 'admin/update_transaction.php';
}

class HolidayEndpoints {
  HolidayEndpoints._();
  static const String holidays = 'admin/holidays.php';
}

class FeedbackEndpoints {
  FeedbackEndpoints._();
  static const String feedback = 'admin/feedback.php';
}

class OfferEndpoints {
  OfferEndpoints._();
  static const String offers = 'admin/offers.php';
  static const String activeOffers = 'offers/active.php';
}

class StaffEndpoints {
  StaffEndpoints._();
  static const String addStaff = 'admin/add_staff.php';
  static const String updateStaff = 'admin/update_user.php';
  static const String deleteStaff = 'admin/delete_user.php';
}

class ManagerEndpoints {
  ManagerEndpoints._();
  static const String updateProfile = 'manager/update_profile.php';
  static const String dashboardStats = 'manager/stats.php';
  static const String operationalFootprint = 'admin/activity_logs.php';
  static const String customers = 'admin/all_users.php';
  static const String updateCustomer = 'admin/update_user.php';
  static const String deleteCustomer = 'admin/delete_user.php';
}

class AdvocateEndpoints {
  AdvocateEndpoints._();
  static const String dashboardStats = 'advocate/stats.php';
  static const String updateProfile = 'customer/update_profile.php';
  static const String changePassword = 'customer/change_password.php';
  static const String operationalFootprint = 'admin/activity_logs.php';
  static const String actions = 'advocate/actions.php';
}

class AuditorEndpoints {
  AuditorEndpoints._();
  static const String summary = 'auditor/summary.php';
  static const String transactions = 'auditor/transactions.php';
  static const String ledger = 'auditor/ledger.php';
  static const String kyc = 'customer/kyc.php';
  static const String profile = 'auditor/profile.php';
  static const String referralSummary = 'customer/referrals.php';
}

class AuditorEndpointsLedgerFilters {
  // Query param names accepted by auditor/ledger.php, for reference.
  AuditorEndpointsLedgerFilters._();
  static const String userId = 'user_id';
  static const String from = 'from';
  static const String to = 'to';
  static const String status = 'status';
  static const String type = 'type';
  static const String category = 'category';
  static const String limit = 'limit';
}

class CustomerEndpoints {
  CustomerEndpoints._();
  static const String cashbackApplication = 'customer/cashback_application.php';
  static const String agreement = 'customer/agreement.php';
  static const String wallet = 'customer/wallet.php';
  static const String requestWithdrawal = 'customer/request_withdrawal.php';

  /// Per-user portfolio snapshot: wallet balance, cashback cycle progress,
  /// transactions, referral count and notifications, all scoped by
  /// `?user_id=`. This is the customer-safe counterpart to
  /// [AuditorEndpoints.summary], which reports platform-wide financials.
  static const String dashboard = 'customer/dashboard.php';

  /// Profile + wallet balance + portfolio stats in one call.
  ///
  /// Deliberately NOT `customer/get_profile.php`: that one joins a
  /// `kyc_details` table which does not exist in this database, so it fails
  /// outright with "Base table or view not found". profile.php reads
  /// `kyc_status`, `aadhar_no` and `pan_no` straight off the `users` row,
  /// which is where they actually live.
  static const String profile = 'customer/profile.php';
  static const String updateProfile = 'customer/update_profile.php';
  static const String changePassword = 'customer/change_password.php';

  /// This customer's own purchase / investment history, scoped by `user_id`.
  /// The Buy screen used to read [AuditorEndpoints.summary] for this, which
  /// returns platform-wide KPIs and no orders at all.
  static const String orders = 'customer/orders.php';

  static const String submitFeedback = 'customer/submit_feedback.php';
  static const String getFeedback = 'customer/get_feedback.php';
}
