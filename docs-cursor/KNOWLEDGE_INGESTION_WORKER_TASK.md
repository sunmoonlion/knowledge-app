# Knowledge Ingestion Worker Task

Status: M1 mock worker implemented, RAGFlow processing deferred

## Objective

Turn the deployed ingestion API from a pure accepted-job endpoint into an executable
state machine:

```text
accepted -> running -> succeeded / failed
```

This task deliberately does not implement RAGFlow parsing, chunking, embedding, or
indexing. It proves the worker boundary, status history, retry surface, and deployment
path first.

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

- No RAGFlow private API calls.
- No object storage artifact fetch.
- No chunk/embed/index work.
- No retrieval validation against RAGFlow.

## Acceptance

- Unit tests pass for ingestion contract, asyncpg URL normalization, and mock worker
  metadata.
- Deployed API accepts info-app standard payload.
- Deployed worker can advance a job to `succeeded`.
- info-app distribution can record a successful response from knowledge-app.

## Next Task

Replace the mock processor with a real processing adapter:

```text
artifact refs -> content fetch -> document profile -> chunk/embed/index -> ragflow ids
```

The worker must then update `ragflow_document_id`, structured failure details, and
retrieval validation metadata.
