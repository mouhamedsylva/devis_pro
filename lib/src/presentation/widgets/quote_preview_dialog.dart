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
  final Uint8List? pdfBytes; // ✨ NOUVEAU : On peut passer les octets déjà générés

  const QuotePreviewDialog({
    super.key,
    required this.quote,
    required this.items,
    required this.company,
    this.client,
    this.pdfBytes,
  });

  @override
  State<QuotePreviewDialog> createState() => _QuotePreviewDialogState();
}

class _QuotePreviewDialogState extends State<QuotePreviewDialog> with SingleTickerProviderStateMixin {
  final _pdfService = QuotePdfService();
  Uint8List? _pdfBytes;
  bool _loading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // ✨ Si les octets sont déjà fournis, on les utilise directement
    if (widget.pdfBytes != null) {
      _pdfBytes = widget.pdfBytes;
      _loading = false;
      _animationController.forward();
    } else {
      _generatePdf();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // AppBar Section
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 12,
              20,
              20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 24),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aperçu du Devis',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.yellow.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.yellow.withOpacity(0.3)),
                            ),
                            child: Text(
                              widget.quote.quoteNumber,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.yellow.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
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

          // Content Section
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
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
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
          ),

          // Action Buttons Section
          if (!_loading)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 30,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          onPressed: () => _pdfService.shareToWhatsApp(
                            pdfBytes: _pdfBytes!,
                            filename: '${widget.quote.quoteNumber}.pdf',
                            clientName: widget.client?.name ?? widget.quote.clientName,
                          ),
                          icon: FontAwesomeIcons.whatsapp,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildActionButton(
                          onPressed: () => _pdfService.share(
                            pdfBytes: _pdfBytes!,
                            filename: '${widget.quote.quoteNumber}.pdf',
                          ),
                          icon: Icons.download_rounded,
                          label: 'Partager',
                          color: AppColors.yellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }
}
