# Code Ocean validation record

This record separates observed platform execution from facts that have not yet
been captured. A successful computation is not, by itself, an adapter release.

## Recorded computation

| Field | Evidence |
| --- | --- |
| Validation date | 2026-09-30 |
| Code Ocean computation | `814585` |
| Adapter commit | `f47e569dfc131bf38a47109b301d1772e03547f3` |
| Canonical module | OMIX L2P Multi `4.1.0` at `53b2ca65aa23f54477f698c4ab6ce0d6ab637a5f` |
| Runtime selected in Code Ocean | `OMIX Pathways v2` |
| Observed outcome | The named-parameter computation completed successfully. |

## Evidence classification

This is **partial platform validation**. It confirms that the merged adapter
could execute in Code Ocean with the named runtime. It does not establish the
runtime's immutable digest, a published capsule release, or a complete durable
checklist of comparison ordering, result rows, shared bubble plots, and other
output assertions.

## Remaining release gates

- Capture the immutable digest for the exact Code Ocean runtime used.
- Record the capsule identifier or URL and any published platform release ID.
- Repeat or inspect the computation and record the effective DEG input,
  comparison order, important named parameters, expected result files, shared
  bubble-plot manifest, and scientific sanity checks.
- Have Beacon verify the completed evidence record against the merged adapter.
- Obtain explicit release approval before creating an adapter tag or publishing
  a capsule release.

Until those gates are complete, `OMIX_MODULE_SOURCE.md` must keep the adapter
version, release tag, platform release, and runtime digest as **Pending**.
