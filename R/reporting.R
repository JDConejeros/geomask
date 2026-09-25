#' Reporte estructurado de un pipeline de geomasking
#'
#' @param original,masked Objetos `sf` POINT.
#' @param method Etiqueta del método.
#' @param parameters Lista de parámetros usados.
#' @param privacy_r Radio para k-anonimato en el reporte.
#' @param d_min Umbral para LPM.
#' @param k_target k-anonimato local deseado para LPM.
#'
#' @return Lista con metadatos, métricas y texto de citación sugerido.
#' @export
mask_report <- function(original,
                        masked,
                        method,
                        parameters = list(),
                        privacy_r = 500,
                        d_min = 300,
                        k_target = 5) {
  pair <- align_original_masked(original, masked)
  k_info <- privacy_k_anonymity(pair$masked, r = privacy_r)
  risk <- privacy_disclosure_risk(pair$original, pair$masked, method = "nn")
  util <- utility_spatial_stats(pair$original, pair$masked)
  lpm <- privacy_location_protection(
    pair$original,
    pair$masked,
    d_min = d_min,
    r = privacy_r,
    k_target = k_target
  )
  citation_text <- paste0(
    "Las coordenadas fueron enmascaradas con el método '", method,
    "' (paquete geomask v", utils::packageVersion("geomask"), ", ",
    format(Sys.Date(), "%Y-%m-%d"), "). ",
    "k-anonimato espacial mínimo (r=", privacy_r, " m): ", k_info$k_global, ". ",
    "Riesgo medio de reidentificación (NN): ", round(risk$risk_mean, 3), ". ",
    "Índice de protección de ubicación (LPM): ", round(lpm$lpm, 3), "."
  )
  list(
    method = method,
    parameters = parameters,
    n_points = nrow(pair$masked),
    privacy = list(
      k_anonymity = k_info$k_global,
      disclosure_risk = risk$risk_mean,
      location_protection = lpm$lpm
    ),
    utility = list(
      ks_nnd = util$nnd$ks_statistic,
      delta_ripley_k = util$ripley_k$delta_integral
    ),
    timestamp = Sys.time(),
    citation_text = citation_text
  )
}
