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

    // Charger les images (Logo & Signature)
    pw.MemoryImage? logoImage;
    if (company.logoPath != null && File(company.logoPath!).existsSync()) {
      logoImage = pw.MemoryImage(File(company.logoPath!).readAsBytesSync());
    }

    pw.MemoryImage? signatureImage;
    if (company.signaturePath != null && File(company.signaturePath!).existsSync()) {
      signatureImage = pw.MemoryImage(File(company.signaturePath!).readAsBytesSync());
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        build: (context) {
          return [
            // Header
            _buildHeader(context, company, quote, logoImage),
            
            pw.SizedBox(height: 30),
            
            // Section informations client et devis
            _buildInfoSection(clientName, clientPhone, clientAddress, quote),
            
            pw.SizedBox(height: 30),
            
            // Section produits
            _buildProductsSection(items),
            
            pw.SizedBox(height: 20),
            
            // Section totaux et Signature
            _buildTotalsAndSignature(quote, company, signatureImage),
            
            pw.SizedBox(height: 30),
            
            // Section conditions
            _buildConditionsSection(),
          ];
        },
        footer: (context) => _buildFooter(company, quote),
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(pw.Context context, Company company, Quote quote, pw.MemoryImage? logoImage) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo et infos entreprise
        pw.Expanded(
          flex: 2,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Container(
                  width: 80,
                  height: 80,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                )
              else
                pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    color: _jaunePrimaire,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      company.name.isNotEmpty ? company.name[0].toUpperCase() : 'B',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: _noir,
                      ),
                    ),
                  ),
                ),
              pw.SizedBox(width: 20),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    company.name.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: _noir,
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    company.phone,
                    style: pw.TextStyle(fontSize: 11, color: _grisTexte),
                  ),
                  if (company.address.isNotEmpty)
                    pw.Text(
                      company.address,
                      style: pw.TextStyle(fontSize: 11, color: _grisTexte),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Bloc Titre DEVIS
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'DEVIS',
                style: pw.TextStyle(
                  fontSize: 40,
                  fontWeight: pw.FontWeight.bold,
                  color: _noir,
                  letterSpacing: 2,
                ),
              ),
              pw.Container(
                width: 120,
                height: 3,
                color: _jaunePrimaire,
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'N° ${quote.quoteNumber}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _noirLeger,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInfoSection(String clientName, String clientPhone, String clientAddress, Quote quote) {
    final validUntil = quote.date.add(const Duration(days: 30));
    
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Destinataire
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DESTINATAIRE',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _jauneFonce,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                clientName.toUpperCase(),
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _noir),
              ),
              if (clientPhone.isNotEmpty)
                pw.Text(clientPhone, style: pw.TextStyle(fontSize: 12, color: _noirLeger)),
              if (clientAddress.isNotEmpty)
                pw.Text(clientAddress, style: pw.TextStyle(fontSize: 12, color: _noirLeger)),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        // Détails temporels
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildInfoRow('ÉMISSION', Formatters.dateShort(quote.date)),
              pw.SizedBox(height: 6),
              _buildInfoRow('VALIDITÉ', Formatters.dateShort(validUntil)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          '$label :',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _grisTexte),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _noir),
        ),
      ],
    );
  }

  pw.Widget _buildProductsSection(List<QuoteItem> items) {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _grisClair, width: 1),
        bottom: pw.BorderSide(color: _noir, width: 1.5),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // Description
        1: const pw.FlexColumnWidth(1), // Qté / Unité
        2: const pw.FlexColumnWidth(1.2), // P.U
        3: const pw.FlexColumnWidth(1.2), // Total
      },
      children: [
        // En-tête de table
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _noir),
          children: [
            _buildTableHeaderCell('DESCRIPTION DES PRESTATIONS'),
            _buildTableHeaderCell('QTÉ', align: pw.TextAlign.center),
            _buildTableHeaderCell('P.U HT', align: pw.TextAlign.right),
            _buildTableHeaderCell('TOTAL HT', align: pw.TextAlign.right),
          ],
        ),
        // Lignes d'articles
        ...items.map((item) {
          final isEven = items.indexOf(item) % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isEven ? _blanc : _grisClair),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.productName,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _noir),
                    ),
                  ],
                ),
              ),
              _buildTableBodyCell(item.quantity.toStringAsFixed(0), align: pw.TextAlign.center),
              _buildTableBodyCell(Formatters.moneyCfa(item.unitPrice), align: pw.TextAlign.right),
              _buildTableBodyCell(Formatters.moneyCfa(item.total), align: pw.TextAlign.right, isBold: true),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableHeaderCell(String label, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: pw.Text(
        label,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _blanc, letterSpacing: 1),
      ),
    );
  }

  pw.Widget _buildTableBodyCell(String value, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(12),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: _noirLeger,
        ),
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

  pw.Widget _buildTotalsAndSignature(Quote quote, Company company, pw.MemoryImage? signatureImage) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Zone Signature (Générée à gauche pour l'équilibre visuel)
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SCEAU & SIGNATURE :',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _noir),
              ),
              pw.SizedBox(height: 10),
              if (signatureImage != null)
                pw.Container(
                  height: 100,
                  child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                )
              else
                pw.Container(
                  height: 100,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _grisMoyen, style: pw.BorderStyle.dashed),
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        // Zone Totaux à droite
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            children: [
              _buildTotalRow('TOTAL HORS TAXE', Formatters.moneyCfa(quote.totalHT, currencyLabel: company.currency)),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Divider(color: _grisMoyen, thickness: 0.5),
              ),
              _buildTotalRow('TOTAL TVA (${(company.vatRate * 100).toStringAsFixed(0)}%)', Formatters.moneyCfa(quote.totalVAT, currencyLabel: company.currency)),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(color: _noir),
                child: _buildTotalRow(
                  'NET À PAYER', 
                  Formatters.moneyCfa(quote.totalTTC, currencyLabel: company.currency),
                  isTTC: true
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotalRow(String label, String value, {bool isTTC = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTTC ? 11 : 9, 
            fontWeight: pw.FontWeight.bold, 
            color: isTTC ? _blanc : _grisTexte
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isTTC ? 14 : 11, 
            fontWeight: pw.FontWeight.bold, 
            color: isTTC ? _jaunePrimaire : _noir
          ),
        ),
      ],
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

