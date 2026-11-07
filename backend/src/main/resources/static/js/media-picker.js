(() => {
    const dialog = document.getElementById('mediaPicker');
    if (!dialog) return;
    const grid = dialog.querySelector('[data-media-grid]');
    const status = dialog.querySelector('[data-media-status]');
    const upload = dialog.querySelector('[data-media-upload]');
    let trigger, page = 0, requestId = 0;
    const csrf = () => ({[document.querySelector('meta[name="_csrf_header"]').content]:
        document.querySelector('meta[name="_csrf"]').content});
    async function response(request) {
        const result = await request;
        if (!result.ok || result.redirected) throw new Error('Unable to load media. Check your session and try again.');
        return result;
    }
    async function select(asset) {
        try {
            if (trigger.dataset.mediaTarget) {
                const input = document.getElementById(trigger.dataset.mediaTarget);
                input.value = asset.id;
                const preview = document.querySelector('[data-media-preview-for="' + input.id + '"]');
                preview.src = asset.previewUrl;
                preview.hidden = false;
                document.querySelector('[data-media-label-for="' + input.id + '"]').textContent = 'Image selected';
                input.dispatchEvent(new Event('change', {bubbles:true}));
                dialog.close();
            } else {
                const body = new URLSearchParams({revisionId:trigger.dataset.mediaRevision,
                    role:trigger.dataset.mediaRole, assetId:asset.id});
                const bound = await fetch('/admin/media/bind', {method:'POST', headers:csrf(), body});
                if (!bound.ok || new URL(bound.url).pathname !== '/admin/content/revisions/' + trigger.dataset.mediaRevision + '/edit') {
                    throw new Error('Image could not be linked. Check your session and try again.');
                }
                const section = trigger.closest('[data-image-section]') || trigger.parentElement;
                let selected = section.querySelector('[data-selected-role="' + trigger.dataset.mediaRole + '"]');
                if (!selected) {
                    selected = document.createElement('span');
                    selected.dataset.selectedRole = trigger.dataset.mediaRole;
                    selected.setAttribute('role', 'status');
                    (section.querySelector('[data-image-previews]') || section).append(selected);
                }
                const preview = document.createElement('img');
                preview.src = asset.previewUrl; preview.alt = 'Selected image';
                preview.style.cssText = 'width:64px;height:64px;object-fit:contain;margin-right:8px';
                selected.replaceChildren(preview, document.createTextNode('Image linked to draft.'));
                dialog.close();
            }
        } catch (error) { status.textContent = error.message; }
    }
    function card(asset) {
        const col = document.createElement('div'); col.className = 'col-12 col-sm-6 col-md-4';
        const box = document.createElement('div'); box.className = 'card p-3 h-100';
        const img = document.createElement('img'); img.src = asset.previewUrl; img.alt = 'Library image preview';
        img.style.cssText = 'height:140px;object-fit:contain';
        const caption = document.createElement('p'); caption.className = 'small text-secondary mt-2';
        caption.textContent = asset.mediaType + ' · ' + Math.ceil(asset.sizeBytes / 1024) + ' KB';
        const button = document.createElement('button'); button.type = 'button'; button.className = 'btn btn-primary';
        button.textContent = 'Use this image'; button.addEventListener('click', () => select(asset));
        box.append(img, caption, button); col.append(box); return col;
    }
    async function load() {
        const id = ++requestId;
        status.textContent = 'Loading images…'; grid.replaceChildren();
        try {
            const result = await response(fetch('/admin/media/images?' + new URLSearchParams({role:trigger.dataset.mediaRole, page})));
            const assets = await result.json();
            if (id !== requestId) return;
            grid.replaceChildren(...assets.map(card));
            status.textContent = assets.length ? 'Choose an image from the library.' : 'No images yet. Upload one above.';
            dialog.querySelector('[data-media-prev]').disabled = page === 0;
            dialog.querySelector('[data-media-next]').disabled = assets.length < 24;
        } catch (error) { if (id === requestId) status.textContent = error.message; }
    }
    document.querySelectorAll('[data-media-role]').forEach(button => button.addEventListener('click', () => {
        trigger = button; page = 0; dialog.querySelector('input[type=file]').value = '';
        dialog.showModal(); load();
    }));
    dialog.querySelector('[data-media-close]').addEventListener('click', () => dialog.close());
    dialog.addEventListener('close', () => { ++requestId; trigger?.focus(); });
    dialog.querySelector('[data-media-prev]').addEventListener('click', () => { if (page > 0) { page--; load(); } });
    dialog.querySelector('[data-media-next]').addEventListener('click', () => { page++; load(); });
    upload.addEventListener('click', async () => {
        const file = dialog.querySelector('input[type=file]').files[0];
        if (!file) { status.textContent = 'Choose a file to upload.'; return; }
        const body = new FormData(); body.set('role', trigger.dataset.mediaRole); body.set('file', file);
        upload.disabled = true; status.textContent = 'Uploading…';
        try {
            const result = await response(fetch('/admin/media/images', {method:'POST', headers:csrf(), body}));
            const asset = await result.json();
            page = 0; await load(); status.textContent = 'Image uploaded. Choose it below.';
            // Uploads are newest-first, including reused assets which may be on an older page.
            grid.replaceChildren(card(asset), ...Array.from(grid.children));
        } catch (error) { status.textContent = error.message; }
        finally { upload.disabled = false; }
    });
})();
