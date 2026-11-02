# IMG-UI.1 — Content Cover Production UI Hardening

## Status

Implementation slice for optional content cover rendering on top of the existing
manifest, asset download and `AssetResolver` production path.

## Audit result

The production foundation already existed before IMG-UI.1:

```text
PackContentManifest.contentAssets
        ↓
role = coverImage
        ↓
ContentVisualPolicy
        ↓
ManifestAssetDescriptor
        ↓
AssetCatalogRepository
        ↓
AssetResolver
        ↓
verified local file
```

`ContentVisualPolicy` already freezes the preview-safe role `coverImage`, allows
only PNG/JPEG/WebP and rejects ambiguous cover bindings. `AssetResolver` already
provides verified local bytes for immutable published assets.

The missing production link was presentation: catalogue members, Content Detail
and Continue Learning did not consume that cover path. A second gap existed in
the learner API contract: Flutter supports manifest schema version 2 while the
OpenAPI document still declared schema version 1 only; WebP was also omitted
from the media response types.

## Production flow

IMG-UI.1 adds one narrow adapter instead of duplicating manifest logic:

```text
ContentCoverResolver
        ↓
AssetResolver.resolveImageContent
        ↓
ContentCover
        ├── Catalogue content member card
        ├── Content Detail hero
        └── Continue Learning thumbnail
```

`ContentCoverResolver` always resolves the exact displayed content identity and
revision with role `coverImage`. It delegates CURRENT membership, exact-revision
binding, download, checksum and local-file verification to `AssetResolver`.

## Availability semantics

A content cover is optional presentation enrichment. The following are valid
learner-visible outcomes:

| Condition | UI result |
| --- | --- |
| No `coverImage` binding | no image; layout collapses |
| Cover not available offline and delivery cannot complete | no image; layout collapses |
| Non-image media bound as cover | no image; layout collapses |
| Unsupported image type such as GIF/SVG | no image; layout collapses |
| Local file exists but Flutter cannot decode it | no image; layout collapses |
| Verified PNG/JPEG/WebP decodes successfully | render cover |

No placeholder, broken-image icon, progress indicator or fixed image slot is
reserved by `ContentCover`. Loading also occupies zero image space. This keeps
content usable and prevents visual metadata from becoming a functional
dependency.

This fail-soft rule is intentionally narrower than manifest validation. Invalid
publication metadata must still fail closed at publication/manifest boundaries.
Once otherwise valid content reaches presentation, inability to show its
optional cover must not block learning.

## Exact-revision rule

The cover is bound to:

```text
(contentCode, contentType, contentRevision, role=coverImage)
```

The UI must never resolve a cover by content code alone and must never silently
reuse an image from another revision. Continue Learning therefore carries the
exact content identity and revision only when its decision targets content.
Practice-test, collection and browse decisions do not invent a cover.

## Surface rules

### Catalogue member card

Content members may render a full-width cover above the existing member text.
Practice-test members are unchanged. If the cover is unavailable, the member
card reduces to the original text-only layout.

### Content Detail

Content Detail may render a hero cover above `ContentDetailPanel`. If unavailable,
`ContentDetailPanel` immediately occupies the available layout; no hero height is
reserved.

### Continue Learning

Only decisions that point to one exact content revision expose cover identity to
the Home card. Other decision kinds remain text-only. Missing/corrupt covers do
not change the continue-learning decision or destination.

## Accessibility

IMG-UI.1 treats the cover as decorative preview media. It must not carry unique
learning information required to understand or complete the content. Therefore
`ContentCover` is excluded from semantics unless a caller supplies an explicit
semantic label.

If future pedagogical images carry information, they require a separate
localized accessibility-text contract; that is not inferred from a filename,
content code or English title.

## Security and access

A cover does not introduce a direct storage URL. Flutter continues to resolve
published asset IDs through Backend and the existing verified asset pipeline.
`deliveryKey` remains storage metadata only.

Access control is inherited from the owning content/collection. IMG-UI.1 does
not create a separate monetization entitlement or image-specific bypass.

## Qualification

Required automated evidence:

```text
Q01  no cover binding -> null resolver result
Q02  missing verified local file -> null resolver result
Q03  supported image -> exact verified ResolvedAsset
Q04  audio/non-image binding -> fail-soft null
Q05  unsupported image media -> fail-soft null
Q06  missing cover widget -> zero layout space
Q07  corrupt image bytes -> zero layout space, no placeholder
Q08  valid image bytes -> requested cover dimensions render
Q09  catalogue content member integrates ContentCover
Q10  Content Detail integrates ContentCover hero
Q11  Continue Learning content target carries exact revision and integrates thumbnail
Q12  format + analyze + full Flutter test suite green on one exact SHA
```

## Non-goals

IMG-UI.1 does not add image authoring, image search/generation, per-image captions,
image galleries, pedagogical diagrams, remote image URLs, new account data or a
new asset persistence model. Those require separate product/contract decisions.
