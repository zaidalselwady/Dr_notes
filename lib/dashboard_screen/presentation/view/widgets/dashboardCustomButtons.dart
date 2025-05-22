import 'package:flutter/material.dart';

class DashboardButton extends StatelessWidget {
  final String imageName;
  final String label;
  final VoidCallback onTap;
  final bool isDoctor;

  const DashboardButton({
    super.key,
    required this.imageName,
    required this.label,
    required this.onTap,
    required this.isDoctor,
  });

  @override
  Widget build(BuildContext context) {
    showMessage() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("🚫 No access to this feature"),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: isDoctor ? onTap : showMessage,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Image.asset(
                  'assets/$imageName', // put your image path here
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF040A17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
