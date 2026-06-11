import 'package:flutter/material.dart';
import 'package:smartsolar/utils/theme.dart';

class RelayControl extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isOn;
  final bool isAutoMode;
  final IconData icon;
  final Function(bool) onToggle;
  final Function(bool) onAutoModeChange;

  const RelayControl({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isOn,
    required this.isAutoMode,
    required this.icon,
    required this.onToggle,
    required this.onAutoModeChange,
  });

  @override
  State<RelayControl> createState() => _RelayControlState();
}

class _RelayControlState extends State<RelayControl> {
  late bool isAutoMode;

  @override
  void initState() {
    super.initState();
    isAutoMode = widget.isAutoMode;
  }

  @override
  void didUpdateWidget(RelayControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAutoMode != widget.isAutoMode) {
      isAutoMode = widget.isAutoMode;
    }
  }

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
                child: Icon(widget.icon, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Text('Auto', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Switch(
                    value: isAutoMode,
                    onChanged: (value) {
                      setState(() => isAutoMode = value);
                      widget.onAutoModeChange(value);
                    },
                    activeThumbColor: AppTheme.primary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  'Turn ON',
                  widget.isOn,
                  isAutoMode,
                  AppTheme.success,
                  () => widget.onToggle(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildButton(
                  'Turn OFF',
                  !widget.isOn,
                  isAutoMode,
                  AppTheme.error,
                  () => widget.onToggle(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isOn
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isOn ? Icons.power : Icons.power_off,
                    size: 16,
                    color: widget.isOn ? AppTheme.success : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isOn ? 'RELAY ON' : 'RELAY OFF',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.isOn ? AppTheme.success : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    String text,
    bool isActive,
    bool isDisabled,
    Color color,
    VoidCallback onPressed,
  ) {
    final isEnabled = !isDisabled && isActive;

    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        disabledBackgroundColor: Colors.grey.withValues(alpha: 0.1),
        disabledForegroundColor: Colors.grey,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(text),
    );
  }
}
