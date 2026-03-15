import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/location_service.dart';

class PermissionScreen extends StatefulWidget {
  final Widget child;
  const PermissionScreen({super.key, required this.child});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _granted = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    try {
      await locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _granted = true;
          _checking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _granted = false;
          _checking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_granted) {
      return widget.child;
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Permissão de Localização Necessária',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Este aplicativo precisa da sua localização para que sua família saiba onde você está.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _checkPermission,
                child: const Text('Tentar Novamente / Dar Permissão'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
