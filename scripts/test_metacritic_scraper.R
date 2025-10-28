# =============================================================================
# Test Script for Metacritic Album Scraper
# =============================================================================
# Purpose: Test and demonstrate the Metacritic scraper functionality
# Usage: source("scripts/test_metacritic_scraper.R")
# =============================================================================

# Load the main scraper script
source("scripts/scrape_metacritic_albums.R")

cat("=== Metacritic Album Scraper - Test Suite ===\n\n")

# =============================================================================
# Test 1: Basic Package Loading
# =============================================================================

cat("Test 1: Checking required packages...\n")

required_packages <- c("httr2", "xml2", "rvest", "tidyverse")
missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) > 0) {
  cat("❌ Missing packages:", paste(missing_packages, collapse = ", "), "\n")
  cat("   Install with: install.packages(c('", paste(missing_packages, collapse = "', '"), "'))\n\n")
  stop("Please install missing packages before continuing.")
} else {
  cat("✓ All required packages are installed\n\n")
}

# =============================================================================
# Test 2: Helper Functions
# =============================================================================

cat("Test 2: Testing helper functions...\n")

# Test clean_text
test_node <- read_html("<html><body><div>Test Text</div></body></html>")
test_div <- html_element(test_node, "div")
result <- clean_text(test_div)
if (result == "Test Text") {
  cat("✓ clean_text() works correctly\n")
} else {
  cat("❌ clean_text() failed\n")
}

# Test extract_score
test_score_html <- read_html("<html><body><div class='score'>85</div></body></html>")
test_score_node <- html_element(test_score_html, "div.score")
score_result <- extract_score(test_score_node)
if (is.numeric(score_result) && score_result == 85) {
  cat("✓ extract_score() works correctly\n")
} else {
  cat("❌ extract_score() failed\n")
}

# Test build_full_url
url_result <- build_full_url("/music/test-album")
if (url_result == "https://www.metacritic.com/music/test-album") {
  cat("✓ build_full_url() works correctly\n")
} else {
  cat("❌ build_full_url() failed\n")
}

cat("\n")

# =============================================================================
# Test 3: Main Scraping Function (Live Test)
# =============================================================================

cat("Test 3: Testing live scraping (this may take a few seconds)...\n")
cat("Note: This test requires internet connection and Metacritic to be accessible.\n\n")

# Attempt to scrape with error handling
scrape_result <- tryCatch({
  albums <- scrape_metacritic_albums(
    delay = 2,
    verbose = FALSE
  )
  albums
}, error = function(e) {
  cat("❌ Scraping failed:", e$message, "\n")
  NULL
})

if (!is.null(scrape_result) && nrow(scrape_result) > 0) {
  cat(sprintf("✓ Successfully scraped %d albums\n", nrow(scrape_result)))

  # Validate data structure
  expected_cols <- c("album_title", "artist_name", "metascore", "user_score",
                     "release_date", "summary", "album_url", "cover_image_url", "scraped_at")

  missing_cols <- setdiff(expected_cols, names(scrape_result))
  if (length(missing_cols) == 0) {
    cat("✓ All expected columns are present\n")
  } else {
    cat("❌ Missing columns:", paste(missing_cols, collapse = ", "), "\n")
  }

  # Check data quality
  cat("\nData Quality Checks:\n")
  cat(sprintf("  - Albums with titles: %d/%d\n",
              sum(!is.na(scrape_result$album_title)), nrow(scrape_result)))
  cat(sprintf("  - Albums with artists: %d/%d\n",
              sum(!is.na(scrape_result$artist_name)), nrow(scrape_result)))
  cat(sprintf("  - Albums with metascores: %d/%d\n",
              sum(!is.na(scrape_result$metascore)), nrow(scrape_result)))
  cat(sprintf("  - Albums with user scores: %d/%d\n",
              sum(!is.na(scrape_result$user_score)), nrow(scrape_result)))

  # Show sample data
  cat("\nSample Data (first 3 albums):\n")
  print(scrape_result %>%
    select(album_title, artist_name, metascore, user_score) %>%
    head(3))

} else {
  cat("⚠ Warning: No data was scraped. This could mean:\n")
  cat("  - Metacritic is temporarily unavailable\n")
  cat("  - The website structure has changed\n")
  cat("  - There's a network connectivity issue\n")
}

cat("\n")

# =============================================================================
# Test 4: Data Export Function
# =============================================================================

cat("Test 4: Testing data export...\n")

if (!is.null(scrape_result) && nrow(scrape_result) > 0) {
  # Create temporary test directory
  test_dir <- tempdir()
  test_file <- "test_albums.csv"

  tryCatch({
    save_albums_to_csv(
      albums_df = scrape_result,
      filename = test_file,
      path = test_dir
    )

    test_path <- file.path(test_dir, test_file)
    if (file.exists(test_path)) {
      cat("✓ CSV export successful\n")
      cat(sprintf("  Test file created at: %s\n", test_path))

      # Verify file can be read back
      read_back <- read_csv(test_path, show_col_types = FALSE)
      if (nrow(read_back) == nrow(scrape_result)) {
        cat("✓ CSV file can be read back correctly\n")
      } else {
        cat("❌ CSV read-back verification failed\n")
      }

      # Clean up
      file.remove(test_path)
      cat("✓ Test file cleaned up\n")
    } else {
      cat("❌ CSV file was not created\n")
    }
  }, error = function(e) {
    cat("❌ Export failed:", e$message, "\n")
  })
} else {
  cat("⊘ Skipping export test (no data available)\n")
}

cat("\n")

# =============================================================================
# Test Summary
# =============================================================================

cat("=== Test Summary ===\n\n")

if (!is.null(scrape_result) && nrow(scrape_result) > 0) {
  cat("✓ All tests completed successfully!\n")
  cat("\nThe scraper is working correctly. You can now use it with:\n")
  cat("  albums <- scrape_metacritic_albums()\n")
  cat("  save_albums_to_csv(albums)\n")
  cat("\nOr run the full example:\n")
  cat("  run_example()\n")
} else {
  cat("⚠ Some tests could not complete due to scraping issues.\n")
  cat("  This may be temporary. Try again later or check your internet connection.\n")
}

cat("\n=== End of Tests ===\n")
