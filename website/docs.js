import { guides } from './guides.js';
const params = new URL(location.href).searchParams;
const requested = params.get('guide') || 'overview';
const current = guides.find(g => g.id === requested);
const article = document.querySelector('#guide');
if (current) {
  // Only repository-authored HTML is rendered. URL/search input is never inserted as HTML.
  article.innerHTML = current.body;
  document.title = `${current.title} — Specter handbook`;
} else {
  article.replaceChildren();
  const title = document.createElement('h1');
  title.textContent = 'That chapter isn’t here.';
  const link = document.createElement('a');
  link.href = 'docs.html';
  link.textContent = 'Return to the handbook →';
  article.append(title, link);
}
const textContent = html => {
  const document = new DOMParser().parseFromString(html, 'text/html');
  return document.body.textContent || '';
};
const searchable = guides.map(g => ({...g, text: textContent(g.body).toLowerCase()}));
function renderNavigation() {
  const query = document.querySelector('#docs-search').value.trim().toLowerCase();
  const result = searchable.filter(g => `${g.title.toLowerCase()} ${g.text}`.includes(query));
  document.querySelector('#docs-nav').replaceChildren(...result.map(g => {
    const a = document.createElement('a');
    a.href = `docs.html?guide=${g.id}`;
    a.textContent = g.title;
    if (current?.id === g.id) a.setAttribute('aria-current', 'page');
    return a;
  }));
  document.querySelector('#docs-count').textContent = query ? `${result.length} matching chapters` : '';
}
document.querySelector('#docs-search').addEventListener('input', renderNavigation);
renderNavigation();
if (current) {
  const index = guides.indexOf(current);
  [guides[index - 1], guides[index + 1]].forEach((g, direction) => {
    if (!g) return;
    const a = document.createElement('a');
    a.href = `docs.html?guide=${g.id}`;
    a.textContent = direction ? `${g.title} →` : `← ${g.title}`;
    document.querySelector('#doc-footer').append(a);
  });
}
