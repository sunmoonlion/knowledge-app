# Knowledge Ingestion Worker Task

Status: M1 mock worker implemented; M2 RAGFlow adapter implemented behind config

## Objective

Turn the deployed ingestion API from a pure accepted-job endpoint into an executable
state machine:

```text
accepted -> running -> succeeded / failed
```

M1 proved the worker boundary, status history, retry surface, and deployment path.
M2 adds a real RAGFlow HTTP adapter, but keeps mock mode when RAGFlow credentials
are not configured.

## M1 Scope

- `POST /api/knowledge/ingestions` creates or idempotently returns a job.
- When Celery is configured, accepted jobs are dispatched to
  `app.tasks.process_knowledge_ingestion`.
- `POST /api/knowledge/ingestions/{ingestion_id}/dispatch` exists for manual smoke
  and local fallback.
- The mock worker updates:
  - `accepted -> running`
  - `running -> succeeded`
  - `knowledge_document_id=mock-knowledge-doc:{job_id}`
  - `status_history[]` with processor metadata
- Terminal jobs are idempotent: dispatching `succeeded/failed` returns the existing job.

## Explicit Non-Scope

- No direct RAGFlow database or private API calls.
- No retrieval-quality validation against RAGFlow yet.
- No cross-engine abstraction beyond the current RAGFlow adapter.

## M2 RAGFlow Adapter

When both `RAGFLOW_API_BASE` and `RAGFLOW_API_KEY` are configured, the worker runs:

```text
artifact refs -> fetch content -> ensure dataset -> upload document -> parse -> poll -> succeeded/failed
```

Supported artifact inputs:

- `metadata.text` / `metadata.content` / `metadata.markdown` inline text.
- `source_artifact_refs[].uri` with `http(s)://`.
- `source_artifact_refs[].uri` with `data:`.
- `source_artifact_refs[].uri` with `s3://bucket/key`.
- `source_artifact_refs[].bucket` + `object_key`.

The adapter uses RAGFlow public HTTP API:

- `GET /api/v1/datasets`
- `POST /api/v1/datasets`
- `POST /api/v1/datasets/{dataset_id}/documents`
- `POST /api/v1/datasets/{dataset_id}/chunks`
- `GET /api/v1/datasets/{dataset_id}/documents/{document_id}`

If RAGFlow is not configured, the worker keeps the M1 mock behavior and records
`mode=mock`, `ragflow=deferred`.
- No retrieval validation against RAGFlow.

## Acceptance

- Unit tests pass for ingestion contract, asyncpg URL normalization, mock metadata,
  RAGFlow metadata, artifact resolution, S3 signing, and RAGFlow HTTP call flow.
- Deployed API accepts info-app standard payload.
- Deployed worker can advance a job to `succeeded`.
- info-app distribution can record a successful response from knowledge-app.

## Next Task

Deploy an image containing the adapter, configure `RAGFLOW_API_KEY`, and run a
real RAGFlow smoke test against the in-cluster `ragflow-sunmoonai-api` service.
After that, add retrieval validation metadata.
