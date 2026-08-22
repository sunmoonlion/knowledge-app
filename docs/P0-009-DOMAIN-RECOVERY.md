# Knowledge P0-009 domain recovery

- Freeze tag: `p0-009a-pre-20260729`
- Scope: the parent repository and all four Knowledge component repositories
- Purpose: recover or compare the complete pre-migration Admin/Web source.

The freeze tag is the only authoritative pre-migration archive. Do not copy old
source trees, `.env*` files, generated Prisma clients, binaries, build output, or
dependency directories into the post-migration repositories.

Inspect a historical file without restoring it:

```bash
git -C /home/zymun/master/knowledge-app/knowledge-admin-frontend \
  show p0-009a-pre-20260729:app/src/example.ts
```

Create an isolated recovery worktree:

```bash
git -C /home/zymun/master/knowledge-app/knowledge-admin-frontend \
  worktree add /tmp/knowledge-admin-frontend-pre-p0-009 \
  p0-009a-pre-20260729
```

The retained ingestion and retrieval implementation lives in the normal
post-migration source tree and must be covered by its source, contract, image,
and pair gates.
