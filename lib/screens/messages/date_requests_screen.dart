import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/date_request_model.dart';
import '../../providers/date_plan_provider.dart';

class DateRequestsScreen extends StatefulWidget {
  const DateRequestsScreen({super.key});

  @override
  State<DateRequestsScreen> createState() => _DateRequestsScreenState();
}

class _DateRequestsScreenState extends State<DateRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, bool> _processingMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatePlanProvider>().fetchRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _respond(String requestId, String action) async {
    setState(() => _processingMap[requestId] = true);
    
    try {
      await context.read<DatePlanProvider>().respondToRequest(requestId, action);
      
      if (!mounted) return;
      setState(() => _processingMap[requestId] = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'accepted' ? 'Date request accepted!' : 'Date request declined'),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _processingMap[requestId] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _pay(String requestId) async {
    final phoneController = TextEditingController();
    final theme = Theme.of(context);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        surfaceTintColor: Colors.transparent,
        title: Text('Pay Reservation', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter M-Pesa number to pay KES 500 reservation fee.', style: GoogleFonts.dmSans(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: '07XXXXXXXX',
                hintStyle: TextStyle(color: theme.hintColor),
                filled: true,
                fillColor: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: theme.hintColor))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.themePrimary(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true && phoneController.text.isNotEmpty) {
      setState(() => _processingMap[requestId] = true);
      try {
        await context.read<DatePlanProvider>().payForRequest(requestId, phoneController.text, 500);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment initiated! Check your phone for M-Pesa prompt.')),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        if (mounted) setState(() => _processingMap[requestId] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Date Requests",
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.themePrimary(context),
          indicatorWeight: 2,
          labelColor: AppColors.themePrimary(context),
          unselectedLabelColor: theme.hintColor,
          labelStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w400),
          tabs: const [
            Tab(text: "Received"),
            Tab(text: "Sent"),
          ],
        ),
      ),
      body: Consumer<DatePlanProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsList(provider.receivedRequests, provider.isLoading, true),
              _buildRequestsList(provider.sentRequests, provider.isLoading, false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(List<DateRequestModel> requests, bool isLoading, bool isReceived) {
    if (isLoading && requests.isEmpty) {
      return _buildShimmerList();
    }
    
    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return _RequestCard(
          request: requests[index],
          isReceived: isReceived,
          onRespond: _respond,
          onPay: _pay,
          isProcessing: _processingMap[requests[index].id] ?? false,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 64, color: theme.dividerColor),
          const SizedBox(height: 20),
          Text(
            "No date requests yet",
            style: TextStyle(fontFamily: 'DM Sans', fontSize: 17, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              "When someone plans a date with you, it will appear here",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: theme.hintColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isDark ? Colors.white10 : Colors.grey[200]!,
        highlightColor: isDark ? Colors.white24 : Colors.grey[50]!,
        child: Container(
          height: 240,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final DateRequestModel request;
  final bool isReceived;
  final Function(String, String)? onRespond;
  final Function(String)? onPay;
  final bool isProcessing;

  const _RequestCard({
    required this.request,
    required this.isReceived,
    this.onRespond,
    this.onPay,
    this.isProcessing = false,
  });

  String _timeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 0) return '${duration.inDays}d ago';
    if (duration.inHours > 0) return '${duration.inHours}h ago';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final person = isReceived ? request.sender : request.receiver;
    final venuePhoto = request.venue.coverImage;
    final hasVenuePhoto = venuePhoto != null && venuePhoto.isNotEmpty;
    final personPhoto = person.photo;
    final hasPersonPhoto = personPhoto != null && personPhoto.isNotEmpty;
    final dateStr = request.preferredDate != null 
        ? DateFormat('EEE, MMM d @ h:mm a').format(request.preferredDate!)
        : 'Date not set';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                hasVenuePhoto
                  ? CachedNetworkImage(
                      imageUrl: venuePhoto,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildVenuePlaceholder(context),
                    )
                  : _buildVenuePlaceholder(context),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Text(
                    request.venue.name,
                    style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: request.status == 'accepted' ? Colors.green.shade600 : request.status == 'declined' ? Colors.red.shade600 : Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      request.status.toUpperCase(),
                      style: const TextStyle(fontFamily: 'DM Sans', color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.dividerColor.withOpacity(0.1),
                      backgroundImage: hasPersonPhoto ? NetworkImage(personPhoto) : null,
                      child: !hasPersonPhoto 
                          ? Text(person.name.isNotEmpty ? person.name[0] : '?', style: GoogleFonts.cormorantGaramond(fontSize: 20, color: AppColors.themePrimary(context), fontWeight: FontWeight.bold))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isReceived ? person.name : 'Date planned for ${person.name}',
                            style: TextStyle(fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          ),
                          if (isReceived)
                            Text("wants to take you out", style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: theme.hintColor)),
                        ],
                      ),
                    ),
                    Text(_timeAgo(request.createdAt), style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: theme.hintColor.withOpacity(0.7))),
                  ],
                ),
                if (request.message != null && request.message!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1))
                    ),
                    child: Text('"${request.message}"', style: GoogleFonts.dmSans(fontStyle: FontStyle.italic, fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.8))),
                  ),
                ],
                const SizedBox(height: 16),
                Divider(color: theme.dividerColor.withOpacity(0.1), height: 1),
                const SizedBox(height: 16),
                _buildDetailRow(context, Icons.calendar_today_rounded, "Date", dateStr),
                const SizedBox(height: 10),
                _buildDetailRow(context, Icons.local_fire_department_outlined, "Vibe", request.vibe),
                const SizedBox(height: 10),
                _buildDetailRow(context, Icons.dinner_dining_outlined, "Package", request.package.name),
                const SizedBox(height: 10),
                _buildDetailRow(context, Icons.wallet_outlined, "Budget", "KES ${request.budget}"),
                
                if (isReceived && request.status == 'pending') ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isProcessing ? null : () => onRespond?.call(request.id, 'declined'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.dividerColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text("Decline", style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.bold, color: theme.hintColor)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isProcessing ? null : () => onRespond?.call(request.id, 'accepted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.themePrimary(context),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: isProcessing 
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text("Accept", style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ] else if (!isReceived && request.status == 'accepted') ...[
                  const SizedBox(height: 20),
                  if (request.paymentReference != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(32), 
                        border: Border.all(color: Colors.green.withOpacity(0.3))
                      ),
                      child: Column(
                        children: [
                          const Text("Booking Confirmed", style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          const SizedBox(height: 2),
                          Text("Receipt: ${request.paymentReference}", style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: Color(0xFF2E7D32))),
                        ],
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: isProcessing ? null : () => onPay?.call(request.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        elevation: 0,
                      ),
                      child: isProcessing 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Pay Reservation — KES 500", style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenuePlaceholder(BuildContext context) {
    return Container(
      height: 140,
      color: Theme.of(context).dividerColor.withOpacity(0.1),
      child: Center(child: Icon(Icons.restaurant_outlined, color: AppColors.themePrimary(context).withOpacity(0.5), size: 40)),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.themePrimary(context)),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: theme.hintColor, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
