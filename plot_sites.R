
Plot sites · R
library(ggplot2)
library(ggrepel)
library(mgcv)
 
# fileEncoding handles the UTF-8 BOM Excel put at the start of the file;
# without it the first column comes in as "X.U.FEFF.Julian"
# Usage: Rscript plot_sites.R <input.csv> <output_suffix>
#   e.g. Rscript plot_sites.R Combined_Sites_2026.csv 2026
#        Rscript plot_sites.R PAB_AllSites_2025.csv  2025
args   <- commandArgs(trailingOnly = TRUE)
infile <- if (length(args) >= 1) args[1] else "Combined_Sites_2026.csv"
suffix <- if (length(args) >= 2) args[2] else ""
dat <- read.csv(infile, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
 
plot_site <- function(site, dat) {
  d <- dat[dat$Site == site, ]
  d <- d[order(d$Julian), ]
  cnt <- d[!is.na(d$Count), ]
 
  # Secondary axes in ggplot2 must be a 1:1 transform of the primary, so the
  # Count points have to be placed in RMSE units. To put them as close to the
  # GAM as a linear axis allows, fit the same GAM geom_smooth uses, predict RMSE
  # on the manual-count days, and regress those predictions on Count. That
  # line is the Count -> RMSE transform; the right axis is its inverse.
  g    <- gam(total_adj_rmse ~ s(Julian, bs = "cs"), data = d)
  fit  <- predict(g, newdata = cnt)
  map  <- lm(fit ~ Count, data = cnt)
  a <- coef(map)[1]; b <- coef(map)[2]
  to_rmse   <- function(x) a + b * x
  from_rmse <- function(y) (y - a) / b
  cnt$Count_pos <- to_rmse(cnt$Count)
 
  # Right-axis breaks: pretty Count values whose positions fall inside the panel
  r_rng <- range(c(d$total_adj_rmse, cnt$Count_pos), na.rm = TRUE)
  c_brk <- pretty(from_rmse(r_rng), n = 6)
  c_brk <- c_brk[to_rmse(c_brk) >= r_rng[1] & to_rmse(c_brk) <= r_rng[2]]
 
  ggplot(d, aes(x = Julian, y = total_adj_rmse)) +
    geom_point(shape = 1, colour = "black", size = 3, stroke = 0.9) +
    geom_smooth(method = "gam", colour = "blue", fill = "grey60",
                alpha = 0.35, linewidth = 1.5) +
    geom_point(data = cnt, aes(x = Julian, y = Count_pos),
               shape = 1, colour = "red", size = 6, stroke = 1.8) +
    geom_text_repel(data = cnt, aes(x = Julian, y = Count_pos, label = Count),
                    colour = "red", fontface = "bold", size = 7,
                    nudge_y = 0.06 * diff(r_rng), point.padding = 0.6,
                    box.padding = 0.4, min.segment.length = Inf, seed = 1) +
    scale_y_continuous(
      name     = "RMS Amplitude (V)",
      labels   = scales::comma,
      sec.axis = sec_axis(from_rmse, name = "Bat Count", breaks = c_brk),
      expand   = expansion(mult = c(0.05, 0.12))   # headroom for labels
    ) +
    labs(title = site, x = "Julian day") +
    theme_classic(base_size = 22) +
    theme(
      plot.title  = element_text(face = "bold", hjust = 0.5, size = 30),
      axis.title  = element_text(size = 24),
      axis.text   = element_text(size = 20, colour = "black"),
      axis.line   = element_line(linewidth = 0.8),
      axis.ticks  = element_line(linewidth = 0.8),
      plot.margin = margin(10, 20, 10, 10)
    )
}
 
for (s in unique(dat$Site)) {
  p  <- plot_site(s, dat)
  fn <- paste0(gsub(" ", "_", s), if (nzchar(suffix)) paste0("_", suffix) else "")
  ggsave(paste0(fn, ".png"), p, width = 10, height = 7, dpi = 300, bg = "white")
  ggsave(paste0(fn, ".pdf"), p, width = 10, height = 7)
}
 
Claude finished the response
