// Original, passive sprite data shared with the app. This preview never launches a shell.
const container = document.querySelector('#companion-previews');
if (container) {
  try {
    const response = await fetch('mascots.json');
    if (!response.ok) throw new Error('Missing catalog');
    const catalog = await response.json();
    const reduced = matchMedia('(prefers-reduced-motion: reduce)');
    const motion = document.querySelector('#companion-motion');
    const pause = document.querySelector('#companion-pause');
    let paused = false;
    let visible = false;
    let tick = 0;
    let timer;
    const cards = ['wisp', 'moss', 'rover'].map((id, index) => {
      const card = document.createElement('div');
      card.className = 'companion-preview';
      const label = document.createElement('label');
      label.htmlFor = `companion-${index}`;
      label.textContent = `TERMINAL 0${index + 1} · ILLUSTRATION`;
      const select = document.createElement('select');
      select.id = label.htmlFor;
      select.setAttribute('aria-label', `Companion for terminal ${index + 1} preview`);
      for (const sprite of catalog.mascots) select.add(new Option(sprite.name, sprite.id));
      select.add(new Option('Off', 'none'));
      select.value = id;
      const canvas = document.createElement('canvas');
      canvas.width = canvas.height = 144;
      canvas.setAttribute('aria-hidden', 'true');
      const description = document.createElement('p');
      const context = canvas.getContext('2d');
      const draw = () => {
        context.clearRect(0, 0, 144, 144);
        const sprite = catalog.mascots.find(item => item.id === select.value);
        description.textContent = sprite?.description || 'A little extra space. Choose a character to bring it back.';
        if (!sprite) return;
        const frame = sprite.states[motion.value][reduced.matches ? 0 : tick % 12];
        frame.forEach((row, y) => [...row].forEach((pixel, x) => {
          if (pixel === '.') return;
          context.fillStyle = sprite.colors[pixel];
          context.fillRect(x * 6, y * 6, 6, 6);
        }));
      };
      select.addEventListener('change', draw);
      card.append(label, select, canvas, description);
      return { card, draw };
    });
    container.replaceChildren(...cards.map(item => item.card));
    const draw = () => cards.forEach(item => item.draw());
    const sync = () => {
      clearInterval(timer);
      draw();
      if (!paused && !reduced.matches && visible && !document.hidden) {
        timer = setInterval(() => { tick++; draw(); }, 125);
      }
    };
    pause.addEventListener('click', () => {
      paused = !paused;
      pause.textContent = paused ? 'Resume animation' : 'Pause animation';
      pause.setAttribute('aria-pressed', String(paused));
      sync();
    });
    motion.addEventListener('change', () => { tick = 0; draw(); });
    reduced.addEventListener('change', sync);
    document.addEventListener('visibilitychange', sync);
    new IntersectionObserver(entries => {
      visible = entries[0].isIntersecting;
      sync();
    }).observe(container);
    draw();
  } catch (error) {
    const message = document.createElement('p');
    message.textContent = 'The companion preview could not load. All twelve characters are available in the native app gallery.';
    container.replaceChildren(message);
    console.error(error);
  }
}
