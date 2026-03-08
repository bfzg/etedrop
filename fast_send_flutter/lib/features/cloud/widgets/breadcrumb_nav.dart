import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/cloud_provider.dart';

/// 面包屑导航
/// 对应 Electron: src/components/cloud/breadcrumb-nav.tsx
class BreadcrumbNav extends ConsumerWidget {
  const BreadcrumbNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segments = ref.watch(breadcrumbSegmentsProvider);
    final theme = Theme.of(context);

    return SizedBox(
      height: 36,
      child: Row(
        children: [
          InkWell(
            onTap: () => ref.read(currentPathProvider.notifier).navigateToRoot(),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('根目录', style: TextStyle(color: theme.colorScheme.primary, fontSize: 14)),
                ],
              ),
            ),
          ),
          for (int i = 0; i < segments.length; i++) ...[
            Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurfaceVariant),
            InkWell(
              onTap: i < segments.length - 1
                  ? () {
                      final path = segments.sublist(0, i + 1).join('/');
                      ref.read(currentPathProvider.notifier).navigate(path);
                    }
                  : null,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  segments[i],
                  style: TextStyle(
                    fontSize: 14,
                    color: i < segments.length - 1
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: i == segments.length - 1 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
