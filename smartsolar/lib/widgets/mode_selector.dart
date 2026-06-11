import 'package:flutter/material.dart';
import 'package:smartsolar/utils/theme.dart';

class ModeSelector extends StatelessWidget {
  final String currentMode;
  final Function(String) onModeSelected;

  const ModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operation Mode',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Select system operating mode',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildModeButton(
                context,
                'HOME',
                Icons.home,
                'Balanced',
                AppTheme.primary,
              ),
              const SizedBox(width: 8),
              _buildModeButton(
                context,
                'SAVING',
                Icons.energy_savings_leaf,
                'Max Solar',
                AppTheme.warning,
              ),
              const SizedBox(width: 8),
              _buildModeButton(
                context,
                'PERFORMANCE',
                Icons.speed,
                'Max Power',
                AppTheme.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    String mode,
    IconData icon,
    String label,
    Color color,
  ) {
    final isSelected = currentMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => onModeSelected(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
              const SizedBox(height: 8),
              Text(
                mode,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected
                      ? color.withValues(alpha: 0.8)
                      : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
