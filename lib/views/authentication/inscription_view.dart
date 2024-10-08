import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_firebase/services/service_locator.dart';
import 'package:todo_firebase/services/task_service.dart';
import '../../utils/authentication_provider.dart';
import '../home/home_view.dart';

class InscriptionView extends StatefulWidget {
  const InscriptionView({super.key});

  @override
  InscriptionViewState createState() => InscriptionViewState();
}

class InscriptionViewState extends State<InscriptionView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Tentative de création du compte utilisateur
        await context.read<AuthenticationProvider>().signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Attendre quelques secondes pour garantir la création des documents Firestore
        await Future.delayed(const Duration(seconds: 2));

        // Création d'une tâche ficitve pour le nouvel utilisateur
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await serviceLocator<TaskService>().createDummyTaskForNewUser(user.uid);
        }
        // Navigation vers l'écran HomeView après l'inscription réussie
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
      } on FirebaseAuthException catch (e) {
        log("FirebaseAuthException: ${e.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${e.message}")),
        );
      } catch (e) {
        // Capture les erreurs inattendues et continue malgré cela
        log("Erreur ignorée lors de l'inscription : $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur inattendue, mais vous êtes connecté.")),
        );

        // Ignorer l'erreur et rediriger vers HomeView malgré l'erreur
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
      } finally {
        // Réinitialisation de l'état de chargement
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez indiquer votre email.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez indiquer un mot de passe.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _signUp,
                child: const Text('Inscription'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
