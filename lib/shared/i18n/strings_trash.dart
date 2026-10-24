import 'package:get/get.dart';

// French display names for trash template categories/items. Stored values
// (Firestore) always stay English. Source: ascoa_web/lib/i18n/fr/trash-names.ts
const Map<String, String> trashCategoriesFr = {
  'Most Likely Items to Find': 'Articles les plus probables',
  'Fishing Gear': 'Matériel de pêche',
  'Tiny Trash (<2.5 cm)': 'Micro-déchets (<2,5 cm)',
  'Packaging Materials': 'Matériaux d\'emballage',
  'Personal Hygiene': 'Hygiène personnelle',
  'Items of Local Concern': 'Articles préoccupants localement',
  'Other Trash': 'Autres déchets',
};

const Map<String, String> trashItemsFr = {
  'Grocery bags (plastic)': 'Sacs de courses (plastique)',
  'Other bags (plastic)': 'Autres sacs (plastique)',
  'Brasseries bottles (glass)': 'Bouteilles Brasseries (verre)',
  'Guinness bottles (glass)': 'Bouteilles Guinness (verre)',
  'Brasseries bottles (plastic)': 'Bouteilles Brasseries (plastique)',
  'Source du Pays bottles (plastic)': 'Bouteilles Source du Pays (plastique)',
  'Beverage cans (Brasseries)': 'Canettes de boisson (Brasseries)',
  'Beverage cans (Guinness)': 'Canettes de boisson (Guinness)',
  'Beverage sachets/pouches': 'Sachets de boisson',
  'Brasseries bottle caps (metal)': 'Capsules de bouteilles Brasseries (métal)',
  'Guinness bottle caps (metal)': 'Capsules de bouteilles Guinness (métal)',
  'Brasseries bottle caps (plastic)': 'Bouchons de bouteilles Brasseries (plastique)',
  'Source du Pays bottle caps (plastic)': 'Bouchons de bouteilles Source du Pays (plastique)',
  'Cigarette butts': 'Mégots de cigarettes',
  'Other lids, bottles and cans': 'Autres couvercles, bouteilles et canettes',
  'Fishing Nets & Pieces (average piece)': 'Filets de pêche et morceaux (morceau moyen)',
  'Rope (1 yard/meter = 1 piece)': 'Corde (1 yard/mètre = 1 pièce)',
  'Appliances (typical)': 'Appareils électroménagers (type courant)',
  'Balloons': 'Ballons',
  'Cigar Tips': 'Bouts de cigare',
  'Cigarette Lighters': 'Briquets',
  'Construction Materials (average)': 'Matériaux de construction (moyenne)',
  'Fireworks (single item)': 'Feux d\'artifice (à l\'unité)',
  'Tires (car)': 'Pneus (voiture)',
  'Wood pieces (per piece)': 'Morceaux de bois (par morceau)',
  'Foam Pieces': 'Morceaux de mousse',
  'Glass Pieces': 'Morceaux de verre',
  'Plastic Pieces': 'Morceaux de plastique',
  'Dresses (small fabric scrap)': 'Vêtements (petit morceau de tissu)',
  'Paper Napkins': 'Serviettes en papier',
  'Rubber Materials (small bits)': 'Matériaux en caoutchouc (petits morceaux)',
  'Paper Waste (small)': 'Déchets de papier (petits)',
  'Cups, plates (foam)': 'Gobelets, assiettes (mousse)',
  'Cups, plates (paper)': 'Gobelets, assiettes (papier)',
  'Cups, plates (plastic)': 'Gobelets, assiettes (plastique)',
  'Food containers (foam)': 'Contenants alimentaires (mousse)',
  'Food containers (plastic)': 'Contenants alimentaires (plastique)',
  'Food wrappers': 'Emballages alimentaires',
  'Lids (plastic)': 'Couvercles (plastique)',
  'Straws/stirrers': 'Pailles/agitateurs',
  'Utensils (plastic)': 'Ustensiles (plastique)',
  '6-Pack Holders': 'Anneaux de packs de 6',
  'Cartons (single flattened box)': 'Cartons (une boîte aplatie)',
  'Sacks (empty single woven sack)': 'Sacs (un sac tissé vide)',
  'Strapping Bands (per length/piece)': 'Bandes de cerclage (par longueur/pièce)',
  'Tooth paste containers': 'Tubes de dentifrice',
  'Tobacco Packaging / Wrap': 'Emballages de tabac',
  'Disposable cups': 'Gobelets jetables',
  'Disposable plates': 'Assiettes jetables',
  'Yogurt containers': 'Pots de yaourt',
  'Detergent bottles': 'Bouteilles de détergent',
  'Lotion and cream containers': 'Contenants de lotion et de crème',
  'Deodorant containers': 'Contenants de déodorant',
  'Shampoo, conditioner and soap bottles': 'Bouteilles de shampooing, d\'après-shampooing et de savon',
  'Other Plastics / Foam Packaging': 'Autres emballages en plastique / mousse',
  'Other Plastic Bottles (oil, bleach)': 'Autres bouteilles en plastique (huile, eau de Javel)',
  'Bathing Slippers': 'Tongs de douche',
  'Condoms (pack/individual wrapper)': 'Préservatifs (paquet/emballage individuel)',
  'Diapers (single)': 'Couches (à l\'unité)',
  'Syringes (single)': 'Seringues (à l\'unité)',
  'Tampons / Sanitary Pad': 'Tampons / serviettes hygiéniques',
  'Tooth Brush': 'Brosses à dents',
  'Bathing Brush': 'Brosses de bain',
  'Coconut shells (single shell)': 'Coques de noix de coco (une coque)',
  'Snail shells (single)': 'Coquilles d\'escargot (à l\'unité)',
  'Dead or Injured animal (small)': 'Animal mort ou blessé (petit)',
};

/// Display helper for template names (keys are the English Firestore names).
class TrashNames {
  TrashNames._();

  static String display(String name) {
    if (Get.locale?.languageCode != 'fr') return name;
    return trashItemsFr[name] ?? trashCategoriesFr[name] ?? name;
  }
}

/// Display helper for environment names ('Inland', 'Freshwater', 'Saltwater',
/// 'Land', 'All'); stored values stay English.
class EnvironmentNames {
  EnvironmentNames._();

  static String display(String name) {
    switch (name) {
      case 'Inland':
      case 'Land':
        return 'core.environmentLand'.tr;
      case 'Freshwater':
        return 'core.environmentFreshwater'.tr;
      case 'Saltwater':
        return 'core.environmentSaltwater'.tr;
      case 'All':
        return 'core.statsAll'.tr;
      default:
        return name;
    }
  }
}
