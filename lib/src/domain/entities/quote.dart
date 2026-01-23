/// Entité Devis.
import 'package:equatable/equatable.dart';

class Quote extends Equatable {
  const Quote({
    required this.id,
    required this.quoteNumber,
    this.clientId,
    this.clientName,
    this.clientPhone,
    required this.date,
    required this.status,
    required this.totalHT,
    required this.totalVAT,
    required this.totalTTC,
  });

  final int id;
  final String quoteNumber;
  final int? clientId; // Nullable : si null, utiliser clientName et clientPhone
  final String? clientName; // Nom du client si pas de clientId
  final String? clientPhone; // Téléphone du client si pas de clientId
  final DateTime date;
  final String status; // Brouillon | Envoyé | Accepté
  final double totalHT;
  final double totalVAT;
  final double totalTTC;

  @override
  List<Object?> get props => [id, quoteNumber, clientId, clientName, clientPhone, date, status, totalHT, totalVAT, totalTTC];
}

