import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Thin wrapper around the ticket-purchase + moment-export endpoints.
///
/// The existing ticket_purchase_screen.dart still inlines the single
/// purchase call. Anything new should go through this service so we
/// have one place to evolve the contract.
class TicketsService {
  final ApiClient _api = ApiClient();

  // ─── Single purchase (existing, exposed here for new callers) ──────

  Future<Map<String, dynamic>> purchaseTicket({
    required String eventId,
    String? phoneNumber,
    String? pricingTierId,
    int quantity = 1,
    String? referredByUserId,
  }) async {
    final body = <String, dynamic>{
      'quantity': quantity,
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
      if (pricingTierId != null && pricingTierId.isNotEmpty) 'pricing_tier_id': pricingTierId,
      if (referredByUserId != null && referredByUserId.isNotEmpty) 'referred_by_user_id': referredByUserId,
    };
    final response = await _api.post('api/v1/tickets/purchase/$eventId/', body);
    return response is Map ? Map<String, dynamic>.from(response) : {};
  }

  // ─── Group purchase ────────────────────────────────────────────────

  /// Buy N tickets for N recipients in a single M-Pesa STK push.
  /// Backend creates the tickets owned by the buyer with each
  /// recipient's email in metadata, sends the email to that
  /// recipient on payment confirmation.
  Future<Map<String, dynamic>> groupPurchase({
    required String eventId,
    required String phoneNumber,
    required List<Map<String, String>> recipients,   // [{email, name}, ...]
    String? pricingTierId,
    String message = '',
  }) async {
    final body = <String, dynamic>{
      'phone_number': phoneNumber,
      'recipients': recipients,
      'message': message,
      if (pricingTierId != null && pricingTierId.isNotEmpty)
        'pricing_tier_id': pricingTierId,
    };
    final response = await _api.post('api/v1/tickets/group-purchase/$eventId/', body);
    return response is Map ? Map<String, dynamic>.from(response) : {};
  }

  // ─── Polling status ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> ticketStatus(String ticketId) async {
    final response = await _api.get('api/v1/tickets/$ticketId/status/');
    return response is Map ? Map<String, dynamic>.from(response) : {};
  }

  // ─── Moment exports (multi-format share sheet) ─────────────────────

  /// URL for an image of a single moment in the requested format.
  /// The Flutter app fetches the bytes when the user picks save/share.
  String momentExportUrl(String momentId, {String format = 'polaroid'}) {
    final base = _api.dio.options.baseUrl;
    return '${base}api/v1/moments/$momentId/export/?format=$format';
  }

  /// URL for a grid of the user's recent moments. count = 4 or 9.
  String momentsGridUrl({int count = 4}) {
    final base = _api.dio.options.baseUrl;
    return '${base}api/v1/moments/exports/grid/?count=$count';
  }
}
