import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/identity_verification_model.dart';

/// KYC has no endpoint of its own — `admin/kyc_requests.php` and
/// `admin/update_kyc_status.php` were never deployed and answer 404, which is
/// why the register never loaded. It is assembled from two live endpoints, and
/// the payloads below are the shapes they actually return.

/// `admin/all_users.php` — the list. Note `role` can be an empty string and
/// `kyc_document` can be null.
const _listResponse = '''
{"status":"success","data":[
 {"id":136,"customer_id":"VEV104","referral_code":"VEVRV4LG","name":"Test User",
  "email":"test@example.com","role":"","status":"ACTIVE","kyc_status":"pending",
  "kyc_document":null,"created_at":"2026-09-18 17:23:42","balance":"0.00"},
 {"id":131,"customer_id":"VEV103","referral_code":"VEV2Z6LM","name":"Test Advocate",
  "email":"advocate@example.com","role":"advocate","status":"ACTIVE","kyc_status":"verified",
  "kyc_document":"uploads/kyc/kyc_131_1750000000.jpg","created_at":"2026-09-04 13:29:09","balance":"0.00"},
 {"id":120,"customer_id":"VEV090","name":"Older Submission","email":"older@example.com",
  "role":"customer","status":"ACTIVE","kyc_status":"rejected","kyc_document":null,
  "created_at":"2026-08-01 09:00:00","balance":"0.00"}
]}
''';

/// `customer/kyc.php?user_id=N` — the detail. Unfilled columns come back as
/// JSON null, which must not print as the string 'null'.
const _detailResponse = '''
{"status":"success","data":{"phone":"8940704388","address":null,"aadhar_no":null,
 "pan_no":null,"kyc_status":"pending","kyc_document":null,"bank_name":null,
 "account_no":null,"ifsc_code":null,"branch_name":null}}
''';

const _filledDetailResponse = '''
{"status":"success","data":{"phone":"9788086424","address":"12 Gandhi St, Chennai",
 "aadhar_no":"1234 5678 9012","pan_no":"ABCDE1234F","kyc_status":"pending",
 "kyc_document":"uploads/kyc/kyc_65_1750000001.jpg","bank_name":"HDFC Bank",
 "account_no":"50100123456789","ifsc_code":"HDFC0001234","branch_name":"T Nagar"}}
''';

List<IdentityRequest> _parseList(String raw) =>
    ((jsonDecode(raw) as Map<String, dynamic>)['data'] as List)
        .map((e) =>
            IdentityRequest.fromListJson((e as Map).cast<String, dynamic>()))
        .toList();

Map<String, dynamic> _data(String raw) =>
    ((jsonDecode(raw) as Map<String, dynamic>)['data'] as Map)
        .cast<String, dynamic>();

void main() {
  group('IdentityRequest.fromListJson', () {
    test('reads an admin/all_users.php row', () {
      final rows = _parseList(_listResponse);
      expect(rows, hasLength(3));

      final first = rows.first;
      expect(first.id, '136');
      expect(first.customerId, 'VEV104');
      expect(first.name, 'Test User');
      expect(first.email, 'test@example.com');
      expect(first.accountStatus, 'ACTIVE');
      expect(first.kycStatus, 'pending');
      expect(first.isPending, isTrue);
      expect(first.hasDocument, isFalse);
      expect(first.documentUrl, isNull);
      expect(first.submittedAt, DateTime(2026, 9, 18, 17, 23, 42));
      // Details are not in this payload, so the sheet knows to fetch them.
      expect(first.detailsLoaded, isFalse);
      expect(first.aadharNo, isNull);
    });

    test('classifies each status', () {
      final rows = _parseList(_listResponse);
      expect(rows[0].statusLabel, 'PENDING');
      expect(rows[1].statusLabel, 'VERIFIED');
      expect(rows[1].isVerified, isTrue);
      expect(rows[2].statusLabel, 'REJECTED');
      expect(rows[2].isRejected, isTrue);
    });

    test('treats an unset kyc_status as pending', () {
      // The column is a free-text varchar; a user who never submitted can hold
      // '', null, or a value written by some other flow.
      for (final raw in [null, '', '  ', 'unknown', 'PENDING']) {
        final r = IdentityRequest.fromListJson(
            {'id': 1, 'name': 'X', 'email': 'x@y.z', 'kyc_status': raw});
        expect(r.kycStatus, 'pending', reason: 'for ${raw.runtimeType} $raw');
      }
    });

    test('accepts the aliases the backend may store', () {
      expect(
        IdentityRequest.fromListJson(
                {'id': 1, 'name': 'X', 'email': '', 'kyc_status': 'APPROVED'})
            .kycStatus,
        'verified',
      );
      expect(
        IdentityRequest.fromListJson(
                {'id': 1, 'name': 'X', 'email': '', 'kyc_status': 'Declined'})
            .kycStatus,
        'rejected',
      );
    });

    test('falls back to Unknown for a blank name', () {
      final r = IdentityRequest.fromListJson(
          {'id': 9, 'name': '   ', 'email': 'a@b.c'});
      expect(r.name, 'Unknown');
      expect(r.initial, 'U');
    });

    test('resolves the document against the site root, not the API base', () {
      final verified = _parseList(_listResponse)[1];
      expect(verified.hasDocument, isTrue);
      // kyc_document is stored relative to the document root, so the URL must
      // not carry the '/api' segment.
      expect(verified.documentUrl, isNotNull);
      expect(
          verified.documentUrl, endsWith('uploads/kyc/kyc_131_1750000000.jpg'));
      expect(verified.documentUrl, isNot(contains('/api/')));
    });
  });

  group('withDetails', () {
    test('folds customer/kyc.php fields onto the list row', () {
      final base = _parseList(_listResponse).first;
      final detailed = base.withDetails(_data(_filledDetailResponse));

      // Identity from the list row is preserved.
      expect(detailed.id, base.id);
      expect(detailed.name, base.name);
      expect(detailed.customerId, 'VEV104');

      // Detail fields arrive.
      expect(detailed.phone, '9788086424');
      expect(detailed.address, '12 Gandhi St, Chennai');
      expect(detailed.aadharNo, '1234 5678 9012');
      expect(detailed.panNo, 'ABCDE1234F');
      expect(detailed.bankName, 'HDFC Bank');
      expect(detailed.accountNo, '50100123456789');
      expect(detailed.ifscCode, 'HDFC0001234');
      expect(detailed.branchName, 'T Nagar');
      expect(detailed.detailsLoaded, isTrue);

      // The detail endpoint's document path is fresher than the list's.
      expect(detailed.hasDocument, isTrue);
      expect(detailed.documentUrl, endsWith('kyc_65_1750000001.jpg'));
    });

    test('turns JSON nulls into null, never the string "null"', () {
      final detailed =
          _parseList(_listResponse).first.withDetails(_data(_detailResponse));

      expect(detailed.phone, '8940704388');
      expect(detailed.address, isNull);
      expect(detailed.aadharNo, isNull);
      expect(detailed.bankName, isNull);
      // This is what the review sheet prints — it must be a dash, not 'null'.
      expect(IdentityRequest.display(detailed.address), '—');
      expect(IdentityRequest.display(detailed.aadharNo), '—');
      expect(IdentityRequest.display(detailed.phone), '8940704388');
      expect(detailed.detailsLoaded, isTrue);
    });

    test('keeps the list document when the detail payload has none', () {
      final verified = _parseList(_listResponse)[1];
      final detailed = verified.withDetails(_data(_detailResponse));
      expect(detailed.kycDocument, 'uploads/kyc/kyc_131_1750000000.jpg');
    });
  });

  group('copyWithStatus', () {
    test('restamps a decision without losing loaded details', () {
      final detailed = _parseList(_listResponse)
          .first
          .withDetails(_data(_filledDetailResponse));
      final approved = detailed.copyWithStatus('verified');

      expect(approved.kycStatus, 'verified');
      expect(approved.isVerified, isTrue);
      expect(approved.isPending, isFalse);
      // Everything else survives, so the row can move between tabs in place.
      expect(approved.id, detailed.id);
      expect(approved.aadharNo, detailed.aadharNo);
      expect(approved.bankName, detailed.bankName);
      expect(approved.detailsLoaded, isTrue);
    });
  });

  group('IdentityFilter', () {
    test('slices the register the way the tabs do', () {
      final rows = _parseList(_listResponse);

      expect(rows.where(IdentityFilter.pending.matches), hasLength(1));
      expect(rows.where(IdentityFilter.verified.matches), hasLength(1));
      expect(rows.where(IdentityFilter.rejected.matches), hasLength(1));
      expect(rows.where(IdentityFilter.all.matches), hasLength(3));
    });

    test('wire names match the kyc_status values the column holds', () {
      expect(IdentityFilter.pending.wire, 'pending');
      expect(IdentityFilter.verified.wire, 'verified');
      expect(IdentityFilter.rejected.wire, 'rejected');
    });
  });
}
