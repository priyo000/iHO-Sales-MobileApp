import 'package:flutter/material.dart';

class CustomerStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final IconData subicon;
  final Color subcolor;

  const CustomerStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtext,
    required this.subicon,
    required this.subcolor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(subicon, size: 12, color: subcolor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  subtext,
                  style: TextStyle(
                    color: subcolor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
