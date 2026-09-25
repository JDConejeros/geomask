#' Configuración reproducible de geomasking
#'
#' @param method Nombre del método (`"donut"`, `"gaussian"`, etc.).
#' @param params Lista de parámetros del método.
#' @param seed Semilla.
#' @param boundary Ruta o objeto sf para límite (opcional).
#'
#' @return Objeto S3 `geomask_config`.
#' @export
geomask_config <- function(method = "donut", params = list(), seed = NULL, boundary = NULL) {
  structure(
    list(
      method = method,
      params = params,
      seed = seed,
      boundary = boundary,
      created = Sys.time()
    ),
    class = "geomask_config"
  )
}

#' Escribir configuración a YAML
#' @param cfg Objeto `geomask_config`.
#' @param path Ruta de salida.
#' @export
write_geomask_config <- function(cfg, path) {
  if (!inherits(cfg, "geomask_config")) {
    cli::cli_abort("{.arg cfg} debe ser un objeto {.cls geomask_config}.")
  }
  if (!requireNamespace("yaml", quietly = TRUE)) {
    cli::cli_abort("Instale {.pkg yaml} para serializar configuraciones.")
  }
  yaml::write_yaml(cfg, path)
  invisible(path)
}

#' Leer configuración YAML
#' @param path Ruta al archivo.
#' @export
read_geomask_config <- function(path) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    cli::cli_abort("Instale {.pkg yaml} para leer configuraciones.")
  }
  cfg <- yaml::read_yaml(path)
  class(cfg) <- c("geomask_config", class(cfg))
  cfg
}

#' Aplicar configuración a datos
#' @param data Objeto `sf` POINT.
#' @param cfg Objeto `geomask_config`.
#' @export
apply_mask <- function(data, cfg) {
  if (!inherits(cfg, "geomask_config")) {
    cli::cli_abort("{.arg cfg} debe ser {.cls geomask_config}.")
  }
  fn <- switch(
    cfg$method,
    donut = mask_donut,
    gaussian = mask_gaussian,
    random_perturbation = mask_random_perturbation,
    density_displacement = mask_density_displacement,
    location_swapping = mask_location_swapping,
    graph_k_component = mask_graph_k_component,
    cli::cli_abort("Método desconocido: {.val {cfg$method}}")
  )
  params <- cfg$params
  if (!is.null(cfg$seed)) params$seed <- cfg$seed
  if (!is.null(cfg$boundary) && inherits(cfg$boundary, "sf")) {
    return(do.call(mask_context_aware, c(list(data = data, method = fn, boundary = cfg$boundary), params)))
  }
  do.call(fn, c(list(data = data), params))
}

#' @export
print.geomask_config <- function(x, ...) {
  cat("<geomask_config method =", x$method, ">\n")
  invisible(x)
}
