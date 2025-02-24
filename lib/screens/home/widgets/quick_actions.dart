import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({Key? key}) : super(key: key);

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildQuickActionButton(
          icon: Icons.phone_in_talk,
          label: 'Call\nSponsor',
          color: Colors.green[700]!,
          onPressed: () {
            // TODO: Implement call sponsor
          },
        ),
        _buildQuickActionButton(
          icon: Icons.edit_note,
          label: 'Daily\nJournal',
          color: Colors.purple[700]!,
          onPressed: () {
            // TODO: Implement journal
          },
        ),
        _buildQuickActionButton(
          icon: Icons.people_alt,
          label: 'Support\nGroup',
          color: Colors.orange[700]!,
          onPressed: () {
            // TODO: Implement community
          },
        ),
      ],
    );
  }
}
