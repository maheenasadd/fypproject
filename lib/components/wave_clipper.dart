// lib/components/toggle_option.dart
import 'package:flutter/material.dart';

class ToggleOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const ToggleOption({
    Key? key,
    required this.icon,
    required this.label,
    this.isActive = false,
    required Null Function() onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: isActive ? Colors.redAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        Switch(
          value: isActive,
          onChanged: (value) {
            // Handle toggle switch logic here
          },
          activeColor: Colors.redAccent,
        ),
      ],
    );
  }
}
