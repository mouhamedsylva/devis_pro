/// Entité Devis.
import 'package:equatable/equatable.dart';

class Quote extends Equatable {
  const Quote({
    required this.id,
    required this.quoteNumber,
    required this.clientId,
    required this.date,
    required this.status,
    required this.totalHT,
    required this.totalVAT,
    required this.totalTTC,
  });

  final int id;
  final String quoteNumber;
  final int clientId;
  final DateTime date;
  final String status; // Brouillon | Envoyé | Accepté
  final double totalHT;
  final double totalVAT;
  final double totalTTC;

  @override
  List<Object?> get props => [id, quoteNumber, clientId, date, status, totalHT, totalVAT, totalTTC];
}

