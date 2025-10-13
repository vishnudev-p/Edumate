import 'package:flutter/material.dart';

class ConnectionStatus extends StatelessWidget {
  final bool isOnline;
  final String? connectionType;

  const ConnectionStatus({
    super.key,
    required this.isOnline,
    this.connectionType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline 
            ? const Color(0xFF1A2A1A) 
            : const Color(0xFF2A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline 
              ? const Color(0xFF10A37F) 
              : const Color(0xFFFF6B6B),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: isOnline 
                ? const Color(0xFF10A37F) 
                : const Color(0xFFFF6B6B),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: isOnline 
                  ? const Color(0xFF10A37F) 
                  : const Color(0xFFFF6B6B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (connectionType != null) ...[
            const SizedBox(width: 4),
            Text(
              '($connectionType)',
              style: TextStyle(
                color: isOnline 
                    ? const Color(0xFF10A37F) 
                    : const Color(0xFFFF6B6B),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
