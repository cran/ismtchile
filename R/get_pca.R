#' @title Calcular análisis de componentes principales -- Calculate Principal Components Analysis
#'
#' @description Cálculo de análisis de componentes principales en base a las 4 vatriables principales del ISMT. La función asume que la base de datos ha pasado por \code{precalc()}, ya que requiere los puntajes normalizados por variable. || || Calculation of principal components analysis based on the 4 main variables of ISMT. Assumes the database has been through \code{precalc()}, as it rqeuires the normalized scores by variable.
#'
#' @param df objeto \code{data.frame} con la informaión de puntajes normalizados. || || \code{data.frame} object with the normalized scores.
#' @param esc string. Nombre de la variable con el puntaje de escolaridad del jefe de hogar. Default is \code{ptje_esc} || || string. Name of the field with the scholarship score for the home head. Default is \code{ptje_esc}.
#' @param hacin string. Nombre del campo con el puntaje de hacinamiento. Default es \code{ptje_hacin}. || || string. Name of the field with the overcrowding score. Default is \code{ptje_hacin}.
#' @param mat string. Nombre del campo con el puntaje de materialidad de la vivienda. Default es \code{ptje_mater}. || || string. Name of the field with the dwelling material score. Default is \code{ptje_mater.}
#' @param alleg string. Nombre del campo con el puntaje de allegamiento. Default is \code{ptje_alleg}. || || string. Name of the field with the relative crowding score. Default is \code{ptje_alleg}.
#'
#' @import stringr
#' @import dplyr
#' @importFrom stats D na.omit prcomp quantile
#'
#' @return objeto \code{data.frame} con el cálculo de componentes principales. || || \code{data.frame} object with the principal components analysis calculation.
#' @export get_pca
#'
#' @examples
#'  data(c17_example)
#'  clean <- c17_example |> literalize(2017) |> cleanup() |> precalc() |> get_pca()

get_pca <- function(df, esc = 'ptje_esc', hacin = 'ptje_hacin', mat = 'ptje_mater', alleg = 'ptje_alleg') {

  ptje_hacin <- NULL
  ptje_esc <- NULL
  ptje_mater <- NULL
  ptje_alleg <- NULL
  PC1 <- NULL
  ismt_p <- NULL

  normvar <- function(x) {

    (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))

  }

  names(df)[names(df) == str_glue('{hacin}')] <- 'ptje_hacin'
  names(df)[names(df) == str_glue('{esc}')] <- 'ptje_esc'
  names(df)[names(df) == str_glue('{mat}')] <- 'ptje_mater'
  names(df)[names(df) == str_glue('{alleg}')] <- 'ptje_alleg'

  tempdf <- stats::na.omit(df) |>
    dplyr::select(

      ptje_hacin, ptje_esc, ptje_mater, ptje_alleg

    )

  pca <- stats::prcomp(tempdf)

  loadings <- as.data.frame(pca$rotation) |>
    dplyr::select(

      PC1

    )

  pc1score <- as.data.frame(t(loadings))

  pc1score <- pc1score |>
    dplyr::mutate(

      ptje_esc = abs(ptje_esc),
      ptje_hacin = abs(ptje_hacin),
      ptje_alleg = abs(ptje_alleg),
      ptje_mater = abs(ptje_mater)

    )

  victor <- pca$sdev ^ 2 / sum(pca$sdev ^ 2)

  propvar <- victor[1]

  pesc <- pc1score$ptje_esc * propvar
  phac <- pc1score$ptje_hacin * propvar
  pviv <- pc1score$ptje_mater * propvar
  pall <- pc1score$ptje_alleg * propvar

  calculations <- df |>
    dplyr::mutate(

      ismt_p = (ptje_esc * pesc) + (ptje_hacin * phac) + (ptje_mater * pviv) + (ptje_alleg * pall)

    ) |>
    dplyr::filter(

      !is.na(ismt_p)

    ) |>
    dplyr::mutate(

      ismt_pn = normvar(ismt_p)

    )

  return(calculations)

}

