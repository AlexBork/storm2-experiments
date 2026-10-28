# Generated benchmark results

Sources: `experiments/logs`.

- `html/index.html`: offline results table with links to individual run pages.
- `html/logs/`: one HTML page per measured run, with its invocation, metadata, and source log.
  Share the entire `html/` folder, including its CSS and JavaScript assets.
- `plots/`: the audit CSV, compact CSV plot tables, reusable TeX commands, and the aggregate comparison.

To use the plots in a paper, copy `aggregate-plots.tex`, `paper-figure.tex`,
`plot-series.csv`, and `plot-curves.csv` from `plots/` into a `pomdp-plots/` folder in the paper project.
For CSV-driven figures, load `pomdp-plots/aggregate-plots.tex` in the paper preamble,
call `\StormPOMDPLoadAggregateData{pomdp-plots}`, and insert `\input{pomdp-plots/paper-figure.tex}` in the body.
Compile twice for the shared legend; Python and pre-rendered images are not needed in the paper project.

`scripts/postprocess.py --compile` also builds `plots/runtime-comparison.pdf` and `.png` with all three panels.
The panels sit side by side at LNCS text width (12.2 cm), with 6 pt lettering.
All plot panels cover the included instances together. Each point is a separate run.
All panels use the configured size limit on the x-axis and separate solid TO and MO lines.
For plotting, killed runs are treated as MO and use their benchmark's normal colour and marker.
Measured runtimes remain in the CSV; other failures get a Failed line when present.
The bound panels show gaps to the best successful under- and over-approximation per instance.
Gap: 100 * abs(bound-best) / max(abs(bound), abs(best)).
The under-reference panel shows deviation from the best observed cut-off bound.
The over-reference panel uses only belief discretisation at resolutions 4 and 5.
It shows the relative interval width between approximation bounds.
