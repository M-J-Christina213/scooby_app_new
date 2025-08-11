
import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
  const SuccessDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.check, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 12),
            const Text('Accepted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('The booking has been accepted and the pet owner has been notified', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
          ]),
        ),
      ),
    );
  }
}