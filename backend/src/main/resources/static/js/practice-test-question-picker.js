/* MVC-R5 Practice Test question picker; keeps the server's newline UUID contract. */
(() => {
  'use strict';
  const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  function enhance(textarea) {
    if (textarea.dataset.questionPickerReady) return;
    textarea.dataset.questionPickerReady = 'true';
    const initial = textarea.value.trim() ? textarea.value.trim().split(/\r?\n/) : [];
    if (initial.some(id => !UUID.test(id.trim()))) return; // Do not lose malformed legacy values.
    const selected = initial.map(id => ({id: id.trim(), label: id.trim()}));
    const parent = textarea.parentElement;
    const box = document.createElement('div');
    box.className = 'border rounded p-3 mt-2';
    const label = document.createElement('label');
    label.className = 'form-label';
    label.textContent = 'Search approved questions';
    const search = document.createElement('input');
    search.type = 'search';
    search.maxLength = 100;
    search.className = 'form-control';
    search.placeholder = 'Enter question title';
    label.appendChild(search);
    const result = document.createElement('select');
    result.className = 'form-select mt-2';
    result.setAttribute('aria-label', 'Approved question revisions');
    const controls = document.createElement('div');
    controls.className = 'd-flex gap-2 mt-2';
    const append = document.createElement('button');
    append.type = 'button'; append.className = 'btn btn-sm btn-outline-primary';
    append.textContent = 'Add question';
    const next = document.createElement('button');
    next.type = 'button'; next.className = 'btn btn-sm btn-outline-secondary';
    next.textContent = 'Next results';
    controls.append(append, next);
    const note = document.createElement('p');
    note.className = 'small text-secondary mt-2';
    note.setAttribute('role', 'status');
    const listing = document.createElement('ol');
    listing.className = 'list-group list-group-numbered mt-3';
    function disabled() { return textarea.disabled; }
    function sync() { textarea.value = selected.map(q => q.id).join('\n'); }
    function render() {
      listing.replaceChildren();
      selected.forEach((q, i) => {
        const li = document.createElement('li');
        li.className = 'list-group-item d-flex justify-content-between align-items-center gap-2';
        const name = document.createElement('span'); name.className = 'text-break';
        name.textContent = q.label;
        const actions = document.createElement('div'); actions.className = 'btn-group btn-group-sm';
        [['Move up', -1], ['Move down', 1], ['Remove', 0]].forEach(([label,delta]) => {
          const button = document.createElement('button');
          button.type = 'button'; button.className = 'btn btn-outline-secondary';
          button.textContent = label; button.disabled = disabled();
          button.addEventListener('click', () => {
            if (delta === 0) selected.splice(i,1);
            else {
              const j = i + delta;
              if (j < 0 || j >= selected.length) return;
              [selected[i], selected[j]] = [selected[j], selected[i]];
            }
            sync(); render();
          });
          actions.appendChild(button);
        });
        li.append(name, actions); listing.appendChild(li);
      });
      search.disabled = disabled(); result.disabled = disabled();
      append.disabled = disabled() || !result.value; next.disabled = disabled() || !next.dataset.available;
    }
    let generation = 0, page = 0;
    async function load(reset) {
      if (reset) page = 0;
      const requestId = ++generation;
      note.textContent = 'Loading approved questions…';
      result.replaceChildren();
      append.disabled = true;
      next.disabled = true;
      try {
        const url = '/admin/content/questions/approved?q=' + encodeURIComponent(search.value.trim()) + '&page=' + page;
        const response = await fetch(url, {credentials:'same-origin', headers:{Accept:'application/json'}});
        if (!response.ok) throw new Error('HTTP ' + response.status);
        const payload = await response.json();
        if (requestId !== generation) return;
        payload.items.forEach(q => {
          const option = document.createElement('option');
          option.value = q.id;
          option.textContent = q.code + ' · rev ' + q.revision + ' — ' + q.title;
          result.appendChild(option);
          const old = selected.find(item => item.id === q.id);
          if (old) old.label = option.textContent;
        });
        next.dataset.available = payload.hasNext ? 'true' : '';
        note.textContent = payload.items.length ? 'Select an exact approved revision.' : 'No approved questions found.';
        render();
      } catch (_) {
        if (requestId === generation) {
          note.textContent = 'Question search unavailable; existing selection is preserved. Retry when online.';
          next.dataset.available = ''; render();
        }
      }
    }
    append.addEventListener('click', () => {
      const option = result.selectedOptions[0];
      if (!option || disabled() || selected.some(q => q.id === option.value)) return;
      selected.push({id:option.value, label:option.textContent});
      sync(); render();
    });
    next.addEventListener('click', () => {page++; load(false);});
    let pending = 0;
    search.addEventListener('input', () => {
      // Invalidate outstanding responses immediately; no remote query on every keystroke.
      ++generation;
      clearTimeout(pending);
      pending = setTimeout(() => load(true), 250);
    });
    box.append(label, result, controls, note, listing);
    textarea.after(box);
    textarea.hidden = true;
    textarea.setAttribute('aria-hidden','true');
    new MutationObserver(render).observe(textarea,{attributes:true,attributeFilter:['disabled']});
    sync(); render(); load(true);
  }
  function init() { document.querySelectorAll('textarea[data-question-picker]').forEach(enhance); }
  document.addEventListener('DOMContentLoaded', init);
  document.body?.addEventListener('htmx:afterSwap', init);
})();
