#' Puntos sintéticos de casos (Región Metropolitana)
#'
#' Datos simulados inspirados en la distribución de establecimientos de salud de
#' Santiago; no corresponden a casos reales identificables.
#'
#' @format Un objeto `sf` con 120 filas y variables:
#' \describe{
#'   \item{id}{Identificador sintético del caso}
#'   \item{fecha}{Fecha simulada de notificación}
#'   \item{edad_grupo}{Grupo etario}
#'   \item{sexo}{Sexo registrado (simulado)}
#'   \item{comuna}{Comuna (RM)}
#' }
#' @source Generado en `data-raw/prepare_data.R` a partir de datos abiertos DEIS (RM).
"geomask_pts"

#' Límites comunales simplificados (RM)
#'
#' Polígonos construidos como envolvente convexa por comuna a partir de
#' establecimientos de salud públicos (referencia espacial, no límites oficiales).
#'
#' @format Un objeto `sf` POLYGON con columnas `zone_id`, `comuna`, `pop`.
"geomask_boundary"

#' Establecimientos de salud de ejemplo (RM, submuestra)
#'
#' @format Un objeto `sf` POINT con metadatos mínimos para tutoriales.
"geomask_services"

#' Grilla de densidad poblacional sintética (RM)
#'
#' @format Objeto `sf` POLYGON con columnas `cell_id`, `density`.
"geomask_pop"
