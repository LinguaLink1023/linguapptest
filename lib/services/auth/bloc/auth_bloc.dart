import 'package:bloc/bloc.dart';
import 'package:linguapp/services/auth/auth_provider.dart';
import 'package:linguapp/services/auth/bloc/auth_event.dart';
import 'package:linguapp/services/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthenProvider provider)
      : super(const AuthStateUninitialized(isLoading: true)) {
      
    on<AuthEventShouldRegister>((event, emit) {
      emit(
        const AuthStateRegistering(
          exception: null,
          isLoading: false,
        ),
      );
    });
    //forgot password
    on<AuthEventForgotPassword>((event, emit) async {
      emit(const AuthStateForgotPassword(
        isLoading: false,
        exception: null,
        hasSentEmail: false,
      ));
  
      final email = event.email;

      if (email == null) {
        return; //进入忘记密码页面
      }
      // 用户想要发送一个忘记密码的邮件
      emit(const AuthStateForgotPassword(
        isLoading: true,
        exception: null,
        hasSentEmail: false,
      ));

      bool didSendEmail;
      Exception? exception;
      try {
        await provider.sendPasswordReset(toEmail: email);
        didSendEmail = true;
        exception = null;
      } on Exception catch (e) {
        didSendEmail = false;
        exception = e;
      }

      emit(AuthStateForgotPassword(
        isLoading: false,
        exception: exception,
        hasSentEmail: didSendEmail,
      ));
    });

    // send email verification
    on<AuthEventSendEmailVerification>((event, emit) async {
      await provider.sendEmailVerification();
      emit(state);
    });
    //register
    on<AuthEventRegister>((event, emit) async {
      final email = event.email;
      final password = event.password;
      try {
        await provider.createUser(
          email: email,
          password: password,
        );
        await provider.sendEmailVerification();
        emit(const AuthStateNeedsVerification(isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateRegistering(exception: e, isLoading: false));
      }
    });
    // initialize
    on<AuthEventInitialize>(
      (event, emit) async {
        await provider.initialize();
        final user = provider.currentUser;
        if (user == null) {
          emit(
            const AuthStateLoggedOut(
              exception: null,
              isLoading: false,
            ),
          );
        } else if (!user.isEmailVerified) {
          emit(const AuthStateNeedsVerification(isLoading: false));
        } else {
          emit(AuthStateLoggedIn(user: user, isLoading: false));
        }
      },
    );
    // log in
    on<AuthEventLogIn>(
      (event, emit) async {
        emit(const AuthStateLoggedOut(
          exception: null,
          isLoading: true,
          loadingText: 'Please wait while I log you in',
        ));
        final email = event.email;
        final password = event.password;
        try {
          final user = await provider.logIn(
            email: email,
            password: password,
          );

          if (!user.isEmailVerified) {
            emit(
              const AuthStateLoggedOut(
                exception: null,
                isLoading: false,
              ),
            );
            emit(const AuthStateNeedsVerification(isLoading: false));
          } else {
            emit(
              const AuthStateLoggedOut(
                exception: null,
                isLoading: false,
              ),
            );
            emit(AuthStateLoggedIn(user: user, isLoading: false));
          }
        } on Exception catch (e) {
          emit(
            AuthStateLoggedOut(
              exception: e,
              isLoading: false,
            ),
          );
        }
      },
    );
    // log out
    on<AuthEventLogOut>(
      (event, emit) async {
        try {
          await provider.logOut();
          emit(
            const AuthStateLoggedOut(
              exception: null,
              isLoading: false,
            ),
          );
        } on Exception catch (e) {
          emit(
            AuthStateLoggedOut(
              exception: e,
              isLoading: false,
            ),
          );
        }
      },
    );
  }
}
