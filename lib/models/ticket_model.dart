import 'package:intl/intl.dart';

class TicketModel {
  final String id;
  final TicketEvent event;
  final String ticketType; // 'qr' | 'invitation' | 'polaroid'
  final String status;
  final int quantity;
  final String totalAmount;
  final String qrHash;
  final String? pdfUrl;
  final DateTime createdAt;

  TicketModel({
    required this.id,
    required this.event,
    required this.ticketType,
    required this.status,
    required this.quantity,
    required this.totalAmount,
    required this.qrHash,
    this.pdfUrl,
    required this.createdAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id']?.toString() ?? '',
      event: TicketEvent.fromJson(json['event']),
      ticketType: json['design_style'] ?? json['ticket_type'] ?? 'qr',
      status: json['status'] ?? 'confirmed',
      quantity: json['quantity'] ?? 1,
      totalAmount: json['total_amount']?.toString() ?? '0',
      qrHash: json['qr_hash']?.toString() ?? json['short_code']?.toString() ?? json['id']?.toString() ?? '',
      pdfUrl: json['pdf_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

class TicketEvent {
  final String id;
  final String title;
  final String? coverImage;
  final String date;
  final String? endDate;
  final String venue;
  final String neighborhood;

  TicketEvent({
    required this.id,
    required this.title,
    this.coverImage,
    required this.date,
    this.endDate,
    required this.venue,
    required this.neighborhood,
  });

  factory TicketEvent.fromJson(Map<String, dynamic> json) {
    return TicketEvent(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      coverImage: json['cover_image'] ?? json['image_url'],
      date: json['start_datetime']?.toString() ?? json['date']?.toString() ?? '',
      endDate: (json['end_datetime'] ?? json['end_date'])?.toString(),
      venue: json['venue_name']?.toString() ?? json['venue']?.toString() ?? '',
      neighborhood: json['neighborhood']?.toString() ?? '',
    );
  }

  DateTime? get startDateTime {
    try { return DateTime.parse(date); } catch (_) { return null; }
  }

  DateTime? get endDateTime {
    if (endDate == null || endDate!.isEmpty) return null;
    try { return DateTime.parse(endDate!); } catch (_) { return null; }
  }

  /// 'upcoming' / 'live' / 'past' / 'unknown'
  String get state {
    final s = startDateTime;
    final e = endDateTime;
    final now = DateTime.now().toUtc();
    if (s == null) return 'unknown';
    final sUtc = s.toUtc();
    final eUtc = e?.toUtc() ?? sUtc.add(const Duration(hours: 3));
    if (now.isBefore(sUtc)) return 'upcoming';
    if (now.isAfter(eUtc)) return 'past';
    return 'live';
  }

  String get formattedDate {
    final dt = startDateTime;
    return dt == null ? date : DateFormat('EEE, MMM d, yyyy').format(dt);
  }

  String get formattedTime {
    final dt = startDateTime;
    return dt == null ? '' : DateFormat('h:mm a').format(dt);
  }
}
