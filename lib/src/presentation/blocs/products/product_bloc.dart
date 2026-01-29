/// BLoC Produits: CRUD basique.
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/product.dart';
import '../../../domain/repositories/product_repository.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(const ProductState.initial()) {
    on<ProductListRequested>((event, emit) async {
      emit(const ProductState.loading());
      try {
        final products = await _productRepository.list();
        emit(ProductState.loaded(products));
      } catch (e) {
        emit(ProductState.failure(e.toString()));
      }
    });

    on<ProductCreateRequested>((event, emit) async {
      try {
        await _productRepository.create(
          name: event.name,
          unitPrice: event.unitPrice,
          vatRate: event.vatRate,
          unit: event.unit,
        );
        await Future.delayed(const Duration(milliseconds: 50)); // Add small delay
        add(const ProductListRequested());
      } catch (e) {
        emit(ProductState.failure(e.toString()));
      }
    });

    on<ProductUpdateRequested>((event, emit) async {
      try {
        await _productRepository.update(event.product);
        add(const ProductListRequested());
      } catch (e) {
        emit(ProductState.failure(e.toString()));
      }
    });

    on<ProductDeleteRequested>((event, emit) async {
      try {
        await _productRepository.delete(event.id);
        add(const ProductListRequested());
      } catch (e) {
        emit(ProductState.failure(e.toString()));
      }
    });
  }

  final ProductRepository _productRepository;
}

