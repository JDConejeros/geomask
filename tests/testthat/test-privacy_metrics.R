test_that("privacy_k_anonymity calcula mínimo", {
  data(geomask_pts, package = "geomask")
  m <- mask_random_perturbation(geomask_pts[1:40, ], max_r = 50, seed = 1)
  k <- privacy_k_anonymity(m, r = 100, return_individual = TRUE)
  expect_true(k$k_global >= 1)
  expect_length(k$k_individual, 40)
})

test_that("privacy_disclosure_risk NN está acotado", {
  data(geomask_pts, package = "geomask")
  m <- mask_donut(geomask_pts[1:25, ], 200, 600, seed = 3)
  r <- privacy_disclosure_risk(geomask_pts[1:25, ], m, method = "nn")
  expect_true(all(r$risk_individual %in% c(0, 1)))
  expect_true(r$risk_mean >= 0 && r$risk_mean <= 1)
})

test_that("privacy_location_protection devuelve lpm", {
  data(geomask_pts, package = "geomask")
  m <- mask_donut(geomask_pts[1:30, ], 400, 1000, seed = 4)
  lpm <- privacy_location_protection(geomask_pts[1:30, ], m, d_min = 350, r = 500, k_target = 2)
  expect_true(lpm$lpm >= 0 && lpm$lpm <= 1)
})
