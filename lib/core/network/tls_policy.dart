import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

/// Applies the app's TLS policy to [dio].
///
/// - **Release builds:** full certificate validation — no bypass, ever.
/// - **Debug/profile builds only:** tolerate a bad certificate for the exact
///   [allowedHost], so local testing is not blocked while the server's
///   certificate chain is being fixed.
///
/// This is a TRANSITIONAL measure shared by every Dio instance in the app
/// (main client, token refresh, retries) so they all behave identically. The
/// real fix is to install the full intermediate certificate chain on the API
/// server (see docs/audit/REMEDIATION_PLAN.md task 1.8); once that is verified,
/// delete this file and its call sites.
///
/// Uses an `is` check rather than a hard cast, so it is a safe no-op on
/// platforms (e.g. web) whose adapter is not an [IOHttpClientAdapter].
void applyTlsPolicy(Dio dio, {String? allowedHost}) {
  if (kReleaseMode) return;
  if (allowedHost == null || allowedHost.isEmpty) return;

  final adapter = dio.httpClientAdapter;
  if (adapter is! IOHttpClientAdapter) return;

  adapter.createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => host == allowedHost;
    return client;
  };
}
