# http://web.mit.edu/darwin/src/modules/Security/cdsa/cdsa/cssmtype.h
KEY_TYPE = {
    0x00+0x0F : 'CSSM_KEYCLASS_PUBLIC_KEY',
    0x01+0x0F : 'CSSM_KEYCLASS_PRIVATE_KEY',
    0x02+0x0F : 'CSSM_KEYCLASS_SESSION_KEY',
    0x03+0x0F : 'CSSM_KEYCLASS_SECRET_PART',
    0xFFFFFFFF : 'CSSM_KEYCLASS_OTHER'
}

CSSM_ALGORITHMS = {
    0 : 'CSSM_ALGID_NONE',
    1 : 'CSSM_ALGID_CUSTOM',
    2 : 'CSSM_ALGID_DH',
    3 : 'CSSM_ALGID_PH',
    4 : 'CSSM_ALGID_KEA',
    5 : 'CSSM_ALGID_MD2',
    6 : 'CSSM_ALGID_MD4',
    7 : 'CSSM_ALGID_MD5',
    8 : 'CSSM_ALGID_SHA1',
    9 : 'CSSM_ALGID_NHASH',
    10 : 'CSSM_ALGID_HAVAL:',
    11 : 'CSSM_ALGID_RIPEMD',
    12 : 'CSSM_ALGID_IBCHASH',
    13 : 'CSSM_ALGID_RIPEMAC',
    14 : 'CSSM_ALGID_DES',
    15 : 'CSSM_ALGID_DESX',
    16 : 'CSSM_ALGID_RDES',
    17 : 'CSSM_ALGID_3DES_3KEY_EDE',
    18 : 'CSSM_ALGID_3DES_2KEY_EDE',
    19 : 'CSSM_ALGID_3DES_1KEY_EEE',
    20 : 'CSSM_ALGID_3DES_3KEY_EEE',
    21 : 'CSSM_ALGID_3DES_2KEY_EEE',
    22 : 'CSSM_ALGID_IDEA',
    23 : 'CSSM_ALGID_RC2',
    24 : 'CSSM_ALGID_RC5',
    25 : 'CSSM_ALGID_RC4',
    26 : 'CSSM_ALGID_SEAL',
    27 : 'CSSM_ALGID_CAST',
    28 : 'CSSM_ALGID_BLOWFISH',
    29 : 'CSSM_ALGID_SKIPJACK',
    30 : 'CSSM_ALGID_LUCIFER',
    31 : 'CSSM_ALGID_MADRYGA',
    32 : 'CSSM_ALGID_FEAL',
    33 : 'CSSM_ALGID_REDOC',
    34 : 'CSSM_ALGID_REDOC3',
    35 : 'CSSM_ALGID_LOKI',
    36 : 'CSSM_ALGID_KHUFU',
    37 : 'CSSM_ALGID_KHAFRE',
    38 : 'CSSM_ALGID_MMB',
    39 : 'CSSM_ALGID_GOST',
    40 : 'CSSM_ALGID_SAFER',
    41 : 'CSSM_ALGID_CRAB',
    42 : 'CSSM_ALGID_RSA',
    43 : 'CSSM_ALGID_DSA',
    44 : 'CSSM_ALGID_MD5WithRSA',
    45 : 'CSSM_ALGID_MD2WithRSA',
    46 : 'CSSM_ALGID_ElGamal',
    47 : 'CSSM_ALGID_MD2Random',
    48 : 'CSSM_ALGID_MD5Random',
    49 : 'CSSM_ALGID_SHARandom',
    50 : 'CSSM_ALGID_DESRandom',
    51 : 'CSSM_ALGID_SHA1WithRSA',
    52 : 'CSSM_ALGID_CDMF',
    53 : 'CSSM_ALGID_CAST3',
    54 : 'CSSM_ALGID_CAST5',
    55 : 'CSSM_ALGID_GenericSecret',
    56 : 'CSSM_ALGID_ConcatBaseAndKey',
    57 : 'CSSM_ALGID_ConcatKeyAndBase',
    58 : 'CSSM_ALGID_ConcatBaseAndData',
    59 : 'CSSM_ALGID_ConcatDataAndBase',
    60 : 'CSSM_ALGID_XORBaseAndData',
    61 : 'CSSM_ALGID_ExtractFromKey',
    62 : 'CSSM_ALGID_SSL3PreMasterGen',
    63 : 'CSSM_ALGID_SSL3MasterDerive',
    64 : 'CSSM_ALGID_SSL3KeyAndMacDerive',
    65 : 'CSSM_ALGID_SSL3MD5_MAC',
    66 : 'CSSM_ALGID_SSL3SHA1_MAC',
    67 : 'CSSM_ALGID_PKCS5_PBKDF1_MD5',
    68 : 'CSSM_ALGID_PKCS5_PBKDF1_MD2',
    69 : 'CSSM_ALGID_PKCS5_PBKDF1_SHA1',
    70 : 'CSSM_ALGID_WrapLynks',
    71 : 'CSSM_ALGID_WrapSET_OAEP',
    72 : 'CSSM_ALGID_BATON',
    73 : 'CSSM_ALGID_ECDSA',
    74 : 'CSSM_ALGID_MAYFLY',
    75 : 'CSSM_ALGID_JUNIPER',
    76 : 'CSSM_ALGID_FASTHASH',
    77 : 'CSSM_ALGID_3DES',
    78 : 'CSSM_ALGID_SSL3MD5',
    79 : 'CSSM_ALGID_SSL3SHA1',
    80 : 'CSSM_ALGID_FortezzaTimestamp',
    81 : 'CSSM_ALGID_SHA1WithDSA',
    82 : 'CSSM_ALGID_SHA1WithECDSA',
    83 : 'CSSM_ALGID_DSA_BSAFE',
    84 : 'CSSM_ALGID_ECDH',
    85 : 'CSSM_ALGID_ECMQV',
    86 : 'CSSM_ALGID_PKCS12_SHA1_PBE',
    87 : 'CSSM_ALGID_ECNRA',
    88 : 'CSSM_ALGID_SHA1WithECNRA',
    89 : 'CSSM_ALGID_ECES',
    90 : 'CSSM_ALGID_ECAES',
    91 : 'CSSM_ALGID_SHA1HMAC',
    92 : 'CSSM_ALGID_FIPS186Random',
    93 : 'CSSM_ALGID_ECC',
    94 : 'CSSM_ALGID_MQV',
    95 : 'CSSM_ALGID_NRA',
    96 : 'CSSM_ALGID_IntelPlatformRandom',
    97 : 'CSSM_ALGID_UTC',
    98 : 'CSSM_ALGID_HAVAL3',
    99 : 'CSSM_ALGID_HAVAL4',
    100 : 'CSSM_ALGID_HAVAL5',
    101 : 'CSSM_ALGID_TIGER',
    102 : 'CSSM_ALGID_MD5HMAC',
    103 : 'CSSM_ALGID_PKCS5_PBKDF2',
    104 : 'CSSM_ALGID_RUNNING_COUNTER',
    0x7FFFFFFF : 'CSSM_ALGID_LAST'
}

#CSSM TYPE
## http://www.opensource.apple.com/source/libsecurity_cssm/libsecurity_cssm-36064/lib/cssmtype.h

########## CSSM_DB_RECORDTYPE #############

#/* Industry At Large Application Name Space Range Definition */
#/* AppleFileDL record types. */
CSSM_DB_RECORDTYPE_APP_DEFINED_START = 0x80000000
CSSM_DL_DB_RECORD_GENERIC_PASSWORD = CSSM_DB_RECORDTYPE_APP_DEFINED_START + 0
CSSM_DL_DB_RECORD_INTERNET_PASSWORD = CSSM_DB_RECORDTYPE_APP_DEFINED_START + 1
CSSM_DL_DB_RECORD_APPLESHARE_PASSWORD = CSSM_DB_RECORDTYPE_APP_DEFINED_START + 2
CSSM_DL_DB_RECORD_USER_TRUST = CSSM_DB_RECORDTYPE_APP_DEFINED_START + 3
CSSM_DL_DB_RECORD_X509_CRL = CSSM_DB_RECORDTYPE_APP_DEFINED_START + 4
CSSM_DL_DB_RECORD_UNLOCK_REFERRAL = CSSM_DB_RECORDTYPE_APP_DEFINED_START + 5
CSSM_DL_DB_RECORD_EXTENDED_ATTRIBUTE = CSSM_DB_RECORDTYPE_APP_DEFINED_START + 6

CSSM_DL_DB_RECORD_X509_CERTIFICATE = CSSM_DB_RECORDTYPE_APP_DEFINED_START + 0x1000
CSSM_DL_DB_RECORD_METADATA = CSSM_DB_RECORDTYPE_APP_DEFINED_START + 0x8000  ## DBBlob
CSSM_DB_RECORDTYPE_APP_DEFINED_END = 0xffffffff

#/* Record Types defined in the Schema Management Name Space */
CSSM_DB_RECORDTYPE_SCHEMA_START = 0x00000000
CSSM_DL_DB_SCHEMA_INFO = CSSM_DB_RECORDTYPE_SCHEMA_START + 0
CSSM_DL_DB_SCHEMA_INDEXES = CSSM_DB_RECORDTYPE_SCHEMA_START + 1
CSSM_DL_DB_SCHEMA_ATTRIBUTES = CSSM_DB_RECORDTYPE_SCHEMA_START + 2
CSSM_DL_DB_SCHEMA_PARSING_MODULE = CSSM_DB_RECORDTYPE_SCHEMA_START + 3
CSSM_DB_RECORDTYPE_SCHEMA_END = CSSM_DB_RECORDTYPE_SCHEMA_START + 4

#/* Record Types defined in the Open Group Application Name Space */
#/* Open Group Application Name Space Range Definition*/
CSSM_DB_RECORDTYPE_OPEN_GROUP_START = 0x0000000A
CSSM_DL_DB_RECORD_ANY = CSSM_DB_RECORDTYPE_OPEN_GROUP_START + 0
CSSM_DL_DB_RECORD_CERT = CSSM_DB_RECORDTYPE_OPEN_GROUP_START + 1
CSSM_DL_DB_RECORD_CRL = CSSM_DB_RECORDTYPE_OPEN_GROUP_START + 2
CSSM_DL_DB_RECORD_POLICY = CSSM_DB_RECORDTYPE_OPEN_GROUP_START + 3
CSSM_DL_DB_RECORD_GENERIC = CSSM_DB_RECORDTYPE_OPEN_GROUP_START + 4
CSSM_DL_DB_RECORD_PUBLIC_KEY = CSSM_DB_RECORDTYPE_OPEN_GROUP_START + 5
CSSM_DL_DB_RECORD_PRIVATE_KEY = CSSM_DB_RECORDTYPE_OPEN_GROUP_START + 6
CSSM_DL_DB_RECORD_SYMMETRIC_KEY = CSSM_DB_RECORDTYPE_OPEN_GROUP_START + 7
CSSM_DL_DB_RECORD_ALL_KEYS = CSSM_DB_RECORDTYPE_OPEN_GROUP_START + 8
CSSM_DB_RECORDTYPE_OPEN_GROUP_END = CSSM_DB_RECORDTYPE_OPEN_GROUP_START + 8
#####################

######## KEYUSE #########
CSSM_KEYUSE_ANY = 0x80000000
CSSM_KEYUSE_ENCRYPT = 0x00000001
CSSM_KEYUSE_DECRYPT = 0x00000002
CSSM_KEYUSE_SIGN = 0x00000004
CSSM_KEYUSE_VERIFY = 0x00000008
CSSM_KEYUSE_SIGN_RECOVER = 0x00000010
CSSM_KEYUSE_VERIFY_RECOVER = 0x00000020
CSSM_KEYUSE_WRAP = 0x00000040
CSSM_KEYUSE_UNWRAP = 0x00000080
CSSM_KEYUSE_DERIVE = 0x00000100
####################

############ CERT TYPE ##############
CERT_TYPE = {
    0x00 : 'CSSM_CERT_UNKNOWN',
    0x01 : 'CSSM_CERT_X_509v1',
    0x02 : 'CSSM_CERT_X_509v2',
    0x03 : 'CSSM_CERT_X_509v3',
    0x04 : 'CSSM_CERT_PGP',
    0x05 : 'CSSM_CERT_SPKI',
    0x06 : 'CSSM_CERT_SDSIv1',
    0x08 : 'CSSM_CERT_Intel',
    0x09 : 'CSSM_CERT_X_509_ATTRIBUTE',
    0x0A : 'CSSM_CERT_X9_ATTRIBUTE',
    0x0C : 'CSSM_CERT_ACL_ENTRY',
    0x7FFE: 'CSSM_CERT_MULTIPLE',
    0x7FFF : 'CSSM_CERT_LAST',
    0x8000 : 'CSSM_CL_CUSTOM_CERT_TYPE'
}
####################################

########### CERT ENCODING #############
CERT_ENCODING = {
    0x00 : 'CSSM_CERT_ENCODING_UNKNOWN',
    0x01 : 'CSSM_CERT_ENCODING_CUSTOM',
    0x02 : 'CSSM_CERT_ENCODING_BER',
    0x03 : 'CSSM_CERT_ENCODING_DER',
    0x04 : 'CSSM_CERT_ENCODING_NDR',
    0x05 : 'CSSM_CERT_ENCODING_SEXPR',
    0x06 : 'CSSM_CERT_ENCODING_PGP',
    0x7FFE: 'CSSM_CERT_ENCODING_MULTIPLE',
    0x7FFF : 'CSSM_CERT_ENCODING_LAST'
}

STD_APPLE_ADDIN_MODULE = {
    '{87191ca0-0fc9-11d4-849a-000502b52122}': 'CSSM itself',
    '{87191ca1-0fc9-11d4-849a-000502b52122}': 'File based DL (aka "Keychain DL")',
    '{87191ca2-0fc9-11d4-849a-000502b52122}': 'Core CSP (local space)',
    '{87191ca3-0fc9-11d4-849a-000502b52122}': 'Secure CSP/DL (aka "Keychain CSPDL")',
    '{87191ca4-0fc9-11d4-849a-000502b52122}': 'X509 Certificate CL',
    '{87191ca5-0fc9-11d4-849a-000502b52122}': 'X509 Certificate TP',
    '{87191ca6-0fc9-11d4-849a-000502b52122}': 'DLAP/OpenDirectory access DL',
    '{87191ca7-0fc9-11d4-849a-000502b52122}': 'TP for ".mac" related policies',
    '{87191ca8-0fc9-11d4-849a-000502b52122}': 'Smartcard CSP/DL',
    '{87191ca9-0fc9-11d4-849a-000502b52122}': 'DL for ".mac" certificate access'
}

SECURE_STORAGE_GROUP = 'ssgp'

AUTH_TYPE = {
    'ntlm': 'kSecAuthenticationTypeNTLM',
    'msna': 'kSecAuthenticationTypeMSN',
    'dpaa': 'kSecAuthenticationTypeDPA',
    'rpaa': 'kSecAuthenticationTypeRPA',
    'http': 'kSecAuthenticationTypeHTTPBasic',
    'httd': 'kSecAuthenticationTypeHTTPDigest',
    'form': 'kSecAuthenticationTypeHTMLForm',
    'dflt': 'kSecAuthenticationTypeDefault',
    '': 'kSecAuthenticationTypeAny',
    '\x00\x00\x00\x00': 'kSecAuthenticationTypeAny'
}

PROTOCOL_TYPE = {
    'ftp ': 'kSecProtocolTypeFTP',
    'ftpa': 'kSecProtocolTypeFTPAccount',
    'http': 'kSecProtocolTypeHTTP',
    'irc ': 'kSecProtocolTypeIRC',
    'nntp': 'kSecProtocolTypeNNTP',
    'pop3': 'kSecProtocolTypePOP3',
    'smtp': 'kSecProtocolTypeSMTP',
    'sox ': 'kSecProtocolTypeSOCKS',
    'imap': 'kSecProtocolTypeIMAP',
    'ldap': 'kSecProtocolTypeLDAP',
    'atlk': 'kSecProtocolTypeAppleTalk',
    'afp ': 'kSecProtocolTypeAFP',
    'teln': 'kSecProtocolTypeTelnet',
    'ssh ': 'kSecProtocolTypeSSH',
    'ftps': 'kSecProtocolTypeFTPS',
    'htps': 'kSecProtocolTypeHTTPS',
    'htpx': 'kSecProtocolTypeHTTPProxy',
    'htsx': 'kSecProtocolTypeHTTPSProxy',
    'ftpx': 'kSecProtocolTypeFTPProxy',
    'cifs': 'kSecProtocolTypeCIFS',
    'smb ': 'kSecProtocolTypeSMB',
    'rtsp': 'kSecProtocolTypeRTSP',
    'rtsx': 'kSecProtocolTypeRTSPProxy',
    'daap': 'kSecProtocolTypeDAAP',
    'eppc': 'kSecProtocolTypeEPPC',
    'ipp ': 'kSecProtocolTypeIPP',
    'ntps': 'kSecProtocolTypeNNTPS',
    'ldps': 'kSecProtocolTypeLDAPS',
    'tels': 'kSecProtocolTypeTelnetS',
    'imps': 'kSecProtocolTypeIMAPS',
    'ircs': 'kSecProtocolTypeIRCS',
    'pops': 'kSecProtocolTypePOP3S',
    'cvsp': 'kSecProtocolTypeCVSpserver',
    'svn ': 'kSecProtocolTypeCVSpserver',
    'AdIM': 'kSecProtocolTypeAdiumMessenger',
    '\x00\x00\x00\x00': 'kSecProtocolTypeAny'
}

# This is somewhat gross: we define a bunch of module-level constants based on
# the SecKeychainItem.h defines (FourCharCodes) by passing them through
# struct.unpack and converting them to ctypes.c_long() since we'll never use
# them for non-native APIs

CARBON_DEFINES = {
    'cdat': 'kSecCreationDateItemAttr',
    'mdat': 'kSecModDateItemAttr',
    'desc': 'kSecDescriptionItemAttr',
    'icmt': 'kSecCommentItemAttr',
    'crtr': 'kSecCreatorItemAttr',
    'type': 'kSecTypeItemAttr',
    'scrp': 'kSecScriptCodeItemAttr',
    'labl': 'kSecLabelItemAttr',
    'invi': 'kSecInvisibleItemAttr',
    'nega': 'kSecNegativeItemAttr',
    'cusi': 'kSecCustomIconItemAttr',
    'acct': 'kSecAccountItemAttr',
    'svce': 'kSecServiceItemAttr',
    'gena': 'kSecGenericItemAttr',
    'sdmn': 'kSecSecurityDomainItemAttr',
    'srvr': 'kSecServerItemAttr',
    'atyp': 'kSecAuthenticationTypeItemAttr',
    'port': 'kSecPortItemAttr',
    'path': 'kSecPathItemAttr',
    'vlme': 'kSecVolumeItemAttr',
    'addr': 'kSecAddressItemAttr',
    'ssig': 'kSecSignatureItemAttr',
    'ptcl': 'kSecProtocolItemAttr',
    'ctyp': 'kSecCertificateType',
    'cenc': 'kSecCertificateEncoding',
    'crtp': 'kSecCrlType',
    'crnc': 'kSecCrlEncoding',
    'alis': 'kSecAlias',
    'inet': 'kSecInternetPasswordItemClass',
    'genp': 'kSecGenericPasswordItemClass',
    'ashp': 'kSecAppleSharePasswordItemClass',
    CSSM_DL_DB_RECORD_X509_CERTIFICATE: 'kSecCertificateItemClass'
}