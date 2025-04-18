#' goxygen
#'
#' Documentation function which extracts a full model documentation from a
#' modularized gams model. The function extracts comments used as documentation,
#' extracts code and can extract and convert GAMS equations as latex code. Output
#' is returned in Markdown, HTML and PDF format.
#'
#' @note Documentation lines in the code must start with *' to be detected as documentation.
#' Identifier at the beginning of each block describe what kind of documentation is given.
#' All identifiers start with @ followed by the name of the identifier. Currently, following
#' identifiers are available
#' \itemize{
#'  \item @title Title
#'  \item @authors List of authors
#'  \item @description Model description (only the documentation text will be interpreted)
#'  \item @equations Equation description (documentation text will be extracted and gams equations
#'  will be converted to latex code)
#'  \item @code Code description (documentation text and code will be extracted)
#'  \item @limitations details about limitations of an implementation
#'  \item @stop everything following will be ignored until the next identifier is mentioned again. Useful
#'  to stop a section
#' }
#'
#' In addition you can store a model logo (100px height, 100px weight) as \code{logo.png} in the main
#' folder of the model which then will be used in the HTML version of the documentation.
#' If you want to add citations to your documentation you can do so by adding a bibtex file with
#' the name literature.bib in the main folder of the model. To link these references in the text
#' you can use the syntax \code{@<id>} in which "<id>" stands for the identifier given to the
#' corresponding bibtex entry.
#'
#' @param path path to the model to be documented
#' @param docfolder folder the documentation should be written to relative to model folder
#' @param cache Boolean to allow read data from existing cache file
#' @param htmlStyle visualization style to be used for the HTML creation. Currently available styles are
#' "classic" and "ming". Ignored for outputs other than HTML. Can be extended by additional templates stored in the
#' \code{templatefolder} in the form \code{<style>.html5} together with a subfolder with supplementary files
#' and the name of the style \code{<style>} (both need to be provided).
#' The preinstalled ming template \code{system.file("templates","ming.css",package="goxygen")}  and
#' \code{system.file("templates","ming.html5",package="goxygen")} can serve as a starting point for own
#' templates.
#' @param texStyle visualization style to be used for the Latex/PDF creation. Currently only "classic" style is
#' available. Ignored for outputs other than Latex/PDF. Can be extended by additional templates stored in the
#' \code{templatefolder} in the format \code{<style>.latex}. Classic template
#' \code{system.file("templates","classic.latex",package="goxygen")} can serve as a starting point for own
#' templates.
#' @param templatefolder Folder in which goxygen will search for template files in addition to the pre-installed ones.
#' @param output List of output to be written, available are "html","pdf" and "tex"
#' @param cff path to a citation file in citation-file-format (ignored if not existing)
#' @param modularCode Boolean deciding whether code should be interpreted as modular GAMS code (only av)
#' @param unitPattern pattern that is usedto identify the unit in the description, default =c("\\(","\\)")
#' @param includeCore boolean whether core should be included or not, default=FALSE
#' @param mainfile main file of the model
#' @param startType input parameter for \code{\link{createListModularCode}}, default = "equations"
#' @param ... optional arguments to \code{\link[gms]{interfaceplot}}, passed via
#' \code{\link[gms]{modules_interfaceplot}}.
#'
#' @author Jan Philipp Dietrich
#' @importFrom stringi stri_extract_all_regex stri_replace_all_regex stri_write_lines
#' @importFrom gms codeCheck modules_interfaceplot is.modularGAMS
#' @importFrom pander pandoc.table.return
#' @importFrom citation read_cff cff2bibentry
#' @importFrom yaml as.yaml
#' @importFrom utils tail toBibtex capture.output
#' @importFrom withr local_dir
#' @seealso \code{\link[gms]{codeCheck}},\code{\link[gms]{interfaceplot}}
#' @examples
#' # make sure that pandoc is available
#' if (check_pandoc()) {
#'   # run goxygen for dummy model and store documentation as HTML in a temporary directory
#'   docfolder <- paste0(tempdir(), "/doc")
#'   goxygen(system.file("dummymodel", package = "gms"),  docfolder = docfolder, output = "html")
#' }
#' @export
goxygen <- function(path = ".",
                    docfolder = "doc",
                    cache = FALSE,
                    output = c("html", "tex", "pdf"),
                    htmlStyle = "ming",
                    texStyle = "classic",
                    templatefolder = ".",
                    cff = "CITATION.cff",
                    modularCode = is.modularGAMS(),
                    unitPattern = c("\\(", "\\)"),
                    includeCore = FALSE,
                    mainfile = "main.gms",
                    startType = "equations",
                    ...) {
  local_dir(path)

  templatefolder <- normalizePath(templatefolder)

  if (file.exists(cff)) {
    citation <- read_cff(cff)
  } else {
    citation <- NULL
  }

  if (!dir.exists(docfolder)) dir.create(docfolder, recursive = TRUE)
  if (file.exists("literature.bib")) file.copy("literature.bib", paste0(docfolder, "/literature.bib"), overwrite = TRUE)
  if (dir.exists(file.path(docfolder, "markdown"))) unlink(file.path(docfolder, "markdown"), recursive = TRUE)

  copyimages <- function(docfolder, paths) {
    imagefolder <- paste0(docfolder, "/images")
    if (!dir.exists(imagefolder)) dir.create(imagefolder, recursive = TRUE)
    file.copy(Sys.glob(paths), imagefolder, overwrite = TRUE)
  }

  if (modularCode) {
    copyimages(docfolder, paths = c("*.png",
                                    "*.jpg",
                                    "modules/*/*.png",
                                    "modules/*/*/*.png",
                                    "modules/*/*.jpg",
                                    "modules/*/*/*.jpg"))
    cachefile <- paste0(docfolder, "/doc.rds")
    if (cache && file.exists(cachefile)) {
      cache <- readRDS(cachefile)
      cc <- cache$cc
      interfaces <- cache$interfaces
    } else {
      cc <- codeCheck(details = TRUE)
      interfaces <- modules_interfaceplot(cc$interfaceInfo,
                                          targetfolder = paste0(docfolder, "/images"),
                                          writetable = FALSE,
                                          includeCore = includeCore,
                                          ...)
      saveRDS(list(cc = cc, interfaces = interfaces), cachefile)
    }
    full <- createListModularCode(cc = cc, interfaces = interfaces, path = ".", citation = citation,
                                  unitPattern = unitPattern, includeCore = includeCore,
                                  mainfile = mainfile, docfolder = docfolder,
                                  startType = startType)
  } else {
    copyimages(docfolder, paths = list.files(pattern = "\\.(jpg|png)$", recursive = TRUE))
    full <- createListSimpleCode(path = ".", citation = citation, mainfile = mainfile)
  }

  local_dir(docfolder)

  if (any(nomatch <- !(output %in% c("html", "pdf", "tex")))) {
    warning(paste0("No output format '", output[nomatch], "' available. It will be ignored."))
  }
  buildMarkdown(full)
  if ("html" %in% output) buildHTML(supplementary = "images", citation = citation, style = htmlStyle,
                                    templatefolder = templatefolder)
  if ("tex" %in% output || "pdf" %in% output) buildTEX(pdf = ("pdf" %in% output), citation = citation, style = texStyle,
                                                       templatefolder = templatefolder)
}
