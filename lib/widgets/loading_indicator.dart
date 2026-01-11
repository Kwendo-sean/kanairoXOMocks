import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;

  const LoadingIndicator({super.key, this.size = 40.0});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryRed),
          strokeWidth: 3.0,
        ),
      ),
    );
  }
}
