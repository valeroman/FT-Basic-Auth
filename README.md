# basic_auth

A new Flutter project.


### Riverpod - Inputs y LoginState

#### Instalamos el paquete formz y riverpod

```
flutter pub add formz, flutter_riverpod
```

- Creamos los archivos inputs `email.dart` y `password.dart`, para tener las validaciones de los inputs

```dart
import 'package:formz/formz.dart';

// Define input validation errors
enum EmailError { empty, format }

// Extend FormzInput and provide the input type and error type.
class Email extends FormzInput<String, EmailError> {

  static final RegExp emailRegExp = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  // Call super.pure to represent an unmodified form input.
  const Email.pure() : super.pure('');

  // Call super.dirty to represent a modified form input.
  const Email.dirty( String value ) : super.dirty(value);



  String? get errorMessage {
    if ( isValid || isPure ) return null;

    if ( displayError == EmailError.empty ) return 'El campo es requerido';
    if ( displayError == EmailError.format ) return 'No tiene formato de correo electrónico';

    return null;
  }

  // Override validator to handle validating a given input value.
  @override
  EmailError? validator(String value) {
    
    if ( value.isEmpty || value.trim().isEmpty ) return EmailError.empty;
    if ( !emailRegExp.hasMatch(value) ) return EmailError.format;

    return null;
  }
}
```


```dart
import 'package:formz/formz.dart';

// Define input validation errors
enum PasswordError { empty, length, format }

// Extend FormzInput and provide the input type and error type.
class Password extends FormzInput<String, PasswordError> {


  static final RegExp passwordRegExp = RegExp(
    r'(?:(?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$',
  );

  // Call super.pure to represent an unmodified form input.
  const Password.pure() : super.pure('');

  // Call super.dirty to represent a modified form input.
  const Password.dirty( String value ) : super.dirty(value);


  String? get errorMessage {
    if ( isValid || isPure ) return null;

    if ( displayError == PasswordError.empty ) return 'El campo es requerido';
    if ( displayError == PasswordError.length ) return 'Mínimo 6 caracteres';
    if ( displayError == PasswordError.format ) return 'Debe de tener Mayúscula, letras y un número';

    return null;
  }


  // Override validator to handle validating a given input value.
  @override
  PasswordError? validator(String value) {

    if ( value.isEmpty || value.trim().isEmpty ) return PasswordError.empty;
    if ( value.length < 6 ) return PasswordError.length;
    if ( !passwordRegExp.hasMatch(value) ) return PasswordError.format;

    return null;
  }
}
```
- Abrimos el archivo `main.dart`, para configurar riverpod agregando el `ProviderScope`

```dart
import 'package:basic_auth/config/config.dart';
import 'package:basic_auth/config/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(child: MainApp())
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      theme: AppTheme().getTheme(),
      debugShowCheckedModeBanner: false,
    );
  }
}

```


- En la carpeta `features -> auth`, creamos la carpeta `providers`.
- Creamos el archivo `login_form_provider.dart`

```dart
import 'package:basic_auth/features/shared/shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';

//! 1 - State del provider

class LoginFormState {

  final bool isPosting;
  final bool isFromPosted;
  final bool isValid;
  final Email email;
  final Password password;

  LoginFormState({
    this.isPosting = false, 
    this.isFromPosted = false, 
    this.isValid = false, 
    this.email = const Email.pure(), 
    this.password = const Password.pure()
  });

  LoginFormState copyWith({
    bool? isPosting,
    bool? isFromPosted,
    bool? isValid,
    Email? email,
    Password? password,
  }) => LoginFormState(
    isPosting: isPosting ?? this.isPosting,
    isFromPosted: isFromPosted ?? this.isFromPosted,
    isValid: isValid ?? this.isValid,
    email: email ?? this.email,
    password: password ?? this.password,    
  );


  // * Para hacer una impresion del estado
  @override
  String toString() {
    return '''
      LoginFormState:
      isPosting: $isPosting
      isFromPosted: $isFromPosted 
      isValid: $isValid 
      email: $email 
      password: $password
    ''';
  }
}

//! 2 - Como imlementar un notifier
class LoginFormNotifier extends StateNotifier<LoginFormState> {
  LoginFormNotifier(): super( LoginFormState() );

  //* Methodos
  onEmailChange( String value) {
    final newEmail = Email.dirty(value);
    state = state.copyWith(
      email: newEmail,
      isValid: Formz.validate([ newEmail, state.password ])
    );
  } 

  onPasswordChange( String value) {
    final newPassword = Password.dirty(value);
    state = state.copyWith(
      password: newPassword,
      isValid: Formz.validate([ newPassword, state.email ])
    );
  } 

  onFormSubmit() {
    _touchEveryField();

    if ( !state.isValid ) return;

    print(state);

  }

  _touchEveryField() {
    final email    = Email.dirty(state.email.value);
    final password = Password.dirty(state.password.value);

    state = state.copyWith(
      isFromPosted: true,
      email: email,
      password: password,
      isValid: Formz.validate([ email, password ])
    );
  }
  
}

//! 3 - StateNotifierProvider - consume afuera
final loginFormProvider = StateNotifierProvider.autoDispose<LoginFormNotifier, LoginFormState>((ref) {
  return LoginFormNotifier();
});
```


#### Conectar formulario con Provider

- Abrimos el archivo  `login_screen.dart` y vamos a cambiar el `StatelessWidget` por `ConsumerWidget` en la clase `_LoginForm`


```dart

import 'package:basic_auth/features/auth/providers/providers.dart';
import 'package:basic_auth/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          body: GeometricalBackground(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
            
                  const SizedBox( height: 60 ),
            
                  //* Icon Banner
                  const Icon(
                    Icons.production_quantity_limits_rounded,
                    color: Colors.white,
                    size: 70,
                  ),
            
                  const SizedBox( height: 60 ),
            
                  Container(
                    width: double.infinity,
                    height: size.height - 260,
                    decoration: BoxDecoration(
                      color: scaffoldBackgroundColor,
                      // color: Colors.lightBlue[200],
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(100)),
                    ),
                    child: const _LoginForm(),
                  )
            
            
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends ConsumerWidget {       // -> Se agrego el ConsumerWidget
  const _LoginForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {       // -> Se agrego el WidgetRef

     //* Tener acceso al state del loginFromProvider
    final loginForm = ref.watch(loginFormProvider);         // -> Se agrego p-ara tener acceso al provider

    final textStyle = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric( horizontal: 50 ),
      child: Column(
        children: [

          const SizedBox( height: 40 ),
          Text('Login', style: textStyle.titleMedium),
          const SizedBox( height: 50 ),

          CustomTextFormField(
            label: 'Correo',
            keyboardType: TextInputType.emailAddress,
            onChanged: ref.read(loginFormProvider.notifier).onEmailChange,      // -> Se agrego
            errorMessage: loginForm.isFromPosted                                // -> Se agrego
              ? loginForm.email.errorMessage
              : null,
          ),
          const SizedBox( height: 30 ),

          CustomTextFormField(
            label: 'Constraseña',
            obscureText: true,
            onChanged: ref.read(loginFormProvider.notifier).onPasswordChange,    // -> Se agrego
            errorMessage: loginForm.isFromPosted                                 // -> Se agrego
              ? loginForm.password.errorMessage
              : null,
          ),
          const SizedBox( height: 30 ),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: CustomFilledButton(
              text: 'Ingresar',
              buttonColor: Colors.black,
              onPressed: () {
                ref.read(loginFormProvider.notifier).onFormSubmit();
              },
            ),
          ),

          const Spacer( flex: 2 ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿No tienes cuenta?'),
              TextButton(
                onPressed: () => context.push('/register'), 
                child: const Text('Crea una aquí')
              )
            ],
          ),

          const Spacer( flex: 1 ),
        ],
      ),
    );
  }
}
```

#### Cambiar el estilo del error

- Abrimos el archivo `custom_text_form_field.dart`, para quitar el border rojo del input 

```dart
import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {

  final String? label;
  final String? hint;
  final String? errorMessage;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const CustomTextFormField({
    super.key, 
    this.label, 
    this.hint, 
    this.errorMessage, 
    this.obscureText = false, 
    this.keyboardType = TextInputType.text, 
    this.onChanged, 
    this.validator
  });

  @override
  Widget build(BuildContext context) {

    final colors = Theme.of(context).colorScheme;

    final border = OutlineInputBorder(
      borderSide: const BorderSide( color: Colors.transparent ),
      borderRadius: BorderRadius.circular(40)
    );

    const borderRadius = Radius.circular(15);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: borderRadius, 
          bottomLeft: borderRadius,
          bottomRight: borderRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 5)
          )
        ]
      ),
      child: TextFormField(
        onChanged: onChanged,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle( fontSize: 20, color: Colors.black54),
        decoration: InputDecoration(
          floatingLabelStyle: const TextStyle( color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          enabledBorder: border,
          focusedBorder: border,
          errorBorder: border.copyWith( borderSide: const BorderSide( color: Colors.transparent )),
          focusedErrorBorder: border.copyWith( borderSide: const BorderSide( color: Colors.transparent )),
          isDense: true,
          label: label != null ? Text(label!) : null,
          hintText: hint,
          errorText: errorMessage,
          focusColor: colors.primary
        ),
      ),
    );
  }
}
```

#### Implementacion de validaciones del Register

- Creamos el archivo `confirm_password.dart`, para realizar la validación si los password son o no iguales

```dart


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

```

- Creamos el Provider del register, en el archivo `register_form_provider.dart`

```dart


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
```

- Conectamos el formulario del register con el provider

```dart

import 'package:basic_auth/features/auth/providers/providers.dart';
import 'package:basic_auth/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textStyles = Theme.of(context).textTheme;

    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          body: GeometricalBackground(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox( height: 30 ),
            
                  //* Icon Banner
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(bottomRight: Radius.circular(10), topRight: Radius.circular(10)),
                        ),
                        child:  IconButton(
                          onPressed: () {
                            if ( !context.canPop() ) return;
                            context.pop();
                          }, 
                          icon: const Icon( Icons.arrow_back_rounded, size: 25, color: Colors.black,),
                        ),
                      ),
                      const Spacer(flex: 1),
                      Text('Crear cuenta', style: textStyles.titleMedium?.copyWith(color: Colors.white)),
                      const Spacer(flex: 2),
                    ],
                  ),
            
                  const SizedBox( height: 80),
            
                  Container(
                    height: size.height + 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: scaffoldBackgroundColor,
                      // color: Colors.red,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(100)),
                    ),
                    child: const _RegisterForm(),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterForm extends ConsumerWidget {

  const _RegisterForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {

     //* Tener acceso al state del registerFromProvider
    final registerForm = ref.watch(registerFormProvider);

    final textStyles = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [

          const SizedBox( height: 50 ),
          Text('Nueva cuenta', style: textStyles.titleMedium),
          const SizedBox( height: 50 ),

          CustomTextFormField(
            label: 'Nombre completo',
            onChanged: ref.read(registerFormProvider.notifier).onUsernameChange,
            errorMessage: registerForm.isFromPosted
              ? registerForm.username.errorMessage
              : null,
          ),
          const SizedBox(height: 30),

          CustomTextFormField(
            label: 'Correo',
            keyboardType: TextInputType.emailAddress,
            onChanged: ref.read(registerFormProvider.notifier).onEmailChange,
            errorMessage: registerForm.isFromPosted
              ? registerForm.email.errorMessage
              : null,
          ),
          const SizedBox(height: 30),

          CustomTextFormField(
            label: 'Password',
            obscureText: true,
            onChanged: ref.read(registerFormProvider.notifier).onPasswordChange,
            errorMessage: registerForm.isFromPosted
              ? registerForm.password.errorMessage
              : null,

          ),
          const SizedBox(height: 30),

          CustomTextFormField(
            label: 'Repita el password',
            obscureText: true,
            onChanged: ref.read(registerFormProvider.notifier).onConfirmedPasswordChange,
            errorMessage: registerForm.isFromPosted
              ? registerForm.confirmedPassword.errorMessage
              : null,
          ),

          const SizedBox(height: 50),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: CustomFilledButton(
              text: 'Crear',
              buttonColor: Colors.black,
               onPressed: () {
                ref.read(registerFormProvider.notifier).onFormSubmit();
              },
            ),
          ),

          const Spacer(flex: 2),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿Ya tienes cuenta?'),
              TextButton(
                onPressed: () {
                  if ( context.canPop() ) {
                    return context.pop();
                  }
                  context.go('/login');
                }, 
                child: const Text('Ingresa aquí')
              )
            ],
          ),

          const Spacer(flex: 2),

        ],
      ),
    );
  }
}
```

#### Variables de entorno

Documentación: https://pub.dev/packages/flutter_dotenv
- Instalamos el paquete `flutter pub add flutter_dotenv`, para usar la variables de entorno

- Creamos en la raiz del proyecto los archivos `.env .env.template` y agregamos lo siguiente:

```dart
API_URL=http://localhost:3000/api
```

- Creamos la carpeta `constants` dentro de `config` 
- Dentro de la carpeta `constants`, creamos el archivo `environment.dart`, para obtener el valor de la variable del archivo .env

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {

  static String apiUrl = dotenv.env['API_URL'] ?? 'No esta configurado el API_URL';

}
```

- Agregamos en el archivo `pubspec.yaml`, y en assets agregamos lo siguiente:

```yaml
 assets:
    - .env                                  // -> Se agrego el .env
    - assets/loaders/
    - assets/images/
    - google_fonts/montserrat_alternates/

```

- Abrimos el archivo `main.dart`, para leer el archivo `.env`


```dart
import 'package:basic_auth/config/config.dart';
import 'package:basic_auth/config/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {

  await dotenv.load(fileName: '.env');          // -> Se agrego 

  runApp(
    const ProviderScope(child: MainApp())
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      theme: AppTheme().getTheme(),
      debugShowCheckedModeBanner: false,
    );
  }
}

```

- ACtualizacion del archivo `main.dart` y `environment.dart`, para tener todo centralizado

main.dart
```dart
import 'package:basic_auth/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {

  await Environment.initEnvironment();

  runApp(
    const ProviderScope(child: MainApp())
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {

     print(Environment.apiUrl);         // -> Probar que se esta leyendo la variable de entorno

    return MaterialApp.router(
      routerConfig: appRouter,
      theme: AppTheme().getTheme(),
      debugShowCheckedModeBanner: false,
    );
  }
}

```

environment.dart
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {

  static initEnvironment() async {

    await dotenv.load(fileName: '.env');

  }

  static String apiUrl = dotenv.env['API_URL'] ?? 'No esta configurado el API_URL';

}
```

#### Auth - Repositorio, Datasource, Entities

- Creamos las carpetas `domain`, `infrastructure` dentro de `features -> auth`

- Dentro de la carpeta `domain` agregamos las carpetas `datasources`, `entities` y `repositories`

- Creamos el archivo `user.dart`, dentro de la carpeta `entities`

```dart
class User {

  final String id;
  final String email;
  final String fullName;
  final List<String> roles;
  final String token;

  User({
    required this.id, 
    required this.email, 
    required this.fullName, 
    required this.roles, 
    required this.token
  });

  bool get isAdmin {
    return roles.contains('admin');
  }
  
}
```

- Creamos el archivo `auth_datasources.dart`, dentro de la carpeta `datasources`

```dart
import 'package:basic_auth/features/auth/domain/domain.dart';

abstract class AuthDatasource {

  Future<User> login( String email, String password );
  Future<User> register( String email, String password, String fullName );
  Future<User> checkauthStatus( String token );

}
```

- Creamos el archivo `auth_repository.dart`, dentro de la carpeta `repositories`

```dart
import 'package:basic_auth/features/auth/domain/domain.dart';

abstract class AuthRepository {

  Future<User> login( String email, String password );
  Future<User> register( String email, String password, String fullName );
  Future<User> checkauthStatus( String token );

}
```

- Dentro de la carpeta `infrastructure` agregamos las carpetas `datasources` y `repositories`

- Creamos el archivo `auth_datasource_impl.dart`, dentro de la carpeta `datasources`

```dart
import 'package:basic_auth/features/auth/domain/domain.dart';


class AuthDatasourceImpl extends AuthDatasource {
  @override
  Future<User> checkauthStatus(String token) {
    // TODO: implement checkauthStatus
    throw UnimplementedError();
  }

  @override
  Future<User> login(String email, String password) {
    // TODO: implement login
    throw UnimplementedError();
  }

  @override
  Future<User> register(String email, String password, String fullName) {
    // TODO: implement register
    throw UnimplementedError();
  }

}
```

- Creamos el archivo `auth_reppository_impl.dart`, dentro de la carpeta `repositories`

```dart
import 'package:basic_auth/features/auth/domain/domain.dart';
import '../infrastructure.dart';

class AuthRepositoryImpl extends AuthRepository {

  final AuthDatasource datasource;

  AuthRepositoryImpl(
    AuthDatasource? datasource
  ) : datasource = datasource ?? AuthDatasourceImpl();

  @override
  Future<User> checkauthStatus(String token) {
    return datasource.checkauthStatus(token);
  }

  @override
  Future<User> login(String email, String password) {
    return datasource.login(email, password);
  }

  @override
  Future<User> register(String email, String password, String fullName) {
    return datasource.register(email, password, fullName);
  }

}
```


#### Implementación del AuthDataSource - Login

- Creamos la carpeta `mappers`, dentro de la carpeta `infrastructure`

- Creamos el archivo `user_mapper.dart`

```dart
import 'package:basic_auth/features/auth/domain/domain.dart';

class UserMapper {

  static  User userJsonToEntity( Map<String, dynamic> json ) => User(
    id: json['id'],
    email: json['email'],
    fullName: json['fullName'],
    roles: List<String>.from(json['roles'].map( (role) => role )),
    token: json['token']
  );

}
```

- Creamos la carpeta `errors`, dentro de `infrastructure`

- Creamos el archivo `auth_errors.dart`

```dart
class WrongCredential implements Exception {}
class InvalidToken implements Exception {}
```

- Agregamos la implementación del login en el archivo `auth_datasource_impl.dart`

```dart
import 'package:basic_auth/config/config.dart';
import 'package:basic_auth/features/auth/infrastructure/infrastructure.dart';
import 'package:dio/dio.dart';
import 'package:basic_auth/features/auth/domain/domain.dart';

class AuthDatasourceImpl extends AuthDatasource {

  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
    )
  );


  @override
  Future<User> checkAuthStatus(String token) {
    // TODO: implement checkAuthStatus
    throw UnimplementedError();
  }

  @override
  Future<User> login(String email, String password) async {

    try {
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password
      });

      final user = UserMapper.userJsonToEntity(response.data);

      return user;

    } catch (e) {
      throw WrongCredential();
    }
  }

  @override
  Future<User> register(String email, String password, String fullName) {
    // TODO: implement register
    throw UnimplementedError();
  }

}
```

#### Auth Provider

- Creamos la carpeta `Providers` dentro de `features -> auth -> presentation`

- Agregamos el archivo `auth_provider.dart`

```dart

import 'package:basic_auth/features/auth/domain/domain.dart';
import 'package:basic_auth/features/auth/infrastructure/infrastructure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {

  final authRepository = AuthRepositoryImpl();

  return AuthNotifier(authRepository: authRepository);
});

class AuthNotifier extends StateNotifier<AuthState> {

  final AuthRepository authRepository;

  AuthNotifier({
    required this.authRepository
  }): super( AuthState() );

  Future<void> loginUser( String email, String password  ) async {

  }

  void registerUser( String email, String password  ) async {
    
  }

  void checkauthStatus() async {
    
  }
  
}

enum AuthStatus {  checking, authenticated, notAuthenticated }

class AuthState {

  final AuthStatus authStatus;
  final User? user;
  final String errorMessage;

  AuthState({
    this.authStatus = AuthStatus.checking, 
    this.user, 
    this.errorMessage = ''
  });

  AuthState copyWith({
    AuthStatus? authStatus,
    User? user,
    String? errorMessage
  }) => AuthState(
    authStatus: authStatus ?? this.authStatus,
    user: user ?? this.user,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
```

#### Login y Logout desde el provider

- Abrimos el archivo `auth_provider.dart` y agregamos el siguiente código:

```dart
import 'package:basic_auth/features/auth/domain/domain.dart';
import 'package:basic_auth/features/auth/infrastructure/infrastructure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {

  final authRepository = AuthRepositoryImpl();

  return AuthNotifier(authRepository: authRepository);
});

class AuthNotifier extends StateNotifier<AuthState> {

  final AuthRepository authRepository;

  AuthNotifier({
    required this.authRepository
  }): super( AuthState() );

  Future<void> loginUser( String email, String password  ) async {

    await Future.delayed( const Duration(milliseconds: 500) );

    try {                                                           // -> Agregamos el try-Catch
      final user = await authRepository.login(email, password);
      _setLoggedUser(user);

    } on WrongCredentials {
      logout('Credenciales no son correctas');
    } catch (e) {
      logout('Error no controlado');
    }

  }

  void registerUser( String email, String password  ) async {
    
  }

  void checkauthStatus() async {
    
  }

  Future<void> logout([String? errorMessage]) async {       // -> Agregamos el logout
    // TODO: limpiar token
    state = state.copyWith(
      authStatus: AuthStatus.notAuthenticated,
      user: null,
      errorMessage: errorMessage
    );
  }

  void _setLoggedUser( User user ) {                        // -> Agregamos el _setLoggerdUser
    // TODO: necesito guardar el token fisicamente
    state = state.copyWith(
      user: user,
      authStatus: AuthStatus.authenticated,
    );
  }
  
}

enum AuthStatus {  checking, authenticated, notAuthenticated }

class AuthState {

  final AuthStatus authStatus;
  final User? user;
  final String errorMessage;

  AuthState({
    this.authStatus = AuthStatus.checking, 
    this.user, 
    this.errorMessage = ''
  });

  AuthState copyWith({
    AuthStatus? authStatus,
    User? user,
    String? errorMessage
  }) => AuthState(
    authStatus: authStatus ?? this.authStatus,
    user: user ?? this.user,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
```


#### Obtener el Token de acceso

- Nota: el error `connection refused`, se da en el emulador de android, ya que utilizamos el localhost y debemos usar el IP de la maquina donde esta el servicio, el servicio es la imagen de docker

#### Manejo de errores

- Abrimos el archivo `auth_errors.dart` y agregamos las nuevas exceptiones

```dart
class WrongCredentials implements Exception {}
class InvalidToken implements Exception {}
class ConnectionTimeout implements Exception {}         // -> se Agrego nueva

class CustomError implements Exception {                // -> Se agrego nueva
  final String message;
  final int errorCode;

  CustomError(this.message, this.errorCode);
}
```

- Abrimos el archivo `auth_datasource_impl.dart` y agregamos las excepciones del login

```dart
import 'package:basic_auth/config/config.dart';
import 'package:basic_auth/features/auth/infrastructure/infrastructure.dart';
import 'package:dio/dio.dart';
import 'package:basic_auth/features/auth/domain/domain.dart';

class AuthDatasourceImpl extends AuthDatasource {

  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
    )
  );


  @override
  Future<User> checkAuthStatus(String token) {
    // TODO: implement checkAuthStatus
    throw UnimplementedError();
  }

  @override
  Future<User> login(String email, String password) async {

    try {
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password
      });

      final user = UserMapper.userJsonToEntity(response.data);

      return user;

    } on DioError catch (e) {                                                       // -> Se agrego nueva
      if ( e.response?.statusCode == 401 ) throw WrongCredentials();                // -> Se agrego nueva
      if ( e.type == DioErrorType.connectionTimeout ) throw ConnectionTimeout();    // -> Se agrego nueva
    throw CustomError('Something wrong happened', 1);                               // -> Se agrego nueva
    
    } catch (e) {
      throw CustomError('Something wrong happened', 1);                             // -> Se agrego nueva
    }
  }

  @override
  Future<User> register(String email, String password, String fullName) {
    // TODO: implement register
    throw UnimplementedError();
  }

}
```

- Abrimos el archivo `auth_provider.dar` y agregamos la validaciones de las excepciones

```dart

import 'package:basic_auth/features/auth/domain/domain.dart';
import 'package:basic_auth/features/auth/infrastructure/infrastructure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {

  final authRepository = AuthRepositoryImpl();

  return AuthNotifier(authRepository: authRepository);
});

class AuthNotifier extends StateNotifier<AuthState> {

  final AuthRepository authRepository;

  AuthNotifier({
    required this.authRepository
  }): super( AuthState() );

  Future<void> loginUser( String email, String password  ) async {

    await Future.delayed( const Duration(milliseconds: 500) );

    try {
      final user = await authRepository.login(email, password);
      _setLoggedUser(user);

    } on WrongCredentials {                             // -> Se agrego nueva
      logout('Credenciales no son correctas');          // -> Se agrego nueva

    } on ConnectionTimeout {                            // -> Se agrego nueva
      logout('Timeout');                                // -> Se agrego nueva
      
    } catch (e) {
      logout('Error no controlado');
    }

  }

  void registerUser( String email, String password  ) async {
    
  }

  void checkauthStatus() async {
    
  }

  Future<void> logout([String? errorMessage]) async {
    // TODO: limpiar token
    state = state.copyWith(
      authStatus: AuthStatus.notAuthenticated,
      user: null,
      errorMessage: errorMessage
    );
  }

  void _setLoggedUser( User user ) {
    // TODO: necesito guardar el token fisicamente
    state = state.copyWith(
      user: user,
      authStatus: AuthStatus.authenticated,
    );
  }
  
}

enum AuthStatus {  checking, authenticated, notAuthenticated }

class AuthState {

  final AuthStatus authStatus;
  final User? user;
  final String errorMessage;

  AuthState({
    this.authStatus = AuthStatus.checking, 
    this.user, 
    this.errorMessage = ''
  });

  AuthState copyWith({
    AuthStatus? authStatus,
    User? user,
    String? errorMessage
  }) => AuthState(
    authStatus: authStatus ?? this.authStatus,
    user: user ?? this.user,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
```


#### Mostrar el error en pantalla

- Abrimos el archivo `login_screen.dart`


```dart

import 'package:basic_auth/features/auth/presentation/providers/auth_provider.dart';
import 'package:basic_auth/features/auth/providers/providers.dart';
import 'package:basic_auth/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          body: GeometricalBackground(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
            
                  const SizedBox( height: 60 ),
            
                  //* Icon Banner
                  const Icon(
                    Icons.production_quantity_limits_rounded,
                    color: Colors.white,
                    size: 70,
                  ),
            
                  const SizedBox( height: 60 ),
            
                  Container(
                    width: double.infinity,
                    height: size.height - 260,
                    decoration: BoxDecoration(
                      color: scaffoldBackgroundColor,
                      // color: Colors.lightBlue[200],
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(100)),
                    ),
                    child: const _LoginForm(),
                  )
            
            
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends ConsumerWidget {

  const _LoginForm();

  void showSnackbar(BuildContext context, String message) {     // -> Se agrego el showSnackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

     //* Tener acceso al state del loginFromProvider
    final loginForm = ref.watch(loginFormProvider);

    ref.listen(authProvider, (previous, next) {                 // -> Se agrego el listener
      if ( next.errorMessage.isEmpty ) return;                  // -> Se agrego
      showSnackbar( context, next.errorMessage );               // -> Se agrego el showSnackbar
    });

    final textStyle = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric( horizontal: 50 ),
      child: Column(
        children: [

          const SizedBox( height: 40 ),
          Text('Login', style: textStyle.titleMedium),
          const SizedBox( height: 50 ),

          CustomTextFormField(
            label: 'Correo',
            keyboardType: TextInputType.emailAddress,
            onChanged: ref.read(loginFormProvider.notifier).onEmailChange,
            errorMessage: loginForm.isFromPosted
              ? loginForm.email.errorMessage
              : null,
          ),
          const SizedBox( height: 30 ),

          CustomTextFormField(
            label: 'Constraseña',
            obscureText: true,
            onChanged: ref.read(loginFormProvider.notifier).onPasswordChange,
            errorMessage: loginForm.isFromPosted  
              ? loginForm.password.errorMessage
              : null,
          ),
          const SizedBox( height: 30 ),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: CustomFilledButton(
              text: 'Ingresar',
              buttonColor: Colors.black,
              onPressed: () {
                ref.read(loginFormProvider.notifier).onFormSubmit();
              },
            ),
          ),

          const Spacer( flex: 2 ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿No tienes cuenta?'),
              TextButton(
                onPressed: () => context.push('/register'), 
                child: const Text('Crea una aquí')
              )
            ],
          ),

          const Spacer( flex: 1 ),
        ],
      ),
    );
  }
}

```


- Abrimos el archivo `auth_errors.dart` y a la clase `CustomError` le quitamos el errorCode

- Abrimos el archivo `auth_datasource_impl.dart`

```dart

import 'package:basic_auth/config/config.dart';
import 'package:basic_auth/features/auth/infrastructure/infrastructure.dart';
import 'package:dio/dio.dart';
import 'package:basic_auth/features/auth/domain/domain.dart';

class AuthDatasourceImpl extends AuthDatasource {

  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
    )
  );


  @override
  Future<User> checkAuthStatus(String token) {
    // TODO: implement checkAuthStatus
    throw UnimplementedError();
  }

  @override
  Future<User> login(String email, String password) async {

    try {
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password
      });

      final user = UserMapper.userJsonToEntity(response.data);

      return user;

    } on DioError catch (e) {
      if ( e.response?.statusCode == 401 ) {                                            // -> Se Modifico el if
        throw CustomError(e.response?.data['message'] ?? 'Credenciales incorrectas' );  // -> Se agrego el CustomError
      }
      if ( e.type == DioErrorType.connectionTimeout ) throw ConnectionTimeout();
    throw CustomError('Something wrong happened');
    
    } catch (e) {
      throw CustomError('Something wrong happened');
    }
  }

  @override
  Future<User> register(String email, String password, String fullName) {
    // TODO: implement register
    throw UnimplementedError();
  }

}
```

- Abrir el archivo `auth_provider.dart` y agregar lo siguiente

```dart

import 'package:basic_auth/features/auth/domain/domain.dart';
import 'package:basic_auth/features/auth/infrastructure/infrastructure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {

  final authRepository = AuthRepositoryImpl();

  return AuthNotifier(authRepository: authRepository);
});

class AuthNotifier extends StateNotifier<AuthState> {

  final AuthRepository authRepository;

  AuthNotifier({
    required this.authRepository
  }): super( AuthState() );

  Future<void> loginUser( String email, String password  ) async {

    await Future.delayed( const Duration(milliseconds: 500) );

    try {
      final user = await authRepository.login(email, password);
      _setLoggedUser(user);
    } on CustomError catch (e) {            // -> Se agrego el CustomError
      logout( e.message );                  // -> Se agrego
    } catch (e) {
      logout('Error no controlado');                 // -> Se agrego
    }

  }

  void registerUser( String email, String password  ) async {
    
  }

  void checkauthStatus() async {
    
  }

  Future<void> logout([String? errorMessage]) async {
    // TODO: limpiar token
    state = state.copyWith(
      authStatus: AuthStatus.notAuthenticated,
      user: null,
      errorMessage: errorMessage
    );
  }

  void _setLoggedUser( User user ) {
    // TODO: necesito guardar el token fisicamente
    state = state.copyWith(
      user: user,
      authStatus: AuthStatus.authenticated,
    );
  }
  
}

enum AuthStatus {  checking, authenticated, notAuthenticated }

class AuthState {

  final AuthStatus authStatus;
  final User? user;
  final String errorMessage;

  AuthState({
    this.authStatus = AuthStatus.checking, 
    this.user, 
    this.errorMessage = ''
  });

  AuthState copyWith({
    AuthStatus? authStatus,
    User? user,
    String? errorMessage
  }) => AuthState(
    authStatus: authStatus ?? this.authStatus,
    user: user ?? this.user,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
```

#### Register desde el Provider

- Abrimos el archivo `auth_provider.dart` y agregamos el siguiente código para el register:

```dart

import 'package:basic_auth/features/auth/domain/domain.dart';
import 'package:basic_auth/features/auth/infrastructure/infrastructure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {

  final authRepository = AuthRepositoryImpl();

  return AuthNotifier(authRepository: authRepository);
});

class AuthNotifier extends StateNotifier<AuthState> {

  final AuthRepository authRepository;

  AuthNotifier({
    required this.authRepository
  }): super( AuthState() );

  Future<void> loginUser( String email, String password  ) async {

    await Future.delayed( const Duration(milliseconds: 500) );

    try {
      final user = await authRepository.login(email, password);
      _setLoggedUser(user);
    } on CustomError catch (e) {
      logout( e.message );
    } catch (e) {
      logout('Error no controlado');
    }

  }

  void registerUser( String email, String password, String fullName  ) async {
    
    await Future.delayed( const Duration(milliseconds: 500) );                  // -> Se agrego

    try {                                                                       // -> Se agrego
      final user = await authRepository.register(email, password, fullName);    // -> Se agrego
      _setLoggedUser(user);                                                     // -> Se agrego
    } on CustomError catch (e) {                                                // -> Se agrego
      logout(e.message);                                                        // -> Se agrego
    } catch (e) {                                                               // -> Se agrego
      logout('Error no controlado');                                            // -> Se agrego
    }                                                                           // -> Se agrego
  }

  void checkauthStatus() async {
    
  }

  Future<void> logout([String? errorMessage]) async {
    // TODO: limpiar token
    state = state.copyWith(
      authStatus: AuthStatus.notAuthenticated,
      user: null,
      errorMessage: errorMessage
    );
  }

  void _setLoggedUser( User user ) {
    // TODO: necesito guardar el token fisicamente
    state = state.copyWith(
      user: user,
      authStatus: AuthStatus.authenticated,
    );
  }
  
}

enum AuthStatus {  checking, authenticated, notAuthenticated }

class AuthState {

  final AuthStatus authStatus;
  final User? user;
  final String errorMessage;

  AuthState({
    this.authStatus = AuthStatus.checking, 
    this.user, 
    this.errorMessage = ''
  });

  AuthState copyWith({
    AuthStatus? authStatus,
    User? user,
    String? errorMessage
  }) => AuthState(
    authStatus: authStatus ?? this.authStatus,
    user: user ?? this.user,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
```

- Abrimos el archivo `auth_datasource_impl.dart`, para realizar la implementación del register llamando al api

```dart

import 'package:basic_auth/config/config.dart';
import 'package:basic_auth/features/auth/infrastructure/infrastructure.dart';
import 'package:dio/dio.dart';
import 'package:basic_auth/features/auth/domain/domain.dart';

class AuthDatasourceImpl extends AuthDatasource {

  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
    )
  );


  @override
  Future<User> checkAuthStatus(String token) {
    // TODO: implement checkAuthStatus
    throw UnimplementedError();
  }

  @override
  Future<User> login(String email, String password) async {

    try {
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password
      });

      final user = UserMapper.userJsonToEntity(response.data);

      return user;

    } on DioError catch (e) {
      if ( e.response?.statusCode == 401 ) {
        throw CustomError(e.response?.data['message'] ?? 'Credenciales incorrectas' );
      }
      if ( e.type == DioErrorType.connectionTimeout ) {
        throw CustomError( 'Revisar conexión a internet' );
      }
      throw Exception();
    
    } catch (e) {
      throw Exception();
    }
  }

  @override
  Future<User> register(String email, String password, String fullName) async {       // -> Se agrego
    try {                                                                             // -> Se agrego
      final response = await dio.post('/auth/register', data: {                       // -> Se agrego
        'email': email,                                                               // -> Se agrego
        'password': password,                                                         // -> Se agrego
        'fullName': fullName,                                                         // -> Se agrego
      });                                                                             // -> Se agrego

      final user = UserMapper.userJsonToEntity(response.data);                        // -> Se agrego

      return user;                                                                    // -> Se agrego

    } on DioError catch (e) {                                                         // -> Se agrego
      if ( e.response?.statusCode == 400 ) {                                          // -> Se agrego
        throw CustomError(e.response?.data['message'] ?? 'Bad request');              // -> Se agrego
      }                                                                               // -> Se agrego
      if ( e.type == DioErrorType.connectionTimeout ) {                               // -> Se agrego
        throw CustomError( 'Revisar conexión a internet' );                           // -> Se agrego
      }                                                                               // -> Se agrego
      throw Exception();                                                              // -> Se agrego
    } catch (e) {                                                                     // -> Se agrego
      throw Exception();                                                              // -> Se agrego
    }                                                                                 // -> Se agrego
  }                                                                                   // -> Se agrego

}
```


- Abrimos el archivo `register_form_provider.dart`


```dart


import 'package:basic_auth/features/auth/presentation/providers/auth_provider.dart';
import 'package:basic_auth/features/shared/shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';

//! 3 - StateNotifierProvider - consume afuera
final registerFormProvider = StateNotifierProvider.autoDispose<RegisterFormNotifier, RegisterFormState>((ref) {
  
  //* Tener la referencia al metodo del register
  final registerCallback = ref.watch(authProvider.notifier).registerUser;     // -> Se agrego


  return RegisterFormNotifier(
    registerCallback: registerCallback                                        // -> Se agrego              
  );
});

//! 2 - Como implementar el notifier
class RegisterFormNotifier extends StateNotifier<RegisterFormState> {

  final Function(String, String, String) registerCallback;                    // -> Se agrego

  RegisterFormNotifier({
    required this.registerCallback                                            // -> Se agrego
  }): super( RegisterFormState() );

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

  onFormSubmit() async {
    _touchEveryField();

    if ( !state.isValid ) return;

    await registerCallback( state.email.value, state.password.value, state.username.value );  // -> Se agrego
    

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

```

- Abrir el archivo `register_screen.dart`

```dart

import 'package:basic_auth/features/auth/providers/providers.dart';
import 'package:basic_auth/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textStyles = Theme.of(context).textTheme;

    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          body: GeometricalBackground(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox( height: 30 ),
            
                  //* Icon Banner
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(bottomRight: Radius.circular(10), topRight: Radius.circular(10)),
                        ),
                        child:  IconButton(
                          onPressed: () {
                            if ( !context.canPop() ) return;
                            context.pop();
                          }, 
                          icon: const Icon( Icons.arrow_back_rounded, size: 25, color: Colors.black,),
                        ),
                      ),
                      const Spacer(flex: 1),
                      Text('Crear cuenta', style: textStyles.titleMedium?.copyWith(color: Colors.white)),
                      const Spacer(flex: 2),
                    ],
                  ),
            
                  const SizedBox( height: 80),
            
                  Container(
                    height: size.height + 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: scaffoldBackgroundColor,
                      // color: Colors.red,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(100)),
                    ),
                    child: const _RegisterForm(),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterForm extends ConsumerWidget {

  const _RegisterForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {

     //* Tener acceso al state del registerFromProvider
    final registerForm = ref.watch(registerFormProvider);               // -> Se agrego

    final textStyles = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [

          const SizedBox( height: 50 ),
          Text('Nueva cuenta', style: textStyles.titleMedium),
          const SizedBox( height: 50 ),

          CustomTextFormField(
            label: 'Nombre completo',
            onChanged: ref.read(registerFormProvider.notifier).onUsernameChange,
            errorMessage: registerForm.isFromPosted
              ? registerForm.username.errorMessage
              : null,
          ),
          const SizedBox(height: 30),

          CustomTextFormField(
            label: 'Correo',
            keyboardType: TextInputType.emailAddress,
            onChanged: ref.read(registerFormProvider.notifier).onEmailChange,
            errorMessage: registerForm.isFromPosted
              ? registerForm.email.errorMessage
              : null,
          ),
          const SizedBox(height: 30),

          CustomTextFormField(
            label: 'Password',
            obscureText: true,
            onChanged: ref.read(registerFormProvider.notifier).onPasswordChange,
            errorMessage: registerForm.isFromPosted
              ? registerForm.password.errorMessage
              : null,

          ),
          const SizedBox(height: 30),

          CustomTextFormField(
            label: 'Repita el password',
            obscureText: true,
            onChanged: ref.read(registerFormProvider.notifier).onConfirmedPasswordChange,
            errorMessage: registerForm.isFromPosted
              ? registerForm.confirmedPassword.errorMessage
              : null,
          ),

          const SizedBox(height: 50),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: CustomFilledButton(
              text: 'Crear',
              buttonColor: Colors.black,
               onPressed: () {
                ref.read(registerFormProvider.notifier).onFormSubmit();             // -> Se agrego
              },
            ),
          ),

          const Spacer(flex: 2),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿Ya tienes cuenta?'),
              TextButton(
                onPressed: () {
                  if ( context.canPop() ) {
                    return context.pop();
                  }
                  context.go('/login');
                }, 
                child: const Text('Ingresa aquí')
              )
            ],
          ),

          const Spacer(flex: 2),

        ],
      ),
    );
  }
}
```



### Go Router - Protección de Rutas

#### Preferencias de usuario - Shared Preferences

- Instalamos el paquete de `shared_preferences` que nos permite grabar data en el dispositivo
```
flutter pub add shared_preferences
```
Documentación: https://pub.dev/packages/shared_preferences


- Creamos una carpeta nueva llamada `services` dentro de `lib -> features -> shared -> infrastructure`

- Agregamos un nuevo archivo llamado `key_value_storage_service.dart`

- Agregamos el siguiente código:

```dart
abstract class KeyValueStorageService {

  Future<void> setKeyValue(String key, value);
  Future getValue(String key);
  Future removeKey(String key);
} 
```

#### Implementar el patrón adaptador

- Modificamos el archvio `key_value_storage_service.dart` agregando tipo de datos genericos

```dart
abstract class KeyValueStorageService {

  Future<void> setKeyValue<T>(String key, T value);
  Future<T?> getValue<T>(String key);
  Future<bool> removeKey(String key);
} 
```

- Creamos el archivo `key_value_storage_service_impl.dart`, para realizar la implementación

```dart
import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_storage_service.dart';

class KeyValueStorageServiceImpl extends KeyValueStorageService {

  Future<SharedPreferences> getSharedPrefs() async {
    return await SharedPreferences.getInstance();
  }

  @override
  Future<T?> getValue<T>(String key) async {
   final prefs = await getSharedPrefs();

    switch (T) {
      case int:
        return prefs.getInt( key) as T?;
      
      case String:
        return prefs.getString(key) as T?;

      default:
        throw UnimplementedError('Get not implemented for type ${ T.runtimeType }');
    }
  }

  @override
  Future<bool> removeKey(String key) async {
    final prefs = await getSharedPrefs();
    return await prefs.remove(key);
  }

  @override
  Future<void> setKeyValue<T>(String key, T value) async {
    final prefs = await getSharedPrefs();

    switch (T) {
      case int:
        prefs.setInt( key, value as int);
        break;
      
      case String:
        prefs.setString(key, value as String);
        break;

      default:
        throw UnimplementedError('Set not implemented for type ${ T.runtimeType }');
    }

  }

}
```


#### Guardar Token en el dispositivo

- abrimos el archivo `auth_provider.dar`


```dart

import 'package:basic_auth/features/auth/domain/domain.dart';
import 'package:basic_auth/features/auth/infrastructure/infrastructure.dart';
import 'package:basic_auth/features/shared/infrastructure/services/key_value_storage_service.dart';
import 'package:basic_auth/features/shared/infrastructure/services/key_value_storage_service_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {

  final authRepository = AuthRepositoryImpl();
  final keyValueStorageService = KeyValueStorageServiceImpl();    // -> Se agrego

  return AuthNotifier(
    authRepository: authRepository,
    keyValueStorageService: keyValueStorageService                // -> Se agrego
  );
});

class AuthNotifier extends StateNotifier<AuthState> {

  final AuthRepository authRepository;
  final KeyValueStorageService keyValueStorageService;            // -> Se agrego

  AuthNotifier({
    required this.authRepository,
    required this.keyValueStorageService                          // -> Se agrego
  }): super( AuthState() );

  Future<void> loginUser( String email, String password  ) async {

    await Future.delayed( const Duration(milliseconds: 500) );

    try {
      final user = await authRepository.login(email, password);
      _setLoggedUser(user);
    } on CustomError catch (e) {
      logout( e.message );
    } catch (e) {
      logout('Error no controlado');
    }

  }

  void registerUser( String email, String password, String fullName  ) async {
    
    await Future.delayed( const Duration(milliseconds: 500) );

    try {
      final user = await authRepository.register(email, password, fullName);
      _setLoggedUser(user);
    } on CustomError catch (e) {
      logout(e.message);
    } catch (e) {
      logout('Error no controlado');
    }
  }

  void checkauthStatus() async {
    
  }

  Future<void> logout([String? errorMessage]) async {
    await keyValueStorageService.removeKey('token');                // -> Se agrego

    state = state.copyWith(
      authStatus: AuthStatus.notAuthenticated,
      user: null,
      errorMessage: errorMessage
    );
  }

  void _setLoggedUser( User user ) async {
    await keyValueStorageService.setKeyValue('token', user.token);  // -> Se agrego
    
    state = state.copyWith(
      user: user,
      authStatus: AuthStatus.authenticated,
      errorMessage: '',
    );
  }
  
}

enum AuthStatus {  checking, authenticated, notAuthenticated }

class AuthState {

  final AuthStatus authStatus;
  final User? user;
  final String errorMessage;

  AuthState({
    this.authStatus = AuthStatus.checking, 
    this.user, 
    this.errorMessage = ''
  });

  AuthState copyWith({
    AuthStatus? authStatus,
    User? user,
    String? errorMessage
  }) => AuthState(
    authStatus: authStatus ?? this.authStatus,
    user: user ?? this.user,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
```


####  Revisar el estado de la autenticación

- Abrimos el archivo `auth_provider.dart`, para usar la función `checkauthStatus`


```dart
import 'package:basic_auth/features/auth/domain/domain.dart';
import 'package:basic_auth/features/auth/infrastructure/infrastructure.dart';
import 'package:basic_auth/features/shared/infrastructure/services/key_value_storage_service.dart';
import 'package:basic_auth/features/shared/infrastructure/services/key_value_storage_service_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {

  final authRepository = AuthRepositoryImpl();
  final keyValueStorageService = KeyValueStorageServiceImpl();

  return AuthNotifier(
    authRepository: authRepository,
    keyValueStorageService: keyValueStorageService
  );
});

class AuthNotifier extends StateNotifier<AuthState> {

  final AuthRepository authRepository;
  final KeyValueStorageService keyValueStorageService;

  AuthNotifier({
    required this.authRepository,
    required this.keyValueStorageService
  }): super( AuthState() ) {
    checkauthStatus();                                                  // -> Se agrego
  }

  Future<void> loginUser( String email, String password  ) async {

    await Future.delayed( const Duration(milliseconds: 500) );

    try {
      final user = await authRepository.login(email, password);
      _setLoggedUser(user);
    } on CustomError catch (e) {
      logout( e.message );
    } catch (e) {
      logout('Error no controlado');
    }

  }

  void registerUser( String email, String password, String fullName  ) async {
    
    await Future.delayed( const Duration(milliseconds: 500) );

    try {
      final user = await authRepository.register(email, password, fullName);
      _setLoggedUser(user);
    } on CustomError catch (e) {
      logout(e.message);
    } catch (e) {
      logout('Error no controlado');
    }
  }

  void checkauthStatus() async {
    
    final token = await keyValueStorageService.getValue<String>('token');   // -> Se agrego

    if ( token == null ) return logout();                                   // -> Se agrego

    try {                                                                   // -> Se agrego
      final user = await authRepository.checkAuthStatus(token);             // -> Se agrego
      _setLoggedUser(user);                                                 // -> Se agrego

    } catch (e) {                                                           // -> Se agrego
      logout();                                                             // -> Se agrego
    }                                                                       // -> Se agrego

  }

  Future<void> logout([String? errorMessage]) async {
    await keyValueStorageService.removeKey('token');

    state = state.copyWith(
      authStatus: AuthStatus.notAuthenticated,
      user: null,
      errorMessage: errorMessage
    );
  }

  void _setLoggedUser( User user ) async {
    await keyValueStorageService.setKeyValue('token', user.token);

    state = state.copyWith(
      user: user,
      authStatus: AuthStatus.authenticated,
      errorMessage: '',
    );
  }
  
}

enum AuthStatus {  checking, authenticated, notAuthenticated }

class AuthState {

  final AuthStatus authStatus;
  final User? user;
  final String errorMessage;

  AuthState({
    this.authStatus = AuthStatus.checking, 
    this.user, 
    this.errorMessage = ''
  });

  AuthState copyWith({
    AuthStatus? authStatus,
    User? user,
    String? errorMessage
  }) => AuthState(
    authStatus: authStatus ?? this.authStatus,
    user: user ?? this.user,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
```

- Abrimos el archivo `auth_datasource_impl.dart`, para realizar la implementacion del `checkAuthStatus`


```dart

import 'package:basic_auth/config/config.dart';
import 'package:basic_auth/features/auth/infrastructure/infrastructure.dart';
import 'package:dio/dio.dart';
import 'package:basic_auth/features/auth/domain/domain.dart';

class AuthDatasourceImpl extends AuthDatasource {

  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
    )
  );


  @override
  Future<User> checkAuthStatus(String token) async {

    try {                                                       // -> Se agrego
      final response = await dio.get('/auth/check-status',      // -> Se agrego
        options: Options(                                       // -> Se agrego
          headers: {                                            // -> Se agrego
            'Authorization': 'Bearer $token'                    // -> Se agrego
          }
        ) 
      );

      final user = UserMapper.userJsonToEntity(response.data);  // -> Se agrego
      return user;                                              // -> Se agrego

    } on DioError catch (e) {                                   // -> Se agrego
      if ( e.response?.statusCode == 401 ) {                    // -> Se agrego
        throw CustomError('Token incorrecto');                  // -> Se agrego
      }
      throw Exception();                                        // -> Se agrego
    
    } catch (e) {                                               // -> Se agrego
      throw Exception();                                        // -> Se agrego
    }
  }

  @override
  Future<User> login(String email, String password) async {

    try {
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password
      });

      final user = UserMapper.userJsonToEntity(response.data);

      return user;

    } on DioError catch (e) {
      if ( e.response?.statusCode == 401 ) {
        throw CustomError(e.response?.data['message'] ?? 'Credenciales incorrectas' );
      }
      if ( e.type == DioErrorType.connectionTimeout ) {
        throw CustomError( 'Revisar conexión a internet' );
      }
      throw Exception();
    
    } catch (e) {
      throw Exception();
    }
  }

  @override
  Future<User> register(String email, String password, String fullName) async {
    try {
      final response = await dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
      });

      final user = UserMapper.userJsonToEntity(response.data);

      return user;

    } on DioError catch (e) {
      if ( e.response?.statusCode == 400 ) {
        throw CustomError(e.response?.data['message'] ?? 'Bad request');
      }
      if ( e.type == DioErrorType.connectionTimeout ) {
        throw CustomError( 'Revisar conexión a internet' );
      }
      throw Exception();
    } catch (e) {
      throw Exception();
    }
  }

}
```


#### Check Auth Status Screen

- Creamos el nuevo screen `check_auth_status_screen.dart` y agregamos el siguiente código:

```dart
import 'package:flutter/material.dart';

class CheckAuthStatusScreen extends StatelessWidget {
  const CheckAuthStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
```

- Agregamos la nueva ruta en el `app_router.dart`

```dart


import 'package:basic_auth/features/auth/presentation/screens/login_screen.dart';
import 'package:basic_auth/features/auth/presentation/screens/register_screen.dart';
import 'package:basic_auth/features/auth/presentation/screens/screens.dart';
import 'package:basic_auth/features/products/presentation/screens/products_screen.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',                                       // -> Se agrego el splash
  routes: [

    //* Primera pantalla
    GoRoute(                                                        // -> Se agrego el splash
      path: '/splash',                                              // -> Se agrego el splash
      builder: (context, state) => const CheckAuthStatusScreen(),   // -> Se agrego el splash
    ), 

    //* Auth Routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    //* Product Routes
    GoRoute(
      path: '/',
      builder: (context, state) => const ProductsScreen(),
    ),
  ]
);
```

- Abrir el archivo `side_menu.dart`, donde esta el boton de cerrar session y cambiamos de `StatefulWidget` a un `ConsumerStatefulWidget`

```dart


import 'package:basic_auth/features/auth/presentation/providers/auth_provider.dart';
import 'package:basic_auth/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SideMenu extends ConsumerStatefulWidget {                     // -> Se cambio a ConsumerStatefulWidget

  final GlobalKey<ScaffoldState> scaffoldKey;

  const SideMenu({
    super.key, 
    required this.scaffoldKey
  });

  @override
  SideMenuState createState() => SideMenuState();                 // -> Se cambio
}

class SideMenuState extends ConsumerState<SideMenu> {             // -> Se cambio

  int navDrawerIndex = 0;

  @override
  Widget build(BuildContext context) {

    final hasNotch = MediaQuery.of(context).viewPadding.top > 35;
    final textStyles = Theme.of(context).textTheme;
    
    return NavigationDrawer(
      elevation: 1,
      selectedIndex: navDrawerIndex,
      onDestinationSelected: (value) {

        setState(() {
          navDrawerIndex = value;
        });

        // final menuItem = appMenuItems[value];
        // context.push( menuItem.link );
        widget.scaffoldKey.currentState?.closeDrawer();
      },
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, hasNotch ? 0 : 20, 16, 0),
          child: Text('Saludos', style: textStyles.titleMedium),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 10),
          child: Text('Tony Stark', style: textStyles.titleSmall),
        ),

        const NavigationDrawerDestination(
          icon: Icon( Icons.home_outlined), 
          label: Text('Productos')
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(28, 10, 16, 10),
          child: Text('Otras opciones'),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomFilledButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();               // -> Se agrego
            },
            text: 'Cerrar sesión',
          ),
        )
      ],
    );
  }
}
```


#### Go_Router - Protección de Rutas

- Abrimos el archivo `app_router.dart` y  creamos un provider que no va a modificar el goRouter

```dart

import 'package:basic_auth/features/auth/presentation/screens/screens.dart';
import 'package:basic_auth/features/products/presentation/screens/products_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


//* Provider sencillo por que no va a cambiar el GoRouter
final goRouterProvider = Provider((ref) {

  return GoRouter(
    initialLocation: '/splash',
    routes: [

      //* Primera pantalla
      GoRoute(
        path: '/splash',
        builder: (context, state) => const CheckAuthStatusScreen(),
      ), 

      //* Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      //* Product Routes
      GoRoute(
        path: '/',
        builder: (context, state) => const ProductsScreen(),
      ),
    ]
  );
});
```

- Abrimos el archivo `main.dart` y realizamos la siguientes modificaciones, cambiamos de `StatelessWidget` a `ConsumerWidget`

```dart
import 'package:basic_auth/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {

  await Environment.initEnvironment();

  runApp(
    const ProviderScope(child: MainApp())
  );
}

class MainApp extends ConsumerWidget {                      // -> Se modifico por un ConsumerWidget
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {       // -> Se agrego WidgetRef

    //* Como estoy dentro de un build uso el watch
    final appRouter = ref.watch(goRouterProvider);          // -> Se agrego

    return MaterialApp.router(
      routerConfig: appRouter,
      theme: AppTheme().getTheme(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```


#### GoRouterNotifier

- Implementamos un ChangeNotifier, creamos un nuevo archivo llamado `app_router_notifier.dart`

```dart
import 'package:basic_auth/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goRouterNotifierProvider = Provider((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  return GoRouterNotifier(authNotifier);
});

class GoRouterNotifier extends ChangeNotifier {

  final AuthNotifier _authNotifier;

  AuthStatus _authStatus = AuthStatus.checking;

  GoRouterNotifier(this._authNotifier) {
    _authNotifier.addListener((state) {
      authStatus = state.authStatus;
    });
  }
  
  AuthStatus get authStatus => _authStatus;

  set authStatus(AuthStatus value) {
    _authStatus = value;
    notifyListeners();
  }
}
```

- Abrimos el archivo `app_router.dart` 

```dart


import 'package:basic_auth/config/router/app_router_notifier.dart';
import 'package:basic_auth/features/auth/presentation/screens/screens.dart';
import 'package:basic_auth/features/products/presentation/screens/products_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


//* Provider sencillo por que no va a cambiar el GoRouter
final goRouterProvider = Provider((ref) {

  final goRouterNotifier = ref.read(goRouterNotifierProvider);        // -> Se agrego

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: goRouterNotifier,                              // -> Se agrego
    routes: [

      //* Primera pantalla
      GoRoute(
        path: '/splash',
        builder: (context, state) => const CheckAuthStatusScreen(),
      ), 

      //* Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      //* Product Routes
      GoRoute(
        path: '/',
        builder: (context, state) => const ProductsScreen(),
      ),
    ],

    redirect: (context, state) {                                      // -> Se agrego
      
      return null;                                                    // -> Se agrego
    }

  );
});
```


#### Navegar dependiendo de la autenticación

- Abrimos el archivo `app_router.dart` y agregamos el siguiente código

```dart


import 'package:basic_auth/config/router/app_router_notifier.dart';
import 'package:basic_auth/features/auth/presentation/providers/auth_provider.dart';
import 'package:basic_auth/features/auth/presentation/screens/screens.dart';
import 'package:basic_auth/features/products/presentation/screens/products_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


//* Provider sencillo por que no va a cambiar el GoRouter
final goRouterProvider = Provider((ref) {

  final goRouterNotifier = ref.read(goRouterNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: goRouterNotifier,
    routes: [

      //* Primera pantalla
      GoRoute(
        path: '/splash',
        builder: (context, state) => const CheckAuthStatusScreen(),
      ), 

      //* Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      //* Product Routes
      GoRoute(
        path: '/',
        builder: (context, state) => const ProductsScreen(),
      ),
    ],

    redirect: (context, state) {
      
      // state.subloc ahora es state.matchedLocation
      // state.params ahora es state.pathParameters

      final isGoingTo = state.matchedLocation;                                          // -> Se agrego
      final authStatus = goRouterNotifier.authStatus;                                   // -> Se agrego

      if ( isGoingTo == '/splash' && authStatus == AuthStatus.checking ) return null;   // -> Se agrego

      if ( authStatus == AuthStatus.notAuthenticated ) {                                // -> Se agrego
        if ( isGoingTo == '/login' || isGoingTo == '/register' ) return null;           // -> Se agrego

        return '/login';                                                                // -> Se agrego
      }

      if ( authStatus == AuthStatus.authenticated ) {                                   // -> Se agrego
        if ( isGoingTo == '/login' || isGoingTo == '/register' || isGoingTo == '/splash' ) {    // -> Se agrego
          return '/';                                                                   // -> Se agrego
        } 
      }

      return null;                                                                      // -> Se agrego
    }

  );
});
```


#### Bloquear botón de login

- abrimos el archivo `login_form_provider.dart`, cambiamos el state de `isPosting`



```dart
import 'package:basic_auth/features/auth/presentation/providers/auth_provider.dart';
import 'package:basic_auth/features/shared/shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';

//! 3 - StateNotifierProvider - consume afuera
final loginFormProvider = StateNotifierProvider.autoDispose<LoginFormNotifier, LoginFormState>((ref) {

  //* Tener la referencia al metodo del loginUser
  final loginUserCallback = ref.watch(authProvider.notifier).loginUser;

  return LoginFormNotifier(
    loginUserCallback: loginUserCallback
  );
});

//! 2 - Como imlementar un notifier
class LoginFormNotifier extends StateNotifier<LoginFormState> {

  final Function(String, String) loginUserCallback;

  LoginFormNotifier({
    required this.loginUserCallback
  }): super( LoginFormState() );

  //* Methodos
  onEmailChange( String value) {
    final newEmail = Email.dirty(value);
    state = state.copyWith(
      email: newEmail,
      isValid: Formz.validate([ newEmail, state.password ])
    );
  } 

  onPasswordChange( String value) {
    final newPassword = Password.dirty(value);
    state = state.copyWith(
      password: newPassword,
      isValid: Formz.validate([ newPassword, state.email ])
    );
  } 

  onFormSubmit() async {
    _touchEveryField();

    if ( !state.isValid ) return;

    state = state.copyWith(isPosting: true);                              // -> Se agrego

    await loginUserCallback( state.email.value, state.password.value );

    state = state.copyWith(isPosting: false);                             // -> Se agrego

  }

  _touchEveryField() {
    final email    = Email.dirty(state.email.value);
    final password = Password.dirty(state.password.value);

    state = state.copyWith(
      isFromPosted: true,
      email: email,
      password: password,
      isValid: Formz.validate([ email, password ])
    );
  }
  
}

//! 1 - State del provider

class LoginFormState {

  final bool isPosting;
  final bool isFromPosted;
  final bool isValid;
  final Email email;
  final Password password;

  LoginFormState({
    this.isPosting = false, 
    this.isFromPosted = false, 
    this.isValid = false, 
    this.email = const Email.pure(), 
    this.password = const Password.pure()
  });

  LoginFormState copyWith({
    bool? isPosting,
    bool? isFromPosted,
    bool? isValid,
    Email? email,
    Password? password,
  }) => LoginFormState(
    isPosting: isPosting ?? this.isPosting,
    isFromPosted: isFromPosted ?? this.isFromPosted,
    isValid: isValid ?? this.isValid,
    email: email ?? this.email,
    password: password ?? this.password,    
  );


  // * Para hacer una impresion del estado
  @override
  String toString() {
    return '''
      LoginFormState:
      isPosting: $isPosting
      isFromPosted: $isFromPosted 
      isValid: $isValid 
      email: $email 
      password: $password
    ''';
  }
}
```

- Abrimos el archivo `login_screen.dart`, para de manera condicionada habilitar o deshabilitar el botón de Ingresar

```dart
import 'dart:ffi';

import 'package:basic_auth/features/auth/presentation/providers/auth_provider.dart';
import 'package:basic_auth/features/auth/providers/providers.dart';
import 'package:basic_auth/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          body: GeometricalBackground(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
            
                  const SizedBox( height: 60 ),
            
                  //* Icon Banner
                  const Icon(
                    Icons.production_quantity_limits_rounded,
                    color: Colors.white,
                    size: 70,
                  ),
            
                  const SizedBox( height: 60 ),
            
                  Container(
                    width: double.infinity,
                    height: size.height - 260,
                    decoration: BoxDecoration(
                      color: scaffoldBackgroundColor,
                      // color: Colors.lightBlue[200],
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(100)),
                    ),
                    child: const _LoginForm(),
                  )
            
            
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends ConsumerWidget {

  const _LoginForm();

  void showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

     //* Tener acceso al state del loginFromProvider
    final loginForm = ref.watch(loginFormProvider);

    ref.listen(authProvider, (previous, next) { 
      if ( next.errorMessage.isEmpty ) return;
      showSnackbar( context, next.errorMessage );
    });

    final textStyle = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric( horizontal: 50 ),
      child: Column(
        children: [

          const SizedBox( height: 40 ),
          Text('Login', style: textStyle.titleMedium),
          const SizedBox( height: 50 ),

          CustomTextFormField(
            label: 'Correo',
            keyboardType: TextInputType.emailAddress,
            onChanged: ref.read(loginFormProvider.notifier).onEmailChange,
            errorMessage: loginForm.isFromPosted
              ? loginForm.email.errorMessage
              : null,
          ),
          const SizedBox( height: 30 ),

          CustomTextFormField(
            label: 'Constraseña',
            obscureText: true,
            onChanged: ref.read(loginFormProvider.notifier).onPasswordChange,
            errorMessage: loginForm.isFromPosted  
              ? loginForm.password.errorMessage
              : null,
          ),
          const SizedBox( height: 30 ),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: CustomFilledButton(
              text: 'Ingresar',
              buttonColor: Colors.black,
              onPressed: loginForm.isPosting                            // -> Se agrego
                ? null                                                  // -> Se agrego
                : ref.read(loginFormProvider.notifier).onFormSubmit     // -> Se agrego
            ),
          ),

          const Spacer( flex: 2 ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿No tienes cuenta?'),
              TextButton(
                onPressed: () => context.push('/register'), 
                child: const Text('Crea una aquí')
              )
            ],
          ),

          const Spacer( flex: 1 ),
        ],
      ),
    );
  }
}

```