part of 'product_bloc.dart';

class ProductState extends Equatable {
  const ProductState._({required this.status, this.products, this.message});

  const ProductState.initial() : this._(status: ProductStatus.initial);
  const ProductState.loading() : this._(status: ProductStatus.loading);
  const ProductState.loaded(List<Product> products) : this._(status: ProductStatus.loaded, products: products);
  const ProductState.failure(String message) : this._(status: ProductStatus.failure, message: message);

  final ProductStatus status;
  final List<Product>? products;
  final String? message;

  @override
  List<Object?> get props => [status, products, message];
}

enum ProductStatus { initial, loading, loaded, failure }

