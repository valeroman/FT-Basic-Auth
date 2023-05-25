
import '../entities/product.dart';

//* Definimos las reglas, nno se implementa nada
abstract class ProductsDatasource {

  Future<List<Product>> getProductByPage({ int limit = 10, int offset = 0 });
  
  Future<Product> getProductById( String id );

  Future<List<Product>> searchProductByTerm( String term );

  Future<Product> createUpdateProduct( Map<String, dynamic> productLike );

}