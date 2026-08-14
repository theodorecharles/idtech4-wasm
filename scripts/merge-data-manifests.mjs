import fs from 'node:fs';

const [doomPath, quakePath, outputPath] = process.argv.slice(2);
if (!doomPath || !quakePath || !outputPath) {
  throw new Error('usage: merge-data-manifests.mjs DOOM_JSON QUAKE_JSON OUTPUT_JSON');
}

const doom = JSON.parse(fs.readFileSync(doomPath, 'utf8'));
const quake = JSON.parse(fs.readFileSync(quakePath, 'utf8'));
const variants = {};
for (const key of ['doom3', 'doom3-mp', 'roe']) {
  variants[key] = { namespace: doom.namespace, version: doom.version, files: doom.variants[key].files };
}
for (const key of ['quake4', 'quake4-mp']) {
  variants[key] = { namespace: quake.namespace, version: quake.version, files: quake.variants[key].files };
}

fs.writeFileSync(outputPath, `${JSON.stringify({ variants }, null, 2)}\n`);

