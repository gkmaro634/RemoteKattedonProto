import 'package:flutter/material.dart';
import 'package:remote_kattedon/core/theme/app_theme.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';

/// ゲームカードウィジェット
class GameCard extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final VoidCallback onTap;
  final Color? colorScheme;

  const GameCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.colorScheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme?.withOpacity(0.1) ?? AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            border: Border.all(
              color: colorScheme ?? AppTheme.primaryColor,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme ?? AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ゲーム開始用ボタン
class GameStartButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const GameStartButton({
    Key? key,
    this.label = 'START',
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 48,
          vertical: 16,
        ),
      ),
      child: isLoading
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 2,
        ),
      )
          : Text(label),
    );
  }
}

/// 戻るボタン
class GoBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const GoBackButton({
    Key? key,
    required this.onPressed,
    this.label = '戻る',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// ゲーム説明カード
class GameDescriptionCard extends StatelessWidget {
  final String title;
  final String description;
  final Color? accentColor;

  const GameDescriptionCard({
    Key? key,
    required this.title,
    required this.description,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: (accentColor ?? AppTheme.primaryColor).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: accentColor ?? AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// ナビゲーション用トップメニュー
class TopNavigationMenu extends StatelessWidget {
  final String currentRoute;
  final VoidCallback onHomePressed;
  final VoidCallback onGameSelectionPressed;

  const TopNavigationMenu({
    Key? key,
    required this.currentRoute,
    required this.onHomePressed,
    required this.onGameSelectionPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.smallPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: onHomePressed,
                  child: const Text('注文'),
                  style: TextButton.styleFrom(
                    backgroundColor: currentRoute == '/' 
                        ? AppTheme.primaryColor.withOpacity(0.1) 
                        : Colors.transparent,
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                TextButton(
                  onPressed: onGameSelectionPressed,
                  child: const Text('ゲーム'),
                  style: TextButton.styleFrom(
                    backgroundColor: currentRoute == '/game-selection' 
                        ? AppTheme.primaryColor.withOpacity(0.1) 
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
