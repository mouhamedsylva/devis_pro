/// BLoC Auth: inscription/connexion par numéro (offline).
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/local/auth_session_store.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/usecases/login_with_phone.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required UserRepository userRepository, AuthSessionStore? sessionStore})
      : _loginWithPhone = LoginWithPhone(userRepository: userRepository),
        _userRepository = userRepository,
        _sessionStore = sessionStore ?? AuthSessionStore(),
        super(const AuthState.unknown()) {
    on<AuthStarted>((event, emit) async {
      emit(const AuthState.loading());
      final phone = await _sessionStore.getPhone();
      if (phone == null || phone.trim().isEmpty) {
        emit(const AuthState.unauthenticated());
        return;
      }
      final user = await _userRepository.findByPhone(phone.trim());
      if (user == null) {
        await _sessionStore.clear();
        emit(const AuthState.unauthenticated());
        return;
      }
      emit(AuthState.authenticated(user));
    });
    on<AuthLoginRequested>((event, emit) async {
      emit(const AuthState.loading());
      try {
        final user = await _loginWithPhone(event.phoneNumber);
        await _sessionStore.setPhone(user.phoneNumber);
        emit(AuthState.authenticated(user));
      } catch (e) {
        emit(AuthState.failure('Connexion impossible: ${e.toString()}'));
      }
    });
    on<AuthLogoutRequested>((event, emit) async {
      await _sessionStore.clear();
      emit(const AuthState.unauthenticated());
    });
  }

  final LoginWithPhone _loginWithPhone;
  final UserRepository _userRepository;
  final AuthSessionStore _sessionStore;
}

