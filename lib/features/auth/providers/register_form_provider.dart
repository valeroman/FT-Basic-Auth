

import 'package:basic_auth/features/shared/shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';

//! 3 - StateNotifierProvider - consume afuera
final registerFormProvider = StateNotifierProvider.autoDispose<RegisterFormNotifier, RegisterFormState>((ref) {
  return RegisterFormNotifier();
});

//! 2 - Como implementar el notifier
class RegisterFormNotifier extends StateNotifier<RegisterFormState> {
  RegisterFormNotifier(): super( RegisterFormState() );

  //* Metodos
  onEmailChange( String value ) {
    final newEmail = Email.dirty(value);
    state = state.copyWith(
      email: newEmail,
      isValid: Formz.validate([ newEmail, state.password, state.username, state.confirmedPassword ])
    );
  }

  onPasswordChange( String value ) {
    final newPassword = Password.dirty(value);
    state = state.copyWith(
      password: newPassword,
      isValid: Formz.validate([ newPassword, state.email, state.username, state.confirmedPassword ])
    );
  }

  onConfirmedPasswordChange( String value ) {
    final newConfirmedPassword = ConfirmedPassword.dirty(original: state.password, value: value);
    state = state.copyWith(
      confirmedPassword: newConfirmedPassword,
      isValid: Formz.validate([ newConfirmedPassword, state.email, state.username, state.password ])
    );
  }

  onUsernameChange( String value) {
    final newUsername = Username.dirty(value);
    state = state.copyWith(
      username: newUsername,
      isValid: Formz.validate([ newUsername, state.email, state.password, state.confirmedPassword ])
    );
  }

  onFormSubmit() {
    _touchEveryField();

    if ( !state.isValid ) return;

    print(state);

  }

  _touchEveryField() {
    final email    = Email.dirty(state.email.value);
    final password1 = Password.dirty(state.password.value);
    final password2 = ConfirmedPassword.dirty(original: password1, value: state.confirmedPassword.value);
    final username = Username.dirty(state.username.value);
    
    state = state.copyWith(
      isFromPosted: true,
      email: email,
      password: password1,
      confirmedPassword: password2,
      username: username,
      isValid: Formz.validate([ email, password1, password2, username ])
    );

  }
  
}

//! 1 - State del provider
class RegisterFormState {

  final bool isPosting;
  final bool isFromPosted;
  final bool isValid;
  final Email email;
  final Password password;
  final ConfirmedPassword confirmedPassword;
  final Username username;

  RegisterFormState({
    this.isPosting = false, 
    this.isFromPosted = false, 
    this.isValid = false, 
    this.email = const Email.pure(), 
    this.password = const Password.pure(), 
    this.confirmedPassword = const ConfirmedPassword.pure(), 
    this.username = const Username.pure()
  });

  RegisterFormState copyWith({
    bool? isPosting,
    bool? isFromPosted,
    bool? isValid,
    Email? email,
    Password? password,
    ConfirmedPassword? confirmedPassword,
    Username? username,
  }) => RegisterFormState(
      isPosting: isPosting ?? this.isPosting,
      isFromPosted: isFromPosted ?? this.isFromPosted,
      isValid: isValid ?? this.isValid,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmedPassword:  confirmedPassword ?? this.confirmedPassword,
      username: username ?? this.username,  
    );

  // * Para hacer una impresion del estado
  @override
  String toString() {
    return '''
      RegisterFormState:
        isPosting: $isPosting
        isFromPosted: $isFromPosted
        isValid: $isValid
        email: $email
        password: $password
        confirmedPassword: $confirmedPassword
        username: $username
    ''';
  }

} 



