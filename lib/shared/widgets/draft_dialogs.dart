import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:we_monitor/shared/constants/app_strings.dart';
import 'package:we_monitor/shared/drafts/form_draft.dart';
import 'package:we_monitor/shared/widgets/app_dialog.dart';

enum DraftExitChoice { keep, discard, stay }

/// Asks whether to restore [draft]. Returns true to continue, false to discard.
Future<bool> showDraftRestoreDialog(
  BuildContext context,
  FormDraft draft,
) async {
  final isCleanup = draft.kind == FormDraft.kindCleanup;
  final parts = <String>[
    if (draft.groupName.trim().isNotEmpty) draft.groupName.trim(),
    if (draft.itemCount > 0) '${draft.itemCount} items',
    if (draft.photos.isNotEmpty) '${draft.photos.length} photos',
  ];
  final edited = DateFormat('d MMM yyyy, HH:mm').format(draft.savedAt);
  final body = [
    '${AppStrings.draftLastEdited}: $edited',
    if (parts.isNotEmpty) parts.join(' · '),
  ].join('\n');

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder:
        (ctx) => PopScope(
          canPop: false,
          child: AppDialog(
            title:
                isCleanup
                    ? AppStrings.draftRestoreCleanupTitle
                    : AppStrings.draftRestoreHotspotTitle,
            body: body,
            primaryActionLabel: AppStrings.draftContinue,
            onPrimaryAction: () => Navigator.of(ctx).pop(true),
            secondaryActions: [
              AppDialogAction(
                label: AppStrings.draftDiscard,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ],
          ),
        ),
  );
  return result ?? true;
}

/// Asks what to do with a form that has data when the user tries to leave.
Future<DraftExitChoice> showDraftExitDialog(BuildContext context) async {
  final result = await showDialog<DraftExitChoice>(
    context: context,
    builder:
        (ctx) => AppDialog(
          title: AppStrings.draftExitTitle,
          body: AppStrings.draftExitBody,
          primaryActionLabel: AppStrings.draftKeep,
          onPrimaryAction: () => Navigator.of(ctx).pop(DraftExitChoice.keep),
          secondaryActions: [
            AppDialogAction(
              label: AppStrings.draftDiscard,
              onPressed: () => Navigator.of(ctx).pop(DraftExitChoice.discard),
            ),
            AppDialogAction(
              label: AppStrings.draftStay,
              onPressed: () => Navigator.of(ctx).pop(DraftExitChoice.stay),
            ),
          ],
        ),
  );
  return result ?? DraftExitChoice.stay;
}
