
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- PANTALLA DE LOGIN ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de autenticación: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocurrió un error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Venered')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Bienvenido a Venered', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => (value == null || !value.contains('@')) ? 'Email inválido' : null,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6) ? 'La contraseña debe tener al menos 6 caracteres' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('Iniciar Sesión'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- PANTALLA DE REGISTRO ---
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
  
  // --- FUNCIÓN DE REGISTRO CORREGIDA ---
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final username = _usernameController.text.trim();
      
      // 1. Registrar al usuario en Supabase Auth
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      // 2. Si el registro es exitoso y tenemos un usuario, insertar en la tabla 'profiles'
      if (response.user != null) {
        final userId = response.user!.id;
        await Supabase.instance.client.from('profiles').insert({
          'id': userId,
          'username': username,
        });

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Registro exitoso! Por favor, revisa tu email para confirmar tu cuenta.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        // Esto es por si acaso, signUp debería lanzar una excepción si falla.
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se pudo obtener el usuario tras el registro.'), backgroundColor: Colors.red),
            );
        }
      }

    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de registro: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocurrió un error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Text('Únete a la comunidad', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Nombre de usuario'),
                  validator: (value) => (value == null || value.isEmpty) ? 'El nombre de usuario es requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => (value == null || !value.contains('@')) ? 'Email inválido' : null,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6) ? 'La contraseña debe tener al menos 6 caracteres' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _register,
                  child: const Text('Registrarse'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('¿Ya tienes cuenta? Inicia Sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// --- PANTALLA PRINCIPAL (HOME) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venered - Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          )
        ],
      ),
      body: const Center(
        child: Text('¡Bienvenido! Has iniciado sesión.'),
      ),
    );
  }
}

// --- FUNCIÓN PRINCIPAL Y CONFIGURACIÓN DE LA APP ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- SUSTITUYE CON TUS PROPIAS CLAVES DE SUPABASE ---
  await Supabase.initialize(
    url: 'https://icqgwhfciabfonkanjwm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImljcWd3aGZjaWFiZm9ua2FuandtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTkwMjc2MzUsImV4cCI6MjAzNDYwMzYzNX0.j9C1J5v0C69o1_3dY42c3G27v34A6iYa8Gj1eL4sS6Y',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Venered Social',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // --- LÓGICA DE NAVEGACIÓN INICIAL ---
      // Si el usuario ya está logueado, va a HomePage, si no, a LoginPage.
      home: Supabase.instance.client.auth.currentSession == null
          ? const LoginPage()
          : const HomePage(),
    );
  }
}
