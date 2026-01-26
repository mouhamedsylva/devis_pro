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
    _generatePdf();
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
          // Elegant AppBar with gradient
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 12,
              20,
              20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
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
                // Close button with elegant styling
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 24),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey.shade700,
                    tooltip: 'Fermer',
                  ),
                ),
                const SizedBox(width: 16),
                // Title section
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
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.yellow.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.yellow.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.quote.quoteNumber,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.yellow.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (widget.client != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12.sp,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.client!.name,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // PDF Preview Content
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Génération du PDF...',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                            spreadRadius: -5,
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

          // Action Buttons with elegant design
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
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Info banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade50,
                              Colors.blue.shade50.withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Partagez ou enregistrez votre devis',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action buttons
                      Row(
                        children: [
                          // WhatsApp Share
                          Expanded(
                            child: _buildActionButton(
                              onPressed: () => _pdfService.shareToWhatsApp(
                                pdfBytes: _pdfBytes!,
                                filename: '${widget.quote.quoteNumber}.pdf',
                                clientName: widget.client?.name ??
                                    widget.quote.clientName,
                              ),
                              icon: FontAwesomeIcons.whatsapp,
                              label: 'WhatsApp',
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF25D366),
                                  Color(0xFF20BA5A),
                                ],
                              ),
                              shadowColor: const Color(0xFF25D366),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Download PDF
                          Expanded(
                            child: _buildActionButton(
                              onPressed: () => _pdfService.share(
                                pdfBytes: _pdfBytes!,
                                filename: '${widget.quote.quoteNumber}.pdf',
                              ),
                              icon: Icons.download_rounded,
                              label: 'Télécharger',
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.yellow,
                                  AppColors.yellow.withOpacity(0.8),
                                ],
                              ),
                              shadowColor: AppColors.yellow,
                            ),
                          ),
                        ],
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
    required Gradient gradient,
    required Color shadowColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}