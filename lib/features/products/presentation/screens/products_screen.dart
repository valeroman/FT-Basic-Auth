import 'package:basic_auth/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      drawer: SideMenu( scaffoldKey: scaffoldKey ),
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            onPressed: () {}, 
            icon: const Icon( Icons.search_rounded )
          )
        ],
      ),
      body: const _ProductView(),
    );
  }
}

class _ProductView extends StatelessWidget {
  const _ProductView();

  @override
  Widget build(BuildContext context) {
    return const Center( child: Text('Hola Planeta'),);
  }
}