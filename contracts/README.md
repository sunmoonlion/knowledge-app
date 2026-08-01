# Knowledge Provider Contracts

This directory is the only editable source of truth for Knowledge ingestion and
retrieval provider contracts. Generated fixtures and downstream client models
must not be edited as substitute schemas.

## Artifact ingestion

- Current compatible major: `artifact/v1`
- Request schema: `artifact/v1/info-knowledge-artifact.schema.json`
- Release manifest and digest: `artifact/v1/contract-manifest.json`
- Producer: Info App
- Provider/consumer: Knowledge App

The v1 contract accepts exactly one immutable, versioned `s3://` object. The
provider resolves it with its own read-only identity and verifies storage
version, size, media type and SHA-256 before any RAGFlow upload. Database IDs are
lineage only; the provider never calls back into the Info database to resolve an
artifact.

Breaking changes require a new major directory and a dual-version migration
window. CI publishes the schema together with its SHA-256 digest.

## Retrieval and citation

- Current compatible major: `retrieval/v1`
- Request schema: `retrieval/v1/knowledge-retrieval-request.schema.json`
- Provider response schema: `retrieval/v1/knowledge-retrieval-response.schema.json`
- Browser-safe citation schema: `retrieval/v1/citation.schema.json`
- Release manifest and digests: `retrieval/v1/contract-manifest.json`
- Provider: Knowledge App
- Service consumer: Research App

Clients submit stable `dataset_key` values only. RAGFlow dataset, document and
chunk identifiers are private provider bindings and are never domain identity.
Every Evidence item is traceable through a stable Knowledge document/version
to an Info document/version. Browsers receive only the citation projection,
including an authorized same-origin source path instead of a raw provider URL.

Breaking changes require a new major directory. Additive optional response
fields remain compatible, but consumers must pin the manifest digests and run
consumer-driven contract tests before accepting a provider release.
