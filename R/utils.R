# Funciones auxiliares internas del paquete geomask
# Comentarios en español según convención del autor

#' Validar que el objeto sea sf de puntos
#' @param data Objeto a validar
#' @param arg Nombre simbólico para mensajes de error
#' @noRd
validate_sf_points <- function(data, arg = rlang::caller_arg(data)) {
  if (!inherits(data, "sf")) {
    cli::cli_abort("{.arg {arg}} debe ser un objeto {.cls sf}.")
  }
  if (!all(sf::st_geometry_type(data, by_geometry = TRUE) %in% "POINT")) {
    cli::cli_abort("{.arg {arg}} debe contener geometrías POINT.")
  }
  if (any(sf::st_is_empty(data))) {
    cli::cli_abort("{.arg {arg}} contiene geometrías vacías.")
  }
  invisible(data)
}

#' Asegurar CRS métrico para distancias en metros
#' @noRd
ensure_metric_crs <- function(data, arg = rlang::caller_arg(data)) {
  validate_sf_points(data, arg = arg)
  crs <- sf::st_crs(data)
  if (is.na(crs)) {
    cli::cli_abort("{.arg {arg}} no tiene CRS definido; asigne uno antes de enmascarar.")
  }
  if (!sf::st_is_longlat(data)) {
    return(data)
  }
  # UTM zona 19S (EPSG:32719) cubre Santiago RM de forma razonable
  sf::st_transform(data, 32719)
}

#' Establecer semilla de forma reproducible
#' @noRd
set_geomask_seed <- function(seed) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
}

#' Desplazamiento polar aleatorio (coordenadas locales)
#' @noRd
polar_offset <- function(n, r_min, r_max) {
  theta <- stats::runif(n, 0, 2 * pi)
  if (r_min <= 0) {
    r <- stats::runif(n, 0, r_max)
  } else {
    r <- stats::runif(n, r_min, r_max)
  }
  cbind(dx = r * cos(theta), dy = r * sin(theta))
}

#' Aplicar desplazamiento a puntos sf ya proyectados
#' @noRd
apply_point_offsets <- function(data_proj, offsets, method, seed) {
  coords <- sf::st_coordinates(data_proj)
  new_coords <- coords + offsets
  out <- data_proj
  sf::st_geometry(out) <- sf::st_sfc(
    lapply(seq_len(nrow(new_coords)), function(i) {
      sf::st_point(new_coords[i, ])
    }),
    crs = sf::st_crs(data_proj)
  )
  dists <- sqrt(offsets[, 1]^2 + offsets[, 2]^2)
  out$geomask_method <- method
  out$geomask_seed <- seed
  out$geomask_displacement_m <- dists
  out
}

#' Emparejar original y enmascarado por fila
#' @noRd
align_original_masked <- function(original, masked) {
  validate_sf_points(original)
  validate_sf_points(masked)
  if (nrow(original) != nrow(masked)) {
    cli::cli_abort(
      "Original y enmascarado deben tener el mismo número de filas ({nrow(original)} vs {nrow(masked)})."
    )
  }
  list(original = original, masked = masked)
}

#' Extraer matriz de coordenadas
#' @noRd
sf_coords <- function(x) {
  sf::st_coordinates(x)[, 1:2, drop = FALSE]
}
