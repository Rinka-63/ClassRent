import 'package:flutter/material.dart';

import 'app_brand_mark.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showBrandLogo = true,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool showBrandLogo;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        automaticallyImplyLeading: canPop || !showBrandLogo,
        leading: showBrandLogo && !canPop
            ? const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Center(
                  child: AppBrandMark(
                    size: 36,
                    backgroundColor: Colors.white,
                  ),
                ),
              )
            : null,
        leadingWidth: showBrandLogo && !canPop ? 52 : null,
        actions: actions,
        surfaceTintColor: Colors.transparent,
        backgroundColor:
            isDark ? colorScheme.surfaceContainerHigh : colorScheme.primary,
        foregroundColor: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
        shape: const Border(
          bottom: BorderSide(color: Colors.transparent),
        ),
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
