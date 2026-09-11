import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/core/models/auth_models.dart';
import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/services/auth_service.dart';

/// The fixtures below are the literal envelopes the PHP endpoints in
/// `api/auth/*` echo — including the quirks the client has to absorb:
/// HTTP 200 on a rejection, `permissions` as a JSON-encoded string, and the
/// reset OTP coming back inline because mail delivery is switched off.
void main() {
  late List<http.Request> sent;

  /// Answers every request with [body] and records what was posted.
  void stub(String body, {int status = 200}) {
    sent = [];
    ApiClient.instance.client = MockClient((request) async {
      sent.add(request);
      return http.Response(body, status,
          headers: {'content-type': 'application/json'});
    });
  }

  Map<String, dynamic> lastBody() =>
      jsonDecode(sent.single.body) as Map<String, dynamic>;

  group('login', () {
    test('parses the authenticated user', () async {
      stub(jsonEncode({
        'status': 'success',
        'message': 'Welcome back, Asha',
        'user': {
          'id': 7,
          'name': 'Asha Menon',
          'email': 'asha@vamanan.dev',
          'role': 'manager',
          'phone': '9876543210',
          'status': 'active',
          'permissions': '["wallets","reports"]',
          'customer_id': 'VEV007',
          'referral_code': 'REF7',
        },
      }));

      final response = await AuthService.instance.login(
        const LoginRequest(email: 'asha@vamanan.dev', password: 'secret'),
      );

      expect(response.success, isTrue);
      expect(response.message, 'Welcome back, Asha');

      final user = response.data!;
      expect(user.id, '7');
      expect(user.role, UserRole.manager);
      expect(user.customerId, 'VEV007');
      // The column stores a JSON array as text, not a list.
      expect(user.permissions, ['wallets', 'reports']);

      expect(lastBody(), {'email': 'asha@vamanan.dev', 'password': 'secret'});
      expect(sent.single.url.path, endsWith('auth/login.php'));
    });

    test('surfaces a rejection sent with HTTP 200', () async {
      stub(jsonEncode({
        'status': 'error',
        'message': 'Your account is pending admin approval.',
      }));

      final response = await AuthService.instance.login(
        const LoginRequest(email: 'new@vamanan.dev', password: 'secret'),
      );

      expect(response.success, isFalse);
      expect(response.message, 'Your account is pending admin approval.');
      expect(response.data, isNull);
    });

    test('rejects an invalid email without calling the backend', () async {
      stub(jsonEncode({'status': 'success'}));

      final response = await AuthService.instance.login(
        const LoginRequest(email: 'not-an-email', password: 'secret'),
      );

      expect(response.success, isFalse);
      expect(response.message, 'Enter a valid email address.');
      expect(sent, isEmpty);
    });

    test('reports a transport failure as a plain message', () async {
      ApiClient.instance.client = MockClient(
        (_) async => throw http.ClientException('Connection refused'),
      );

      final response = await AuthService.instance.login(
        const LoginRequest(email: 'asha@vamanan.dev', password: 'secret'),
      );

      expect(response.success, isFalse);
      expect(response.message, contains('Could not reach the server'));
    });

    test('survives a PHP notice printed ahead of the JSON', () async {
      stub('<br /><b>Warning</b>: something in config.php on line 12<br />'
          '{"status":"error","message":"No account found with this email."}');

      final response = await AuthService.instance.login(
        const LoginRequest(email: 'ghost@vamanan.dev', password: 'secret'),
      );

      expect(response.success, isFalse);
      expect(response.message, 'No account found with this email.');
    });
  });

  group('register', () {
    test('posts the referral only when one was entered', () async {
      stub(jsonEncode({
        'status': 'success',
        'message': 'Registration successful! Your account is pending admin approval.',
        'user_id': 42,
      }));

      final response = await AuthService.instance.register(const RegisterRequest(
        name: 'Ravi Kumar',
        email: 'ravi@vamanan.dev',
        phone: '9876543210',
        password: 'secret123',
      ));

      expect(response.success, isTrue);
      expect(response.data!.userId, '42');
      expect(lastBody().containsKey('referral_code'), isFalse);
    });

    test('includes a trimmed referral code when present', () async {
      stub(jsonEncode({'status': 'success', 'user_id': 43}));

      await AuthService.instance.register(const RegisterRequest(
        name: 'Ravi Kumar',
        email: 'ravi@vamanan.dev',
        phone: '9876543210',
        password: 'secret123',
        referralCode: '  VEV007 ',
      ));

      expect(lastBody()['referral_code'], 'VEV007');
    });

    test('requires a phone number, which the backend also demands', () async {
      stub(jsonEncode({'status': 'success'}));

      final response = await AuthService.instance.register(const RegisterRequest(
        name: 'Ravi Kumar',
        email: 'ravi@vamanan.dev',
        phone: '',
        password: 'secret123',
      ));

      expect(response.success, isFalse);
      expect(response.message, 'Enter your phone number.');
      expect(sent, isEmpty);
    });
  });

  group('password reset', () {
    test('captures the OTP the backend returns inline', () async {
      stub(jsonEncode({
        'status': 'success',
        'message': 'Identity verified. Synchronization code generated.',
        'otp': '048213',
      }));

      final response = await AuthService.instance.forgotPassword(
        const ForgotPasswordRequest(email: ' asha@vamanan.dev '),
      );

      expect(response.success, isTrue);
      expect(response.data!.otp, '048213');
      expect(response.data!.hasInlineOtp, isTrue);
      // The email is trimmed once and reused for the remaining two steps.
      expect(response.data!.email, 'asha@vamanan.dev');
    });

    test('passes the rate-limit refusal through', () async {
      stub(jsonEncode({
        'status': 'error',
        'message':
            'Too many requests. Please wait 2 minutes before requesting a new code.',
      }));

      final response = await AuthService.instance.forgotPassword(
        const ForgotPasswordRequest(email: 'asha@vamanan.dev'),
      );

      expect(response.success, isFalse);
      expect(response.message, contains('Too many requests'));
    });

    test('sends email, otp and new_password on the final step', () async {
      stub(jsonEncode({
        'status': 'success',
        'message': 'Your password has been successfully reset.',
      }));

      final response = await AuthService.instance.resetPassword(
        const ResetPasswordRequest(
          email: 'asha@vamanan.dev',
          otp: '048213',
          newPassword: 'newsecret',
          confirmPassword: 'newsecret',
        ),
      );

      expect(response.success, isTrue);
      expect(lastBody(), {
        'email': 'asha@vamanan.dev',
        'otp': '048213',
        'new_password': 'newsecret',
      });
      expect(sent.single.url.path, endsWith('auth/reset_password.php'));
    });

    test('catches mismatched passwords before the round trip', () async {
      stub(jsonEncode({'status': 'success'}));

      final response = await AuthService.instance.resetPassword(
        const ResetPasswordRequest(
          email: 'asha@vamanan.dev',
          otp: '048213',
          newPassword: 'newsecret',
          confirmPassword: 'different',
        ),
      );

      expect(response.success, isFalse);
      expect(response.message, 'The passwords do not match.');
      expect(sent, isEmpty);
    });

    test('rejects a code that is not six digits', () async {
      stub(jsonEncode({'status': 'success'}));

      final response = await AuthService.instance.verifyOtp(
        const VerifyOtpRequest(email: 'asha@vamanan.dev', otp: '123'),
      );

      expect(response.success, isFalse);
      expect(response.message, 'The verification code is 6 digits.');
      expect(sent, isEmpty);
    });
  });
}
