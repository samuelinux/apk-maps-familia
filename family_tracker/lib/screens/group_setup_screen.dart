import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

class GroupSetupScreen extends StatefulWidget {
  const GroupSetupScreen({super.key});

  @override
  State<GroupSetupScreen> createState() => _GroupSetupScreenState();
}

class _GroupSetupScreenState extends State<GroupSetupScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Família')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome da Família (para criar)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                String? code = await dbService.createGroup(user.uid, _nameController.text);
                setState(() => _isLoading = false);
                if (code != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Grupo criado! Código: $code')));
                }
              },
              child: const Text('Criar Nova Família'),
            ),
            const Divider(height: 50),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Código da Família (para entrar)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                bool success = await dbService.joinGroup(user.uid, _codeController.text);
                setState(() => _isLoading = false);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código inválido')));
                }
              },
              child: const Text('Entrar em Família Existente'),
            ),
          ],
        ),
      ),
    );
  }
}
