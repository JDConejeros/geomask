test_that("mask_donut respeta distancia mínima", {
  data(geomask_pts, package = "geomask")
  min_r <- 300
  max_r <- 900
  masked <- mask_donut(geomask_pts[1:50, ], min_r = min_r, max_r = max_r, seed = 1)
  expect_s3_class(masked, "sf")
  expect_equal(nrow(masked), 50)
  expect_true(all(masked$geomask_displacement_m >= min_r - 1e-6))
  expect_true(all(masked$geomask_displacement_m <= max_r + 1e-6))
})

test_that("mask_donut valida radios", {
  data(geomask_pts, package = "geomask")
  expect_error(mask_donut(geomask_pts, min_r = 500, max_r = 400), regexp = "min_r")
})

test_that("reproducibilidad con semilla", {
  data(geomask_pts, package = "geomask")
  a <- mask_gaussian(geomask_pts[1:20, ], sigma = 200, seed = 99)
  b <- mask_gaussian(geomask_pts[1:20, ], sigma = 200, seed = 99)
  expect_equal(sf::st_coordinates(a), sf::st_coordinates(b))
})

test_that("mask_location_swapping mantiene filas", {
  data(geomask_pts, package = "geomask")
  sub <- geomask_pts[1:30, ]
  out <- mask_location_swapping(sub, context_vars = c("comuna", "edad_grupo"), seed = 2)
  expect_equal(nrow(out), 30)
})
