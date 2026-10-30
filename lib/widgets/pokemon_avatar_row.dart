import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/pokemon_data.dart';

class PokemonAvatarRow extends StatelessWidget {
  final List<int> pokemonIds;
  final double size;
  final VoidCallback? onTap;

  const PokemonAvatarRow({
    super.key,
    required this.pokemonIds,
    this.size = 36,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pokemonIds.isEmpty)
            _buildEmptySlot(context)
          else
            ...pokemonIds.map((id) {
              final p = allPokemon.firstWhere(
                (p) => p.id == id,
                orElse: () =>
                    const PokemonInfo(id: 1, name: 'bulbasaur', nameKo: '이상해씨'),
              );
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: _buildAvatar(context, p),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, PokemonInfo p) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.cFill,
        shape: BoxShape.circle,
        border: Border.all(color: context.cBorder, width: 1),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: p.spriteUrl,
          fit: BoxFit.contain,
          placeholder: (c, u) => const Center(
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
          errorWidget: (c, u, e) => Icon(
            Icons.catching_pokemon,
            size: size * 0.5,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlot(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.cFill,
        shape: BoxShape.circle,
        border: Border.all(
          color: context.cBorder,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Icon(
        Icons.add,
        size: size * 0.45,
        color: Colors.grey[400],
      ),
    );
  }
}

// 포켓몬 선택 버튼 (최대 3개 표시)
class PokemonSelectorRow extends StatelessWidget {
  final List<int> selectedIds;
  final VoidCallback onTap;
  final double avatarSize;

  const PokemonSelectorRow({
    super.key,
    required this.selectedIds,
    required this.onTap,
    this.avatarSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.cFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.cBorder),
        ),
        child: Row(
          children: [
            // 포켓몬 아바타들 (최대 3개)
            ...List.generate(3, (i) {
              if (i < selectedIds.length) {
                final id = selectedIds[i];
                final p = allPokemon.firstWhere(
                  (p) => p.id == id,
                  orElse: () => const PokemonInfo(
                      id: 1, name: 'bulbasaur', nameKo: '이상해씨'),
                );
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    children: [
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          color: context.cSurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.3),
                              width: 1.5),
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: p.spriteUrl,
                            fit: BoxFit.contain,
                            placeholder: (c, u) => const SizedBox(
                              child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5, color: Color(0xFFEF4444)),
                              ),
                            ),
                            errorWidget: (c, u, e) => Icon(
                                Icons.catching_pokemon,
                                size: avatarSize * 0.5,
                                color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.nameKo,
                        style: TextStyle(fontSize: 9, color: context.cSlate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: context.cSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: context.cBorder,
                          width: 1,
                          style: BorderStyle.solid),
                    ),
                    child: Icon(Icons.add,
                        size: avatarSize * 0.4, color: Colors.grey[400]),
                  ),
                );
              }
            }),
            const Spacer(),
            Text(
              selectedIds.isEmpty ? '포켓몬 선택' : '변경',
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFFEF4444)),
          ],
        ),
      ),
    );
  }
}
