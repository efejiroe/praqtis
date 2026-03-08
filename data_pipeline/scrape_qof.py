"""
Extract phase: scrape the latest Quality and Outcomes Framework (QOF) raw CSV
data from NHS Digital and download it to data_pipeline/raw_data/.
"""

import logging
import re
import sys
from pathlib import Path

import requests
from bs4 import BeautifulSoup

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
NHS_PUBLICATION_URL = (
    "https://digital.nhs.uk/data-and-information/publications/statistical/"
    "quality-and-outcomes-framework-achievement-prevalence-and-exceptions-data"
)
# Matches the raw CSV zip, e.g. QOF2425.zip, QOF2526.zip
TARGET_FILENAME_PATTERN = re.compile(r"QOF\d{4}\.zip", re.IGNORECASE)
RAW_DATA_DIR = Path(__file__).parent / "raw_data"
HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (compatible; PRAQTIS-ETL/1.0; "
        "+https://github.com/efejiroe/praqtis)"
    )
}

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def find_latest_publication_url() -> str:
    """Find the URL of the most recent QOF publication year page."""
    log.info("Fetching QOF publication index: %s", NHS_PUBLICATION_URL)
    response = requests.get(NHS_PUBLICATION_URL, headers=HEADERS, timeout=30)
    response.raise_for_status()
    soup = BeautifulSoup(response.text, "html.parser")

    # QOF uses financial year links like "2024-25", "2025-26"
    year_pattern = re.compile(r"\d{4}-\d{2}", re.IGNORECASE)
    candidates = []
    for a in soup.find_all("a", href=True):
        href = a["href"]
        if "quality-and-outcomes-framework" in href and year_pattern.search(href):
            year_match = year_pattern.search(href)
            if year_match:
                candidates.append((year_match.group(), href))

    if not candidates:
        raise RuntimeError(
            "Could not find a QOF year publication link. "
            "The NHS Digital page structure may have changed."
        )

    # Sort descending and take the latest
    candidates.sort(key=lambda x: x[0], reverse=True)
    latest_year, latest_href = candidates[0]
    if latest_href.startswith("/"):
        latest_href = "https://digital.nhs.uk" + latest_href
    log.info("Latest QOF publication (%s): %s", latest_year, latest_href)
    return latest_href


def find_download_url(pub_url: str) -> tuple[str, str]:
    """Return (download_url, filename) for the QOF raw CSV ZIP."""
    log.info("Fetching QOF publication detail page: %s", pub_url)
    response = requests.get(pub_url, headers=HEADERS, timeout=30)
    response.raise_for_status()
    soup = BeautifulSoup(response.text, "html.parser")

    for a in soup.find_all("a", href=True):
        href = a["href"]
        if TARGET_FILENAME_PATTERN.search(href):
            filename = href.split("/")[-1].split("?")[0]
            log.info("Found QOF raw CSV file: %s", filename)
            return href, filename

    raise RuntimeError(
        f"Could not find QOF raw CSV ZIP on {pub_url}. "
        "The page structure may have changed."
    )


def download_file(url: str, dest_dir: Path, filename: str) -> Path:
    """Stream-download a file into dest_dir and return the local path."""
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest_path = dest_dir / filename

    log.info("Downloading %s -> %s", url, dest_path)
    with requests.get(url, headers=HEADERS, stream=True, timeout=180) as r:
        r.raise_for_status()
        with open(dest_path, "wb") as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)

    size_kb = dest_path.stat().st_size // 1024
    log.info("Download complete: %s (%d KB)", dest_path.name, size_kb)
    return dest_path


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> None:
    try:
        pub_url = find_latest_publication_url()
        download_url, filename = find_download_url(pub_url)
        local_path = download_file(download_url, RAW_DATA_DIR, filename)
        log.info("SUCCESS — QOF file saved to %s", local_path)
    except requests.HTTPError as exc:
        log.error("HTTP error: %s", exc)
        sys.exit(1)
    except RuntimeError as exc:
        log.error("Scraper error: %s", exc)
        sys.exit(1)


if __name__ == "__main__":
    main()
