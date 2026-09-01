# Prompt install — tempel ke AI agent

Buka **project app** kamu di Cursor (Agent mode). Tempel blok di bawah. **Kamu tidak perlu jalankan terminal sendiri** — agent yang menjalankan.

Sesuaikan `[bracket]` sekali, lalu kirim.

---

Install **solo-dev-ai-kit** ke project ini. Saya tidak menjalankan perintah terminal sendiri — kamu yang jalankan semuanya.

## Sumber kit

- Clone jika belum ada: `https://github.com/sahibul-nf/solo-dev-ai-kit` → pakai `~/solo-dev-ai-kit` atau `/tmp/solo-dev-ai-kit`
- Atau path yang sudah ada: `[path/to/solo-dev-ai-kit]`

## Project ini

| Setting | Nilai |
|---------|--------|
| **Target** | workspace saat ini (app — **jangan** ubah repo kit) |
| **GitHub repo** | `[owner/repo]` atau auto-detect dari `git remote` |
| **Stack** | `[Next.js / Flutter / …]` → `--app-stack web|mobile|both` (auto: `pubspec.yaml` → mobile) |
| **AI tools** | `[cursor,antigravity]` (disarankan) |
| **Perintah tes CI** | `[npm test / flutter test / pytest]` |
| **Branch** | auto-detect (`dev`→`main` jika `dev` ada; else single branch). Atau `--main-only` |
| **Setup GitHub** | `[ya / tidak]` — label, project board, kolom QA |
| **Max putaran verify** | `[default 3]` — `--verify-max-rounds N`; override per task di chat (*max 2 putaran untuk #12*) |
| **Client reports** | `[ya / tidak]` — label `client-facing` |

## Yang harus kamu lakukan

1. **Prasyarat** — cek `gh` dan `jq`; kalau kurang, beri tahu saya apa yang perlu di-install. Kalau scope `gh` kurang: `gh auth refresh -h github.com -s repo,project,read:project`.
2. **Bootstrap** — jalankan `bootstrap.sh` dari kit. Contoh:

   ```bash
   /path/to/solo-dev-ai-kit/bootstrap.sh \
     --target . \
     --repo OWNER/REPO \
     --tools cursor,antigravity \
     --ci-test "npm test" \
     --run-github-setup
   ```

3. **Jangan timpa** `AGENTS.md` atau `docs/how-to-run.md` custom saya kecuali saya minta `--force`.
4. **Isi** `docs/how-to-run.md` — ganti semua `TBD`; hapus section web/mobile jika tidak dipakai.
5. **Laporkan** output `./scripts/gh-check-ui-tools.sh` (cek saja — jangan install Playwright atau MobAI).
6. **Ringkas** file ter-install, URL board, dan arahkan ke `docs/troubleshooting.md` + `scripts/README.md`.
7. **Smoke test** — triage saja (tanpa code): *"Login redirect loop after token refresh"*. Harapan: issue + acceptance criteria + *mau kerjakan # berapa dulu?*

Jangan implement fitur app. Berhenti setelah install + ringkasan smoke test.

---

## Singkat (kit sudah di disk)

```text
Install solo-dev-ai-kit ke project ini. Jalankan bootstrap.sh dari [path/to/solo-dev-ai-kit] dengan --tools cursor,antigravity --run-github-setup. Isi docs/how-to-run.md. Jangan coding fitur app.
```

## Singkat (clone dari GitHub)

```text
Clone https://github.com/sahibul-nf/solo-dev-ai-kit, bootstrap ke project ini (--tools cursor,antigravity --run-github-setup), isi docs/how-to-run.md, smoke test triage saja. Saya tidak jalankan terminal — kamu yang jalankan.
```
