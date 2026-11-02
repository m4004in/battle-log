import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import '../theme/app_theme.dart';

const Color _kRed = Color(0xFFEF4444);

/// 백업 코드 만들기: 코드를 보여주고 자동으로 클립보드에 복사
Future<void> showBackupDialog(BuildContext context) async {
  final provider = context.read<TournamentProvider>();
  final code = provider.exportCode();
  var copied = true;
  try {
    await Clipboard.setData(ClipboardData(text: code));
  } catch (_) {
    copied = false;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => _BackupDialog(
      code: code,
      recordCount: provider.records.length,
      folderCount: provider.folders.length,
      autoCopied: copied,
    ),
  );
}

class _BackupDialog extends StatefulWidget {
  final String code;
  final int recordCount;
  final int folderCount;
  final bool autoCopied;
  const _BackupDialog({
    required this.code,
    required this.recordCount,
    required this.folderCount,
    required this.autoCopied,
  });

  @override
  State<_BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<_BackupDialog> {
  late bool _copied = widget.autoCopied;

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.code));
      if (mounted) setState(() => _copied = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.cSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('백업 코드',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: context.cInk)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '대회 ${widget.recordCount}개 · 폴더 ${widget.folderCount}개가 담겼어요.\n'
              '${_copied ? '코드가 복사되었습니다. ' : ''}메모 앱이나 카톡 "나와의 채팅"에 붙여넣어 보관하세요.',
              style:
                  TextStyle(fontSize: 13, height: 1.5, color: context.cSlate),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.cFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  widget.code,
                  style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      fontFamily: 'monospace',
                      color: context.cSlate),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kRed,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _copy,
          icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 16),
          label: Text(_copied ? '복사됨' : '코드 복사',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

/// 백업 코드로 복원 (현재 기록을 덮어씀)
Future<void> showRestoreDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const _RestoreDialog(),
  );
}

class _RestoreDialog extends StatefulWidget {
  const _RestoreDialog();

  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && mounted) {
        setState(() {
          _ctrl.text = data!.text!;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '붙여넣기 권한이 없어요. 입력칸을 길게 눌러 직접 붙여넣어 주세요.');
      }
    }
  }

  Future<void> _restore() async {
    if (_ctrl.text.trim().isEmpty) {
      setState(() => _error = '백업 코드를 붙여넣어 주세요.');
      return;
    }
    setState(() => _busy = true);
    final provider = context.read<TournamentProvider>();
    final err = await provider.importCodeOverwrite(_ctrl.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    final n = provider.records.length;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('복원 완료! 대회 기록 $n개를 불러왔어요.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.cSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('백업 코드로 복원',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: context.cInk)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '복원하면 지금 저장된 기록이 모두 지워지고\n백업 코드의 내용으로 바뀝니다.',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: _kRed,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              minLines: 4,
              maxLines: 4,
              style: TextStyle(
                  fontSize: 11, fontFamily: 'monospace', color: context.cInk),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                hintText: 'BLOG 로 시작하는 백업 코드를 붙여넣으세요',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                filled: true,
                fillColor: context.cFill,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kRed, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste_rounded, size: 16),
                label: const Text('붙여넣기'),
                style: TextButton.styleFrom(foregroundColor: context.cInk),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(_error!,
                    style: const TextStyle(fontSize: 12.5, color: _kRed)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('취소', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kRed,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _busy ? null : _restore,
          child:
              const Text('복원하기', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
