import 'package:flutter/material.dart';

enum AdminStatusType {
  pending,
  verified,
  active,
  banned,
  approved,
  rejected,
  waiting,
}

class AdminStatusChip extends StatelessWidget {
  final AdminStatusType type;
  final String? customText;

  const AdminStatusChip({
    super.key,
    required this.type,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getStatusConfig(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        customText ?? config.text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: config.color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(AdminStatusType type) {
    switch (type) {
      case AdminStatusType.pending:
        return _StatusConfig('PENDING', Colors.orange);
      case AdminStatusType.verified:
        return _StatusConfig('VERIFIED', Colors.green);
      case AdminStatusType.active:
        return _StatusConfig('ACTIVE', Colors.green);
      case AdminStatusType.banned:
        return _StatusConfig('BANNED', Colors.red);
      case AdminStatusType.approved:
        return _StatusConfig('APPROVED', Colors.green);
      case AdminStatusType.rejected:
        return _StatusConfig('REJECTED', Colors.red);
      case AdminStatusType.waiting:
        return _StatusConfig('WAITING', Colors.orange);
    }
  }
}

class _StatusConfig {
  final String text;
  final Color color;

  _StatusConfig(this.text, this.color);
}