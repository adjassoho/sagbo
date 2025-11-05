import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TestCallScreen extends StatefulWidget {
  const TestCallScreen({Key? key}) : super(key: key);

  @override
  State<TestCallScreen> createState() => _TestCallScreenState();
}

class _TestCallScreenState extends State<TestCallScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _status = '';

  Future<void> _makePhoneCall(String phoneNumber) async {
    setState(() {
      _status = 'Tentative d\'appel vers: $phoneNumber';
    });

    try {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      
      debugPrint('URI d\'appel: $launchUri');
      
      if (await canLaunchUrl(launchUri)) {
        debugPrint('canLaunchUrl retourne true');
        await launchUrl(
          launchUri,
          mode: LaunchMode.externalApplication,
        );
        setState(() {
          _status = 'Appel lancé avec succès!';
        });
      } else {
        debugPrint('canLaunchUrl retourne false');
        setState(() {
          _status = 'Impossible de lancer l\'appel. Vérifiez les permissions.';
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'appel: $e');
      setState(() {
        _status = 'Erreur: $e';
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test d\'appel'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
                hintText: '+229 12345678',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final phone = _phoneController.text.trim();
                if (phone.isNotEmpty) {
                  _makePhoneCall(phone);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Appeler',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 40),
            const Text(
              'Tests rapides:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => _makePhoneCall('123'),
                  child: const Text('Test 123'),
                ),
                ElevatedButton(
                  onPressed: () => _makePhoneCall('+22912345678'),
                  child: const Text('Test +229...'),
                ),
                ElevatedButton(
                  onPressed: () => _makePhoneCall('911'),
                  child: const Text('Test 911'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
