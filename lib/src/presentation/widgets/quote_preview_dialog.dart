import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:printing/printing.dart';
import 'package:sizer/sizer.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/quote.dart';
import '../../domain/entities/quote_item.dart';
import '../services/quote_pdf_service.dart';

class QuotePreviewDialog extends StatefulWidget {
  final Quote quote;
  final List<QuoteItem> items;
  final Company company;
  final Client? client;

  const QuotePreviewDialog({
    super.key,
    required this.quote,
    required this.items,
    required this.company,
    this.client,
  });

  @override
  State<QuotePreviewDialog> createState() => _QuotePreviewDialogState();
}

class _QuotePreviewDialogState extends State<QuotePreviewDialog> {
  final _pdfService = QuotePdfService();
  Uint8List? _pdfBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    final bytes = await _pdfService.buildPdf(
      company: widget.company,
      client: widget.client,
      quote: widget.quote,
      items: widget.items,
    );
    if (mounted) {
      setState(() {
        _pdfBytes = bytes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.grey[100],
      child: Column(
        children: [
          // Custom AppBar
          Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 28),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.black87,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aperçu du Devis',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        widget.quote.quoteNumber,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: PdfPreview(
                      build: (format) => _pdfBytes!,
                      useActions: false,
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      maxPageWidth: 700,
                    ),
                  ),
          ),

          // Actions
          if (!_loading)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // WhatsApp Share
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pdfService.shareToWhatsApp(
                        pdfBytes: _pdfBytes!,
                        filename: '${widget.quote.quoteNumber}.pdf',
                        clientName: widget.client?.name ?? widget.quote.clientName,
                      ),
                      icon: const Icon(FontAwesomeIcons.whatsapp, size: 20),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Download PDF
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pdfService.share(
                        pdfBytes: _pdfBytes!,
                        filename: '${widget.quote.quoteNumber}.pdf',
                      ),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text('Enregistrer/PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
