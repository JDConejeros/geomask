#' Estadísticas espaciales de utilidad (NND, Ripley K)
#'
#' @param original,masked Objetos `sf` POINT.
#' @param metrics Vector entre `"nnd"`, `"ripley_k"`.
#' @param r_seq Secuencia de radios para K de Ripley (m).
#'
#' @return Lista con estadísticas comparativas.
#' @export
utility_spatial_stats <- function(original,
                                  masked,
                                  metrics = c("nnd", "ripley_k"),
                                  r_seq = seq(100, 2000, by = 200)) {
  metrics <- match.arg(metrics, several.ok = TRUE)
  pair <- align_original_masked(original, masked)
  o <- ensure_metric_crs(pair$original)
  m <- sf::st_transform(pair$masked, sf::st_crs(o))
  out <- list()
  if ("nnd" %in% metrics) {
    nnd <- function(x) {
      coords <- sf_coords(x)
      n <- nrow(coords)
      if (n < 2) return(numeric(0))
      dmat <- as.matrix(stats::dist(coords))
      diag(dmat) <- Inf
      apply(dmat, 1, min)
    }
    nnd_o <- nnd(o)
    nnd_m <- nnd(m)
    out$nnd <- list(
      original = nnd_o,
      masked = nnd_m,
      ks_statistic = if (length(nnd_o) > 0 && length(nnd_m) > 0) {
        stats::ks.test(nnd_o, nnd_m)$statistic
      } else {
        NA_real_
      }
    )
  }
  if ("ripley_k" %in% metrics) {
    ripley_k <- function(x, r_vals) {
      coords <- sf_coords(x)
      n <- nrow(coords)
      if (n < 2) return(rep(NA_real_, length(r_vals)))
      dmat <- as.matrix(stats::dist(coords))
      vapply(r_vals, function(r) {
        sum(dmat <= r) / (n * (n - 1))
      }, numeric(1))
    }
    k_o <- ripley_k(o, r_seq)
    k_m <- ripley_k(m, r_seq)
    out$ripley_k <- list(
      r = r_seq,
      original = k_o,
      masked = k_m,
      delta_integral = sum(abs(k_o - k_m), na.rm = TRUE) * mean(diff(r_seq))
    )
  }
  out
}

#' Detección de clusters: Moran global y concordancia LISA
#'
#' @param original,masked Puntos o polígonos con variable `value`.
#' @param zones Polígonos para conteo si entradas son puntos.
#' @param value_col Columna numérica.
#' @param weight_style `"queen"` o `"knn"` (requiere `spdep`).
#'
#' @return Lista con Moran global y concordancia LISA.
#' @export
utility_cluster_detection <- function(original,
                                      masked,
                                      zones = NULL,
                                      value_col = "value",
                                      weight_style = c("queen", "knn")) {
  weight_style <- match.arg(weight_style)
  if (!requireNamespace("spdep", quietly = TRUE)) {
    cli::cli_abort("Se requiere {.pkg spdep} para Moran/LISA.")
  }
  prep <- function(x) {
    if (inherits(x, "sf") && all(sf::st_geometry_type(x) %in% "POINT") && !is.null(zones)) {
      z <- sf::st_transform(zones, sf::st_crs(x))
      j <- sf::st_join(x, z)
      if (!"zone_id" %in% names(j)) {
        cli::cli_abort("{.arg zones} debe incluir columna {.field zone_id}.")
      }
      j |>
        dplyr::group_by(.data$zone_id) |>
        dplyr::summarise(value = dplyr::n(), geometry = sf::st_union(.data$geometry), .groups = "drop")
    } else {
      x
    }
  }
  o <- prep(original)
  m <- prep(masked)
  make_listw <- function(poly) {
    nb <- if (weight_style == "queen") {
      spdep::poly2nb(poly, queen = TRUE)
    } else {
      coords <- sf::st_coordinates(sf::st_centroid(poly))
      spdep::knearneigh(coords, k = min(4, nrow(poly) - 1))
      spdep::knn2nb(spdep::knearneigh(coords, k = min(4, nrow(poly) - 1)))
    }
    spdep::nb2listw(nb, style = "W", zero.policy = TRUE)
  }
  lw_o <- make_listw(o)
  lw_m <- make_listw(m)
  moran_o <- spdep::moran.test(o[[value_col]], lw_o, zero.policy = TRUE)$estimate[["Moran I statistic"]]
  moran_m <- spdep::moran.test(m[[value_col]], lw_m, zero.policy = TRUE)$estimate[["Moran I statistic"]]
  lisa_o <- spdep::localmoran(o[[value_col]], lw_o, zero.policy = TRUE)[, 1]
  lisa_m <- spdep::localmoran(m[[value_col]], lw_m, zero.policy = TRUE)[, 1]
  list(
    moran_original = moran_o,
    moran_masked = moran_m,
    delta_moran = abs(moran_o - moran_m),
    lisa_concordance = mean(sign(lisa_o) == sign(lisa_m), na.rm = TRUE)
  )
}

#' Resumen epidemiológico espacial
#'
#' @param original,masked Puntos `sf`.
#' @param zones Polígonos con población (`pop`).
#' @param pop_col Columna de población.
#' @param services Puntos de servicios de salud (opcional).
#'
#' @return Lista con tasas y distancias a servicios.
#' @export
utility_epi_summary <- function(original,
                                masked,
                                zones,
                                pop_col = "pop",
                                services = NULL) {
  count_by_zone <- function(pts, zones_sf) {
    z <- sf::st_transform(zones_sf, sf::st_crs(pts))
    j <- sf::st_join(pts, z)
    j |>
      dplyr::group_by(.data$zone_id) |>
      dplyr::summarise(cases = dplyr::n(), pop = dplyr::first(.data[[pop_col]]), .groups = "drop") |>
      dplyr::mutate(rate = .data$cases / .data$pop * 1e5)
  }
  rates_o <- count_by_zone(original, zones)
  rates_m <- count_by_zone(masked, zones)
  dist_services <- function(pts) {
    if (is.null(services)) return(NULL)
    s <- sf::st_transform(services, sf::st_crs(pts))
    as.numeric(sf::st_distance(pts, sf::st_nearest_feature(pts, s)))
  }
  list(
    rates_original = rates_o,
    rates_masked = rates_m,
    rate_mae = mean(abs(rates_o$rate - rates_m$rate), na.rm = TRUE),
    dist_services_original = dist_services(original),
    dist_services_masked = dist_services(masked)
  )
}

#' Resumen de utilidad (envolvente)
#'
#' @inheritParams utility_spatial_stats
#' @param ... Argumentos adicionales para sub-funciones.
#'
#' @return Objeto S3 `geomask_utility`.
#' @export
utility_summary <- function(original, masked, ...) {
  stats <- utility_spatial_stats(original, masked, ...)
  structure(
    list(
      spatial_stats = stats,
      computed_at = Sys.time()
    ),
    class = "geomask_utility"
  )
}

#' @export
print.geomask_utility <- function(x, ...) {
  cat("<geomask utility summary>\n")
  if (!is.null(x$spatial_stats$nnd$ks_statistic)) {
    cat("KS NND:", round(x$spatial_stats$nnd$ks_statistic, 4), "\n")
  }
  if (!is.null(x$spatial_stats$ripley_k$delta_integral)) {
    cat("Delta integral K:", round(x$spatial_stats$ripley_k$delta_integral, 4), "\n")
  }
  invisible(x)
}
