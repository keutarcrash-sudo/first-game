const { chromium } = require('playwright'); const fs = require('fs');
(async () => {
  const b = await chromium.launch({ args: ['--use-gl=swiftshader','--enable-webgl','--ignore-gpu-blocklist'] });
  const p = await b.newPage(); p.on('pageerror', e => console.log('ERR', e.message)); p.on('console', m => { if (m.type()==='error') console.log('CERR', m.text()); });
  await p.goto('http://127.0.0.1:8766/baker.html');
  const res = await p.evaluate((fn) => window[fn](), process.argv[3] || 'bakeAll');
  const out = process.argv[2];
  for (const [k, v] of Object.entries(res)) {
    if (typeof v === 'string') fs.writeFileSync(`${out}/${k}.png`, Buffer.from(v.split(',')[1], 'base64'));
    else for (const [a, d] of Object.entries(v)) fs.writeFileSync(`${out}/${k}_${a}.png`, Buffer.from(d.split(',')[1], 'base64'));
  }
  console.log(Object.keys(res)); await b.close();
})();
