import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../core/providers/app_providers.dart';

class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({
    super.key,
    required this.rideId,
  });

  static const routeName = '/rating';

  final String rideId;

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  double _rating = 5;

  final TextEditingController _commentCtrl =
      TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rideId = widget.rideId.trim();

    if (rideId.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Corrida inválida.',
          ),
        ),
      );

      return;
    }

    try {
      setState(() {
        _sending = true;
      });

      await ref.read(rideRepositoryProvider).submitRating(
            rideId: rideId,
            score: _rating.round(),
            comment: _commentCtrl.text.trim(),
          );

      if (!mounted) return;

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao enviar avaliação: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Avaliar corrida',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Como foi a sua experiência?',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 14),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              allowHalfRating: false,
              itemCount: 5,
              itemBuilder: (_, __) =>
                  const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (value) {
                if (!mounted) return;

                setState(() {
                  _rating = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              maxLength: 500,
              decoration:
                  const InputDecoration(
                labelText:
                    'Comentário (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _sending ? null : _submit,
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Enviar avaliação',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}