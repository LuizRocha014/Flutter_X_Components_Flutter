import 'dart:io';

import 'package:componentes_lr/src/utils/utils/midia/camera.dart';
import 'package:componentes_lr/src/utils/utils/midia/midia_util.dart';
import 'package:flutter/material.dart';

/// Campo reutilizavel para selecionar imagem da camera ou galeria.
class ImagePickerInputWidget extends StatefulWidget {
  const ImagePickerInputWidget({
    super.key,
    this.title = 'Imagem',
    this.initialImagePath,
    this.onImageChanged,
  });

  final String title;
  final String? initialImagePath;
  final ValueChanged<String?>? onImageChanged;

  @override
  State<ImagePickerInputWidget> createState() => _ImagePickerInputWidgetState();
}

class _ImagePickerInputWidgetState extends State<ImagePickerInputWidget> {
  MidiaUtil? _midia;
  String? _remoteUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialImagePath?.trim();
    if (initial != null && initial.isNotEmpty) {
      if (initial.startsWith('http://') || initial.startsWith('https://')) {
        _remoteUrl = initial;
      } else if (File(initial).existsSync()) {
        _midia = MidiaUtil.camera(id: 'initial', file: File(initial));
      }
    }
  }

  Future<void> _pickImage() async {
    setState(() => _loading = true);
    try {
      final picked = await btnAnexarFotoUnica(_midia, context, acceptPdf: false)
          .timeout(const Duration(seconds: 30));
      if (picked != null) {
        setState(() {
          _midia = picked;
          _remoteUrl = null;
        });
        widget.onImageChanged?.call(picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao abrir câmera/galeria: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importImage() async {
    setState(() => _loading = true);
    try {
      final picked = await btnEscolheGaleria(context).timeout(const Duration(seconds: 30));
      if (picked != null) {
        setState(() {
          _midia = picked;
          _remoteUrl = null;
        });
        widget.onImageChanged?.call(picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao importar imagem: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearImage() {
    setState(() {
      _midia = null;
      _remoteUrl = null;
    });
    widget.onImageChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = _midia != null || _remoteUrl != null;

    Widget preview;
    if (_midia?.path != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(_midia!.path!),
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else if (_remoteUrl != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          _remoteUrl!,
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(scheme),
        ),
      );
    } else {
      preview = _placeholder(scheme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        preview,
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickImage,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_a_photo_outlined),
              label: Text(hasImage ? 'Câmera / galeria' : 'Adicionar foto'),
            ),
            OutlinedButton.icon(
              onPressed: _loading ? null : _importImage,
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Importar imagem'),
            ),
            if (hasImage) ...[
              IconButton(
                tooltip: 'Remover imagem',
                onPressed: _loading ? null : _clearImage,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
        color: scheme.surfaceContainerHighest.withOpacity(0.4),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 38,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
