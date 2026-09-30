# Code Ocean validation plan

This plan is required after the reviewed adapter commit is merged. Local and
GitHub checks do not constitute Code Ocean validation.

## Candidate identity

Before each run, record:

- the exact merged adapter commit;
- canonical OMIX source commit
  `eee4433cd74d0ce9bd1daba1571ca6312cba7ea2`;
- the Code Ocean capsule or release identifier;
- runtime tag `codeocean/omix-r-pathway:r4.4.3-bioconductor3.20-v1`; and
- the immutable runtime digest resolved by the platform.

## Required runs

1. **Attached demo, named parameters**
   - Leave `DEG Table` blank.
   - Keep `Mouse` and ordered comparisons `B-A,C-A,B-C`.
   - Confirm the adapter selects exactly one table under `/data/deg_table`.
2. **Explicit user table**
   - Select a compatible CSV with `DEG Table`.
   - Use at least two comparisons in a nonalphabetical requested order.
   - Confirm result and plot order matches the request.
3. **Workflow result**
   - Connect one upstream wide DEG result with comparison-specific t-statistic,
     p-value, and fold-change columns.
   - Leave the three column overrides blank and confirm deterministic mapping.
4. **Ambiguity failure**
   - Attach two eligible DEG tables without selecting one explicitly.
   - Confirm the run stops and prints every candidate path.
5. **Advanced controls**
   - Run once with `pathway_bubble_significance_statistic=pval`,
     `collection_color_scale=shared`, and a nondefault `pathway_bubble_top_n`.
   - Run once with a small custom pathway table and verify its configured
     pathway-name and gene-symbol columns.

## Required artifacts and assertions

- `l2p_multi_results.csv` contains every pathway meeting the selected export
  criteria; the figure row limit does not truncate it.
- `l2p_multi_results_provenance.csv` is present.
- Shared combined, faceted, and collection-specific
  `L2P-Multi-Pathway-Bubble_*.png` files and the manifest are present when
  bubble plots are enabled.
- The manifest records the requested comparison order, significance statistic,
  selection scopes, dimensions, and color-scale behavior.
- No retired capsule-local legacy plot or user-selected output path is used.
- No files are written outside `/results`.

Record the run links, output checks, runtime digest, and any approved exception
in `OMIX_MODULE_SOURCE.md` before creating an adapter release tag.
