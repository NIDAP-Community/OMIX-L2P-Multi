# Code Ocean validation record

This record separates observed platform execution from facts that have not yet
been captured. A successful computation is not, by itself, an adapter release.

## Validated execution-bearing commit

| Field | Evidence |
| --- | --- |
| Validation date | 2026-10-01 |
| Code Ocean capsule | [`5721592`](https://poc-nci.codeocean.io/capsule/5721592/tree) |
| Code Ocean computation | `868130` |
| Adapter commit | `743acb2ebae0ca4325bf801bb8ef1f59a71ab3cb` |
| Canonical module | OMIX L2P Multi `4.1.0` at `53b2ca65aa23f54477f698c4ab6ce0d6ab637a5f` |
| Runtime selected in Code Ocean | `OMIX Pathways (2)`; R 4.4.3, Bioconductor 3.20, `fgsea`, `GSVA`, `l2p`, `l2psupp`, and `OmixPathwayPlots` 0.2.0 |
| Compute resource | 1 core / 8 GB RAM |
| Effective demo input | Attached `Demo DEG_table`; explicit DEG file left blank |
| Effective ordered comparisons | `B-A,C-A,B-C` |
| Effective species and pathway collections | `Mouse`; `H, GO, REACTOME` |
| Effective gene selection | Threshold mode; p-value `0.05`; absolute linear fold change `1.2` |
| Effective shared-plot settings | Top 20; adjusted-p-value significance; independent collection color scales |
| Observed outcome | The synchronized computation completed successfully in 1 minute 26 seconds. |

## Observed artifacts

Code Ocean displayed the following `/results` artifacts for computation
`868130`:

- `l2p_multi_results.csv` (11.75 MB);
- `l2p_multi_results_provenance.csv` (2.03 KB);
- `L2P-Multi-Pathway-Bubble_across_collections.png` (660.72 KB);
- `L2P-Multi-Pathway-Bubble_combined_pathways.png` (672.15 KB);
- `L2P-Multi-Pathway-Bubble_go.png` (526.76 KB);
- `L2P-Multi-Pathway-Bubble_h.png` (412.77 KB);
- `L2P-Multi-Pathway-Bubble_reactome.png` (642.72 KB);
- `L2P-Multi-Pathway-Bubble_manifest.csv` (875 B); and
- the captured run output (4.29 KB).

This verifies the attached-demo named-parameter run and the presence of the
stable output set. It does not, by itself, verify the contents and ordering
assertions inside every artifact.

## Earlier computation

Computation `814585` completed successfully on 2026-09-30 against adapter
commit `f47e569dfc131bf38a47109b301d1772e03547f3` using `OMIX Pathways v2`.
It preceded the documentation-only commits that recorded its evidence.

## Evidence classification

This is **partial platform validation**. It confirms that exact adapter commit
`743acb2ebae0ca4325bf801bb8ef1f59a71ab3cb` could execute in Code Ocean with
the named runtime and attached demo, and that the expected stable artifacts
were produced. It does not establish
the runtime's immutable digest, a published capsule release, the internal
ordering assertions, or the remaining explicit-table, workflow, ambiguity,
suffix-override, advanced-plot, and custom-pathway runs in the validation plan.

## Remaining release gates

- Capture the immutable digest for the exact Code Ocean runtime used.
- Record any published platform release ID after explicit release approval.
- Inspect the result and provenance tables plus bubble-plot manifest and record
  the required comparison-order, row-order, and scientific sanity assertions.
- Complete the remaining explicit-table, workflow, ambiguity, suffix-override,
  advanced-plot, and custom-pathway cases in the validation plan.
- Have Beacon verify the completed evidence record against the merged adapter.
- Obtain explicit release approval before creating an adapter tag or publishing
  a capsule release.

Until those gates are complete, `OMIX_MODULE_SOURCE.md` must keep the adapter
version, release tag, platform release, and runtime digest as **Pending**.
