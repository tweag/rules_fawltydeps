"""Example Python library with external dependency."""

# This would normally require requests in deps
# Uncomment to test dependency checking:
# import requests


def fetch_data(url):
    """Fetch data from URL.
    
    Note: This is a stub implementation.
    To test FawltyDeps, uncomment the import above and use requests.
    """
    # return requests.get(url).json()
    return {"status": "not implemented"}
