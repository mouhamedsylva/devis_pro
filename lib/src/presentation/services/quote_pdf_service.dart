/// Service PDF: génération + partage/sauvegarde.
///
/// - `pdf` construit le document
/// - `printing` permet la prévisualisation/partage (WhatsApp via share sheet)
/// - `share_plus` pour partager vers WhatsApp et autres apps
/// - `path_provider` pour sauvegarder localement.
import 'dart:typed_data';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/quote.dart';
import '../../domain/entities/quote_item.dart';

class QuotePdfService {
  // Couleurs du design
  static const PdfColor _jaunePrimaire = PdfColor.fromInt(0xFFFFC107);
  static const PdfColor _jauneFonce = PdfColor.fromInt(0xFFFFA000);
  static const PdfColor _noir = PdfColor.fromInt(0xFF1A1A1A);
  static const PdfColor _noirLeger = PdfColor.fromInt(0xFF2D2D2D);
  static const PdfColor _blanc = PdfColors.white;
  static const PdfColor _grisClair = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor _grisMoyen = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor _grisTexte = PdfColor.fromInt(0xFF666666);

  Future<Uint8List> buildPdf({
    required Company company,
    Client? client,
    required Quote quote,
    required List<QuoteItem> items,
  }) async {
    final doc = pw.Document();

    // Utiliser clientName/clientPhone si client est null
    final clientName = client?.name ?? quote.clientName ?? 'Client';
    final clientPhone = client?.phone ?? quote.clientPhone ?? '';
    final clientAddress = client?.address ?? '';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: _blanc,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header avec bande jaune
                _buildHeader(context, company, quote),
                
                // Section informations client et devis
                _buildInfoSection(clientName, clientPhone, clientAddress, quote),
                
                // Section produits
                _buildProductsSection(items),
                
                // Section totaux
                _buildTotalsSection(quote, company),
                
                // Section conditions
                _buildConditionsSection(),
                
                // Footer
                _buildFooter(company, quote),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(pw.Context context, Company company, Quote quote) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [_jaunePrimaire, _jauneFonce],
        ),
      ),
      padding: const pw.EdgeInsets.all(40),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Logo et infos entreprise
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo placeholder
              pw.Container(
                width: 70,
                height: 70,
                decoration: pw.BoxDecoration(
                  color: _blanc,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    company.name.isNotEmpty ? company.name[0].toUpperCase() : 'B',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: _noir,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 15),
              // Infos entreprise
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    company.name,
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: _noir,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    company.phone,
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: _noirLeger,
                    ),
                  ),
                  if (company.address.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      company.address,
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: _noirLeger,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          // Titre DEVIS
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'DEVIS',
                style: pw.TextStyle(
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                  color: _noir,
                  letterSpacing: -1,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: _noir,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text(
                  quote.quoteNumber,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _jaunePrimaire,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoSection(String clientName, String clientPhone, String clientAddress, Quote quote) {
    final validUntil = quote.date.add(const Duration(days: 30));
    
    return pw.Container(
      color: _grisClair,
      padding: const pw.EdgeInsets.all(40),
      child: pw.Row(
        children: [
          // Bloc Client
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CLIENT',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _grisTexte,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: _blanc,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    border: pw.Border(
                      left: pw.BorderSide(color: _jaunePrimaire, width: 4),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        clientName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: _noir,
                        ),
                      ),
                      if (clientPhone.isNotEmpty) ...[
                        pw.SizedBox(height: 8),
                        pw.Text(
                          clientPhone,
                          style: pw.TextStyle(
                            fontSize: 15,
                            color: _noir,
                          ),
                        ),
                      ],
                      if (clientAddress.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          clientAddress,
                          style: pw.TextStyle(
                            fontSize: 15,
                            color: _noir,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 30),
          // Bloc Informations devis
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INFORMATIONS DU DEVIS',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _grisTexte,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: _blanc,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    border: pw.Border(
                      left: pw.BorderSide(color: _jaunePrimaire, width: 4),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            'Date d\'émission:',
                            style: pw.TextStyle(
                              fontSize: 15,
                              color: _noir,
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: _jaunePrimaire,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                            ),
                            child: pw.Text(
                              Formatters.dateShort(quote.date),
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: _noir,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Valide jusqu\'au:',
                            style: pw.TextStyle(
                              fontSize: 15,
                              color: _noir,
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: _jaunePrimaire,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                            ),
                            child: pw.Text(
                              Formatters.dateShort(validUntil),
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: _noir,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProductsSection(List<QuoteItem> items) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Détails du devis',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: _noir,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            decoration: pw.BoxDecoration(
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Table(
              border: pw.TableBorder(
                top: pw.BorderSide(color: _noir, width: 0),
                bottom: pw.BorderSide(color: _grisMoyen, width: 1),
                left: pw.BorderSide.none,
                right: pw.BorderSide.none,
                horizontalInside: pw.BorderSide(color: _grisMoyen, width: 1),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
              },
              children: [
                // En-tête
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: _noir,
                    borderRadius: pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(8),
                      topRight: pw.Radius.circular(8),
                    ),
                  ),
                  children: [
                    _buildTableCell('Description', isHeader: true),
                    _buildTableCell('Quantité', isHeader: true, align: pw.TextAlign.center),
                    _buildTableCell('Prix Unitaire', isHeader: true, align: pw.TextAlign.right),
                    _buildTableCell('TVA', isHeader: true, align: pw.TextAlign.right),
                    _buildTableCell('Total HT', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                // Lignes de produits
                ...items.map((item) {
                  final vatPercent = (item.vatRate * 100).toStringAsFixed(0);
                  return pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(18),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.productName,
                              style: pw.TextStyle(
                                fontSize: 15,
                                fontWeight: pw.FontWeight.bold,
                                color: _noir,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildTableCell(
                        item.quantity.toStringAsFixed(0),
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        Formatters.moneyCfa(item.unitPrice),
                        align: pw.TextAlign.right,
                      ),
                      _buildTableCell(
                        '$vatPercent%',
                        align: pw.TextAlign.right,
                      ),
                      _buildTableCell(
                        Formatters.moneyCfa(item.total),
                        align: pw.TextAlign.right,
                        isBold: true,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 13 : 15,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? _blanc : _noirLeger,
        ),
      ),
    );
  }

  pw.Widget _buildTotalsSection(Quote quote, Company company) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(40, 0, 40, 40),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 400,
            padding: const pw.EdgeInsets.all(25),
            decoration: pw.BoxDecoration(
              color: _grisClair,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Sous-total HT',
                      style: pw.TextStyle(
                        fontSize: 15,
                        color: _noirLeger,
                      ),
                    ),
                    pw.Text(
                      Formatters.moneyCfa(quote.totalHT, currencyLabel: company.currency),
                      style: pw.TextStyle(
                        fontSize: 15,
                        color: _noirLeger,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(color: _grisMoyen, height: 1),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TVA',
                      style: pw.TextStyle(
                        fontSize: 15,
                        color: _noirLeger,
                      ),
                    ),
                    pw.Text(
                      Formatters.moneyCfa(quote.totalVAT, currencyLabel: company.currency),
                      style: pw.TextStyle(
                        fontSize: 15,
                        color: _noirLeger,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Divider(color: _noir, height: 2),
                pw.SizedBox(height: 15),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL TTC',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: _noir,
                      ),
                    ),
                    pw.Text(
                      Formatters.moneyCfa(quote.totalTTC, currencyLabel: company.currency),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: _jauneFonce,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildConditionsSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      color: _grisClair,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CONDITIONS ET MODALITÉS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _noir,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildConditionItem('Devis valable 30 jours à compter de la date d\'émission'),
              _buildConditionItem('Acompte de 40% à la commande'),
              _buildConditionItem('Paiement du solde à la livraison'),
              _buildConditionItem('Délai d\'exécution: 15 jours ouvrables'),
              _buildConditionItem('Garantie: 1 an sur les travaux réalisés'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildConditionItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '✓',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _jaunePrimaire,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 14,
                color: _grisTexte,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(Company company, Quote quote) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      decoration: const pw.BoxDecoration(
        color: _noir,
      ),
      child: pw.Column(
        children: [
          pw.Text(
            '${company.name.toUpperCase()} - ${company.address}',
            style: pw.TextStyle(
              fontSize: 13,
              color: _blanc,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            company.phone,
            style: pw.TextStyle(
              fontSize: 13,
              color: _blanc,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: pw.BoxDecoration(
              color: _jaunePrimaire,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(25)),
            ),
            child: pw.Text(
              quote.status.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _noir,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<File> saveToDownloads({
    required String filename,
    required Uint8List pdfBytes,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(pdfBytes, flush: true);
    return file;
  }

  Future<void> share({required Uint8List pdfBytes, required String filename}) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }

  /// Partage le PDF via le share sheet (incluant WhatsApp)
  Future<void> shareToWhatsApp({
    required Uint8List pdfBytes,
    required String filename,
    String? clientName,
  }) async {
    // Sauvegarder temporairement le fichier
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(pdfBytes, flush: true);

    // Message par défaut pour WhatsApp
    final text = clientName != null
        ? 'Bonjour $clientName, voici votre devis : $filename'
        : 'Voici votre devis : $filename';

    // Partager via le share sheet (WhatsApp apparaîtra dans les options)
    await Share.shareXFiles(
      [XFile(file.path)],
      text: text,
      subject: 'Devis - $filename',
    );
  }
}

