#' k-anonimato espacial
#'
#' @param masked Objeto `sf` POINT enmascarado.
#' @param r Radio de vecindad (metros).
#' @param return_individual Si TRUE, devuelve también el vector por punto.
#'
#' @return Lista con `k_global` (mínimo) y opcionalmente `k_individual`.
#' @export
#' @references Sweeney, L. (2002). k-anonymity. *IJUFKS*, 10(05), 557–570.
#' @examples
#' data(geomask_pts, package = "geomask")
#' m <- mask_donut(geomask_pts, 300, 900, seed = 1)
#' privacy_k_anonymity(m, r = 500)
privacy_k_anonymity <- function(masked, r, return_individual = FALSE) {
  validate_sf_points(masked)
  if (r <= 0) cli::cli_abort("{.arg r} debe ser positivo.")
  m <- ensure_metric_crs(masked)
  coords <- sf_coords(m)
  n <- nrow(m)
  dmat <- as.matrix(stats::dist(coords))
  k_ind <- vapply(seq_len(n), function(i) {
    sum(dmat[i, ] <= r) # incluye el propio punto
  }, numeric(1))
  k_global <- min(k_ind)
  out <- list(k_global = k_global, r = r)
  if (return_individual) out$k_individual <- k_ind
  out
}

#' Riesgo de divulgación (nearest neighbor o probabilístico)
#'
#' @param original Objeto `sf` POINT original.
#' @param masked Objeto `sf` POINT enmascarado.
#' @param method `"nn"` o `"prob"`.
#' @param bandwidth Ancho de banda para método probabilístico.
#'
#' @return Lista con riesgos individuales y promedio.
#' @export
privacy_disclosure_risk <- function(original, masked, method = c("nn", "prob"), bandwidth = 500) {
  method <- match.arg(method)
  pair <- align_original_masked(original, masked)
  o <- ensure_metric_crs(pair$original)
  m <- sf::st_transform(pair$masked, sf::st_crs(o))
  o_coords <- sf_coords(o)
  m_coords <- sf_coords(m)
  n <- nrow(o)
  rd <- numeric(n)
  if (method == "nn") {
    for (i in seq_len(n)) {
      d <- sqrt((o_coords[, 1] - m_coords[i, 1])^2 + (o_coords[, 2] - m_coords[i, 2])^2)
      rd[i] <- as.numeric(which.min(d) == i)
    }
  } else {
    for (i in seq_len(n)) {
      d <- sqrt((o_coords[, 1] - m_coords[i, 1])^2 + (o_coords[, 2] - m_coords[i, 2])^2)
      w <- exp(-d / bandwidth)
      rd[i] <- w[i] / sum(w)
    }
  }
  list(
    risk_individual = rd,
    risk_mean = mean(rd),
    method = method
  )
}

#' Índice de protección de ubicación (Location Protection Metric)
#'
#' Métrica sugerida para evaluar el enmascaramiento: proporción de puntos cuyo
#' desplazamiento supera un umbral de protección `d_min` **y** cumplen k-anonimato
#' local >= `k_target` dentro de `r`. Combina distancia de geomasking y densidad
#' de vecinos enmascarados (trade-off operacional).
#'
#' @param original,masked Objetos `sf` POINT alineados por fila.
#' @param d_min Umbral mínimo de desplazamiento (m).
#' @param r Radio para k-anonimato local.
#' @param k_target k mínimo deseado por punto.
#'
#' @return Lista con `lpm` (0-1), componentes y conteos.
#' @export
#' @references
#' Kwan, M.-P., Casas, I., & Schmitz, B. C. (2004). *Cartographica*, 39(2), 15–28.
#' @examples
#' data(geomask_pts, package = "geomask")
#' m <- mask_donut(geomask_pts, 400, 1000, seed = 2)
#' privacy_location_protection(geomask_pts, m, d_min = 350, r = 600, k_target = 3)
privacy_location_protection <- function(original, masked, d_min, r, k_target = 5) {
  pair <- align_original_masked(original, masked)
  o <- ensure_metric_crs(pair$original)
  m <- sf::st_transform(pair$masked, sf::st_crs(o))
  disp <- sqrt(
    (sf::st_coordinates(m)[, 1] - sf::st_coordinates(o)[, 1])^2 +
      (sf::st_coordinates(m)[, 2] - sf::st_coordinates(o)[, 2])^2
  )
  k_info <- privacy_k_anonymity(m, r = r, return_individual = TRUE)
  protected <- (disp >= d_min) & (k_info$k_individual >= k_target)
  list(
    lpm = mean(protected),
    n_protected = sum(protected),
    n_total = length(protected),
    displacement_m = disp,
    k_individual = k_info$k_individual,
    d_min = d_min,
    r = r,
    k_target = k_target
  )
}
