#' Enmascaramiento con restricciones geográficas
#'
#' Aplica un método de masking y re-muestrea ubicaciones inválidas (fuera de
#' límite o en zonas prohibidas).
#'
#' @param data Objeto `sf` POINT.
#' @param method Función de masking (p.ej. `mask_donut`).
#' @param boundary Polígono `sf` de área permitida.
#' @param forbidden Polígonos prohibidos (opcional).
#' @param max_iter Intentos por punto.
#' @param ... Argumentos pasados a `method`.
#'
#' @return Objeto `sf` enmascarado.
#' @export
#' @references
#' Cassa, C. A., et al. (2006). A context-sensitive approach to anonymizing spatial
#' surveillance data. *JAMIA*, 13(2), 160–165.
#' @examples
#' \donttest{
#' data(geomask_boundary, package = "geomask")
#' data(geomask_pts, package = "geomask")
#' pts <- sf::st_sf(geomask_pts[1:50, , drop = FALSE])
#' masked <- mask_context_aware(
#'   pts,
#'   method = mask_donut,
#'   boundary = geomask_boundary,
#'   min_r = 200,
#'   max_r = 800,
#'   seed = 5,
#'   max_iter = 5
#' )
#' }
mask_context_aware <- function(data,
                               method = mask_donut,
                               boundary = NULL,
                               forbidden = NULL,
                               max_iter = 30,
                               ...) {
  validate_sf_points(data)
  if (!is.function(method)) {
    cli::cli_abort("{.arg method} debe ser una función de masking.")
  }
  out <- method(data, ...)
  if (is.null(boundary) && is.null(forbidden)) {
    return(out)
  }
  data_m <- ensure_metric_crs(data)
  out_m <- sf::st_transform(out, sf::st_crs(data_m))
  bnd <- if (!is.null(boundary)) {
    sf::st_transform(sf::st_union(boundary), sf::st_crs(data_m))
  } else {
    NULL
  }
  forb <- if (!is.null(forbidden)) sf::st_transform(sf::st_union(forbidden), sf::st_crs(data_m)) else NULL
  for (i in seq_len(nrow(out_m))) {
    ok <- point_is_valid(out_m[i, ], bnd, forb)
    attempt <- 1
    while (!ok && attempt <= max_iter) {
      single <- method(data_m[i, , drop = FALSE], ...)
      cand <- sf::st_transform(single, sf::st_crs(data_m))
      sf::st_geometry(out_m)[i] <- sf::st_geometry(cand)
      ok <- point_is_valid(out_m[i, ], bnd, forb)
      attempt <- attempt + 1
    }
    if (!ok && !is.null(bnd)) {
      # fallback: muestreo dentro del límite permitido
      sampled <- sf::st_sample(bnd, size = 1)
      if (length(sampled) > 0 && point_is_valid(sampled, bnd, forb)) {
        sf::st_geometry(out_m)[i] <- sampled
        ok <- TRUE
      }
    }
    if (!ok) {
      cli::cli_warn("Punto {i}: no se encontró ubicación válida tras {max_iter} intentos.")
    }
  }
  out_m$geomask_context_aware <- TRUE
  sf::st_transform(out_m, sf::st_crs(data))
}

#' @noRd
point_is_valid <- function(pt, boundary, forbidden) {
  inside <- TRUE
  if (!is.null(boundary)) {
    inside <- any(sf::st_intersects(pt, boundary, sparse = FALSE))
  }
  if (!inside) return(FALSE)
  if (!is.null(forbidden)) {
    in_forbidden <- any(sf::st_within(pt, forbidden, sparse = FALSE))
    if (in_forbidden) return(FALSE)
  }
  TRUE
}
