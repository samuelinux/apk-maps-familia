import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/location_service.dart';
import 'screens/login_screen.dart';
import 'screens/group_setup_screen.dart';
import 'screens/map_screen.dart';
import 'models/app_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<LocationService>(create: (_) => LocationService()),
      ],
      child: MaterialApp(
        title: 'Family Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription? _locationSubscription;
  String? _currentUserId;

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _setupUser(User user, DatabaseService dbService, LocationService locationService) {
    if (_currentUserId == user.uid) return;
    _currentUserId = user.uid;

    // Save user to Firestore
    dbService.saveUser(UserModel(
      uid: user.uid,
      displayName: user.displayName ?? 'Usuário',
      email: user.email ?? '',
      photoUrl: user.photoURL ?? '',
    ));

    // Start location updates
    _locationSubscription?.cancel();
    _locationSubscription = locationService.getLocationStream().listen((position) {
      dbService.updateUserLocation(user.uid, position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dbService = Provider.of<DatabaseService>(context);
    final locationService = Provider.of<LocationService>(context);

    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;

          // Schedule setup after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _setupUser(user, dbService, locationService);
          });

          return StreamBuilder<UserModel>(
            stream: dbService.getUserStream(user.uid),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              final userData = userSnapshot.data!;
              if (userData.groupId == null || userData.groupId!.isEmpty) {
                return const GroupSetupScreen();
              } else {
                return MapScreen(groupId: userData.groupId!);
              }
            },
          );
        }

        _currentUserId = null;
        _locationSubscription?.cancel();
        _locationSubscription = null;
        return const LoginScreen();
      },
    );
  }
}
