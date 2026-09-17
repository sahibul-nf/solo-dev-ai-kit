# Uninstall workflow kit — tempel ke AI agent

Hapus **solo-dev-ai-kit** dari **project app** ini (file lokal saja). **Agent yang jalankan terminal** — bukan kamu.

**TIDAK menghapus:** GitHub Issues, Project board, labels, PR, atau kode fitur app.

---

Uninstall **solo-dev-ai-kit** dari project ini. Saya tidak menjalankan terminal sendiri — kamu yang jalankan.

## Sebelum menghapus

1. Pastikan ini **project app** (bukan repo kit).
2. **Dry-run** dulu:

```bash
/path/to/solo-dev-ai-kit/uninstall-workflow-kit.sh --target . --dry-run
```

3. Tampilkan daftar file yang akan dihapus.

## Uninstall

```bash
/path/to/solo-dev-ai-kit/uninstall-workflow-kit.sh --target .
```

Default:

- Hapus file kit (`.workflow-kit*`, `scripts/gh-*.sh`, cursor rules/commands, docs workflow).
- **Tetap** `docs/how-to-run.md`.
- Isi project-specific dari `AGENTS.md` → `docs/project-guidelines.md`, lalu hapus `AGENTS.md`.
- **Tidak** mengubah board/issues/labels GitHub.

Pakai `--keep-agents` hanya jika saya minta `AGENTS.md` tidak disentuh.

## Setelah uninstall

1. Tampilkan `git diff --stat`.
2. Konfirmasi GitHub Project/issues **tidak** diubah.
3. Ingatkan saya reload Cursor.
4. Jangan ubah kode fitur app.

## Singkat

```text
Dry-run uninstall-workflow-kit.sh (--target .), lalu apply. Keep how-to-run.md; simpan project-specific AGENTS ke docs/project-guidelines.md. Jangan ubah board GitHub. Tampilkan git diff.
```
