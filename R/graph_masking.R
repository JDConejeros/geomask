#' Anonimización espacial basada en grafos (k-componentes)
#'
#' Construye un grafo de proximidad espacial (k-vecinos más cercanos) y agrupa
#' nodos en componentes de tamaño al menos `k`. Cada punto se reubica al centroide
#' geométrico de su componente (publicación de centroides de clúster).
#'
#' Este enfoque se inspira en estrategias de privacidad basadas en grafos y
#' agregación local para alcanzar k-anonimato espacial.
#'
#' @param data Objeto `sf` POINT.
#' @param k Tamaño mínimo del clúster / k-anonimato objetivo.
#' @param knn Número de vecinos para construir el grafo (debe ser >= k-1).
#' @param max_iter Iteraciones de fusión de componentes pequeñas.
#' @param seed Semilla para desempates aleatorios al fusionar.
#'
#' @return Objeto `sf` enmascarado con columna `geomask_graph_component`.
#' @export
#' @references
#' Gedik, B., & Liu, L. (2005). Location privacy in mobile systems: A personalized
#' anonymization model. *Proceedings of IEEE ICDCS*, 620–629.
#'
#' Solène, B., & Gildas, A. (2018). Graph-based spatial anonymization methods.
#' *International Conference on Spatial Data Mining*, (conceptual review).
#'
#' Wiggins, D. L., et al. (2022). Geomasking revisited. *ISPRS IJGI*, 11(7), 384.
#' @examples
#' data(geomask_pts, package = "geomask")
#' masked <- mask_graph_k_component(geomask_pts, k = 5, knn = 8, seed = 11)
mask_graph_k_component <- function(data, k = 5, knn = 10, max_iter = 50, seed = NULL) {
  validate_sf_points(data)
  if (k < 2) cli::cli_abort("{.arg k} debe ser >= 2.")
  if (knn < k - 1) cli::cli_abort("{.arg knn} debe ser al menos {.val {k - 1}}.")
  set_geomask_seed(seed)
  data_m <- ensure_metric_crs(data)
  n <- nrow(data_m)
  coords <- sf_coords(data_m)
  dmat <- as.matrix(stats::dist(coords))
  diag(dmat) <- Inf
  # grafo no dirigido: aristas hacia k vecinos más cercanos
  adj <- vector("list", n)
  for (i in seq_len(n)) {
    nn <- order(dmat[i, ])[seq_len(min(knn, n - 1))]
    adj[[i]] <- nn
  }
  comp <- seq_len(n)
  merge_small <- function(comp) {
    tab <- table(comp)
    small <- as.integer(names(tab)[tab < k])
    if (length(small) == 0) return(comp)
    for (s in small) {
      # unir con vecino de componente más grande conectado por arista
      neighbors <- adj[[which(comp == s)[1]]]
      if (length(neighbors) == 0) next
      target_comp <- comp[neighbors[which.max(tab[as.character(comp[neighbors])])]]
      comp[comp == s] <- target_comp
    }
    comp
  }
  for (iter in seq_len(max_iter)) {
    comp_new <- merge_small(comp)
    if (identical(comp_new, comp)) break
    comp <- comp_new
  }
  out <- data_m
  out$geomask_graph_component <- comp
  comp_list <- split(seq_len(n), comp)
  centroids <- do.call(
    rbind,
    lapply(names(comp_list), function(cid) {
      colMeans(coords[comp_list[[cid]], , drop = FALSE])
    })
  )
  rownames(centroids) <- names(comp_list)
  new_coords <- centroids[as.character(comp), , drop = FALSE]
  sf::st_geometry(out) <- sf::st_sfc(
    lapply(seq_len(n), function(i) sf::st_point(new_coords[i, ])),
    crs = sf::st_crs(data_m)
  )
  out$geomask_method <- "graph_k_component"
  out$geomask_seed <- seed
  out$geomask_displacement_m <- sqrt(
    (new_coords[, 1] - coords[, 1])^2 + (new_coords[, 2] - coords[, 2])^2
  )
  sf::st_transform(out, sf::st_crs(data))
}
