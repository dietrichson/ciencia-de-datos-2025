# =============================================================================
# Metacritic Album Scraper
# =============================================================================
# Purpose: Scrape album data from Metacritic's new releases page
# Author: Data Science Seminar
# Date: 2025-10-28
#
# URL: https://www.metacritic.com/browse/albums/release-date/new-releases/date?view=detailed
#
# Dependencies: httr2, xml2, rvest, tidyverse
# =============================================================================

# Load required libraries
library(httr2)
library(xml2)
library(rvest)
library(tidyverse)

# =============================================================================
# Helper Functions
# =============================================================================

#' Clean and extract text from HTML nodes
#'
#' @param node An xml_node object
#' @return A cleaned text string or NA if node is missing
clean_text <- function(node) {
  if (length(node) == 0) {
    return(NA_character_)
  }
  text <- html_text(node, trim = TRUE)
  if (text == "" || text == "tbd") {
    return(NA_character_)
  }
  return(text)
}

#' Extract and clean numeric scores
#'
#' @param node An xml_node object containing score
#' @return Numeric score or NA
extract_score <- function(node) {
  if (length(node) == 0) {
    return(NA_real_)
  }
  text <- html_text(node, trim = TRUE)
  if (text == "tbd" || text == "") {
    return(NA_real_)
  }
  score <- as.numeric(text)
  return(score)
}

#' Build full URL from relative path
#'
#' @param relative_url Character string of relative URL
#' @return Full URL string
build_full_url <- function(relative_url) {
  if (is.na(relative_url) || relative_url == "") {
    return(NA_character_)
  }
  if (startsWith(relative_url, "http")) {
    return(relative_url)
  }
  paste0("https://www.metacritic.com", relative_url)
}

# =============================================================================
# Main Scraping Function
# =============================================================================

#' Scrape album data from a single Metacritic page
#'
#' @param url Character string of the URL to scrape
#' @param delay Numeric value for delay between requests in seconds (default: 2)
#' @param verbose Logical indicating whether to print progress messages
#' @return A tibble containing album data with columns:
#'   - album_title: Name of the album
#'   - artist_name: Name of the artist
#'   - metascore: Critic score (0-100)
#'   - user_score: User score (0-10)
#'   - release_date: Release date as character
#'   - summary: Album description/summary
#'   - album_url: Full URL to album page
#'   - cover_image_url: Full URL to album cover image
#'   - scraped_at: Timestamp of when data was scraped
#'
#' @examples
#' \dontrun{
#' # Scrape the main new releases page
#' albums <- scrape_metacritic_albums()
#'
#' # Scrape with custom settings
#' albums <- scrape_metacritic_albums(
#'   url = "https://www.metacritic.com/browse/albums/...",
#'   delay = 3,
#'   verbose = TRUE
#' )
#' }
#'
#' @export
scrape_metacritic_albums <- function(
    url = "https://www.metacritic.com/browse/albums/release-date/new-releases/date?view=detailed",
    delay = 2,
    verbose = TRUE) {

  # Validate inputs
  if (!is.character(url) || length(url) != 1) {
    stop("URL must be a single character string")
  }

  if (!is.numeric(delay) || delay < 0) {
    stop("Delay must be a non-negative number")
  }

  if (verbose) {
    cat(sprintf("Starting scrape of: %s\n", url))
    cat(sprintf("Politeness delay: %s seconds\n\n", delay))
  }

  # Add politeness delay (except for first request)
  if (delay > 0) {
    Sys.sleep(delay)
  }

  # Make HTTP request with proper headers
  tryCatch({
    # Build request with httr2
    response <- request(url) %>%
      req_user_agent("R Web Scraper for Educational Purposes (unsam.edu.ar)") %>%
      req_headers(
        "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language" = "en-US,en;q=0.9"
      ) %>%
      req_timeout(30) %>%
      req_perform()

    # Check response status
    if (resp_status(response) != 200) {
      stop(sprintf("HTTP request failed with status: %d", resp_status(response)))
    }

    # Parse HTML content
    page <- resp_body_html(response)

    if (verbose) {
      cat("Page successfully downloaded. Parsing album data...\n\n")
    }

  }, error = function(e) {
    stop(sprintf("Failed to fetch page: %s", e$message))
  })

  # Extract all album entries (each in a <tr> tag)
  album_rows <- html_elements(page, "tr")

  if (length(album_rows) == 0) {
    warning("No album entries found on page. Website structure may have changed.")
    return(tibble(
      album_title = character(),
      artist_name = character(),
      metascore = numeric(),
      user_score = numeric(),
      release_date = character(),
      summary = character(),
      album_url = character(),
      cover_image_url = character(),
      scraped_at = as.POSIXct(character())
    ))
  }

  if (verbose) {
    cat(sprintf("Found %d potential album entries. Extracting data...\n", length(album_rows)))
  }

  # Extract data from each album row
  albums_list <- map(album_rows, function(row) {
    tryCatch({
      # Extract album title
      title_node <- html_element(row, "h3")
      album_title <- clean_text(title_node)

      # Skip rows without titles (likely header/footer rows)
      if (is.na(album_title)) {
        return(NULL)
      }

      # Extract artist name
      artist_node <- html_element(row, "div.artist")
      artist_name <- clean_text(artist_node)

      # Extract Metascore (critic score)
      metascore_node <- html_element(row, "div.metascore_w")
      metascore <- extract_score(metascore_node)

      # Extract user score (different class: metascore_w user)
      user_score_node <- html_element(row, "div.metascore_w.user")
      user_score <- extract_score(user_score_node)

      # Extract release date
      release_date_node <- html_element(row, "div.clamp-details span")
      release_date <- clean_text(release_date_node)

      # Extract summary
      summary_node <- html_element(row, "div.summary")
      summary <- clean_text(summary_node)

      # Extract album URL
      url_node <- html_element(row, "a.title")
      album_url <- html_attr(url_node, "href")
      album_url <- build_full_url(album_url)

      # Extract cover image URL
      img_node <- html_element(row, "img")
      cover_image_url <- html_attr(img_node, "src")

      # Return as named list
      list(
        album_title = album_title,
        artist_name = artist_name,
        metascore = metascore,
        user_score = user_score,
        release_date = release_date,
        summary = summary,
        album_url = album_url,
        cover_image_url = cover_image_url,
        scraped_at = Sys.time()
      )

    }, error = function(e) {
      # Skip problematic rows silently
      return(NULL)
    })
  })

  # Remove NULL entries (rows that failed or had no data)
  albums_list <- compact(albums_list)

  if (length(albums_list) == 0) {
    warning("No valid album data could be extracted. Website structure may have changed.")
    return(tibble(
      album_title = character(),
      artist_name = character(),
      metascore = numeric(),
      user_score = numeric(),
      release_date = character(),
      summary = character(),
      album_url = character(),
      cover_image_url = character(),
      scraped_at = as.POSIXct(character())
    ))
  }

  # Convert to tibble
  albums_df <- bind_rows(albums_list)

  if (verbose) {
    cat(sprintf("\n✓ Successfully extracted %d albums\n", nrow(albums_df)))
    cat(sprintf("✓ Metascores available: %d albums\n", sum(!is.na(albums_df$metascore))))
    cat(sprintf("✓ User scores available: %d albums\n", sum(!is.na(albums_df$user_score))))
  }

  return(albums_df)
}

# =============================================================================
# Multi-Page Scraping Function
# =============================================================================

#' Scrape multiple pages of album data from Metacritic
#'
#' @param base_url Character string of the base URL (without page parameter)
#' @param pages Integer vector of page numbers to scrape
#' @param delay Numeric value for delay between requests in seconds
#' @param verbose Logical indicating whether to print progress messages
#' @return A tibble containing combined album data from all pages
#'
#' @examples
#' \dontrun{
#' # Scrape first 3 pages
#' albums <- scrape_multiple_pages(pages = 0:2, delay = 3)
#' }
#'
#' @export
scrape_multiple_pages <- function(
    base_url = "https://www.metacritic.com/browse/albums/release-date/new-releases/date",
    pages = 0:2,
    delay = 2,
    verbose = TRUE) {

  if (verbose) {
    cat(sprintf("=== Scraping %d pages from Metacritic ===\n\n", length(pages)))
  }

  # Scrape each page
  all_albums <- map_dfr(pages, function(page_num) {
    if (verbose) {
      cat(sprintf("--- Page %d ---\n", page_num))
    }

    # Construct URL with page parameter
    url <- sprintf("%s?page=%d&view=detailed", base_url, page_num)

    # Scrape page
    albums <- scrape_metacritic_albums(
      url = url,
      delay = delay,
      verbose = verbose
    )

    # Add page number to data
    albums <- albums %>%
      mutate(page_number = page_num, .before = 1)

    if (verbose) {
      cat("\n")
    }

    return(albums)
  })

  if (verbose) {
    cat(sprintf("\n=== Scraping Complete ===\n"))
    cat(sprintf("Total albums collected: %d\n", nrow(all_albums)))
    cat(sprintf("Unique albums: %d\n", n_distinct(all_albums$album_url)))
  }

  return(all_albums)
}

# =============================================================================
# Data Export Functions
# =============================================================================

#' Save scraped album data to CSV file
#'
#' @param albums_df Tibble of album data
#' @param filename Character string for output filename
#' @param path Character string for output directory (default: "data")
#' @return Invisible NULL
#'
#' @export
save_albums_to_csv <- function(albums_df, filename = "metacritic_albums.csv", path = "data") {
  # Create directory if it doesn't exist
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }

  full_path <- file.path(path, filename)
  write_csv(albums_df, full_path)

  cat(sprintf("✓ Data saved to: %s\n", full_path))
  cat(sprintf("  Rows: %d | Columns: %d\n", nrow(albums_df), ncol(albums_df)))

  invisible(NULL)
}

# =============================================================================
# Example Usage
# =============================================================================

#' Run example scraping workflow
#'
#' This function demonstrates how to use the scraper and is useful for testing.
#' It scrapes the first page of new album releases and saves the data.
#'
#' @export
run_example <- function() {
  cat("=== Metacritic Album Scraper - Example Usage ===\n\n")

  # Scrape first page
  cat("1. Scraping first page of new releases...\n\n")
  albums <- scrape_metacritic_albums(verbose = TRUE)

  # Display summary
  cat("\n2. Data Summary:\n")
  print(glimpse(albums))

  # Display first few albums
  cat("\n3. Sample Data (first 3 albums):\n")
  print(albums %>%
    select(album_title, artist_name, metascore, user_score, release_date) %>%
    head(3))

  # Save to CSV
  cat("\n4. Saving data to CSV...\n")
  save_albums_to_csv(albums)

  cat("\n=== Example Complete ===\n")

  invisible(albums)
}

# =============================================================================
# Script Execution (when run directly)
# =============================================================================

# Uncomment the following line to run the example when sourcing this script:
# run_example()

# Or use individual functions:
# albums <- scrape_metacritic_albums()
# save_albums_to_csv(albums, filename = "albums_2025-10-28.csv")
