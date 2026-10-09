# Bat acoustic activity plots

`plot_sites.R` makes one figure per site showing nightly RMS amplitude from the acoustic detector (left axis) with a GAM trend line, and manual bat counts (right axis) overlaid on the same panel. Output is sized for a poster.

![Example output: Willard Pond Barn, 2026](example/Willard_Pond_Barn_2026.png)

Small black circles are nightly RMS amplitude. The blue line is a GAM fit to those values with a grey 95% confidence band. Red circles are manual bat counts, labeled with the count. The right axis reads in bat-count units.

## Requirements

R 4.x with:

```r
install.packages(c("ggplot2", "ggrepel", "mgcv", "scales"))
```

`mgcv` ships with R, but the `library(mgcv)` call is explicit so `geom_smooth(method = "gam")` works in a clean session.

## Input file

A CSV with one row per site per night. Required columns (names are case-sensitive):

| Column           | Type    | Description                                                        |
|------------------|---------|--------------------------------------------------------------------|
| `Julian`         | integer | Day of year. This is the x axis.                                   |
| `total_adj_rmse` | numeric | Adjusted RMS amplitude for that night. Left y axis.                |
| `Count`          | integer | Manual bat count. Leave blank on nights with no count.             |
| `Site`           | string  | Site name. One plot is made per unique value, used as the title.  |

Extra columns (`date`, `total_raw_rmse`, an unnamed row-index column) are ignored.

Example:

```
Julian,total_adj_rmse,Count,Site
160,43373.9182,421,Willard Pond Barn
161,36930.88369,,Willard Pond Barn
162,42861.31255,,Willard Pond Barn
160,33822.69206,,Tolman Barn
```

Notes on the input:

- Blank `Count` cells are read as `NA`. Do not put `0` on nights with no count; `0` is a real count and will be plotted.
- A UTF-8 byte-order mark at the start of the file (Excel adds one when saving as "CSV UTF-8") is handled. Without the `fileEncoding = "UTF-8-BOM"` argument in the script, the first column would be read as `X.U.FEFF.Julian`.
- Each site needs at least two manual counts. The right axis is derived from a linear fit of the GAM to the counts, and that fit needs two points.
- Each site needs enough nights for `mgcv` to fit a smooth. Roughly 10 or more is safe.

## Running it

From a shell, in the directory containing the CSV:

```bash
Rscript plot_sites.R Combined_Sites_2026.csv 2026
Rscript plot_sites.R PAB_AllSites_2025.csv  2025
```

Arguments:

1. Path to the input CSV. Defaults to `Combined_Sites_2026.csv` if omitted.
2. Suffix appended to output filenames. Optional. Use it to keep years separate.

From RStudio, `commandArgs()` returns nothing, so set the two variables at the top of the script by hand before sourcing:

```r
infile <- "PAB_AllSites_2025.csv"
suffix <- "2025"
```

## Output

For each site, a PNG (10 x 7 in, 300 dpi, white background) and a PDF (vector, same dimensions) in the working directory. Spaces in site names become underscores:

```
Brown_Barn_2025.png
Brown_Barn_2025.pdf
Tolman_Barn_2025.png
...
```

The PDF is the one to place on the poster. It scales without loss and the fonts stay editable.

## How the right axis works

ggplot2 only allows a secondary axis that is a fixed linear transform of the primary axis. Bat counts therefore have to be drawn in RMS-amplitude coordinates. The script picks that transform from the data:

1. Fit the same GAM that `geom_smooth()` draws.
2. Predict RMS amplitude on the nights that have a manual count.
3. Regress those predictions on the counts.

The resulting line (`a + b * Count`) maps counts onto the left axis, and its inverse labels the right axis. This puts the red points as close to the trend line as any linear axis can. Two consequences to be aware of:

- The intercept `a` is usually not zero, so the two axes do not share a zero. Read them as independent scales.
- When counts barely vary between nights (for example 60, 62, 54), the right axis spans a narrow range. That is a faithful reflection of the data, not a bug.

If you want the axes to share a zero, change `lm(fit ~ Count, data = cnt)` to `lm(fit ~ 0 + Count, data = cnt)` and set `a <- 0`. The red points will sit further from the curve.

## Adjusting the look

All styling is in `plot_site()`:

| What                     | Where                                                        |
|--------------------------|--------------------------------------------------------------|
| Axis titles              | `name =` in `scale_y_continuous()` and `sec_axis()`, `x =` in `labs()` |
| Trend line color         | `colour = "blue"` in `geom_smooth()`                         |
| Confidence band          | `fill = "grey60", alpha = 0.35` in `geom_smooth()`           |
| GAM smoothness           | add `formula = y ~ s(x, k = 10)` to `geom_smooth()` and the matching `gam()` call; lower `k` for a smoother line |
| Count point size/color   | `size`, `stroke`, `colour` in the second `geom_point()`      |
| Count label offset       | `nudge_y` in `geom_text_repel()` (fraction of the y range)   |
| Text sizes               | `base_size` in `theme_classic()`, plus `plot.title`, `axis.title`, `axis.text` in `theme()` |
| Figure dimensions        | `width`, `height`, `dpi` in `ggsave()`                       |

If you change `base_size`, scale the explicit `size =` values in `theme()` and `geom_text_repel()` proportionally. Text at `base_size = 22` is legible from about 1.5 m on a 36 x 48 in poster when the figure is placed at 10 x 7 in.

## Known data issues

- Both input files have one night per site, immediately before a multi-day gap, where `total_raw_rmse` is roughly a tenth of its neighbors (2025: day 185 Willard Pond, 186 Brown Barn, 165 Tolman). These look like partial recordings before the detector went down and they pull the GAM toward zero locally. Consider removing them.
- `Combined_Sites_2026.csv` has two Tolman Barn rows for Julian day 234. One is probably day 233.
