# Knowledge Ingestion Worker Task

> 历史实施快照，最后有效日期为 2026-07-11。本文仅保留 ingestion worker/RAGFlow 早期实现证据；当前任务、契约和部署状态以代码、测试以及 k8s 仓库的 MoocManus v5 文档为准。

Status: M1 mock worker implemented; M2 RAGFlow adapter implemented and deployed behind config; ops endpoints implemented

## Objective

Turn the deployed ingestion API from a pure accepted-job endpoint into an executable
state machine:

```text
accepted -> running -> succeeded / failed
```

M1 proved the worker boundary, status history, retry surface, and deployment path.
M2 adds a real RAGFlow HTTP adapter, but keeps mock mode when RAGFlow credentials
are not configured.

The worker now uses explicit terminal error statuses instead of collapsing every
failure into `failed`:

```text
accepted -> running -> succeeded
accepted -> running -> ragflow_config_error / ragflow_parse_failed / artifact_unreadable / external_api_error / failed
```

## M1 Scope

- `POST /api/knowledge/ingestions` creates or idempotently returns a job.
- When Celery is configured, accepted jobs are dispatched to
  `app.tasks.process_knowledge_ingestion`.
- `POST /api/knowledge/ingestions/{ingestion_id}/dispatch` exists for manual smoke
  and local fallback.
- `POST /api/knowledge/ingestions/{ingestion_id}/retry` resets terminal failures
  to `accepted` and redispatches them. `ragflow_config_error` is blocked unless
  `force=true`, because retrying before fixing RAGFlow configuration only creates
  repeated bad jobs.
- `GET /api/knowledge/ragflow/config-check` checks whether the adapter is enabled,
  reachable, and whether the current RAGFlow tenant has a default embedding model.
  It reports only booleans and non-secret metadata; it never returns the API key.
- `GET /api/knowledge/ingestions` supports operational filters:
  `source_app`, `source_document_id`, `source_document_version_id`,
  `target_dataset`, `status`, `ragflow_document_id`, `idempotency_key`,
  `created_from`, and `created_to`.
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
- `POST /api/v1/datasets/{dataset_id}/documents/parse`
- `GET /api/v1/datasets/{dataset_id}/documents?id={document_id}`

Important RAGFlow API details verified against v0.25.4:

- `GET /datasets?name=...` returns a permission error for arbitrary names in the
  current deployment. The adapter lists visible datasets and matches names
  client-side before creating a new dataset.
- `GET /documents/{document_id}` downloads the original file and returns
  `application/octet-stream`; it is not a document status endpoint.

If RAGFlow is not configured, the worker keeps the M1 mock behavior and records
`mode=mock`, `ragflow=deferred`.
- No retrieval validation against RAGFlow.

## Acceptance

- Unit tests pass for ingestion contract, asyncpg URL normalization, mock metadata,
  RAGFlow metadata, artifact resolution, S3 signing, and RAGFlow HTTP call flow.
- Deployed API accepts info-app standard payload.
- Deployed worker can advance a job to `succeeded`.
- info-app distribution can record a successful response from knowledge-app.

## Current Real RAGFlow Smoke

The deployed adapter reaches RAGFlow successfully:

```text
ensure dataset -> create dataset -> upload document -> parse document -> poll document status
```

2026-07-11 update:

- RAGFlow UI default models have been configured:
  - `LLM=deepseek-v3@Tongyi-Qianwen`
  - `Embedding=text-embedding-v3@Tongyi-Qianwen`
- `GET /api/knowledge/ragflow/config-check` now reports:

```text
enabled=true
reachable=true
has_default_embedding=true
ready=true
```

The first smoke after selecting `Tongyi-Qianwen` used the provider default
DashScope endpoint and failed with `dashscope.aliyuncs.com:443 connect timeout`.
After reconfiguring the provider endpoint to the Beijing MaaS URL, retrying the
same job succeeded.

Verified smoke job:

```text
knowledge ingestion id: 7012be9a-7071-4445-9e01-f412b4717baf
ragflow dataset: codex-smoke / fee8dcdc7cc611f1a85655b688ac3ca7
ragflow document: 20769e647cc911f1a85655b688ac3ca7
ragflow parse status: DONE
ragflow chunk count: 1
final knowledge status: succeeded
```

## Next Task

Add retrieval validation metadata and run an info-app -> knowledge-app end-to-end
distribution smoke with real artifacts.
