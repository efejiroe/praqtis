"""
Extract phase: scrape the latest "Patients Registered at a GP Practice" dataset
from NHS Digital and download the totals CSV to data_pipeline/raw_data/.
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
    "patients-registered-at-a-gp-practice"
)
TARGET_FILENAME_PATTERN = re.compile(r"gp-reg-pat-prac-all", re.IGNORECASE)
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
    """Find the URL of the most recent monthly publication page."""
    log.info("Fetching GP patients publication index: %s", NHS_PUBLICATION_URL)
    response = requests.get(NHS_PUBLICATION_URL, headers=HEADERS, timeout=30)
    response.raise_for_status()
    soup = BeautifulSoup(response.text, "html.parser")

    month_pattern = re.compile(
        r"(January|February|March|April|May|June|July|August|"
        r"September|October|November|December)\s+\d{4}",
        re.IGNORECASE,
    )
    for a in soup.find_all("a", href=True):
        if month_pattern.search(a.get_text()):
            href = a["href"]
            if href.startswith("/"):
                href = "https://digital.nhs.uk" + href
            log.info("Latest GP patients publication: %s", href)
            return href

    raise RuntimeError(
        "Could not find a monthly publication link. "
        "The NHS Digital page structure may have changed."
    )


def find_download_url(pub_url: str) -> tuple[str, str]:
    """Return (download_url, filename) for the GP practice totals ZIP."""
    log.info("Fetching publication detail page: %s", pub_url)
    response = requests.get(pub_url, headers=HEADERS, timeout=30)
    response.raise_for_status()
    soup = BeautifulSoup(response.text, "html.parser")

    for a in soup.find_all("a", href=True):
        href = a["href"]
        if TARGET_FILENAME_PATTERN.search(href):
            filename = href.split("/")[-1].split("?")[0]
            log.info("Found GP patients file: %s", filename)
            return href, filename

    raise RuntimeError(
        f"Could not find GP patients totals file on {pub_url}. "
        "The page structure may have changed."
    )


def download_file(url: str, dest_dir: Path, filename: str) -> Path:
    """Stream-download a file into dest_dir and return the local path."""
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest_path = dest_dir / filename

    log.info("Downloading %s -> %s", url, dest_path)
    with requests.get(url, headers=HEADERS, stream=True, timeout=120) as r:
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
        log.info("SUCCESS — GP patients file saved to %s", local_path)
    except requests.HTTPError as exc:
        log.error("HTTP error: %s", exc)
        sys.exit(1)
    except RuntimeError as exc:
        log.error("Scraper error: %s", exc)
        sys.exit(1)


if __name__ == "__main__":
    main()
