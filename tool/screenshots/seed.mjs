// Seeds the LOCAL Firebase emulators with demo data for store screenshots.
// Never runs against production: it refuses to start unless every emulator
// host variable is set. See README.md in this folder.
import { readFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomUUID } from 'node:crypto';
import admin from 'firebase-admin';
import sharp from 'sharp';

for (const v of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST', 'FIREBASE_STORAGE_EMULATOR_HOST']) {
  if (!process.env[v]) {
    console.error(`Refusing to run: ${v} is not set (this script only seeds the local emulators).`);
    process.exit(1);
  }
}

const HERE = dirname(fileURLToPath(import.meta.url));
const APP = join(HERE, '..', '..');
const ASCOA = join(APP, '..');
const PROJECT = 'trash-monitoring-app-88131';
const BUCKET = `${PROJECT}.firebasestorage.app`;
const STORAGE_HOST = process.env.FIREBASE_STORAGE_EMULATOR_HOST;

admin.initializeApp({ projectId: PROJECT, storageBucket: BUCKET });
const db = admin.firestore();
const auth = admin.auth();
const bucket = admin.storage().bucket();

export const DEMO = { email: 'amina.demo@example.com', password: 'wemonitor2026' };

// ---------- helpers ----------
let seed = 7;
const rand = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);
const between = (a, b) => Math.round(a + rand() * (b - a));

async function upload(path, buffer, contentType = 'image/jpeg') {
  const token = randomUUID();
  await bucket.file(path).save(buffer, {
    contentType,
    metadata: { metadata: { firebaseStorageDownloadTokens: token } },
  });
  // URL as the app sees it (adb reverse maps localhost to this machine).
  return `http://localhost:${STORAGE_HOST.split(':')[1]}/v0/b/${BUCKET}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

async function uploadPhoto(dir, name, srcFile) {
  const src = readFileSync(join(ASCOA, 'Images-App', srcFile));
  const full = await sharp(src).rotate().resize({ width: 1280, withoutEnlargement: true }).jpeg({ quality: 85 }).toBuffer();
  const thumb = await sharp(src).rotate().resize({ width: 400 }).jpeg({ quality: 80 }).toBuffer();
  return {
    photo: await upload(`${dir}/${name}.jpg`, full),
    thumb: await upload(`${dir}/thumb_${name}.jpg`, thumb),
  };
}

async function initialsAvatar(text, bg) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512">
    <rect width="512" height="512" fill="${bg}"/>
    <text x="50%" y="54%" font-family="Segoe UI, Arial" font-size="200" font-weight="600"
      fill="#ffffff" text-anchor="middle" dominant-baseline="middle">${text}</text></svg>`;
  return sharp(Buffer.from(svg)).webp({ quality: 90 }).toBuffer();
}

const ddmmyyyy = (d) =>
  `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`;

// ---------- reference data ----------
const template = JSON.parse(readFileSync(join(APP, 'trash_template.json'), 'utf8'));
const itemIndex = {}; // itemName -> { category display name, weight }
for (const cat of Object.values(template.categories)) {
  for (const [name, w] of Object.entries(cat.items)) itemIndex[name] = { category: cat.name, weight: w };
}

// Typical hauls per environment: [item, min, max]
const HAULS = {
  Saltwater: [
    ['Grocery bags (plastic)', 40, 140], ['Source du Pays bottles (plastic)', 30, 110],
    ['Brasseries bottles (plastic)', 20, 80], ['Beverage sachets/pouches', 30, 120],
    ['Brasseries bottles (glass)', 4, 18], ['Bathing Slippers', 6, 25],
    ['Rope (1 yard/meter = 1 piece)', 10, 40], ['Fishing Nets & Pieces (average piece)', 1, 4],
    ['Food containers (foam)', 10, 40], ['Plastic Pieces', 60, 200], ['Cigarette butts', 30, 150],
    ['Coconut shells (single shell)', 4, 15],
  ],
  Freshwater: [
    ['Grocery bags (plastic)', 50, 160], ['Other bags (plastic)', 20, 60],
    ['Source du Pays bottles (plastic)', 25, 90], ['Beverage sachets/pouches', 40, 120],
    ['Food containers (plastic)', 15, 50], ['Diapers (single)', 4, 16],
    ['Sacks (empty single woven sack)', 3, 12], ['Bathing Slippers', 5, 18],
    ['Other Plastic Bottles (oil, bleach)', 6, 20], ['Plastic Pieces', 50, 160],
  ],
  Land: [
    ['Grocery bags (plastic)', 60, 180], ['Beverage sachets/pouches', 40, 140],
    ['Brasseries bottles (glass)', 6, 24], ['Guinness bottles (glass)', 4, 14],
    ['Beverage cans (Brasseries)', 15, 50], ['Brasseries bottle caps (metal)', 30, 90],
    ['Food wrappers', 40, 120], ['Cups, plates (plastic)', 15, 45],
    ['Cartons (single flattened box)', 3, 12], ['Cigarette butts', 50, 200],
  ],
};

function haul(env) {
  const picks = HAULS[env].filter(() => rand() < 0.75);
  const categories = {};
  let total = 0;
  for (const [name, lo, hi] of picks) {
    const { category, weight } = itemIndex[name];
    const count = between(lo, hi);
    const itemTotal = Math.round(weight * count * 1000) / 1000;
    (categories[category] ??= {})[name] = { count, weightPerItem: weight, totalWeight: itemTotal };
    total += itemTotal;
  }
  return { categories, totalWeight: Math.round(total * 100) / 100 };
}

const SITES = {
  limbeDownBeach: { location: 'Down Beach, Limbe', lat: 4.0118, lng: 9.2078, env: 'Saltwater' },
  mileSix: { location: 'Mile 6 Beach, Limbe', lat: 4.0539, lng: 9.0921, env: 'Saltwater' },
  kribi: { location: 'Plage de Kribi, Kribi', lat: 2.9406, lng: 9.9087, env: 'Saltwater' },
  molyko: { location: 'Molyko, Buea', lat: 4.1527, lng: 9.2905, env: 'Land' },
  bueaTown: { location: 'Buea Town stream, Buea', lat: 4.1558, lng: 9.2397, env: 'Freshwater' },
  bonaberi: { location: 'Wouri riverbank, Bonabéri, Douala', lat: 4.0698, lng: 9.6676, env: 'Freshwater' },
  bonamoussadi: { location: 'Bonamoussadi, Douala', lat: 4.0889, lng: 9.7430, env: 'Land' },
  tiko: { location: 'Tiko market, Tiko', lat: 4.0754, lng: 9.3601, env: 'Land' },
  mutengene: { location: 'Mutengene, Tiko', lat: 4.0913, lng: 9.3133, env: 'Land' },
};

// ---------- people ----------
const PEOPLE = [
  { key: 'amina', first: 'Amina', last: 'Nkeng', city: 'Buea', color: '#419310', demo: true },
  { key: 'jp', first: 'Jean-Paul', last: 'Mbarga', city: 'Douala', color: '#357187' },
  { key: 'grace', first: 'Grace', last: 'Ewane', city: 'Limbe', color: '#B5651D' },
  { key: 'samuel', first: 'Samuel', last: 'Fon', city: 'Bamenda', color: '#6A4C93' },
  { key: 'clarisse', first: 'Clarisse', last: 'Ngo Bassa', city: 'Kribi', color: '#C0392B' },
];

// Amina: one cleanup roughly every week since mid-June (keeps a weekly streak),
// [daysAgo, site, group, people, photo?]
const TODAY = new Date();
TODAY.setHours(10, 0, 0, 0);
const AMINA_CLEANUPS = [
  [1, 'limbeDownBeach', 'ASCOA Volunteers', 34, '7.jpg'],
  [8, 'molyko', 'Molyko Green Team', 18, '5.jpg'],
  [14, 'bueaTown', 'ASCOA Volunteers', 12],
  [21, 'mileSix', 'Limbe Youth Network', 26, '2.webp'],
  [29, 'molyko', 'Molyko Green Team', 15],
  [35, 'limbeDownBeach', 'International Coastal Cleanup 2026', 120, '7.jpg'],
  [42, 'tiko', 'ASCOA Volunteers', 9],
  [49, 'bonaberi', 'Wouri Clean Rivers', 22],
  [56, 'kribi', 'ASCOA Volunteers', 17, '2.webp'],
  [63, 'mutengene', 'Molyko Green Team', 11],
  [70, 'bueaTown', 'ASCOA Volunteers', 8],
  [84, 'limbeDownBeach', 'ASCOA Volunteers', 21],
  [98, 'bonamoussadi', 'Wouri Clean Rivers', 14],
  [112, 'mileSix', 'World Ocean Day 2026', 45, '5.jpg'],
];
const OTHER_CLEANUPS = [
  ['jp', 3, 'bonamoussadi', 'Wouri Clean Rivers', 16, '5.jpg'],
  ['grace', 4, 'mileSix', 'Limbe Youth Network', 28, '2.webp'],
  ['clarisse', 6, 'kribi', 'Kribi Ocean Friends', 19, '7.jpg'],
  ['samuel', 9, 'molyko', 'ASCOA Volunteers', 10],
  ['jp', 12, 'bonaberi', 'Wouri Clean Rivers', 24],
  ['grace', 16, 'limbeDownBeach', 'Limbe Youth Network', 31],
  ['clarisse', 20, 'kribi', 'Kribi Ocean Friends', 12],
];

const HOTSPOTS = [
  ['amina', 2, 'Behind Molyko market, Buea', 4.1509, 9.2889, '5.jpg', 'Plastic bags and sachets piling up near the drain after the rains.'],
  ['amina', 11, 'Down Beach fish landing, Limbe', 4.0109, 9.2063, '7.jpg', 'Fishing nets and bottles washed up along the landing site.'],
  ['amina', 26, 'Buea Town stream crossing', 4.1561, 9.2402, '5.jpg', 'Stream blocked by bottles and food containers.'],
  ['amina', 5, 'Ndokoti junction, Douala', 4.0466, 9.7365, '5.jpg', 'Roadside dumping next to the bus stop.'],
  ['amina', 7, 'Mile 4 roundabout, Limbe', 4.0227, 9.1810, '7.jpg', 'Sachets and cans along the gutter.'],
  ['clarisse', 13, 'Lobé river mouth, Kribi', 2.8792, 9.8966, '2.webp', 'Plastic caught in the rocks at the river mouth.'],
];

// ---------- run ----------
async function main() {
  console.log('Clearing emulators…');
  const [fsHost, authHost] = [process.env.FIRESTORE_EMULATOR_HOST, process.env.FIREBASE_AUTH_EMULATOR_HOST];
  await fetch(`http://${fsHost}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
  await fetch(`http://${authHost}/emulator/v1/projects/${PROJECT}/accounts`, { method: 'DELETE' });
  await bucket.deleteFiles({ force: true });

  console.log('Seeding emulators…');

  await db.doc('app-templates/trash_template').set(template);
  const cities = JSON.parse(readFileSync(join(ASCOA, 'ascoa_web', 'data', 'cities-fallback.json'), 'utf8'));
  await db.doc('config/cities').set({ ...cities, updatedAt: new Date().toISOString() });
  const version = /^version:\s*([\d.]+)/m.exec(readFileSync(join(APP, 'pubspec.yaml'), 'utf8'))[1];
  await db.doc('config/app_version').set({ android: { latest: version }, ios: { latest: version } });

  // People + avatars
  const uids = {};
  for (const p of PEOPLE) {
    const email = p.demo ? DEMO.email : `${p.key}.demo@example.com`;
    const user = await auth.createUser({
      email, password: DEMO.password, emailVerified: true, displayName: `${p.first} ${p.last}`,
    });
    uids[p.key] = user.uid;
    const avatar = await initialsAvatar(`${p.first[0]}${p.last[0]}`, p.color);
    const avatarUrl = await upload(`avatars/${user.uid}/avatar.webp`, avatar, 'image/webp');
    await db.doc(`users/${user.uid}`).set({
      uid: user.uid, email, firstName: p.first, lastName: p.last,
      phoneNumber: '677000000', city: p.city, countryCode: 'CM',
      avatarUrl, thumbUrl: avatarUrl, avatarUpdatedAt: new Date().toISOString(),
      isProfileComplete: true, signUpMethod: 'email', cleanups: [],
      createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-05-02T09:00:00Z')),
      // Mark every achievement as already celebrated so no dialogs pop up mid-capture.
      achievements: Object.fromEntries(
        ['weight_warrior', 'item_hunter', 'cleanup_champion', 'hotspot_scout', 'dedicated_days',
          'streak_master', 'mobilizer', 'explorer', 'cartographer']
          .map((id) => [id, { level: 0, seen: 99, updatedAt: new Date().toISOString() }]),
      ),
    });
  }

  // Cleanups
  const photoCache = {};
  const cleanupPhoto = async (file) =>
    (photoCache[file] ??= await uploadPhoto('cleanups/demo', file.replace(/\W/g, '_'), file));
  const addCleanup = async (owner, daysAgo, siteKey, group, people, photo) => {
    const site = SITES[siteKey];
    const date = new Date(TODAY.getTime() - daysAgo * 86400000);
    const { categories, totalWeight } = haul(site.env);
    const media = photo ? await cleanupPhoto(photo) : null;
    const ref = db.collection('cleanups').doc();
    await ref.set({
      userId: uids[owner],
      createdAt: admin.firestore.Timestamp.fromDate(date),
      basicInfo: {
        peopleCount: people, groupName: group, date: ddmmyyyy(date),
        location: site.location, locationLatitude: site.lat, locationLongitude: site.lng,
      },
      trashCollected: { environment: site.env, categories, totalWeight },
      metadata: {
        notes: null,
        photoUrls: media ? [media.photo] : [],
        thumbUrls: media ? [media.thumb] : [],
      },
      flagged: false,
    });
    await db.doc(`users/${uids[owner]}`).update({ cleanups: admin.firestore.FieldValue.arrayUnion(ref.id) });
    return totalWeight;
  };

  let aminaKg = 0;
  for (const [d, s, g, n, ph] of AMINA_CLEANUPS) aminaKg += await addCleanup('amina', d, s, g, n, ph);
  for (const [o, d, s, g, n, ph] of OTHER_CLEANUPS) await addCleanup(o, d, s, g, n, ph);

  // Hotspots
  for (const [owner, daysAgo, name, lat, lng, file, notes] of HOTSPOTS) {
    const ref = db.collection('plastic_hotspots').doc();
    const media = await uploadPhoto(`hotspots/${ref.id}`, 'photo', file);
    await ref.set({
      userId: uids[owner],
      createdAt: admin.firestore.Timestamp.fromDate(new Date(TODAY.getTime() - daysAgo * 86400000)),
      location: { name, latitude: lat, longitude: lng },
      photoUrls: [media.photo], thumbUrls: [media.thumb], notes, status: 'reported',
    });
  }

  // Home "Highlights" carousel (spotlight/) — ASCOA's own event photos.
  for (const f of ['1.webp', '8.jpeg', '3.webp', '6.jpg', '4.webp']) {
    const buf = await sharp(readFileSync(join(ASCOA, 'Images-App', f))).jpeg({ quality: 85 }).toBuffer();
    await upload(`spotlight/${f.replace(/\W/g, '_')}.jpg`, buf);
  }

  // News: the latest real posts from ascoa-cm.org (what syncPosts mirrors in prod).
  const posts = await (await fetch('https://ascoa-cm.org/wp-json/wp/v2/posts?per_page=6&_embed=wp:featuredmedia')).json();
  let i = 0;
  for (const p of posts) {
    const media = p._embedded?.['wp:featuredmedia']?.[0];
    const src = media?.media_details?.sizes?.medium_large?.source_url ?? media?.source_url;
    let imagePath = null;
    if (src) {
      const buf = Buffer.from(await (await fetch(src)).arrayBuffer());
      imagePath = `posts/${p.id}.jpg`;
      await upload(imagePath, await sharp(buf).resize({ width: 900, withoutEnlargement: true }).jpeg({ quality: 85 }).toBuffer());
    }
    const title = p.title.rendered.replace(/&#8217;/g, '’').replace(/&amp;/g, '&').replace(/&#8211;/g, '–');
    await db.doc(`posts/${p.id}`).set({
      id: p.id, link: p.link, title, imagePath,
      updatedAt: admin.firestore.Timestamp.fromDate(new Date(TODAY.getTime() - i++ * 3600000)),
    });
  }

  console.log(`Done. Demo login: ${DEMO.email} / ${DEMO.password}`);
  console.log(`Amina: ${AMINA_CLEANUPS.length} cleanups, ${aminaKg.toFixed(1)} kg`);
}

await main();
process.exit(0);
