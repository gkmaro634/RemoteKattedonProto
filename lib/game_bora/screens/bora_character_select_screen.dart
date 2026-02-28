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

  Widget _statBar(int value, {int max = 5}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        return Container(
          width: 14,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: i < value
                ? const Color(0xFFFF5722)
                : const Color(0xFFBDBDBD),
            border: Border.all(color: const Color(0xFF9E9E9E)),
          ),
        );
      }),
    );
  }

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
                    crossAxisCount: MediaQuery.of(context).size.width < 600 ? 1 : 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                    children: CHARACTERS.values.map((char) {
                      final isSelected = _selected == char.id;
                      return GestureDetector(
                        onTap: () => _onSelect(char.id),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.boraColor.withOpacity(0.2) : AppTheme.backgroundColor,
                            border: Border.all(
                              color: isSelected ? AppTheme.boraColor : const Color(0xFFBDBDBD),
                              width: isSelected ? 3 : 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  char.emoji,
                                  style: const TextStyle(fontSize: 40),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  char.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  char.description,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 6,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('引き上げ速度', style: TextStyle(fontSize: 10)),
                                      _statBar(char.stats.netSpeed),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('視力', style: TextStyle(fontSize: 10)),
                                      _statBar(char.stats.visionRange),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('人徳', style: TextStyle(fontSize: 10)),
                                      _statBar(char.stats.virtue),
                                    ],
                                  ),
                                ],
                              ),
                            ],
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
