/// Service PDF: génération + partage/sauvegarde.
///
/// - `pdf` construit le document
/// - `printing` permet la prévisualisation/partage (WhatsApp via share sheet)
/// - `path_provider` pour sauvegarder localement.
import 'dart:typed_data';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/quote.dart';
import '../../domain/entities/quote_item.dart';

class QuotePdfService {
  Future<Uint8List> buildPdf({
    required Company company,
    required Client client,
    required Quote quote,
    required List<QuoteItem> items,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('DEVIS', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('N° ${quote.quoteNumber}'),
              pw.Text('Date: ${Formatters.dateShort(quote.date)}'),
              pw.SizedBox(height: 14),
              pw.Text('Entreprise', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(company.name),
              pw.Text(company.phone),
              pw.Text(company.address),
              pw.SizedBox(height: 14),
              pw.Text('Client', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(client.name),
              pw.Text(client.phone),
              pw.Text(client.address),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Désignation')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qté')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('PU')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total')),
                    ],
                  ),
                  ...items.map(
                    (it) => pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(it.productName)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(it.quantity.toString())),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(it.unitPrice.toStringAsFixed(0))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(it.total.toStringAsFixed(0))),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total HT: ${Formatters.moneyCfa(quote.totalHT, currencyLabel: company.currency)}'),
                      pw.Text('TVA: ${Formatters.moneyCfa(quote.totalVAT, currencyLabel: company.currency)}'),
                      pw.Text(
                        'Total TTC: ${Formatters.moneyCfa(quote.totalTTC, currencyLabel: company.currency)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
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
}

