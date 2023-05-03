
import 'package:basic_auth/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
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
                          icon: const Icon( Icons.arrow_back_rounded, size: 40, color: Colors.black,),
                        ),
                      ),
                      const Spacer(flex: 1),
                      Text('Crear cuenta', style: textStyles.titleLarge?.copyWith(color: Colors.white)),
                      const Spacer(flex: 2),
                    ],
                  ),
            
                  const SizedBox( height: 80),
            
                  Container(
                    height: size.height - 100,
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

class _RegisterForm extends StatelessWidget {

  const _RegisterForm();

  @override
  Widget build(BuildContext context) {

    final textStyles = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [

          const SizedBox( height: 50 ),
          Text('Nueva cuenta', style: textStyles.titleMedium),
          const SizedBox( height: 50 ),

          const CustomTextFormField(
            label: 'Nombre completo',
          ),
          const SizedBox(height: 30),

          const CustomTextFormField(
            label: 'Correo',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 30),

          const CustomTextFormField(
            label: 'Password',
            obscureText: true,

          ),
          const SizedBox(height: 30),

          const CustomTextFormField(
            label: 'Repita el password',
            obscureText: true,
          ),
          const SizedBox(height: 30),

           const CustomTextFormField(
            label: 'Repita el password',
            obscureText: true,
          ),
          const SizedBox(height: 50),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: CustomFilledButton(
              text: 'Crear',
              buttonColor: Colors.black,
              onPressed: () {},
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