.pragma library

// A new "rev" query makes Qt Quick reload the icon; the provider must ignore it.
function withRevision(url, revision) {
    if (!url)
        return "";
    if (!url.startsWith("image://icon/"))
        return url;
    const query = url.indexOf("?");
    if (query === -1)
        return url + "?rev=" + revision;
    // A bare "?" is part of the icon name to the provider.
    if (url.indexOf("=", query) === -1)
        return url;
    return url + "&rev=" + revision;
}
