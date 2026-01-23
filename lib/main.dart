/// DevisPro – Génération de devis (FCFA), offline-first, Clean Architecture + BLoC.
///
/// Entry point: instancie la DB locale SQLite et injecte les repositories/blocs.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';

import 'src/core/services/email_service.dart';
import 'src/core/theme/app_theme.dart';
import 'src/data/datasources/local/app_database.dart';
import 'src/data/repositories/client_repository_impl.dart';
import 'src/data/repositories/company_repository_impl.dart';
import 'src/data/repositories/otp_repository_impl.dart';
import 'src/data/repositories/product_repository_impl.dart';
import 'src/data/repositories/quote_repository_impl.dart';
import 'src/data/repositories/template_repository_impl.dart';
import 'src/data/repositories/user_repository_impl.dart';
import 'src/domain/repositories/client_repository.dart';
import 'src/domain/repositories/company_repository.dart';
import 'src/domain/repositories/otp_repository.dart';
import 'src/domain/repositories/product_repository.dart';
import 'src/domain/repositories/quote_repository.dart';
import 'src/domain/repositories/template_repository.dart';
import 'src/domain/repositories/user_repository.dart';
import 'src/presentation/blocs/auth/auth_bloc.dart';
import 'src/presentation/blocs/clients/client_bloc.dart';
import 'src/presentation/blocs/company/company_bloc.dart';
import 'src/presentation/blocs/products/product_bloc.dart';
import 'src/presentation/blocs/quotes/quote_bloc.dart';
import 'src/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'src/presentation/blocs/template/template_bloc.dart';
import 'src/presentation/blocs/template/template_event.dart';
import 'src/presentation/screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    // ✨ Service d'envoi d'emails (configuration SMTP Gmail)
    // TODO: Remplacer par vos identifiants dans lib/src/core/services/email_service.dart
    final emailService = EmailService();

    // Repositories
    final userRepository = UserRepositoryImpl(db.database);
    final otpRepository = OTPRepositoryImpl(db.database, emailService);
    final companyRepository = CompanyRepositoryImpl(db);
    final clientRepository = ClientRepositoryImpl(db);
    final productRepository = ProductRepositoryImpl(db);
    final quoteRepository = QuoteRepositoryImpl(db);
    final templateRepository = TemplateRepositoryImpl(db);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UserRepository>.value(value: userRepository),
        RepositoryProvider<OTPRepository>.value(value: otpRepository),
        RepositoryProvider<CompanyRepository>.value(value: companyRepository),
        RepositoryProvider<ClientRepository>.value(value: clientRepository),
        RepositoryProvider<ProductRepository>.value(value: productRepository),
        RepositoryProvider<QuoteRepository>.value(value: quoteRepository),
        RepositoryProvider<TemplateRepository>.value(value: templateRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(
              userRepository: userRepository,
              otpRepository: otpRepository,
            )..add(const AuthStarted()),
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
          BlocProvider(
            create: (_) => DashboardBloc(
              clientRepository: clientRepository,
              productRepository: productRepository,
              quoteRepository: quoteRepository,
            ),
          ),
          BlocProvider(
            create: (_) => TemplateBloc(templateRepository)
              ..add(const TemplateInitializePredefined()),
          ),
        ],
        child: Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'DevisPro',
              theme: AppTheme.light(),
              home: const AuthGate(),
            );
          },
        ),
      ),
    );
  }
}
