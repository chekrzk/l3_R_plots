// Static plots are shown by default. webR starts only when the user clicks "Run".
const panels = document.querySelectorAll('.tab-panel');
for (const tab of document.querySelectorAll('.tab')) {
  tab.addEventListener('click', () => {
    for (const t of document.querySelectorAll('.tab')) t.setAttribute('aria-selected', String(t === tab));
    for (const panel of panels) panel.hidden = panel.id !== `panel-${tab.dataset.tab}`;
  });
}

let enginePromise = null;
let ggplotReady = false;
let busy = false;

async function startR() {
  if (!enginePromise) {
    enginePromise = (async () => {
      const { WebR } = await import('https://webr.r-wasm.org/latest/webr.mjs');
      const webR = new WebR();
      await webR.init();
      // Download local copies shipped alongside the site: same data as build.R.
      for (const [file, target] of [['heroes.csv', '/home/web_user/heroes.csv'], ['meta_dataset.txt', '/home/web_user/meta_dataset.txt']]) {
        const response = await fetch(file);
        if (!response.ok) throw new Error(`Не удалось загрузить ${file}: HTTP ${response.status}`);
        await webR.FS.writeFile(target, new Uint8Array(await response.arrayBuffer()));
      }
      await webR.evalRVoid(`
        heroes <- read.csv('/home/web_user/heroes.csv', na.strings = c('-', '-99', 'NA', ''), check.names = TRUE)
        meta <- read.delim('/home/web_user/meta_dataset.txt', check.names = TRUE)
        weight <- na.omit(heroes$Weight)
        poli <- subset(meta, Design == 'Policy Change')
      `);
      return webR;
    })().catch(err => { enginePromise = null; throw err; });
  }
  return enginePromise;
}

for (const plot of document.querySelectorAll('.plot')) {
  const run = plot.querySelector('.run-code');
  if (!run) continue;
  const code = plot.querySelector('.r-code');
  const original = code.value;
  const reset = plot.querySelector('.reset-code');
  const status = plot.querySelector('.run-status');
  const consoleOutput = plot.querySelector('.console-output');
  const canvas = plot.querySelector('.live-canvas');
  const initial = plot.querySelector('.visual img');

  reset.addEventListener('click', () => {
    code.value = original;
    canvas.hidden = true;
    initial.hidden = false;
    consoleOutput.hidden = true;
    status.textContent = 'Исходный график восстановлен.';
  });

  run.addEventListener('click', async () => {
    if (busy) { status.textContent = 'Дождитесь завершения другого вычисления R.'; return; }
    busy = true;
    run.disabled = true;
    status.textContent = 'Загрузка R и подготовка данных (при первом запуске может занять время)...';
    let shelter = null;
    try {
      const webR = await startR();
      if (run.dataset.kind === 'ggplot' && !ggplotReady) {
        status.textContent = 'Установка ggplot2 в браузере (первый запуск)...';
        await webR.installPackages(['ggplot2']);
        await webR.evalRVoid('library(ggplot2)');
        ggplotReady = true;
      }
      status.textContent = 'Выполняется R-код...';
      shelter = await new webR.Shelter();
      const result = await shelter.captureR(code.value, {
        withAutoprint: true,
        captureStreams: true,
        captureGraphics: { width: 850, height: 550, bg: 'white' }
      });
      const output = result.output.map(line => line.data).join('\n').trim();
      consoleOutput.textContent = output;
      consoleOutput.hidden = !output;
      if (result.images.length) {
        const img = result.images.at(-1);
        canvas.width = img.width;
        canvas.height = img.height;
        canvas.getContext('2d').drawImage(img, 0, 0);
        canvas.hidden = false;
        initial.hidden = true;
        status.textContent = 'График построен настоящим R в браузере.';
      } else {
        status.textContent = 'Код выполнен, но график не создан. Вывод см. ниже.';
      }
    } catch (err) {
      status.textContent = `Ошибка: ${err?.message || String(err)}`;
      console.error(err);
    } finally {
      if (shelter) await shelter.purge();
      run.disabled = false;
      busy = false;
    }
  });
}
