import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/core/theme/app_theme.dart';
import 'package:remote_kattedon/navigation/route_names.dart';
import 'package:remote_kattedon/game_bora/models/bora_models.dart';

class BoraCharacterSelectScreen extends StatefulWidget {
  const BoraCharacterSelectScreen({Key? key}) : super(key: key);

  @override
  State<BoraCharacterSelectScreen> createState() => _BoraCharacterSelectScreenState();
}

class _BoraCharacterSelectScreenState extends State<BoraCharacterSelectScreen> {
  CharacterType? _selected;

  // Previously showed stat bars here; removed to reduce card height.

  void _onSelect(CharacterType type) {
    setState(() {
      _selected = type;
    });
  }

  void _onStart() {
    if (_selected == null) return;
    final char = CHARACTERS[_selected]!;
    context.go(RouteNames.boraGame, extra: char);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('漁師を選ぶ'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '漁師を選ぶ',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: isMobile ? 1 : 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    // モバイルでは縦長すぎないよう、高さを小さくする（width/height）。
                    childAspectRatio: isMobile ? 3.2 : 1.2,
                    children: CHARACTERS.values.map((char) {
                      final isSelected = _selected == char.id;
                      return GestureDetector(
                        onTap: () => _onSelect(char.id),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.boraColor.withOpacity(0.2) : AppTheme.backgroundColor,
                            border: Border.all(
                              color: isSelected ? AppTheme.boraColor : const Color(0xFFBDBDBD),
                              width: isSelected ? 3 : 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // カード内の利用可能幅から各統計列の幅を算出
                              final paddingTotal = 12 * 2; // Container の左右パディング
                              final gapTotal = 8 * 2; // SizedBox の合計幅
                              final statItemWidth = (constraints.maxWidth - paddingTotal - gapTotal) / 3;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      char.emoji,
                                      style: TextStyle(fontSize: isMobile ? 36 : 36),
                                    ),
                                  ),
                                  const SizedBox(height: 0),
                                  Center(
                                    child: Text(
                                      char.name,
                                      style: TextStyle(fontSize: isMobile ? 16 : 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Text(
                                      char.description,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: isMobile ? 4 : 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _selected != null ? _onStart : null,
                  child: const Text('この漁師で始める'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
