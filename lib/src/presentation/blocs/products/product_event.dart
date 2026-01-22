part of 'product_bloc.dart';

sealed class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class ProductListRequested extends ProductEvent {
  const ProductListRequested();
}

class ProductCreateRequested extends ProductEvent {
  const ProductCreateRequested({required this.name, required this.unitPrice, required this.vatRate});

  final String name;
  final double unitPrice;
  final double vatRate;

  @override
  List<Object?> get props => [name, unitPrice, vatRate];
}

class ProductUpdateRequested extends ProductEvent {
  const ProductUpdateRequested(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

class ProductDeleteRequested extends ProductEvent {
  const ProductDeleteRequested(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

