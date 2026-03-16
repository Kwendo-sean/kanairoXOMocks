import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_typography.dart';
import '../models/discovery_models.dart';
import '../providers/connection_provider.dart';
import '../providers/notification_provider.dart';
import 'liquid_glass_button.dart';
import 'safe_network_image.dart';

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
        setState(() {
          _connectionStatus = 'pending_sent';
        });

        await notificationProvider.refreshNotifications();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection request sent!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        widget.onConnectionSuccess?.call();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send request: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _getConnectButtonText() {
    if (_isProcessing) return 'Sending...';
    switch (_connectionStatus) {
      case 'pending_sent': return 'Request Sent';
      case 'mutual': return 'Connected';
      case 'pending': return 'Accept';
      default: return 'Connect';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.48,
          decoration: BoxDecoration(
            borderRadius: AppRadius.lg,
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.lg,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background photo
                SafeNetworkImage(
                  url: widget.profile.profilePhotoUrl,
                  fit: BoxFit.cover,
                ),

                // Bottom gradient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.45, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),
                ),

                // Name + match badge
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.profile.fullName,
                                    style: AppTypography.displayMedium.copyWith(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.profile.neighborhood.isNotEmpty)
                                    Text(
                                      widget.profile.neighborhood,
                                      style: AppTypography.caption.copyWith(color: Colors.white70),
                                    ),
                                ],
                              ),
                            ),
                            
                            // Match badge
                            ClipRRect(
                              borderRadius: AppRadius.full,
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.85),
                                    borderRadius: AppRadius.full,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${widget.profile.matchScore}%',
                                        style: AppTypography.buttonText.copyWith(fontSize: 13),
                                      ),
                                      Text(
                                        'Match',
                                        style: AppTypography.caption.copyWith(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Action buttons row below card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LiquidGlassButton(
                variant: LiquidButtonVariant.outline,
                size: LiquidButtonSize.sm,
                onPressed: widget.onSave,
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_border, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('Save', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
              LiquidGlassButton(
                size: LiquidButtonSize.lg,
                onPressed: _handleConnect,
                child: Row(
                  children: [
                    Icon(
                      _connectionStatus == 'mutual' ? Icons.check_circle : Icons.favorite,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(_getConnectButtonText(), style: AppTypography.buttonText),
                  ],
                ),
              ),
              LiquidGlassButton(
                variant: LiquidButtonVariant.ghost,
                size: LiquidButtonSize.sm,
                onPressed: widget.onNotNow,
                child: Row(
                  children: [
                    const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('Not Now', style: AppTypography.labelMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
