import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/record_folder.dart';
import '../models/tournament_record.dart';
import '../providers/tournament_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/folder_picker_sheet.dart';
import '../widgets/masonry_list.dart';

const Color _kRed = Color(0xFFEF4444);

/// 폴더 목록 화면 (폴더 추가 / 이름 변경 / 삭제)
class FolderListScreen extends StatelessWidget {
  final Widget Function(TournamentRecord record) cardBuilder;
  final void Function(BuildContext context, TournamentRecord record) onEdit;

  const FolderListScreen({
    super.key,
    required this.cardBuilder,
    required this.onEdit,
  });

  Future<void> _add(BuildContext context) async {
    final name = await showFolderNameDialog(context);
    if (name == null || name.isEmpty || !context.mounted) return;
    await context.read<TournamentProvider>().addFolder(name);
  }

  Future<void> _rename(BuildContext context, RecordFolder f) async {
    final name =
        await showFolderNameDialog(context, initial: f.name, title: '폴더 이름 변경');
    if (name == null || name.isEmpty || !context.mounted) return;
    await context.read<TournamentProvider>().renameFolder(f.id, name);
  }

  Future<void> _delete(BuildContext context, RecordFolder f, int count) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('폴더 삭제',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: ctx.cInk)),
        content: Text(
          '"${f.name}" 폴더를 삭제할까요?\n폴더만 사라지고, 안에 넣어 둔 기록($count개)은 삭제되지 않습니다.',
          style: TextStyle(fontSize: 14, height: 1.5, color: ctx.cInk),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('삭제', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<TournamentProvider>().deleteFolder(f.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final folders = provider.folders;

    return Scaffold(
      backgroundColor: context.cBg,
      appBar: AppBar(
        backgroundColor: context.cSurface,
        elevation: 0,
        title: Text('폴더',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.cInk)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Material(
                color: _kRed,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => _add(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: Colors.white),
                        SizedBox(width: 3),
                        Text('폴더 추가',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.cLine),
        ),
      ),
      body: folders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open_rounded,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 14),
                    Text('폴더가 없어요',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: context.cInk)),
                    const SizedBox(height: 8),
                    Text(
                      '폴더를 만들고, 기록 카드 제목 옆의\n폴더 버튼으로 기록을 넣어 보세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, height: 1.5, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _add(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.create_new_folder_outlined,
                          size: 18),
                      label: const Text('첫 폴더 만들기',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              itemCount: folders.length,
              itemBuilder: (ctx, i) {
                final f = folders[i];
                final count = provider.recordsInFolder(f.id).length;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: context.cSurface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FolderDetailScreen(
                            folderId: f.id,
                            cardBuilder: cardBuilder,
                            onEdit: onEdit,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                        child: Row(
                          children: [
                            const Icon(Icons.folder_rounded,
                                size: 30, color: _kRed),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: context.cInk),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('기록 $count개',
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          color: context.cSlate)),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: '이름 변경',
                              icon: Icon(Icons.edit_outlined,
                                  size: 20, color: context.cSlate),
                              onPressed: () => _rename(context, f),
                            ),
                            IconButton(
                              tooltip: '폴더 삭제',
                              icon: Icon(Icons.delete_outline,
                                  size: 22, color: context.cSlate),
                              onPressed: () => _delete(context, f, count),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// 폴더 안 화면 (이 폴더에 넣은 기록만 표시)
class FolderDetailScreen extends StatelessWidget {
  final String folderId;
  final Widget Function(TournamentRecord record) cardBuilder;
  final void Function(BuildContext context, TournamentRecord record) onEdit;

  const FolderDetailScreen({
    super.key,
    required this.folderId,
    required this.cardBuilder,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final folder = provider.folderById(folderId);
    final items = provider.recordsInFolder(folderId);

    return Scaffold(
      backgroundColor: context.cBg,
      appBar: AppBar(
        backgroundColor: context.cSurface,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.folder_rounded, size: 22, color: _kRed),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                folder?.name ?? '폴더',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.cInk),
              ),
            ),
            const SizedBox(width: 8),
            Text('${items.length}',
                style: TextStyle(fontSize: 14, color: context.cSlate)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.cLine),
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '이 폴더는 비어 있어요.\n기록 카드 제목 옆의 폴더 버튼으로\n기록을 넣어 보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, height: 1.6, color: Colors.grey[500]),
                ),
              ),
            )
          : MasonryList(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              itemCount: items.length,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => onEdit(context, items[i]),
                child: cardBuilder(items[i]),
              ),
            ),
    );
  }
}
