"""
Extract phase: scrape the latest "Appointments in General Practice" CSV
from NHS Digital and download it to data_pipeline/raw_data/.
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
    "appointments-in-general-practice"
)
RAW_DATA_DIR = Path(__file__).parent / "raw_data"
HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (compatible; PRAQTIS-ETL/1.0; "
        "+https://github.com/efejiroashano/practis)"
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
def fetch_page(url: str) -> BeautifulSoup:
    """Fetch a URL and return a BeautifulSoup object."""
    log.info("Fetching publication index: %s", url)
    response = requests.get(url, headers=HEADERS, timeout=30)
    response.raise_for_status()
    return BeautifulSoup(response.text, "html.parser")


def find_latest_publication_url(soup: BeautifulSoup) -> str:
    """
    Find the URL of the most recent monthly publication page.
    The index lists publications newest-first; we take the first link
    whose text looks like a month + year (e.g. 'September 2024').
    """
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
            log.info("Latest publication page: %s", href)
            return href

    raise RuntimeError(
        "Could not find a monthly publication link on the index page. "
        "The NHS Digital page structure may have changed."
    )


def find_csv_download_url(pub_url: str) -> tuple[str, str]:
    """
    Fetch a publication detail page and return (download_url, filename)
    for the primary practice-level appointments CSV (or ZIP).

    Looks for links to files.digital.nhs.uk that contain 'CSV' or end in
    .csv / .zip and whose anchor text or surrounding context references
    'practice' or 'appointment'.
    """
    log.info("Fetching publication detail page: %s", pub_url)
    response = requests.get(pub_url, headers=HEADERS, timeout=30)
    response.raise_for_status()
    soup = BeautifulSoup(response.text, "html.parser")

    file_pattern = re.compile(r"\.(csv|zip)$", re.IGNORECASE)
    relevance_pattern = re.compile(
        r"(practice|appointment|appt|csv)", re.IGNORECASE
    )

    candidates = []
    for a in soup.find_all("a", href=True):
        href = a["href"]
        text = a.get_text(strip=True)
        if file_pattern.search(href) and relevance_pattern.search(
            text + href
        ):
            candidates.append((href, text))

    if not candidates:
        raise RuntimeError(
            f"No CSV/ZIP download links found on {pub_url}. "
            "The page structure may have changed."
        )

    # Prefer links explicitly mentioning 'practice' in the anchor text
    practice_links = [
        (h, t) for h, t in candidates if "practice" in t.lower()
    ]
    chosen_href, chosen_text = (practice_links or candidates)[0]

    filename = chosen_href.split("/")[-1].split("?")[0]
    log.info("Selected file: %s (%s)", filename, chosen_text)
    return chosen_href, filename


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
        index_soup = fetch_page(NHS_PUBLICATION_URL)
        pub_url = find_latest_publication_url(index_soup)
        download_url, filename = find_csv_download_url(pub_url)
        local_path = download_file(download_url, RAW_DATA_DIR, filename)
        log.info("SUCCESS — file saved to %s", local_path)
    except requests.HTTPError as exc:
        log.error("HTTP error: %s", exc)
        sys.exit(1)
    except RuntimeError as exc:
        log.error("Scraper error: %s", exc)
        sys.exit(1)


if __name__ == "__main__":
    main()
