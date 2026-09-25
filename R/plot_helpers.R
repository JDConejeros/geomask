#' Mapa comparativo original vs enmascarado
#'
#' Función auxiliar para vignettes; requiere `ggplot2` y `sf`.
#'
#' @param original,masked Objetos `sf` POINT.
#' @param boundary Polígono opcional de contexto.
#' @param title Título del gráfico.
#'
#' @return Objeto `ggplot`.
#' @export
plot_mask_comparison <- function(original, masked, boundary = NULL, title = "Geomasking") {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Instale {.pkg ggplot2} para graficar.")
  }
  o <- sf::st_transform(original, 32719)
  m <- sf::st_transform(masked, sf::st_crs(o))
  o$layer <- "Original"
  m$layer <- "Enmascarado"
  combined <- rbind(o[, c("layer", "geometry")], m[, c("layer", "geometry")])
  p <- ggplot2::ggplot(combined) +
    ggplot2::geom_sf(ggplot2::aes(color = .data$layer), alpha = 0.7, size = 0.8) +
    ggplot2::scale_color_manual(values = c("Original" = "#2166AC", "Enmascarado" = "#B2182B")) +
    ggplot2::labs(title = title, color = NULL) +
    ggplot2::theme_minimal()
  if (!is.null(boundary)) {
    b <- sf::st_transform(boundary, sf::st_crs(o))
    p <- p + ggplot2::geom_sf(data = b, fill = NA, color = "grey40", linewidth = 0.3)
  }
  p
}

#' Distribución de desplazamientos
#' @param masked Objeto enmascarado con `geomask_displacement_m`.
#' @export
plot_displacement_distribution <- function(masked) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Instale {.pkg ggplot2}.")
  }
  if (!"geomask_displacement_m" %in% names(masked)) {
    cli::cli_abort("El objeto no contiene {.field geomask_displacement_m}.")
  }
  ggplot2::ggplot(masked, ggplot2::aes(x = .data$geomask_displacement_m)) +
    ggplot2::geom_histogram(bins = 30, fill = "#4393C3", color = "white") +
    ggplot2::labs(
      title = "Distribución de desplazamientos",
      x = "Distancia (m)",
      y = "Frecuencia"
    ) +
    ggplot2::theme_minimal()
}
