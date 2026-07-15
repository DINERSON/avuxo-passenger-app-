import 'dart:ui';

import 'package:flutter/material.dart';

class TripFinishedPanel extends StatefulWidget {
  const TripFinishedPanel({
    super.key,
    required this.price,
    required this.onSubmitReview,
  });

  final double price;
  final void Function(double rating, String comment) onSubmitReview;

  @override
  State<TripFinishedPanel> createState() => _TripFinishedPanelState();
}

class _TripFinishedPanelState extends State<TripFinishedPanel> {
  static const Color avuxoGreen = Color(0xFF24F877);

  final TextEditingController controller = TextEditingController();

  double rating = 5;

  bool submitting = false;
  bool submitted = false;

  String get money {
    if (widget.price <= 0) {
      return 'Valor calculado';
    }

    return 'R\$ ${widget.price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (submitting || submitted) return;

    setState(() {
      submitting = true;
    });

    try {
      final safeRating = rating.clamp(1, 5).toDouble();

      final comment = controller.text.trim().length > 300
          ? controller.text.trim().substring(0, 300)
          : controller.text.trim();

      widget.onSubmitReview(
        safeRating,
        comment,
      );

      if (!mounted) return;

      setState(() {
        submitted = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final height = MediaQuery.of(context).size.height;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom + 72,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: height * 0.72,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 18,
              sigmaY: 18,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1117).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: avuxoGreen.withValues(alpha: 0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: avuxoGreen.withValues(alpha: 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: avuxoGreen,
                      size: 58,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Corrida finalizada',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      money,
                      style: const TextStyle(
                        color: avuxoGreen,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Avalie sua experiência com o motorista.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) {
                          final selected = index < rating;

                          return GestureDetector(
                            onTap: submitted || submitting
                                ? null
                                : () {
                                    setState(() {
                                      rating = (index + 1).toDouble();
                                    });
                                  },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Icon(
                                Icons.star_rounded,
                                color: selected ? avuxoGreen : Colors.white24,
                                size: 38,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      enabled: !submitted && !submitting,
                      maxLines: 2,
                      maxLength: 300,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        counterStyle: const TextStyle(
                          color: Colors.white38,
                        ),
                        hintText: 'Comentário opcional',
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: submitted || submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: avuxoGreen,
                          disabledBackgroundColor:
                              Colors.white.withValues(alpha: 0.12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                submitted
                                    ? 'AVALIAÇÃO ENVIADA'
                                    : 'ENVIAR AVALIAÇÃO',
                                style: TextStyle(
                                  color:
                                      submitted ? Colors.white54 : Colors.black,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}