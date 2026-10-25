// Carga el catálogo (datos/peliculas.json) en Firestore. Se ejecuta UNA vez,
// desde la carpeta del proyecto, con las reglas temporales publicadas:
//
//   firebase deploy --only firestore:rules --config herramientas/carga/firebase.json
//   node herramientas/cargar_peliculas.mjs
//   firebase deploy --only firestore:rules
//
// Pide el correo y la contraseña de una cuenta de la app (no se guardan en
// ningún archivo) y escribe con la API REST de Firebase. No usa claves
// secretas: la «apiKey» web solo identifica el proyecto.
import { readFileSync } from 'node:fs';
import readline from 'node:readline';

const opciones = readFileSync('lib/firebase_options.dart', 'utf8');
const web = opciones.slice(opciones.indexOf('static const FirebaseOptions web'));
const apiKey = web.match(/apiKey: '([^']+)'/)[1];
const proyecto = web.match(/projectId: '([^']+)'/)[1];
const peliculas = JSON.parse(readFileSync('datos/peliculas.json', 'utf8'));

function preguntar(texto, oculto = false) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout, terminal: true });
  if (oculto) rl._writeToOutput = (s) => rl.output.write(s.startsWith(texto) ? s : '');
  return new Promise((resolver) => rl.question(texto, (r) => { rl.close(); if (oculto) console.log(); resolver(r.trim()); }));
}

const correo = await preguntar('Correo de tu cuenta en la app: ');
const clave = await preguntar('Contraseña (no se muestra): ', true);

const login = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email: correo, password: clave, returnSecureToken: true }),
});
if (!login.ok) {
  console.error('No se pudo iniciar sesión: revisa el correo y la contraseña.');
  process.exit(1);
}
const { idToken } = await login.json();

// Convierte un objeto JS al formato de campos de la API REST de Firestore.
const aCampos = (p) => ({
  titulo: { stringValue: p.titulo },
  anio: { integerValue: String(p.anio) },
  genero: { stringValue: p.genero },
  director: { stringValue: p.director },
  duracion: { integerValue: String(p.duracion) },
  sinopsis: { stringValue: p.sinopsis },
});

let cargadas = 0;
for (const p of peliculas) {
  const url = `https://firestore.googleapis.com/v1/projects/${proyecto}/databases/(default)/documents/peliculas/${p.id}`;
  const r = await fetch(url, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${idToken}` },
    body: JSON.stringify({ fields: aCampos(p) }),
  });
  if (!r.ok) {
    console.error(`Falló «${p.titulo}» (${r.status}). ¿Publicaste las reglas temporales?`);
    process.exit(1);
  }
  cargadas++;
}
console.log(`Listo: ${cargadas} películas cargadas en Firestore (proyecto ${proyecto}).`);
console.log('Ahora publica las reglas definitivas: firebase deploy --only firestore:rules');
