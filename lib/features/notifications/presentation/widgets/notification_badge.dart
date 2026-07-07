import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({
    required this.child,
    required this.count,
    super.key,
  });

  final Widget child;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Badge(
      backgroundColor: Colors.red,
      smallSize: count > 9 ? null : 9,
      label: count > 9
          ? Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            )
          : null,
      child: child,
    );
  }
}
