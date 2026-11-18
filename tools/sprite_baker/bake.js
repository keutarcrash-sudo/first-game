// Fabrique d'images : rend les modeles 3D (recipes.json) en planches PNG + sheet.json.
// Usage : node bake.js [id ...]   (sans argument : tous les elements)
const http = require("http");
const fs = require("fs");
const path = require("path");
const { chromium } = require("playwright");

const ROOT = path.resolve(__dirname, "..", "..");
const MODELS = path.join(ROOT, "assets", "models", "source");
const OUT = path.join(ROOT, "assets", "sprites");

const ROUTES = [
  ["/three/", path.join(__dirname, "node_modules", "three")],
  ["/models/", MODELS],
];

function serve() {
  const server = http.createServer((req, res) => {
    const url = decodeURIComponent(req.url.split("?")[0]);
    let file = null;
    if (url === "/page.html") file = path.join(__dirname, "page.html");
    for (const [prefix, dir] of ROUTES) {
      if (url.startsWith(prefix)) file = path.join(dir, url.slice(prefix.length));
    }
    if (!file || !fs.existsSync(file) || !fs.statSync(file).isFile()) { res.writeHead(404); res.end(); return; }
    const type = { ".html": "text/html", ".js": "text/javascript", ".png": "image/png", ".glb": "model/gltf-binary" }[path.extname(file)] || "application/octet-stream";
    res.writeHead(200, { "Content-Type": type });
    fs.createReadStream(file).pipe(res);
  });
  return new Promise((ok) => server.listen(0, "127.0.0.1", () => ok(server)));
}

(async () => {
  const recipes = JSON.parse(fs.readFileSync(path.join(__dirname, "recipes.json"), "utf8"));
  const wanted = process.argv.slice(2);
  const ids = wanted.length ? wanted : Object.keys(recipes.items);
  const server = await serve();
  const browser = await chromium.launch({ args: ["--use-gl=swiftshader", "--enable-webgl", "--ignore-gpu-blocklist"] });
  const page = await browser.newPage();
  page.on("pageerror", (e) => console.log("PAGE ERROR", e.message));
  page.on("console", (m) => { if (m.type() === "error") console.log("PAGE CONSOLE", m.text()); });
  await page.goto(`http://127.0.0.1:${server.address().port}/page.html`);
  const common = { cell: recipes.cell, anchor: recipes.anchor, pitch_degrees: recipes.pitch_degrees, outline_thickness: recipes.outline_thickness, directions: recipes.directions, kenney_palettes: recipes.kenney_palettes };
  let failed = false;
  for (const id of ids) {
    const item = recipes.items[id];
    if (!item) { console.log("recette inconnue : " + id); failed = true; continue; }
    const res = await page.evaluate(([it, c]) => window.bakeItem(it, c), [item, common]);
    const dir = path.join(OUT, id);
    fs.mkdirSync(dir, { recursive: true });
    const sheet = { cell: recipes.cell, anchor: recipes.anchor, directions: item.directions || recipes.directions, animations: {} };
    for (const [name, a] of Object.entries(res)) {
      fs.writeFileSync(path.join(dir, name + ".png"), Buffer.from(a.png.split(",")[1], "base64"));
      sheet.animations[name] = { file: name + ".png", frames: a.frames, fps: recipes.fps, loop: a.loop };
      if (a.shifted > 0) console.log(`info ${id}/${name} : ${a.shifted} images decalees pour rester dans la case`);
      if (a.clipped > 0) { console.log(`ATTENTION ${id}/${name} : ${a.clipped} pixels opaques touchent le bord de la case`); failed = true; }
    }
    fs.writeFileSync(path.join(dir, "sheet.json"), JSON.stringify(sheet, null, "\t") + "\n");
    console.log("ok " + id + " : " + Object.keys(res).join(", "));
  }
  await browser.close(); server.close();
  process.exit(failed ? 1 : 0);
})();
