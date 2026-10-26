// Servidor propio del asistente de IA de «Reseñas de Películas».
//
// Por qué existe: la clave del proveedor de IA (Gemini) es un secreto y NUNCA
// va dentro de la app. Vive solo aquí, en una variable de entorno. Además:
//   - solo atiende a personas con sesión: verifica el token de Firebase;
//   - recibe datos mínimos (títulos, géneros, estrellas y texto de reseñas;
//     nunca correos ni el token en el cuerpo);
//   - registra el tamaño y los nombres de los campos, nunca su contenido.
//
// Dos modos: GEMINI (si existe GEMINI_API_KEY) o REGLAS (sin internet ni
// clave, con respuestas calculadas; sirve de plan B si se agota la cuota).
//
// Encender (desde esta carpeta):  node servidor.js
// Sin dependencias: solo Node.js 18 o superior.

import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';

try {
  process.loadEnvFile?.('.env'); // opcional: copia .env.example como .env
} catch {
  // sin .env: se usan las variables de la terminal
}

const PUERTO = Number(process.env.PORT) || 3000;
const CLAVE = (process.env.GEMINI_API_KEY || '').trim();
const MODELO = (process.env.GEMINI_MODEL || 'gemini-3.5-flash-lite').trim();

// La «apiKey» web de Firebase NO es un secreto: solo identifica el proyecto.
// Se usa para preguntarle a Firebase si el token de la persona es válido.
const opciones = readFileSync(new URL('../lib/firebase_options.dart', import.meta.url), 'utf8');
const web = opciones.slice(opciones.indexOf('static const FirebaseOptions web'));
const FIREBASE_API_KEY = web.match(/apiKey: '([^']+)'/)[1];

const MAX_BYTES = 20_000;

function responder(res, codigo, cuerpo) {
  res.writeHead(codigo, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  });
  res.end(cuerpo === undefined ? '' : JSON.stringify(cuerpo));
}

/** Pregunta a Firebase si el token es válido. Devuelve el uid o null. */
async function verificarToken(cabecera) {
  const token = (cabecera || '').startsWith('Bearer ') ? cabecera.slice(7) : '';
  if (!token) return null;
  try {
    const r = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${FIREBASE_API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ idToken: token }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!r.ok) return null;
    const datos = await r.json();
    return datos.users?.[0]?.localId ?? null;
  } catch {
    return null;
  }
}

// ---------- Modo REGLAS (sin IA) ----------

function resumirConReglas({ pelicula, resenas }) {
  if (!resenas.length) return `«${pelicula.titulo}» todavía no tiene reseñas.`;
  const promedio = resenas.reduce((s, r) => s + r.estrellas, 0) / resenas.length;
  const positivas = resenas.filter((r) => r.estrellas >= 4).length;
  const negativas = resenas.filter((r) => r.estrellas <= 2).length;
  const tono = promedio >= 4 ? 'muy bien valorada' : promedio >= 3 ? 'con opiniones divididas' : 'poco valorada';
  return `«${pelicula.titulo}» tiene ${resenas.length} reseña(s) y un promedio de ${promedio.toFixed(1)} estrellas: está ${tono}. ` +
    `${positivas} opinión(es) positiva(s) y ${negativas} negativa(s).`;
}

// Palabras que la gente usa para pedir cada género (sin tildes, en minúsculas).
const PALABRAS_POR_GENERO = {
  'animación': ['anima', 'dibujo', 'familia', 'ninos', 'infantil'],
  'ciencia ficción': ['ciencia', 'ficcion', 'espacio', 'futur', 'robot', 'matrix'],
  'terror': ['terror', 'miedo', 'susto', 'horror'],
  'comedia': ['comedia', 'risa', 'reir', 'divertid', 'gracios'],
  'romance': ['romance', 'romant', 'amor', 'pareja'],
  'acción': ['accion', 'pelea', 'explosi'],
  'suspenso': ['suspenso', 'thriller', 'misterio', 'intriga'],
  'fantasía': ['fantasia', 'magia', 'magic'],
  'drama': ['drama', 'llorar', 'emotiv', 'conmovedor'],
  'aventura': ['aventura', 'dinosaur'],
  'crimen': ['crimen', 'mafia', 'gangster'],
};

const sinTildes = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();

function recomendarConReglas({ consulta, catalogo, porVer }) {
  const texto = sinTildes(consulta || '');
  const enLista = new Set(porVer.map((p) => p.titulo));
  const generos = [...new Set(catalogo.map((p) => p.genero))];
  let genero = generos.find((g) => texto.includes(sinTildes(g)))
    ?? generos.find((g) => (PALABRAS_POR_GENERO[g] ?? []).some((palabra) => texto.includes(palabra)));
  if (!genero && porVer.length) {
    const cuenta = {};
    for (const p of porVer) cuenta[p.genero] = (cuenta[p.genero] || 0) + 1;
    genero = Object.entries(cuenta).sort((a, b) => b[1] - a[1])[0][0];
  }
  // No se recomienda lo que ya está en su lista ni la película que nombró en la pregunta.
  const candidatas = catalogo
    .filter((p) => !enLista.has(p.titulo) && !texto.includes(sinTildes(p.titulo)))
    .filter((p) => !genero || p.genero === genero)
    .slice(0, 3);
  if (!candidatas.length) return 'No encontré películas nuevas para recomendarte con esos datos. Prueba con otro género.';
  const lista = candidatas.map((p) => `«${p.titulo}» (${p.anio})`).join(', ');
  return genero ? `Si te gusta ${genero}, te recomiendo: ${lista}.` : `Te recomiendo empezar por: ${lista}.`;
}

// ---------- Modo GEMINI ----------

class ErrorProveedor extends Error {
  constructor(codigo, mensaje) {
    super(mensaje);
    this.codigo = codigo;
  }
}

async function preguntarAGemini(instrucciones, datos) {
  let r;
  try {
    r = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${MODELO}:generateContent`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': CLAVE },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: instrucciones }] },
        contents: [{ role: 'user', parts: [{ text: JSON.stringify(datos) }] }],
        generationConfig: { temperature: 0.4, maxOutputTokens: 300 },
      }),
      signal: AbortSignal.timeout(20_000),
    });
  } catch {
    throw new ErrorProveedor(504, 'El servicio de IA no respondió a tiempo. Inténtalo de nuevo.');
  }
  if (r.status === 429) throw new ErrorProveedor(429, 'Se alcanzó el límite gratuito de consultas a la IA. Inténtalo más tarde.');
  if (r.status === 400 || r.status === 401 || r.status === 403) {
    throw new ErrorProveedor(502, 'El servicio de IA rechazó la petición. Revisa la clave GEMINI_API_KEY del servidor.');
  }
  if (!r.ok) throw new ErrorProveedor(502, 'El servicio de IA tuvo un problema. Inténtalo de nuevo.');
  const datosRespuesta = await r.json();
  const texto = datosRespuesta.candidates?.[0]?.content?.parts?.map((p) => p.text).join('').trim();
  if (!texto) throw new ErrorProveedor(502, 'El servicio de IA no devolvió una respuesta. Inténtalo de nuevo.');
  // La app muestra texto plano: se quitan las marcas de Markdown que a veces
  // agrega el modelo (negritas con ** y viñetas con * al inicio de línea).
  return texto.replace(/\*\*(.+?)\*\*/g, '$1').replace(/^\s*[*-]\s+/gm, '• ');
}

const FORMATO = ' Responde en texto plano, sin Markdown (sin asteriscos ni almohadillas); usa «•» para las listas.';

const INSTRUCCIONES = {
  resumen:
    'Eres el asistente de una app de reseñas de películas. Recibes una película y sus reseñas (estrellas de 1 a 5 y texto). ' +
    'Resume en español, en 2 o 3 frases, qué opinan las personas: lo que más gusta, lo que menos y el promedio. ' +
    'Usa solo la información recibida; no inventes datos de la película.',
  recomendacion:
    'Eres el asistente de una app de reseñas de películas. Recibes la pregunta de la persona, el catálogo disponible y su lista «por ver». ' +
    'Recomienda en español hasta 3 películas SOLO del catálogo recibido (no de fuera), explicando en una frase por qué cada una. ' +
    'No recomiendes las que ya están en su lista. Si la pregunta no trata de películas, responde que solo puedes ayudar con el catálogo.',
};

// ---------- Validación de la petición ----------

function validar(cuerpo) {
  if (cuerpo.tipo === 'resumen') {
    if (!cuerpo.pelicula?.titulo || !Array.isArray(cuerpo.resenas)) return 'Faltan la película o sus reseñas.';
    return null;
  }
  if (cuerpo.tipo === 'recomendacion') {
    if (typeof cuerpo.consulta !== 'string' || !cuerpo.consulta.trim()) return 'Escribe una pregunta.';
    if (!Array.isArray(cuerpo.catalogo) || !Array.isArray(cuerpo.porVer)) return 'Faltan el catálogo o la lista.';
    return null;
  }
  return 'Tipo de consulta desconocido.';
}

// ---------- Servidor HTTP ----------

const servidor = createServer(async (req, res) => {
  if (req.method === 'OPTIONS') return responder(res, 204);
  if (req.method !== 'POST' || req.url !== '/asistente') return responder(res, 404, { detail: 'Ruta no encontrada.' });

  let bruto = '';
  for await (const parte of req) {
    bruto += parte;
    if (bruto.length > MAX_BYTES) return responder(res, 413, { detail: 'La consulta es demasiado grande.' });
  }

  const uid = await verificarToken(req.headers.authorization);
  if (!uid) return responder(res, 401, { detail: 'Tu sesión no es válida. Inicia sesión de nuevo.' });

  let cuerpo;
  try {
    cuerpo = JSON.parse(bruto);
  } catch {
    return responder(res, 400, { detail: 'La consulta no es un JSON válido.' });
  }
  const problema = validar(cuerpo);
  if (problema) return responder(res, 422, { detail: problema });

  // Registro: tamaño y nombres de campos. Nunca el contenido, la clave ni el token.
  console.log(`Petición «${cuerpo.tipo}»: ${bruto.length} bytes · campos: ${Object.keys(cuerpo).join(', ')}`);

  try {
    const respuesta = CLAVE
      ? await preguntarAGemini(INSTRUCCIONES[cuerpo.tipo] + FORMATO, cuerpo)
      : cuerpo.tipo === 'resumen'
        ? resumirConReglas(cuerpo)
        : recomendarConReglas(cuerpo);
    responder(res, 200, { respuesta, fuente: CLAVE ? 'gemini' : 'reglas' });
  } catch (e) {
    if (e instanceof ErrorProveedor) return responder(res, e.codigo, { detail: e.message });
    console.error('Error inesperado del servidor:', e.message);
    responder(res, 500, { detail: 'El asistente tuvo un problema inesperado. Inténtalo de nuevo.' });
  }
});

servidor.listen(PUERTO, () => {
  const modo = CLAVE ? `GEMINI, modelo ${MODELO}, clave leída del entorno` : 'REGLAS, sin clave de IA';
  console.log(`Servidor del asistente (modo ${modo}) escuchando en http://localhost:${PUERTO}`);
  console.log(`Desde el emulador Android, la app usa http://10.0.2.2:${PUERTO}`);
});
