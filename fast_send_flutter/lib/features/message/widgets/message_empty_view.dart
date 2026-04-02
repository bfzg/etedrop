import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../styles/styles.dart';

class MessageEmptyView extends StatelessWidget {
  const MessageEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.noMessagesYet, style: AppTextStyles.hint(context)),
          const SizedBox(height: 8),
          Text(l10n.noMessagesSubtitle, style: AppTextStyles.secondary(context)),
        ],
      ),
    );
  }
}
