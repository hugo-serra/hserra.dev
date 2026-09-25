# CLAUDE.md — hserra.dev

Personal website and blog. Built with Astro, styled with the `@hs/design` design system. Deployed on Vercel.

## Project notes

- **Vault note:** `projects/2026-03-31_personal-websites.md` — routes, status, content plan
- **Infrastructure note:** `projects/2026-06-04_personal-websites-infrastructure.md` — Vercel config, domains, deploy flow
- **Blog spec:** `projects/2026-03-31_blog.md`
- **Resume spec:** `projects/2026-03-31_resume.md`

## Deploy path

Forgejo is the primary repository (`ssh://forgejo@git.home/hserra/hserra.dev.git`). Its push mirror copies every push to GitHub, and Vercel builds from GitHub: pushing to Forgejo `main` deploys production, and any other branch gets a Vercel preview. Push to Forgejo, never to GitHub directly. The site stays on Vercel; it is not served from the homelab (decided 2026-09-25, hserra/hserra.dev#2).

The Vercel build needs no secrets and no access to `git.home`: the design system is vendored (below), so `bun install` fetches only public packages.

## Design system

**All visual decisions come from `@hs/design`.** Before writing any CSS or HTML, read:

- `/Users/hserra/projects/personal/design/PRODUCT.md` — personality, principles, anti-references
- `/Users/hserra/projects/personal/design/DESIGN.md` — tokens, color rules, typography, elevation, do's and don'ts
- `/Users/hserra/projects/personal/design/IMPLEMENTATION.md` — canonical component reference (HTML patterns, modifiers, token table)

The DS is **vendored**, not installed: `src/styles/vendor/hs-design.css` is a committed, single-file copy that `src/styles/base.css` imports. The committed file is the pin, and Vercel builds from it.

- **Change version deliberately:** `scripts/vendor-design.sh <tag>` (needs SSH access to `git.home`, so run it on the Mac), then review the diff and the rendered site, and commit. The file's first line records the source tag and commit.
- **Never edit `src/styles/vendor/hs-design.css` by hand**, and never add `@hs/design` back to `package.json`: Vercel cannot reach `git.home`.
- **Today's vendored version is old** (`5952170`, just after `v0.2.0`). The DS docs above describe the current release, so a class they mention may not exist in the vendored copy yet; check the file before relying on one.

Available components: `button`, `badge`, `field`, `gallery`, `lightbox`, `table`, `alert`, `card`, `empty`, `metric`, `nav`, `post-list`, `prose`, `reading-bar`, `skeleton`, `stat-list`, `theme-toggle`, `tile`, `timeline`, `toast`.

**Never write custom color values when a DS token covers the case.** Use `var(--color-primary)`, `var(--color-ink)`, `var(--color-muted)`, etc.

**Never add a second font family.** Inter + system stack is set by `--font-sans`. Hierarchy is weight contrast only (300 / 400 / 600).

**No decorative shadows, gradients, or tints on the page background.**

## Design rules in brief

- Teal primary (`--color-primary`) belongs on: nav brand, links/active states, metrics, primary buttons
- Teal primary does NOT belong on: body text, headings, decorative elements, error states
- Dark mode via `@media (prefers-color-scheme: dark)` — already in the DS tokens, no extra work needed
- Manual toggle: `data-theme="dark"` on `<html>`, persisted in `localStorage`, bootstrapped before CSS loads
- Mobile-first CSS only. Base styles for phone; `min-width` queries for tablet (640px) and desktop (1024px)
- All interactive elements: minimum 44×44px touch target
- Motion: state changes only (hover, focus, open/close) — no entrance animations

## Tech stack

- **Framework:** Astro (content-first, zero JS by default, MDX for blog posts)
- **Styling:** `@hs/design` CSS — NOT Tailwind (the current codebase has AstroPaper/Tailwind remnants; strip them during the rebuild)
- **Hosting:** Vercel
- **Font:** Inter (loaded via DS or self-hosted)

## Routes

| Route | Component | Notes |
|---|---|---|
| `/` | Home | Intro, skills grouped by layer, links to blog + latest post |
| `/about` | About | Background, experience, education. Uses `.timeline` for work history, `.prose` for narrative |
| `/blog` | Blog index | `.post-list` component. See blog spec note |
| `/blog/[slug]` | Blog post | `.post-header` + `.prose` + `.reading-bar`. MDX |
| `/resume` | Resume | Rendered from `resume.json` at build time. `.timeline` for experience, `.prose` for narrative sections |
| `/contact` | Contact | Contact form + social links |

## Key conventions

### Dark mode bootstrap

Add this inline script in `<head>` **before** the stylesheet, to avoid flash:

```html
<script>
  (function () {
    var t = localStorage.getItem('theme');
    if (t) document.documentElement.setAttribute('data-theme', t);
  })();
</script>
```

### Container pattern

```html
<div class="container">…</div>
```

The DS `.container` class handles centering, max-width (1280px), and fluid `padding-inline: clamp(1rem, 5vw, 2rem)`.

### Nav

```html
<header class="nav">
  <a class="nav-brand" href="/">Hugo Serra</a>
  <div class="nav-right">
    <nav>…links…</nav>
    <button class="theme-btn" id="theme-toggle" aria-label="Switch theme">…</button>
  </div>
</header>
```

`.nav-brand` is teal automatically — the primary brand signal on every page.

### Blog posts

MDX files in `src/content/blog/`. Frontmatter: `title`, `date`, `tags`, `description`, `draft`. Reading time is computed at build time. Use `.post-header` above `.prose` on post pages.

### Resume data

`resume.json` at the project root (JSONResume schema). The `/resume` page reads it at Astro build time — no runtime fetching. Changes to `resume.json` require a redeploy.

## Current state

The codebase is an AstroPaper starter template. The rebuild plan:

1. Strip AstroPaper, Tailwind, and all AstroPaper components
2. Install `@hs/design`
3. Build layouts and pages from scratch using DS components
4. Migrate content (blog posts, resume) from existing files

Do not try to incrementally adapt the existing AstroPaper styles — rip and replace.
