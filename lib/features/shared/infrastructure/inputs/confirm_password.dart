

import 'package:basic_auth/features/shared/infrastructure/inputs/password.dart';
import 'package:formz/formz.dart';

enum PasswordFieldValidationError { empty, match }

class ConfirmedPassword extends FormzInput<String, PasswordFieldValidationError> {
  const ConfirmedPassword.pure() : original = const Password.pure(), super.pure('');
  const ConfirmedPassword.dirty({ required this.original, String value = ''}) : super.dirty(value);

  final Password original;


  String? get errorMessage {
    if ( isValid || isPure ) return null;

    if ( displayError == PasswordFieldValidationError.empty ) return 'El campo es requeridos';
    if ( displayError == PasswordFieldValidationError.match) return 'No es igual el password';

    return null;
  }

  @override
  PasswordFieldValidationError? validator(String value) {
    
    if ( value.isEmpty || value.trim().isEmpty ) return PasswordFieldValidationError.empty;
    if ( original.value.toString() != value ) return PasswordFieldValidationError.match;

    return null;
  }
}
