// lib/widgets/profile_card.dart - UPDATED
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/discovery_models.dart';
import '../providers/connection_provider.dart';
import '../providers/notification_provider.dart';

class ProfileCard extends StatefulWidget {
  final DiscoveryProfile profile;
  final double compatibilityScore;
  final String compatibilityText;
  final String explanation;
  final VoidCallback onNotNow;
  final VoidCallback onSave;
  final VoidCallback? onConnectionSuccess;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.compatibilityScore,
    required this.compatibilityText,
    required this.explanation,
    required this.onNotNow,
    required this.onSave,
    this.onConnectionSuccess,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  bool _isProcessing = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
    final result = await connectionProvider.checkConnectionStatus(widget.profile.userId);

    if (result['success'] == true && result['data'] != null) {
      final data = result['data'] as Map<String, dynamic>;
      if (data['exists'] == true) {
        setState(() {
          _connectionStatus = data['connection_type'];
        });
      } else {
        setState(() {
          _connectionStatus = 'none';
        });
      }
    }
  }

  Future<void> _handleConnect() async {
    if (_isProcessing || _connectionStatus == 'pending_sent' || _connectionStatus == 'mutual') {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

      final result = await connectionProvider.quickConnect(widget.profile.userId);

      if (result['success'] == true) {
        // Update local status
        setState(() {
          _connectionStatus = 'pending_sent';
        });

        // Refresh notifications
        await notificationProvider.refreshNotifications();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Connection request sent!'),
            backgroundColor: Colors.green,
          ),
        );

        // Call success callback if provided
        widget.onConnectionSuccess?.call();
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _getConnectButtonText() {
    if (_isProcessing) return 'Sending...';

    switch (_connectionStatus) {
      case 'pending_sent':
        return 'Request Sent';
      case 'mutual':
        return 'Connected';
      case 'pending':
        return 'Accept Request';
      case 'rejected':
        return 'Try Again';
      default:
        return 'Connect';
    }
  }

  Color _getConnectButtonColor(ThemeData theme) {
    if (_isProcessing) return Colors.grey;

    switch (_connectionStatus) {
      case 'pending_sent':
        return Colors.orange;
      case 'mutual':
        return Colors.green;
      case 'pending':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

  IconData _getConnectButtonIcon() {
    if (_isProcessing) return Icons.more_horiz;

    switch (_connectionStatus) {
      case 'pending_sent':
        return Icons.hourglass_top;
      case 'mutual':
        return Icons.check_circle;
      case 'pending':
        return Icons.person_add;
      case 'rejected':
        return Icons.replay;
      default:
        return Icons.favorite;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Image Section (same as before)
                Container(
                  height: 350,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                    image: DecorationImage(
                      image: _getImageProvider(widget.profile.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(25),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),

                      // Online indicator
                      if (widget.profile.isOnline)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // Profile info at bottom of image
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.profile.displayName,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Compatibility badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCompatibilityColor(widget.compatibilityScore)
                                        .withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${widget.compatibilityScore.toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        widget.compatibilityText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            if (widget.profile.age != null || widget.profile.gender != null)
                              Text(
                                '${widget.profile.age ?? ''} ${widget.profile.gender ?? ''}'.trim(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),

                            if (widget.profile.location != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 16, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.profile.location!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Details Section (same as before)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bio
                          if (widget.profile.bio != null && widget.profile.bio!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                widget.profile.bio!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ),

                          // Intents
                          if (widget.profile.primaryIntent != null || widget.profile.secondaryIntent != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (widget.profile.primaryIntent != null)
                                    _buildIntentChip(widget.profile.primaryIntent!),
                                  if (widget.profile.secondaryIntent != null)
                                    _buildIntentChip(widget.profile.secondaryIntent!),
                                ],
                              ),
                            ),

                          // Interests
                          if (widget.profile.interests.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Interests',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final interest in widget.profile.interests.take(8))
                                        _buildInterestChip(interest),
                                      if (widget.profile.interests.length > 8)
                                        _buildInterestChip(
                                            '+${widget.profile.interests.length - 8} more'),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          // Moods
                          if (widget.profile.currentMoods != null && widget.profile.currentMoods!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current Mood',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final mood in widget.profile.currentMoods!.take(3))
                                        _buildMoodChip(mood),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          // Explanation
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.insights,
                                  color: Colors.blue[700],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.explanation,
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // Action Buttons - UPDATED
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Save Button
                      _buildActionButton(
                        icon: Icons.bookmark_border,
                        label: 'Save',
                        color: Colors.blue,
                        onPressed: widget.onSave,
                        isProcessing: _isProcessing,
                      ),

                      // Connect Button - UPDATED
                      _buildActionButton(
                        icon: _getConnectButtonIcon(),
                        label: _getConnectButtonText(),
                        color: _getConnectButtonColor(theme),
                        onPressed: _handleConnect,
                        isPrimary: _connectionStatus != 'pending_sent' && _connectionStatus != 'mutual',
                        isProcessing: _isProcessing,
                        isDisabled: _connectionStatus == 'pending_sent' || _connectionStatus == 'mutual',
                      ),

                      // Not Now Button
                      _buildActionButton(
                        icon: Icons.close,
                        label: 'Not Now',
                        color: Colors.grey,
                        onPressed: widget.onNotNow,
                        isProcessing: _isProcessing,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_isProcessing)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntentChip(String intent) {
    return Chip(
      label: Text('🎯 $intent'),
      backgroundColor: Colors.orange[100],
      labelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.orange[900],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  Widget _buildInterestChip(String interest) {
    return Chip(
      label: Text(interest),
      backgroundColor: Colors.green[50],
      labelStyle: TextStyle(
        color: Colors.green[900],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  Widget _buildMoodChip(String mood) {
    return Chip(
      label: Text('😊 $mood'),
      backgroundColor: Colors.purple[50],
      labelStyle: TextStyle(
        color: Colors.purple[900],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isProcessing = false,
    bool isDisabled = false,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isPrimary ? color : color.withOpacity(isDisabled ? 0.3 : 0.1),
            shape: BoxShape.circle,
            boxShadow: isPrimary && !isProcessing && !isDisabled
                ? [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: IconButton(
            onPressed: isProcessing || isDisabled ? null : onPressed,
            icon: isProcessing
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPrimary ? Colors.white : color,
                ),
              ),
            )
                : Icon(
              icon,
              color: isPrimary ? Colors.white : color,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getCompatibilityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    } else {
      return NetworkImage(imageUrl);
    }
  }
}