const $ = (selector) => document.querySelector(selector);
const sessionLabels = ['studio', 'server', 'tests', 'scripts', 'docs', 'build', 'sandbox', 'assets', 'notes', 'tools', 'review', 'scratch'];
if ($('#session-grid')) {
  sessionLabels.forEach((name, i) => {
    const tile = document.createElement('div');
    tile.className = 'session-tile';
    const label = document.createElement('span');
    label.textContent = `${String(i + 1).padStart(2, '0')} / ${name}`;
    const prompt = document.createElement('b');
    prompt.textContent = '❯ ';
    tile.append(label, prompt, document.createTextNode(`~/${name}`));
    $('#session-grid').append(tile);
  });
}
function preview(theme) {
  const el = document.createElement('span');
  el.className = 'theme-preview';
  el.style.setProperty('--bg', theme.background);
  el.style.setProperty('--fg', theme.foreground);
  const path = document.createElement('span');
  path.textContent = '~/studio  ·  main';
  path.style.opacity = '.7';
  const command = document.createElement('span');
  command.className = 'theme-prompt';
  command.textContent = '❯ swift build';
  const output = document.createElement('span');
  output.textContent = 'Build complete.';
  output.style.color = theme.palette[2];
  const palette = document.createElement('span');
  palette.className = 'palette';
  palette.setAttribute('aria-hidden', 'true');
  theme.palette.slice(0, 8).forEach(color => {
    const swatch = document.createElement('i');
    swatch.style.background = color;
    palette.append(swatch);
  });
  el.append(path, command, output, palette);
  el.setAttribute('aria-hidden', 'true');
  return el;
}
function card(theme, select) {
  const button = document.createElement('button');
  button.className = 'theme-card';
  button.type = 'button';
  button.dataset.theme = theme.id;
  button.setAttribute('aria-label', `Preview ${theme.name}, ${theme.isDark ? 'dark' : 'light'} theme`);
  button.setAttribute('aria-pressed', 'false');
  const caption = document.createElement('span');
  caption.className = 'theme-caption';
  const name = document.createElement('span');
  name.textContent = theme.name;
  const mode = document.createElement('small');
  mode.textContent = theme.isDark ? 'DARK ↗' : 'LIGHT ↗';
  caption.append(name, mode);
  button.append(preview(theme), caption);
  button.addEventListener('click', () => select(theme));
  return button;
}
function markSelected(theme) {
  document.querySelectorAll('[data-theme]').forEach(el => el.setAttribute('aria-pressed', String(el.dataset.theme === theme.id)));
}
try {
  const response = await fetch('themes.json');
  if (!response.ok) throw new Error('The theme catalog could not be loaded.');
  const themes = await response.json();
  if ($('#featured-themes')) {
    const choose = theme => {
      const hero = $('#hero-terminal');
      hero.style.setProperty('--terminal-bg', theme.background);
      hero.style.setProperty('--terminal-fg', theme.foreground);
      hero.style.setProperty('--terminal-accent', theme.palette[2]);
      hero.style.setProperty('--terminal-cursor', theme.cursor);
      $('#hero-theme-name').textContent = theme.name;
      markSelected(theme);
    };
    ['specter-night', 'alpine-dawn', 'fig-nocturne'].forEach(id => {
      const theme = themes.find(item => item.id === id);
      $('#featured-themes').append(card(theme, choose));
    });
    choose(themes[0]);
  }
  if ($('#theme-catalog')) {
    let selected = themes.find(t => t.id === new URL(location.href).searchParams.get('theme')) || themes[0];
    let page = 0;
    const pageSize = 24;
    const choose = theme => {
      selected = theme;
      $('#selected-name').textContent = theme.name;
      $('#download-theme').href = `themes/${theme.id}.json`;
      $('#download-theme').download = `${theme.id}.json`;
      $('#selected-preview').replaceChildren(preview(theme));
      const url = new URL(location.href);
      url.searchParams.set('theme', theme.id);
      history.replaceState(null, '', url);
      markSelected(theme);
    };
    const render = () => {
      const query = $('#theme-search').value.trim().toLowerCase();
      const mode = $('#appearance').value;
      const result = themes.filter(t => t.name.toLowerCase().includes(query) && (mode === 'all' || t.isDark === (mode === 'dark')));
      const pages = Math.max(1, Math.ceil(result.length / pageSize));
      page = Math.max(0, Math.min(page, pages - 1));
      const catalog = $('#theme-catalog');
      catalog.replaceChildren(...result.slice(page * pageSize, (page + 1) * pageSize).map(t => card(t, choose)));
      if (!result.length) {
        const empty = document.createElement('p');
        empty.className = 'empty';
        empty.textContent = 'No themes found. Try another name or appearance.';
        catalog.append(empty);
      }
      $('#theme-count').textContent = `${result.length} themes`;
      $('#page-status').textContent = `Page ${page + 1} of ${pages}`;
      $('#previous-page').disabled = page === 0;
      $('#next-page').disabled = page >= pages - 1;
      markSelected(selected);
    };
    $('#theme-filters').addEventListener('submit', event => event.preventDefault());
    ['#theme-search', '#appearance'].forEach(id => $(id).addEventListener('input', () => { page = 0; render(); }));
    $('#previous-page').addEventListener('click', () => { page--; render(); });
    $('#next-page').addEventListener('click', () => { page++; render(); });
    choose(selected);
    render();
  }
} catch (error) {
  const target = $('#theme-catalog') || $('#featured-themes');
  if (target) {
    const message = document.createElement('p');
    message.setAttribute('role', 'alert');
    message.textContent = 'Themes could not load. Please reload the page. The full collection is also available in the app.';
    target.replaceChildren(message);
  }
  console.error(error);
}
