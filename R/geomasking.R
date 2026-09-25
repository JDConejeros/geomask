#' Perturbación aleatoria uniforme en disco
#'
#' Desplaza cada punto en dirección y distancia uniformes dentro de un radio máximo.
#'
#' @param data Objeto `sf` con geometrías POINT.
#' @param max_r Radio máximo de desplazamiento (metros si CRS proyectado).
#' @param seed Semilla opcional para reproducibilidad.
#'
#' @return Objeto `sf` con columnas `geomask_method`, `geomask_seed`, `geomask_displacement_m`.
#' @export
#' @references
#' Kwan, M.-P., Casas, I., & Schmitz, B. C. (2004). Protection of geoprivacy and
#' accuracy of spatial information. *Cartographica*, 39(2), 15–28.
#' @examples
#' data(geomask_pts, package = "geomask")
#' set.seed(1)
#' masked <- mask_random_perturbation(geomask_pts, max_r = 800, seed = 42)
#' masked$geomask_displacement_m[1:3]
mask_random_perturbation <- function(data, max_r, seed = NULL) {
  validate_sf_points(data)
  if (!is.numeric(max_r) || length(max_r) != 1 || max_r <= 0) {
    cli::cli_abort("{.arg max_r} debe ser un número positivo.")
  }
  set_geomask_seed(seed)
  data_m <- ensure_metric_crs(data)
  n <- nrow(data_m)
  offsets <- polar_offset(n, r_min = 0, r_max = max_r)
  out <- apply_point_offsets(data_m, offsets, "random_perturbation", seed)
  # devolver al CRS original para no sorprender al usuario
  sf::st_transform(out, sf::st_crs(data))
}

#' Geomasking tipo donut (anillo)
#'
#' Garantiza una distancia mínima de desplazamiento al punto original.
#'
#' @param data Objeto `sf` POINT.
#' @param min_r Distancia mínima (metros en CRS métrico).
#' @param max_r Distancia máxima.
#' @param seed Semilla opcional.
#'
#' @return Objeto `sf` enmascarado.
#' @export
#' @references
#' Allshouse, W. B., et al. (2010). Geomasking sensitive health data and privacy
#' protection. *Spatial and Spatio-temporal Epidemiology*, 1(2-3), 101–110.
#' @examples
#' data(geomask_pts, package = "geomask")
#' masked <- mask_donut(geomask_pts, min_r = 300, max_r = 1200, seed = 7)
mask_donut <- function(data, min_r, max_r, seed = NULL) {
  validate_sf_points(data)
  if (min_r >= max_r) {
    cli::cli_abort("{.arg min_r} debe ser estrictamente menor que {.arg max_r}.")
  }
  if (min_r < 0 || max_r <= 0) {
    cli::cli_abort("Los radios deben ser positivos.")
  }
  if (inherits(max_r, "units")) {
    min_r <- as.numeric(units::drop_units(min_r))
    max_r <- as.numeric(units::drop_units(max_r))
  }
  set_geomask_seed(seed)
  data_m <- ensure_metric_crs(data)
  n <- nrow(data_m)
  offsets <- polar_offset(n, r_min = min_r, r_max = max_r)
  out <- apply_point_offsets(data_m, offsets, "donut", seed)
  sf::st_transform(out, sf::st_crs(data))
}

#' Geomasking gaussiano (perturbación normal)
#'
#' @param data Objeto `sf` POINT.
#' @param sigma Desviación estándar del desplazamiento en x e y (metros).
#' @param seed Semilla opcional.
#'
#' @return Objeto `sf` enmascarado.
#' @export
#' @examples
#' data(geomask_pts, package = "geomask")
#' masked <- mask_gaussian(geomask_pts, sigma = 400, seed = 3)
mask_gaussian <- function(data, sigma, seed = NULL) {
  validate_sf_points(data)
  if (!is.numeric(sigma) || length(sigma) != 1 || sigma <= 0) {
    cli::cli_abort("{.arg sigma} debe ser un número positivo.")
  }
  set_geomask_seed(seed)
  data_m <- ensure_metric_crs(data)
  n <- nrow(data_m)
  offsets <- cbind(
    dx = stats::rnorm(n, sd = sigma),
    dy = stats::rnorm(n, sd = sigma)
  )
  out <- apply_point_offsets(data_m, offsets, "gaussian", seed)
  sf::st_transform(out, sf::st_crs(data))
}

#' Desplazamiento donut escalado por densidad poblacional
#'
#' @param data Objeto `sf` POINT.
#' @param pop_layer Raster (`SpatRaster`) o polígonos `sf` con columna de densidad.
#' @param density_col Nombre de columna si `pop_layer` es `sf`.
#' @param r_base Radio máximo base (m).
#' @param r_min_base Radio mínimo base (m).
#' @param scale_fun `"logistic"`, `"linear"` o función `f(ratio)` vectorizada.
#' @param s_min,s_max Límites del factor de escala.
#' @param seed Semilla opcional.
#'
#' @return Objeto `sf` enmascarado.
#' @export
mask_density_displacement <- function(data,
                                      pop_layer,
                                      density_col = "density",
                                      r_base = 1000,
                                      r_min_base = 200,
                                      scale_fun = c("logistic", "linear"),
                                      s_min = 0.5,
                                      s_max = 2.5,
                                      seed = NULL) {
  validate_sf_points(data)
  scale_fun <- match.arg(scale_fun)
  data_m <- ensure_metric_crs(data)
  dens <- extract_local_density(data_m, pop_layer, density_col)
  ratio <- dens / mean(dens, na.rm = TRUE)
  ratio[is.na(ratio)] <- 1
  scale_vec <- switch(
    scale_fun,
    linear = s_min + (s_max - s_min) * pmin(pmax(ratio, 0), 3) / 3,
    logistic = {
      z <- (log(pmax(dens, 1e-6)) - mean(log(pmax(dens, 1e-6)), na.rm = TRUE)) /
        stats::sd(log(pmax(dens, 1e-6)), na.rm = TRUE)
      z[is.na(z)] <- 0
      s_min + (s_max - s_min) * stats::pnorm(z)
    }
  )
  set_geomask_seed(seed)
  n <- nrow(data_m)
  offsets <- matrix(0, n, 2)
  for (i in seq_len(n)) {
    off <- polar_offset(1, r_min = r_min_base * scale_vec[i], r_max = r_base * scale_vec[i])
    offsets[i, ] <- off
  }
  out <- apply_point_offsets(data_m, offsets, "density_displacement", seed)
  out$geomask_density_scale <- scale_vec
  sf::st_transform(out, sf::st_crs(data))
}

#' @noRd
extract_local_density <- function(data_m, pop_layer, density_col) {
  if (inherits(pop_layer, "SpatRaster")) {
    if (!requireNamespace("terra", quietly = TRUE)) {
      cli::cli_abort("Se requiere el paquete {.pkg terra} para capas raster.")
    }
    pts <- terra::vect(data_m)
    vals <- terra::extract(pop_layer, pts)[, 2]
    return(as.numeric(vals))
  }
  if (inherits(pop_layer, "sf")) {
    pop_m <- sf::st_transform(pop_layer[, density_col, drop = FALSE], sf::st_crs(data_m))
    joined <- sf::st_join(data_m, pop_m, join = sf::st_nearest_feature)
    return(as.numeric(joined[[density_col]]))
  }
  cli::cli_abort("{.arg pop_layer} debe ser {.cls sf} o {.cls SpatRaster}.")
}

#' Agregación adaptativa por zonas (k-anonimato de conteo)
#'
#' Fusiona zonas con menos de `k` puntos y reubica casos al centroide de la zona resultante.
#'
#' @param data Objeto `sf` POINT.
#' @param zones Polígonos `sf` con identificador de zona en `zone_id`.
#' @param zone_id Nombre de columna identificadora en `zones`.
#' @param k Umbral mínimo de puntos por zona.
#' @param merge_method `"centroid_dist"` o `"adjacency"`.
#'
#' @return Objeto `sf` POINT enmascarado (centroides de zona).
#' @export
mask_adaptive_aggregation <- function(data,
                                        zones,
                                        zone_id = "zone_id",
                                        k = 5,
                                        merge_method = c("centroid_dist", "adjacency")) {
  validate_sf_points(data)
  merge_method <- match.arg(merge_method)
  if (!inherits(zones, "sf") || !all(sf::st_geometry_type(zones) %in% c("POLYGON", "MULTIPOLYGON"))) {
    cli::cli_abort("{.arg zones} debe ser un objeto sf de polígonos.")
  }
  if (!zone_id %in% names(zones)) {
    cli::cli_abort("La columna {.field {zone_id}} no existe en {.arg zones}.")
  }
  data_m <- ensure_metric_crs(data)
  zones_m <- sf::st_transform(zones, sf::st_crs(data_m))
  joined <- sf::st_join(data_m, zones_m[, zone_id, drop = FALSE])
  if (any(is.na(joined[[zone_id]]))) {
    cli::cli_warn("Algunos puntos quedaron fuera de las zonas; se excluyen del agregado.")
    joined <- joined[!is.na(joined[[zone_id]]), ]
  }
  zone_counts <- table(joined[[zone_id]])
  zone_map <- as.character(names(zone_counts))
  names(zone_map) <- names(zone_counts)

  merge_until_k <- function(ids, counts) {
    repeat {
      small <- names(counts[counts < k])
      if (length(small) == 0) break
      z <- small[1]
      if (merge_method == "centroid_dist") {
        cents <- sf::st_centroid(zones_m[zones_m[[zone_id]] %in% names(counts), ])
        idx <- match(names(counts), cents[[zone_id]])
        dists <- as.matrix(dist(sf::st_coordinates(cents)[idx, ]))
        rownames(dists) <- colnames(dists) <- names(counts)
        partners <- setdiff(names(counts), z)
        if (length(partners) == 0) break
        target <- partners[which.min(dists[z, partners])]
      } else {
        # adyacencia simple vía sf usando st_touches
        pol <- zones_m[zones_m[[zone_id]] %in% names(counts), ]
        nb <- sf::st_touches(pol)
        idx_z <- which(pol[[zone_id]] == z)
        touch_ids <- pol[[zone_id]][unlist(nb[idx_z])]
        touch_ids <- touch_ids[touch_ids != z]
        if (length(touch_ids) == 0) {
          target <- setdiff(names(counts), z)[1]
        } else {
          target <- touch_ids[which.max(counts[touch_ids])]
        }
      }
      counts[target] <- counts[target] + counts[z]
      counts <- counts[names(counts) != z]
      zone_map[zone_map == z] <- target
    }
    list(map = zone_map, counts = counts)
  }

  res <- merge_until_k(zone_map, as.integer(zone_counts))
  joined$geomask_zone <- res$map[as.character(joined[[zone_id]])]
  # centroides por zona agregada
  cents <- joined |>
    dplyr::group_by(.data$geomask_zone) |>
    dplyr::summarise(geometry = sf::st_union(.data$geometry), .groups = "drop")
  cents <- sf::st_centroid(cents)
  out <- joined
  out$geomask_method <- "adaptive_aggregation"
  out$geomask_seed <- NA_real_
  match_cent <- cents[match(out$geomask_zone, cents$geomask_zone), ]
  sf::st_geometry(out) <- sf::st_geometry(match_cent)
  out$geomask_displacement_m <- sqrt(
    (sf::st_coordinates(out)[, 1] - sf::st_coordinates(joined)[, 1])^2 +
      (sf::st_coordinates(out)[, 2] - sf::st_coordinates(joined)[, 2])^2
  )
  sf::st_transform(out, sf::st_crs(data))
}

#' Intercambio de ubicaciones dentro de grupos contextuales
#'
#' @param data Objeto `sf` POINT.
#' @param context_vars Variables que definen grupos de permutación.
#' @param min_dist Distancia mínima entre ubicación original y asignada (m).
#' @param seed Semilla opcional.
#'
#' @return Objeto `sf` con geometrías permutadas.
#' @export
mask_location_swapping <- function(data, context_vars, min_dist = 0, seed = NULL) {
  validate_sf_points(data)
  if (length(context_vars) == 0) {
    cli::cli_abort("Indique al menos una variable en {.arg context_vars}.")
  }
  missing <- setdiff(context_vars, names(data))
  if (length(missing)) {
    cli::cli_abort("Faltan columnas en {.arg data}: {.field {missing}}.")
  }
  set_geomask_seed(seed)
  data_m <- ensure_metric_crs(data)
  coords <- sf_coords(data_m)
  out <- data_m
  groups <- split(seq_len(nrow(data_m)), interaction(data_m[context_vars], drop = TRUE))
  for (idx in groups) {
    if (length(idx) < 2) next
    perm <- idx
    ok <- FALSE
    for (attempt in seq_len(100)) {
      perm <- sample(idx)
      if (all(perm != idx)) {
        dswap <- sqrt((coords[idx, 1] - coords[perm, 1])^2 + (coords[idx, 2] - coords[perm, 2])^2)
        if (all(dswap >= min_dist)) {
          ok <- TRUE
          break
        }
      }
    }
    if (!ok) {
      cli::cli_warn("Grupo con {length(idx)} puntos: no se logró permutación ideal; se usa la mejor disponible.")
    }
    sf::st_geometry(out)[idx] <- sf::st_geometry(data_m)[perm]
  }
  out$geomask_method <- "location_swapping"
  out$geomask_seed <- seed
  out$geomask_displacement_m <- sqrt(
    (sf::st_coordinates(out)[, 1] - coords[, 1])^2 +
      (sf::st_coordinates(out)[, 2] - coords[, 2])^2
  )
  sf::st_transform(out, sf::st_crs(data))
}
