import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/pokemon_data.dart';
import '../utils/hangul_search.dart';

// 세대 정의
const List<Map<String, dynamic>> _generations = [
  {'label': '전체', 'start': 1, 'end': 1025},
  {'label': '1세대', 'start': 1, 'end': 151},
  {'label': '2세대', 'start': 152, 'end': 251},
  {'label': '3세대', 'start': 252, 'end': 386},
  {'label': '4세대', 'start': 387, 'end': 493},
  {'label': '5세대', 'start': 494, 'end': 649},
  {'label': '6세대', 'start': 650, 'end': 721},
  {'label': '7세대', 'start': 722, 'end': 809},
  {'label': '8세대', 'start': 810, 'end': 905},
  {'label': '9세대', 'start': 906, 'end': 1025},
  {'label': '메가진화', 'kind': 'mega'},
];

class PokemonPickerDialog extends StatefulWidget {
  final List<int> selectedIds;
  final int maxSelect;

  const PokemonPickerDialog({
    super.key,
    required this.selectedIds,
    this.maxSelect = 3,
  });

  @override
  State<PokemonPickerDialog> createState() => _PokemonPickerDialogState();
}

class _PokemonPickerDialogState extends State<PokemonPickerDialog>
    with SingleTickerProviderStateMixin {
  late List<int> _selectedIds;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  /// 전체 도감 (일반 + 메가진화 + 폼)
  static final List<PokemonInfo> _allEntries = [
    ...allPokemon,
    ...megaPokemon,
    ...ogerponForms,
  ];

  // 탭 인덱스에 따라 필터링된 포켓몬 목록
  List<PokemonInfo> _getFiltered(int tabIndex) {
    // 검색 중에는 탭과 무관하게 전체 도감(메가진화·폼 포함)에서 찾는다
    if (_search.trim().isNotEmpty) {
      final query = _search.trim();
      final chosungQuery = isChosungSearch(query) ? query : null;
      final hits = _allEntries
          .where((p) => matchesPokemonQuery(
                nameKo: p.nameKo,
                name: p.name,
                id: p.id,
                query: query,
              ))
          .toList();

      // 앞에서부터 맞는 것을 먼저 보여준다 (예: 'ㄷㄹ' -> 드래펄트가 메가드래캄보다 위)
      int rank(PokemonInfo p) {
        if (chosungQuery != null) {
          return toChosung(p.nameKo).startsWith(chosungQuery) ? 0 : 1;
        }
        return p.nameKo.startsWith(query) ? 0 : 1;
      }

      hits.sort((a, b) {
        final c = rank(a).compareTo(rank(b));
        if (c != 0) return c;
        return a.id.compareTo(b.id);
      });
      return hits;
    }

    final gen = _generations[tabIndex];
    final isMegaTab = gen['kind'] == 'mega';
    final start = (gen['start'] as int?) ?? 0;
    final end = (gen['end'] as int?) ?? 0;

    List<PokemonInfo> base;
    if (isMegaTab) {
      base = List<PokemonInfo>.from(megaPokemon);
    } else {
      base = allPokemon.where((p) => p.id >= start && p.id <= end).toList();
      // 오거폰의 세 가지 가면 폼은 9세대 오거폰 바로 다음에 배치한다.
      if (gen['label'] == '9세대' || gen['label'] == '전체') {
        final ogerponIndex = base.indexWhere((p) => p.id == 1017);
        if (ogerponIndex >= 0) {
          base.insertAll(ogerponIndex + 1, ogerponForms);
        }
      }
    }
    return base;
  }

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
    _tabController = TabController(length: _generations.length, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.88,
        child: Column(
          children: [
            // ── 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Text(
                    '포켓몬 선택',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.cInk,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedIds.length}/${widget.maxSelect}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),

            // ── 검색창
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '이름 · 초성 · 번호로 검색...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.grey[400], size: 18),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: 16, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: context.cFill,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),

            // ── 선택된 포켓몬 미리보기
            if (_selectedIds.isNotEmpty)
              Container(
                height: 60,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.cFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.cBorder),
                ),
                child: Row(
                  children: [
                    const Text(
                      '선택됨:',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    ..._selectedIds.map((id) {
                      final p = pokemonById(id) ?? allPokemon.first;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: p.spriteUrl,
                                width: 38,
                                height: 38,
                                fit: BoxFit.contain,
                                placeholder: (c, u) => Container(
                                    width: 38,
                                    height: 38,
                                    color: context.cBorder),
                                errorWidget: (c, u, e) => const Icon(
                                    Icons.catching_pokemon,
                                    size: 18,
                                    color: Colors.grey),
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedIds.remove(id)),
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 10, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            // ── 세대 탭 바
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.cLine, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: const Color(0xFFEF4444),
                indicatorWeight: 2.5,
                labelColor: const Color(0xFFEF4444),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                tabs: _generations
                    .map((g) => Tab(
                          text: g['label'] as String,
                          height: 36,
                        ))
                    .toList(),
              ),
            ),

            // ── 포켓몬 그리드 (탭별)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(_generations.length, (tabIdx) {
                  return _buildGrid(tabIdx);
                }),
              ),
            ),

            // ── 확인 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context, _selectedIds),
                  child: Text(
                    _selectedIds.isEmpty
                        ? '선택 완료 (선택 없음)'
                        : '선택 완료 (${_selectedIds.length}마리)',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(int tabIndex) {
    final filtered = _getFiltered(tabIndex);
    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          '검색 결과가 없습니다',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.78,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final p = filtered[i];
        final isSelected = _selectedIds.contains(p.id);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(p.id);
              } else if (_selectedIds.length < widget.maxSelect) {
                _selectedIds.add(p.id);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                  : context.cFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? const Color(0xFFEF4444) : context.cBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    CachedNetworkImage(
                      imageUrl: p.spriteUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      placeholder: (c, u) => const SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (c, u, e) => const Icon(
                        Icons.catching_pokemon,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 10, color: Colors.white),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    p.nameKo,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected ? const Color(0xFFEF4444) : context.cSlate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  p.displayNumber ?? '#${p.id.toString().padLeft(4, '0')}',
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
