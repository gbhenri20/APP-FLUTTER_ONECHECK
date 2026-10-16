import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/checklist_models.dart';
import '../providers/checklist_providers.dart';

class VistoriaChecklistPage extends ConsumerStatefulWidget {
  const VistoriaChecklistPage({super.key, required this.checklistId});

  final String checklistId;

  @override
  ConsumerState<VistoriaChecklistPage> createState() =>
      _VistoriaChecklistPageState();
}

class _VistoriaChecklistPageState
    extends ConsumerState<VistoriaChecklistPage> {
  int _comodoIndex = 0;
  bool _saving = false;

  Future<void> _salvarItem({
    required Checklist checklist,
    required Comodo comodo,
    required ItemVistoriaCatalogo catalogo,
    required String estado,
    String? observacao,
    ChecklistItem? existing,
  }) async {
    setState(() => _saving = true);
    try {
      await ref.read(checklistRepositoryProvider).upsertItem(
            checklistId: checklist.id,
            comodoId: comodo.id,
            itemVistoriaId: catalogo.id,
            estado: estado,
            observacao: observacao,
            existingItemId: existing?.id,
          );
      ref.invalidate(checklistDetailProvider(widget.checklistId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item salvo')),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _foto({
    required ChecklistItem item,
    required ImageSource source,
  }) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return;
    setState(() => _saving = true);
    try {
      final bytes = kIsWeb ? await file.readAsBytes() : null;
      await ref.read(checklistRepositoryProvider).uploadFoto(
            checklistId: widget.checklistId,
            itemId: item.id,
            filePath: file.path,
            bytes: bytes,
            filename: file.name,
          );
      ref.invalidate(checklistDetailProvider(widget.checklistId));
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(checklistDetailProvider(widget.checklistId));
    final catalogoAsync = ref.watch(itensCatalogoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist da vistoria'),
        actions: [
          TextButton(
            onPressed: () =>
                context.push('/vistoria/${widget.checklistId}/revisao'),
            child: const Text('Revisar'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const OcLoading(),
        error: (e, _) => OcErrorView(
          message: e is AppException ? e.message : 'Erro ao carregar',
          onRetry: () =>
              ref.invalidate(checklistDetailProvider(widget.checklistId)),
        ),
        data: (checklist) {
          if (!checklist.podeEditar) {
            return OcEmptyState(
              title: 'Vistoria finalizada',
              subtitle:
                  'Status: ${labelChecklistStatus(checklist.status)}. Edição bloqueada pela API.',
              icon: Icons.lock_outline,
              action: FilledButton(
                onPressed: () =>
                    context.push('/vistoria/${checklist.id}/revisao'),
                child: const Text('Ver revisão'),
              ),
            );
          }

          final comodos = checklist.comodos;
          if (comodos.isEmpty) {
            return const OcEmptyState(
              title: 'Imóvel sem cômodos',
              subtitle:
                  'Cadastre cômodos no sistema web antes de preencher o checklist.',
            );
          }

          final index = _comodoIndex.clamp(0, comodos.length - 1);
          final comodo = comodos[index];
          final catalogo = catalogoAsync.valueOrNull ?? const [];

          return Column(
            children: [
              if (_saving) const LinearProgressIndicator(minHeight: 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: index > 0
                          ? () => setState(() => _comodoIndex = index - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            comodo.nomeExibicao,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Cômodo ${index + 1} de ${comodos.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: index < comodos.length - 1
                          ? () => setState(() => _comodoIndex = index + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: catalogoAsync.isLoading
                    ? const OcLoading(message: 'Carregando catálogo...')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: catalogo.length,
                        itemBuilder: (context, i) {
                          final cat = catalogo[i];
                          ChecklistItem? existing;
                          for (final it in checklist.itens) {
                            if (it.comodoId == comodo.id &&
                                it.itemVistoriaId == cat.id) {
                              existing = it;
                              break;
                            }
                          }
                          final saved = existing;
                          return _ItemEditor(
                            catalogo: cat,
                            existing: saved,
                            onSave: (estado, obs) => _salvarItem(
                              checklist: checklist,
                              comodo: comodo,
                              catalogo: cat,
                              estado: estado,
                              observacao: obs,
                              existing: saved,
                            ),
                            onCamera: saved == null
                                ? null
                                : () => _foto(
                                      item: saved,
                                      source: ImageSource.camera,
                                    ),
                            onGallery: saved == null
                                ? null
                                : () => _foto(
                                      item: saved,
                                      source: ImageSource.gallery,
                                    ),
                            onDeleteFoto: saved == null || saved.fotos.isEmpty
                                ? null
                                : () async {
                                    final foto = saved.fotos.first;
                                    await ref
                                        .read(checklistRepositoryProvider)
                                        .deleteFoto(
                                          checklistId: checklist.id,
                                          itemId: saved.id,
                                          fotoId: foto.id,
                                        );
                                    ref.invalidate(
                                      checklistDetailProvider(
                                        widget.checklistId,
                                      ),
                                    );
                                  },
                            apiBase: ref.read(appConfigProvider).apiBaseUrl,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({
    required this.catalogo,
    required this.existing,
    required this.onSave,
    required this.apiBase,
    this.onCamera,
    this.onGallery,
    this.onDeleteFoto,
  });

  final ItemVistoriaCatalogo catalogo;
  final ChecklistItem? existing;
  final Future<void> Function(String estado, String? observacao) onSave;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onDeleteFoto;
  final String apiBase;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late String? _estado = widget.existing?.estado;
  late final TextEditingController _obs =
      TextEditingController(text: widget.existing?.observacao ?? '');

  @override
  void dispose() {
    _obs.dispose();
    super.dispose();
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${widget.apiBase}$url';
  }

  @override
  Widget build(BuildContext context) {
    final filled = _estado != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.catalogo.nome,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Icon(
                filled ? Icons.check_circle : Icons.radio_button_unchecked,
                color: filled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
          if (widget.catalogo.categoria != null)
            Text(
              widget.catalogo.categoria!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: ['otimo', 'bom', 'regular', 'ruim'].map((e) {
              return ChoiceChip(
                label: Text(labelEstadoItem(e)),
                selected: _estado == e,
                onSelected: (_) => setState(() => _estado = e),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _obs,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Observações',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.existing?.fotos.isNotEmpty == true)
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: widget.existing!.fotos
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _resolveUrl(f.url),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          Row(
            children: [
              TextButton.icon(
                onPressed: _estado == null
                    ? null
                    : () => widget.onSave(_estado!, _obs.text.trim().isEmpty
                        ? null
                        : _obs.text.trim()),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar'),
              ),
              if (widget.onCamera != null)
                IconButton(
                  tooltip: 'Câmera',
                  onPressed: widget.onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                ),
              if (widget.onGallery != null)
                IconButton(
                  tooltip: 'Galeria',
                  onPressed: widget.onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                ),
              if (widget.onDeleteFoto != null)
                IconButton(
                  tooltip: 'Remover foto',
                  onPressed: widget.onDeleteFoto,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          if (widget.existing == null)
            Text(
              'Salve o estado antes de anexar fotos.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
