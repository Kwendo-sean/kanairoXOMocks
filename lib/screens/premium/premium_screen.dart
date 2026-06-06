import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/models/subscription_models.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final ApiClient apiClient = ApiClient();
  List<SubscriptionPlan> _plans = [];
  UserSubscription? _mySub;
  bool _loading = true;
  SubscriptionPlan? _selectedPlan;
  final TextEditingController _phoneController = TextEditingController();
  Timer? _pollTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        apiClient.get('api/v1/subscriptions/plans/'),
        apiClient.get('api/v1/subscriptions/me/'),
      ]);
      
      setState(() {
        _plans = (results[0]['plans'] as List).map((p) => SubscriptionPlan.fromJson(p)).toList();
        _mySub = UserSubscription.fromJson(results[1]);
        if (_plans.isNotEmpty) _selectedPlan = _plans.first;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _startSubscription() async {
    if (_selectedPlan == null || _phoneController.text.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final response = await apiClient.post('api/v1/subscriptions/subscribe/', {
        'plan_id': _selectedPlan!.id,
        'phone_number': _phoneController.text,
      });

      if (response['status'] == 'payment_initiated') {
        _startPolling();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _startPolling() {
    int attempts = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      if (attempts > 20) { // Max 60s
        timer.cancel();
        setState(() => _isProcessing = false);
        return;
      }

      try {
        final status = await apiClient.get('api/v1/subscriptions/me/');
        if (status['is_premium'] == true) {
          timer.cancel();
          setState(() {
            _mySub = UserSubscription.fromJson(status);
            _isProcessing = false;
          });
          _showSuccess();
        }
      } catch (_) {}
    });
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Welcome to Premium!', style: TextStyle(color: Colors.white)),
        content: const Text('Your KanairoXO+ subscription is now active.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Great!')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            child: Column(
              children: [
                _buildHero(),
                _buildFeatures(),
                _buildPlanPicker(),
                _buildCheckout(),
              ],
            ),
          ),
    );
  }

  Widget _buildHero() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [AppConstants.primaryRed.withOpacity(0.8), Colors.black],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt, size: 80, color: Colors.amber),
          Text('KanairoXO+', style: AppTypography.displayLarge.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text('Real connections, real perks', style: AppTypography.bodyLarge.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    if (_plans.isEmpty) return const SizedBox.shrink();
    final allFeatures = _plans.first.features;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: allFeatures.length,
        itemBuilder: (context, index) => Container(
          width: 150,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.amber, size: 20),
              const SizedBox(height: 8),
              Text(allFeatures[index], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanPicker() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: _plans.map((plan) {
          final isSelected = _selectedPlan?.id == plan.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedPlan = plan),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? AppConstants.primaryRed.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppConstants.primaryRed : Colors.white.withOpacity(0.1), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(plan.interval, style: TextStyle(color: Colors.white.withOpacity(0.5))),
                    ],
                  ),
                  Text('KES ${plan.price}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCheckout() {
    if (_mySub?.isPremium == true) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text('You are already a Premium member!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _phoneController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'M-Pesa Number (07...)',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          LiquidGlassButton(
            onPressed: _isProcessing ? null : _startSubscription,
            width: double.infinity,
            child: _isProcessing 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Start Premium'),
          ),
          const SizedBox(height: 12),
          Text('Secured payment via M-Pesa', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
