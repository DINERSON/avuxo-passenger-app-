import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final auth = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: profile.when(
        data: (user) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(
                    user.name.isNotEmpty
                        ? user.name
                        : 'Usuário',
                  ),
                  subtitle: Text(
                    user.phone.isNotEmpty
                        ? user.phone
                        : 'Telefone não informado',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('ID'),
                      subtitle: Text(
                        user.id.isNotEmpty
                            ? user.id
                            : '-',
                      ),
                    ),
                    ListTile(
                      title: const Text('Email'),
                      subtitle: Text(
                        (user.email ?? '').isNotEmpty
                            ? user.email!
                            : '-',
                      ),
                    ),
                    ListTile(
                      title: const Text('Tipo'),
                      subtitle: Text(
                        user.role.isNotEmpty
                            ? user.role
                            : '-',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: auth.loading
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(authNotifierProvider.notifier)
                              .signOut();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erro ao sair: $e',
                                ),
                              ),
                            );
                          }
                        }
                      },
                child: Text(
                  auth.loading
                      ? 'Saindo...'
                      : 'Sair',
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Não foi possível carregar seu perfil.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      ref.invalidate(profileProvider);
                    },
                    child: const Text(
                      'Tentar novamente',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}