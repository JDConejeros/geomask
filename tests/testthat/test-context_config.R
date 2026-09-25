test_that("mask_context_aware respeta boundary", {
  data(geomask_pts, package = "geomask")
  data(geomask_boundary, package = "geomask")
  sub <- sf::st_sf(geomask_pts[1:15, , drop = FALSE])
  out <- mask_context_aware(
    sub,
    method = mask_donut,
    boundary = geomask_boundary,
    min_r = 150,
    max_r = 500,
    seed = 8,
    max_iter = 10
  )
  b <- sf::st_transform(sf::st_union(geomask_boundary), sf::st_crs(out))
  inside <- apply(sf::st_intersects(out, b, sparse = FALSE), 1, any)
  expect_true(all(inside))
})

test_that("geomask_config roundtrip yaml", {
  skip_if_not_installed("yaml")
  cfg <- geomask_config(method = "donut", params = list(min_r = 100, max_r = 400), seed = 1)
  tmp <- tempfile(fileext = ".yml")
  write_geomask_config(cfg, tmp)
  cfg2 <- read_geomask_config(tmp)
  expect_equal(cfg2$method, "donut")
})

test_that("mask_graph_k_component produce desplazamiento", {
  data(geomask_pts, package = "geomask")
  out <- mask_graph_k_component(geomask_pts[1:35, ], k = 4, knn = 6, seed = 1)
  expect_true(any(out$geomask_displacement_m > 0))
})
