/// Service PDF: génération + partage/sauvegarde - Design Professionnel Compact
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
  // Couleurs du design professionnel
  static const PdfColor _jaunePrimaire = PdfColor.fromInt(0xFFFFC107);
  static const PdfColor _noir = PdfColor.fromInt(0xFF1A1A1A);
  static const PdfColor _blanc = PdfColors.white;
  static const PdfColor _grisClair = PdfColor.fromInt(0xFFF8F9FA);
  static const PdfColor _grisMoyen = PdfColor.fromInt(0xFFDEE2E6);
  static const PdfColor _grisTexte = PdfColor.fromInt(0xFF6C757D);

  /// Génère le PDF de manière optimisée - UNE SEULE PAGE A4
  Future<Uint8List> buildPdf({
    required Company company,
    Client? client,
    required Quote quote,
    required List<QuoteItem> items,
  }) async {
    final doc = pw.Document();

    final clientName = client?.name ?? quote.clientName ?? 'Client';
    final clientPhone = client?.phone ?? quote.clientPhone ?? '';
    final clientAddress = client?.address ?? '';

    // Chargement asynchrone des images
    final images = await Future.wait([
      _loadMemoryImage(company.logoPath),
      _loadMemoryImage(company.signaturePath),
    ]);

    final logoImage = images[0];
    final signatureImage = images[1];

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header compact avec logo et infos
              _buildCompactHeader(company, quote, logoImage),
              
              pw.SizedBox(height: 15),
              
              // 2. Bande jaune avec infos client et dates
              _buildInfoBand(clientName, clientPhone, clientAddress, quote),
              
              pw.SizedBox(height: 15),
              
              // 3. Tableau produits ultra-compact
              _buildCompactProductsTable(items),
              
              pw.SizedBox(height: 12),
              
              // 4. Totaux et signature en bas
              _buildBottomSection(quote, company, signatureImage),
              
              pw.Spacer(),
              
              // 5. Footer avec conditions
              _buildCompactFooter(company),
            ],
          );
        },
      ),
    );

    return await doc.save();
  }

  Future<pw.MemoryImage?> _loadMemoryImage(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return pw.MemoryImage(bytes);
      }
    } catch (e) {
      print('Erreur chargement image PDF: $e');
    }
    return null;
  }

  // 1. HEADER COMPACT
  pw.Widget _buildCompactHeader(Company company, Quote quote, pw.MemoryImage? logoImage) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Logo + Nom entreprise
        pw.Row(
          children: [
            if (logoImage != null)
              pw.Container(
                width: 50,
                height: 50,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              )
            else
              pw.Container(
                width: 50,
                height: 50,
                decoration: pw.BoxDecoration(
                  color: _jaunePrimaire,
                  borderRadius: pw.BorderRadius.circular(8),
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
            pw.SizedBox(width: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  company.name.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _noir,
                    letterSpacing: 1,
                  ),
                ),
                pw.Text(
                  company.phone,
                  style: pw.TextStyle(fontSize: 9, color: _grisTexte),
                ),
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
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: _noir,
                letterSpacing: 2,
              ),
            ),
            pw.Container(
              width: 80,
              height: 2,
              color: _jaunePrimaire,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              quote.quoteNumber,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _grisTexte,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. BANDE INFO JAUNE
  pw.Widget _buildInfoBand(String clientName, String clientPhone, String clientAddress, Quote quote) {
    final validUntil = quote.date.add(const Duration(days: 30));
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _grisClair,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _jaunePrimaire, width: 2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Client
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CLIENT',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _grisTexte,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  clientName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _noir,
                  ),
                ),
                if (clientPhone.isNotEmpty)
                  pw.Text(
                    clientPhone,
                    style: pw.TextStyle(fontSize: 9, color: _grisTexte),
                  ),
              ],
            ),
          ),
          // Dates
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Row(
                children: [
                  pw.Text(
                    'ÉMIS LE : ',
                    style: pw.TextStyle(fontSize: 8, color: _grisTexte),
                  ),
                  pw.Text(
                    Formatters.dateShort(quote.date),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _noir,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Row(
                children: [
                  pw.Text(
                    'VALIDE JUSQU\'AU : ',
                    style: pw.TextStyle(fontSize: 8, color: _grisTexte),
                  ),
                  pw.Text(
                    Formatters.dateShort(validUntil),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _noir,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. TABLEAU PRODUITS ULTRA-COMPACT
  pw.Widget _buildCompactProductsTable(List<QuoteItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: _grisMoyen, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3.5),
        1: const pw.FlexColumnWidth(0.8),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
      },
      children: [
        // En-tête
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _noir),
          children: [
            _buildTableHeader('DESCRIPTION'),
            _buildTableHeader('QTÉ', align: pw.TextAlign.center),
            _buildTableHeader('P.U HT', align: pw.TextAlign.right),
            _buildTableHeader('TOTAL HT', align: pw.TextAlign.right),
          ],
        ),
        // Lignes produits
        ...items.map((item) {
          final isEven = items.indexOf(item) % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? _blanc : _grisClair,
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: pw.Text(
                  item.productName,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _noir,
                  ),
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
                Formatters.moneyCfa(item.total),
                align: pw.TextAlign.right,
                isBold: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableHeader(String label, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        label,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: _blanc,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(String value, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: _noir,
        ),
      ),
    );
  }

  // 4. SECTION BAS : TOTAUX + SIGNATURE
  pw.Widget _buildBottomSection(Quote quote, Company company, pw.MemoryImage? signatureImage) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // SIGNATURE À GAUCHE
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SIGNATURE & CACHET',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: _grisTexte,
                  letterSpacing: 0.8,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 70,
                width: 150,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _grisMoyen, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: signatureImage != null
                    ? pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      )
                    : pw.Center(
                        child: pw.Text(
                          'Signature',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: _grisMoyen,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        // TOTAUX À DROITE
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Total HT
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: _grisClair,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL HT',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _grisTexte,
                      ),
                    ),
                    pw.Text(
                      Formatters.moneyCfa(quote.totalHT, currencyLabel: company.currency),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _noir,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              // TVA
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: _grisClair,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TVA (${(company.vatRate * 100).toStringAsFixed(0)}%)',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _grisTexte,
                      ),
                    ),
                    pw.Text(
                      Formatters.moneyCfa(quote.totalVAT, currencyLabel: company.currency),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _noir,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              // NET À PAYER
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: _noir,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'NET À PAYER',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _blanc,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.Text(
                      Formatters.moneyCfa(quote.totalTTC, currencyLabel: company.currency),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: _jaunePrimaire,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. FOOTER COMPACT AVEC CONDITIONS
  pw.Widget _buildCompactFooter(Company company) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _grisClair,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CONDITIONS',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _noir,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _buildCondition('• Devis valable 30 jours'),
              ),
              pw.Expanded(
                child: _buildCondition('• Acompte 40% à la commande'),
              ),
              pw.Expanded(
                child: _buildCondition('• Délai: 15 jours ouvrables'),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: _grisMoyen, thickness: 0.5),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${company.name} - ${company.address}',
                style: pw.TextStyle(fontSize: 7, color: _grisTexte),
              ),
              pw.Text(
                company.phone,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: _noir,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCondition(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 7,
        color: _grisTexte,
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

  Future<void> shareToWhatsApp({
    required Uint8List pdfBytes,
    required String filename,
    String? clientName,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(pdfBytes, flush: true);

    final text = clientName != null
        ? 'Bonjour $clientName, voici votre devis : $filename'
        : 'Voici votre devis : $filename';

    await Share.shareXFiles(
      [XFile(file.path)],
      text: text,
      subject: 'Devis - $filename',
    );
  }
}