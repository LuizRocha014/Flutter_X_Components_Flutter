import 'package:flutter/material.dart';

import 'form_factor.dart';

/// Shell para telas de módulo: [AppBar] no mobile; barra superior ampla + corpo centralizado no desktop.
class AdaptiveModulePage extends StatelessWidget {
  const AdaptiveModulePage({
    super.key,
    required this.title,
    required this.body,
    required this.onBack,
  });

  final String title;
  final Widget body;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (isMobileFormFactor) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
        ),
        body: body,
      );
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            elevation: 1,
            color: scheme.surface,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
