/* Progressive enhancement of MVC textarea wire formats; backend remains authoritative. */
(() => {
  'use strict';
  const formats = {
    examples: [{name: 'Example'}],
    keyPoints: [{name: 'Key point'}],
    sections: [{name: 'Heading'}, {name: 'Text'}],
    segments: [{name: 'Start ms', numeric: true}, {name: 'End ms', numeric: true}, {name: 'Text'}],
    options: [{name: 'Key'}, {name: 'Correct', boolean: true}, {name: 'Answer'}]
  };
  const escapeRequired = value => value.includes('|') || value.includes('\n') || value.includes('\r');
  function attach(textarea) {
    const spec = formats[textarea.dataset.structured];
    if (!spec || textarea.dataset.enhanced) return;
    textarea.dataset.enhanced = 'true';
    const original = textarea.value;
    const entries = original ? original.split(/\r?\n/) : [];
    // Preserve malformed legacy data in the native textarea, never silently modify it.
    if (entries.some(line => line.split('|').length !== spec.length)) return;
    const parent = textarea.parentElement;
    const frame = document.createElement('div');
    frame.className = 'border rounded p-3 mt-2 mb-2';
    const rows = document.createElement('div');
    rows.className = 'd-grid gap-2';
    const message = document.createElement('div');
    message.className = 'small text-danger mt-2';
    message.setAttribute('role', 'alert');
    const add = document.createElement('button');
    add.type = 'button';
    add.className = 'btn btn-sm btn-outline-primary mt-2';
    add.textContent = '+ Add row';
    const controls = [];
    function sync() {
      const values = [];
      let invalid = false;
      for (const row of rows.children) {
        const parts = [...row.querySelectorAll('[data-structured-value]')].map(input => {
          if (input.type === 'checkbox') return String(input.checked);
          const value = input.value.trim();
          if (escapeRequired(value)) invalid = true;
          return value;
        });
        values.push(parts.join('|'));
      }
      message.textContent = invalid ? 'Pipe characters and line breaks are not supported in structured fields.' : '';
      textarea.setCustomValidity(invalid ? 'Invalid structured value' : '');
      if (!invalid) textarea.value = values.join('\n');
    }
    function makeRow(parts) {
      const line = document.createElement('div');
      line.className = 'row g-2 align-items-end';
      spec.forEach((field, i) => {
        const col = document.createElement('div');
        col.className = 'col-12 col-md';
        const label = document.createElement('label');
        label.className = 'form-label small';
        label.textContent = field.name;
        const input = document.createElement('input');
        input.dataset.structuredValue = 'true';
        input.className = 'form-control form-control-sm';
        input.disabled = textarea.disabled;
        if (field.boolean) {
          input.type = 'checkbox';
          input.className = 'form-check-input';
          input.checked = parts[i] === 'true';
        } else {
          input.type = field.numeric ? 'number' : 'text';
          input.value = parts[i] ?? '';
          if (field.numeric) { input.min = '0'; input.step = '1'; }
        }
        const id = 'structured-' + textarea.id + '-' + controls.length;
        input.id = id;
        label.htmlFor = id;
        controls.push(input);
        input.addEventListener('input', sync);
        input.addEventListener('change', sync);
        col.append(label, input);
        line.appendChild(col);
      });
      const actions = document.createElement('div');
      actions.className = 'col-auto d-flex gap-1';
      [['↑', -1], ['↓', 1], ['Remove', 0]].forEach(([name, delta]) => {
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'btn btn-sm btn-outline-secondary';
        btn.textContent = name;
        btn.disabled = textarea.disabled;
        btn.setAttribute('aria-label', name + ' row');
        btn.addEventListener('click', () => {
          if (delta === 0) line.remove();
          else if (delta < 0 && line.previousElementSibling) rows.insertBefore(line, line.previousElementSibling);
          else if (delta > 0 && line.nextElementSibling) rows.insertBefore(line.nextElementSibling, line);
          sync();
        });
        actions.appendChild(btn);
      });
      line.appendChild(actions);
      rows.appendChild(line);
    }
    entries.forEach(entry => makeRow(entry.split('|')));
    add.disabled = textarea.disabled;
    add.addEventListener('click', () => { makeRow([]); sync(); });
    frame.append(rows, add, message);
    textarea.hidden = true;
    textarea.setAttribute('aria-hidden', 'true');
    parent.insertBefore(frame, textarea.nextSibling);
    const form = textarea.closest('form');
    form?.addEventListener('submit', event => {
      sync();
      if (!textarea.checkValidity()) { event.preventDefault(); textarea.reportValidity(); }
    });
    const observer = new MutationObserver(() => {
      const disabled = textarea.disabled;
      add.disabled = disabled;
      controls.forEach(input => { input.disabled = disabled; });
      rows.querySelectorAll('button').forEach(button => { button.disabled = disabled; });
    });
    observer.observe(textarea, {attributes: true, attributeFilter: ['disabled']});
    sync();
  }
  function initialize() { document.querySelectorAll('textarea[data-structured]').forEach(attach); }
  document.addEventListener('DOMContentLoaded', initialize);
  document.body?.addEventListener('htmx:afterSwap', initialize);
})();
