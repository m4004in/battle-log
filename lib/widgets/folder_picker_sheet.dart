import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tournament_record.dart';
import '../providers/tournament_provider.dart';
import '../theme/app_theme.dart';

const Color _kRed = Color(0xFFEF4444);

/// 폴더 이름 입력 다이얼로그 (새 폴더 / 이름 변경 공용)
Future<String?> showFolderNameDialog(BuildContext context,
    {String initial = '', String title = '새 폴더'}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _FolderNameDialog(initial: initial, title: title),
  );
}

class _FolderNameDialog extends StatefulWidget {
  final String initial;
  final String title;
  const _FolderNameDialog({required this.initial, required this.title});

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.cSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.title,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: context.cInk)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLength: 20,
        style: TextStyle(fontSize: 15, color: context.cInk),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: '폴더 이름',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          filled: true,
          fillColor: context.cFill,
          counterText: '',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
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
          onPressed: _submit,
          child:
              const Text('확인', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

/// 기록을 넣을 폴더 선택 시트
Future<void> showFolderPickerSheet(
    BuildContext context, TournamentRecord record) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.cSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => _FolderPickerSheet(recordId: record.id),
  );
}

class _FolderPickerSheet extends StatelessWidget {
  final String recordId;
  const _FolderPickerSheet({required this.recordId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final folders = provider.folders;
    final record = provider.records.where((r) => r.id == recordId).toList();
    final currentId = record.isEmpty ? null : record.first.folderId;

    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                '폴더에 넣기',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.cInk),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  if (folders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Text(
                        '아직 폴더가 없어요. 아래에서 새 폴더를 만들어 보세요.',
                        style: TextStyle(fontSize: 13, color: context.cSlate),
                      ),
                    ),
                  for (final f in folders)
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      leading: Icon(
                        f.id == currentId
                            ? Icons.folder
                            : Icons.folder_outlined,
                        color: f.id == currentId ? _kRed : context.cSlate,
                      ),
                      title: Text(
                        f.name,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.cInk),
                      ),
                      subtitle: Text(
                        '기록 ${provider.recordsInFolder(f.id).length}개',
                        style: TextStyle(fontSize: 12, color: context.cSlate),
                      ),
                      trailing: f.id == currentId
                          ? const Icon(Icons.check_circle,
                              color: _kRed, size: 22)
                          : null,
                      onTap: () async {
                        await provider.setRecordFolder(recordId, f.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  if (currentId != null)
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      leading: Icon(Icons.folder_off_outlined,
                          color: context.cSlate),
                      title: Text('폴더에서 빼기',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.cInk)),
                      onTap: () async {
                        await provider.setRecordFolder(recordId, null);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kRed,
                    side: const BorderSide(color: _kRed),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.create_new_folder_outlined, size: 20),
                  label: const Text('새 폴더 만들기',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () async {
                    final name = await showFolderNameDialog(context);
                    if (name == null || name.isEmpty) return;
                    final f = await provider.addFolder(name);
                    await provider.setRecordFolder(recordId, f.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
