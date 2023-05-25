import 'package:basic_auth/features/products/domain/domain.dart';
import 'products_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


//? State Notifier Provider

//* Provider
final productsProvider = StateNotifierProvider<ProducsNotifier, ProductsState>((ref) {

  final productsRepository = ref.watch( productsRepositoryProvider );

  return ProducsNotifier(productsRepository: productsRepository);
});

//* Notifier
class ProducsNotifier extends StateNotifier<ProductsState>{

  final ProductsRepository productsRepository;

  ProducsNotifier({
    required this.productsRepository
  }): super( ProductsState() ) {
    loadNextPage();
  }

  Future loadNextPage() async {

    //* Evitar que se haga muchas peticiones
    if ( state.isLoading || state.isLastPage ) return;

    state = state.copyWith( isLoading: true );

    final products = await productsRepository
      .getProductByPage(limit: state.limit, offset: state.offset);

    if ( products.isEmpty ) {

      state = state.copyWith(
        isLoading: false,
        isLastPage: true
      );

      return;
    }

    state = state.copyWith(
      isLastPage: false,
      isLoading: false,
      offset: state.offset + 10,
      products: [...state.products, ...products]
    );

  }

}

//* State
//* Como quiero que luzca el estado del provider
class ProductsState {

  final bool isLastPage;
  final int limit;
  final int offset;
  final bool isLoading;
  final List<Product> products;

  ProductsState({
    this.isLastPage = false,
    this.limit = 10,
    this.offset = 0,
    this.isLoading = false,
    this.products = const []
  }); 

  ProductsState copyWith({
    bool? isLastPage,
    int? limit,
    int? offset,
    bool? isLoading,
    List<Product>? products,
  }) => ProductsState(
    isLastPage: isLastPage ?? this.isLastPage,
    limit: limit ?? this.limit,
    offset: offset ?? this.offset,
    isLoading: isLoading ?? this.isLoading,
    products: products ?? this.products,
  );

}