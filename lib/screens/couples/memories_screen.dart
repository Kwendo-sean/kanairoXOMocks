import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/services/couple_service.dart';
import 'package:kanairoxo/models/memory_model.dart' as memory_model;
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/screens/couples/add_memory_screen.dart';
import 'package:kanairoxo/screens/couples/memory_detail_screen.dart';
import 'dart:math' as math;

class MemoriesEnhancedScreen extends StatefulWidget {
  const MemoriesEnhancedScreen({super.key});

  @override
  State<MemoriesEnhancedScreen> createState() => _MemoriesEnhancedScreenState();
}

class _MemoriesEnhancedScreenState extends State<MemoriesEnhancedScreen> {
  final CoupleService _coupleService = CoupleService();
  List<memory_model.Memory> _memories = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    setState(() => _isLoading = true);
    try {
      final memories = await _coupleService.getMemories(type: _selectedFilter);
      setState(() {
        _memories = memories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text("Memories", style: AppTypography.screenTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_photo_alternate_outlined, color: context.textColor),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddMemoryScreen()),
            ).then((_) => _loadMemories()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _memories.isEmpty
                    ? _buildEmptyState()
                    : _buildPolaroidGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ["All", "Event", "Date", "Vibe", "Milestone"];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (ctx, i) {
          final isSel = _selectedFilter == filters[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filters[i]),
              selected: isSel,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedFilter = filters[i]);
                  _loadMemories();
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: Theme.of(context).cardColor,
              labelStyle: AppTypography.caption.copyWith(
                color: isSel ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              shape: StadiumBorder(side: BorderSide(color: AppColors.primary.withOpacity(0.2))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPolaroidGrid() {
    List<memory_model.Memory> leftCol = [];
    List<memory_model.Memory> rightCol = [];
    for (int i = 0; i < _memories.length; i++) {
      if (i.isEven) leftCol.add(_memories[i]);
      else rightCol.add(_memories[i]);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: leftCol.map((m) => _buildPolaroid(m)).toList())),
          Expanded(child: Column(children: rightCol.map((m) => _buildPolaroid(m)).toList())),
        ],
      ),
    );
  }

  Widget _buildPolaroid(memory_model.Memory memory) {
    final randomAngle = (math.Random().nextDouble() * 0.04) - 0.02;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MemoryDetailScreen(memory: memory)),
      ),
      child: Transform.rotate(
        angle: randomAngle,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 36),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 8, offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: CachedNetworkImage(
                  imageUrl: memory.photo ?? '',
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => Container(
                    color: AppColors.primary.withOpacity(0.05),
                    child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 28),
                  ),
                  errorWidget: (ctx, url, err) => Container(
                    color: AppColors.primary.withOpacity(0.05),
                    child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 28),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                memory.title,
                style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic),
                maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(memory.memoryDate),
                style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140, height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary.withOpacity(0.4), size: 32),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Your story starts here', style: AppTypography.labelMedium),
          const SizedBox(height: 6),
          Text('Share your first experience together', style: AppTypography.caption),
          const SizedBox(height: 20),
          LiquidGlassButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddMemoryScreen()),
            ).then((_) => _loadMemories()),
            child: Text('Add Memory', style: AppTypography.buttonText),
          ),
        ],
      ),
    );
  }
}
