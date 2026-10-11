import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../theme/palette.dart';
import '../theme/type.dart';

Future<Comment?> showCommentSheet(BuildContext context,
        {required String articleId, required String title}) =>
    showModalBottomSheet<Comment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CommentSheet(articleId: articleId, title: title),
    );

class _CommentSheet extends StatefulWidget {
  const _CommentSheet({required this.articleId, required this.title});

  final String articleId;
  final String title;

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: SettingsScope.of(context).commentName);
  final _content = TextEditingController();
  bool _sending = false;
  Map<String, String> _serverErrors = const {};
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _serverErrors = const {};
      _error = null;
    });
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    final settings = SettingsScope.of(context);
    try {
      final comment = await NewsApi.instance
          .postComment(widget.articleId, name: _name.text, content: _content.text);
      settings.commentName = _name.text.trim();
      if (mounted) Navigator.of(context).pop(comment);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _serverErrors = e.errors;
        _error = e.errors.isEmpty ? e.message : null;
      });
      _form.currentState!.validate();
    }
  }

  String? _check(String field, String? v, int min, int max) {
    if (_serverErrors[field] case final msg?) return msg;
    final len = (v ?? '').trim().length;
    if (len < min) return len == 0 ? 'Wajib diisi' : 'Minimal $min karakter';
    if (len > max) return 'Maksimal $max karakter';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: p.depth(2),
        ),
        padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + MediaQuery.paddingOf(context).bottom),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: p.rule, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Text('Tulis Tanggapan', style: AppType.display(24, color: p.ink)),
              const SizedBox(height: 4),
              Text('untuk “${widget.title}”',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.serif(14, color: p.muted, style: FontStyle.italic, height: 1.4)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                enabled: !_sending,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 50,
                decoration: const InputDecoration(labelText: 'Nama', counterText: ''),
                validator: (v) => _check('name', v, 2, 50),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _content,
                enabled: !_sending,
                autofocus: _name.text.isNotEmpty,
                minLines: 4,
                maxLines: 7,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Tanggapanmu',
                  alignLabelWithHint: true,
                ),
                validator: (v) => _check('content', v, 3, 500),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_error!, style: AppType.sans(13, color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _sending ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: p.accent.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Kirim Tanggapan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
