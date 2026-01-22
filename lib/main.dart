/// DevisPro – Génération de devis (FCFA), offline-first, Clean Architecture + BLoC.
///
/// Entry point: instancie la DB locale SQLite et injecte les repositories/blocs.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/core/theme/app_theme.dart';
import 'src/data/datasources/local/app_database.dart';
import 'src/data/datasources/local/sqflite_bootstrap.dart';
import 'src/data/repositories/client_repository_impl.dart';
import 'src/data/repositories/company_repository_impl.dart';
import 'src/data/repositories/product_repository_impl.dart';
import 'src/data/repositories/quote_repository_impl.dart';
import 'src/data/repositories/user_repository_impl.dart';
import 'src/domain/repositories/client_repository.dart';
import 'src/domain/repositories/company_repository.dart';
import 'src/domain/repositories/product_repository.dart';
import 'src/domain/repositories/quote_repository.dart';
import 'src/domain/repositories/user_repository.dart';
import 'src/presentation/blocs/auth/auth_bloc.dart';
import 'src/presentation/blocs/clients/client_bloc.dart';
import 'src/presentation/blocs/company/company_bloc.dart';
import 'src/presentation/blocs/products/product_bloc.dart';
import 'src/presentation/blocs/quotes/quote_bloc.dart';
import 'src/presentation/screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initSqflite();
  final db = await AppDatabase.open();

  runApp(
    DevisProApp(
      db: db,
    ),
  );
}

class DevisProApp extends StatelessWidget {
  const DevisProApp({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final userRepository = UserRepositoryImpl(db);
    final companyRepository = CompanyRepositoryImpl(db);
    final clientRepository = ClientRepositoryImpl(db);
    final productRepository = ProductRepositoryImpl(db);
    final quoteRepository = QuoteRepositoryImpl(db);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UserRepository>.value(value: userRepository),
        RepositoryProvider<CompanyRepository>.value(value: companyRepository),
        RepositoryProvider<ClientRepository>.value(value: clientRepository),
        RepositoryProvider<ProductRepository>.value(value: productRepository),
        RepositoryProvider<QuoteRepository>.value(value: quoteRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(userRepository: userRepository)..add(const AuthStarted()),
          ),
          BlocProvider(
            create: (_) => CompanyBloc(companyRepository: companyRepository),
          ),
          BlocProvider(
            create: (_) => ClientBloc(clientRepository: clientRepository),
          ),
          BlocProvider(
            create: (_) => ProductBloc(productRepository: productRepository),
          ),
          BlocProvider(
            create: (_) => QuoteBloc(quoteRepository: quoteRepository),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'DevisPro',
          theme: AppTheme.light(),
          home: const AuthGate(),
        ),
      ),
    );
  }
}
