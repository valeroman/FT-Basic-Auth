
import 'package:basic_auth/features/auth/presentation/providers/auth_provider.dart';
import 'package:basic_auth/features/products/domain/domain.dart';
import 'package:basic_auth/features/products/infrastructure/infrastructure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//* Proveedor de Products poder establecer a lo largo de toda la aplicacion la instancia 
//* de nuestro ProductsRepositoryImpl


final productsRepositoryProvider = Provider<ProductsRepository>((ref) {

  final accessToken = ref.watch( authProvider ).user?.token ?? '';

  final productsRepository = ProductsRepositoryImpl(
    ProductsDatasourceImpl(accessToken: accessToken)
  );

  return productsRepository;

});