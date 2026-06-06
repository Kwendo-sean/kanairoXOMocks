import 'package:intl/intl.dart';

class TicketModel {
  final int id;
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
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      event: TicketEvent.fromJson(json['event']),
      ticketType: json['ticket_type'] ?? 'qr',
      status: json['status'] ?? 'confirmed',
      quantity: json['quantity'] ?? 1,
      totalAmount: json['total_amount']?.toString() ?? '0',
      qrHash: json['qr_hash'] ?? '',
      pdfUrl: json['pdf_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

class TicketEvent {
  final int id;
  final String title;
  final String? coverImage;
  final String date;
  final String venue;
  final String neighborhood;

  TicketEvent({
    required this.id,
    required this.title,
    this.coverImage,
    required this.date,
    required this.venue,
    required this.neighborhood,
  });

  factory TicketEvent.fromJson(Map<String, dynamic> json) {
    return TicketEvent(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      coverImage: json['cover_image'] ?? json['image_url'],
      date: json['date'] ?? '',
      venue: json['venue'] ?? '',
      neighborhood: json['neighborhood'] ?? '',
    );
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('EEE, MMM d, yyyy').format(dt);
    } catch (e) {
      return date;
    }
  }

  String get formattedTime {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('h:mm a').format(dt);
    } catch (e) {
      return '';
    }
  }
}
