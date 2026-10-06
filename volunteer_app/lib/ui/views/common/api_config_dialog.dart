import 'package:flutter/material.dart';
import 'package:volunteer_app/core/constants/api_constants.dart';

class ApiConfigDialog extends StatefulWidget {
  const ApiConfigDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const ApiConfigDialog(),
    );
  }

  @override
  State<ApiConfigDialog> createState() => _ApiConfigDialogState();
}

class _ApiConfigDialogState extends State<ApiConfigDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ApiConstants.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings_ethernet, color: Color(0xFF00695C)),
          SizedBox(width: 8),
          Text('Server Configuration', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select or specify your Backend REST API host address:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'e.g. http://10.0.2.2:3000',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ActionChip(
                  label: const Text('Android (10.0.2.2)'),
                  onPressed: () {
                    _controller.text = 'http://10.0.2.2:3000';
                  },
                ),
                ActionChip(
                  label: const Text('Web/Desktop (localhost)'),
                  onPressed: () {
                    _controller.text = 'http://localhost:3000';
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_controller.text.isNotEmpty) {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              await ApiConstants.setBaseUrl(_controller.text.trim());
              nav.pop();
              messenger.showSnackBar(
                SnackBar(content: Text('API Base URL updated to: ${ApiConstants.baseUrl}')),
              );
            }
          },
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
