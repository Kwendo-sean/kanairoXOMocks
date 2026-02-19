import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BucketListCard extends StatefulWidget {
  final List<Map<String, dynamic>> aspirations;

  const BucketListCard({super.key, required this.aspirations});

  @override
  State<BucketListCard> createState() => _BucketListCardState();
}

class _BucketListCardState extends State<BucketListCard> {
  
  void _toggleCheckbox(int index) {
    setState(() {
      widget.aspirations[index]['isChecked'] = !widget.aspirations[index]['isChecked'];
    });
  }

  @override
  Widget build(BuildContext context) {
    // Separate lists for checked and unchecked items
    final checkedItems = widget.aspirations.where((item) => item['isChecked'] == true).toList();
    final uncheckedItems = widget.aspirations.where((item) => item['isChecked'] == false).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: const BorderSide(color: AppConstants.lightGray, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const PhosphorIcon(PhosphorIcons.listChecks, color: AppConstants.primaryRed, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Our Bucket List',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Unchecked items first
            ...uncheckedItems.map((item) {
              final index = widget.aspirations.indexOf(item);
              return _buildBucketListItem(title: item['title'], isChecked: item['isChecked'], onToggle: () => _toggleCheckbox(index));
            }).toList(),
             if (checkedItems.isNotEmpty && uncheckedItems.isNotEmpty) const Divider(height: 24),
            // Checked items last
            ...checkedItems.map((item) {
              final index = widget.aspirations.indexOf(item);
              return _buildBucketListItem(title: item['title'], isChecked: item['isChecked'], onToggle: () => _toggleCheckbox(index));
            }).toList(),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('View All Items', style: TextStyle(color: AppConstants.primaryRed)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBucketListItem({required String title, required bool isChecked, required VoidCallback onToggle}) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Icon(
              isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: isChecked ? AppConstants.primaryRed : AppConstants.secondaryGray,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                  color: isChecked ? AppConstants.secondaryGray : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
