test_that("utility_spatial_stats sin masking fuerte conserva KS bajo", {
  data(geomask_pts, package = "geomask")
  sub <- geomask_pts[1:60, ]
  tiny <- mask_random_perturbation(sub, max_r = 1, seed = 1)
  stats <- utility_spatial_stats(sub, tiny, metrics = c("nnd", "ripley_k"))
  expect_true(stats$nnd$ks_statistic < 0.5)
})

test_that("utility_summary crea objeto S3", {
  data(geomask_pts, package = "geomask")
  sub <- geomask_pts[1:40, ]
  m <- mask_donut(sub, 100, 400, seed = 1)
  u <- utility_summary(sub, m)
  expect_s3_class(u, "geomask_utility")
})
