// Offline upload and weekly streak strings.
// Plural pairs: `key` is used for a count of 1, `keyPlural` otherwise.
const Map<String, String> syncEn = {
  'sync.doneTitle': 'Uploads complete',
  'sync.doneBody': '@count saved entry was uploaded.',
  'sync.doneBodyPlural': '@count saved entries were uploaded.',
  'sync.errorTitle': 'Error',
  'sync.loadFailed': 'Failed to load pending cleanups.',
  'sync.offlineTitle': 'Offline',
  'sync.offlineBody':
      "You're offline. It will upload automatically when you're back online.",
  'sync.missingTitle': 'Photo not found',
  'sync.missingBody':
      '@count photo for "@place" is no longer on this phone, so it was skipped. The rest are still uploading.',
  'sync.missingBodyPlural':
      '@count photos for "@place" are no longer on this phone, so they were skipped. The rest are still uploading.',
  'sync.uploadedTitle': 'Uploaded',
  'sync.cleanupUploaded': 'Cleanup uploaded successfully.',
  'sync.hotspotUploaded': 'Hotspot report uploaded successfully.',
  'sync.failedWillRetry':
      'Upload interrupted. It will continue automatically when the connection is back.',
  'sync.uploadFailed':
      'Upload failed. It will retry automatically, or tap Upload to try now.',
  'sync.deletedTitle': 'Deleted',
  'sync.cleanupDeleted': 'Cleanup deleted.',
  'sync.hotspotDeleted': 'Hotspot report deleted.',
  'sync.deleteFailed': 'Failed to delete cleanup.',
  'sync.hotspotNoPhotos':
      "All photos of this report are missing from the phone. A hotspot report needs at least one photo, so it can't be uploaded. You can delete it.",
  'sync.streakTitle': '@count-week streak!',
  'sync.streakTitlePlural': '@count-week streak!',
  'sync.streakSafeBody':
      'This week is done. Come back next week to keep your streak going.',
  'sync.streakAtRiskBody':
      'Log a cleanup or report a hotspot before Sunday to keep your streak.',
  'sync.streakLostTitle': 'Streak lost',
  'sync.streakLostBody':
      'Your @count-week streak ended. Log a cleanup or report a hotspot to start a new one.',
  'sync.streakLostBodyPlural':
      'Your @count-week streak ended. Log a cleanup or report a hotspot to start a new one.',
  'sync.weeksUnit': 'week in a row',
  'sync.weeksUnitPlural': 'weeks in a row',
  'sync.streakContinue': 'Keep it up',
  'sync.streakRestart': 'Start a new streak',
};

const Map<String, String> syncFr = {
  'sync.doneTitle': 'Envois terminés',
  'sync.doneBody': '@count entrée enregistrée a été envoyée.',
  'sync.doneBodyPlural': '@count entrées enregistrées ont été envoyées.',
  'sync.errorTitle': 'Erreur',
  'sync.loadFailed': 'Impossible de charger les nettoyages en attente.',
  'sync.offlineTitle': 'Hors ligne',
  'sync.offlineBody':
      "Vous êtes hors ligne. L'envoi se fera automatiquement dès le retour de la connexion.",
  'sync.missingTitle': 'Photo introuvable',
  'sync.missingBody':
      "@count photo de « @place » n'est plus sur ce téléphone, elle a donc été ignorée. Les autres continuent d'être envoyées.",
  'sync.missingBodyPlural':
      "@count photos de « @place » ne sont plus sur ce téléphone, elles ont donc été ignorées. Les autres continuent d'être envoyées.",
  'sync.uploadedTitle': 'Envoyé',
  'sync.cleanupUploaded': 'Nettoyage envoyé avec succès.',
  'sync.hotspotUploaded': 'Signalement de point noir envoyé avec succès.',
  'sync.failedWillRetry':
      'Envoi interrompu. Il reprendra automatiquement au retour de la connexion.',
  'sync.uploadFailed':
      "Échec de l'envoi. Nouvel essai automatique, ou appuyez sur Envoyer pour réessayer maintenant.",
  'sync.deletedTitle': 'Supprimé',
  'sync.cleanupDeleted': 'Nettoyage supprimé.',
  'sync.hotspotDeleted': 'Signalement de point noir supprimé.',
  'sync.deleteFailed': 'Impossible de supprimer le nettoyage.',
  'sync.hotspotNoPhotos':
      'Toutes les photos de ce signalement ont disparu du téléphone. Un signalement de point noir nécessite au moins une photo, il ne peut donc pas être envoyé. Vous pouvez le supprimer.',
  'sync.streakTitle': 'Série de @count semaine !',
  'sync.streakTitlePlural': 'Série de @count semaines !',
  'sync.streakSafeBody':
      'Cette semaine est validée. Revenez la semaine prochaine pour continuer votre série.',
  'sync.streakAtRiskBody':
      'Enregistrez un nettoyage ou signalez un point noir avant dimanche pour garder votre série.',
  'sync.streakLostTitle': 'Série perdue',
  'sync.streakLostBody':
      'Votre série de @count semaine est terminée. Enregistrez un nettoyage ou signalez un point noir pour en commencer une nouvelle.',
  'sync.streakLostBodyPlural':
      'Votre série de @count semaines est terminée. Enregistrez un nettoyage ou signalez un point noir pour en commencer une nouvelle.',
  'sync.weeksUnit': "semaine d'affilée",
  'sync.weeksUnitPlural': "semaines d'affilée",
  'sync.streakContinue': 'Continuer',
  'sync.streakRestart': 'Commencer une nouvelle série',
};
