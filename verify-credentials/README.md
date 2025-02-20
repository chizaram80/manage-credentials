# Credential Verification Smart Contract

A Clarity smart contract for the Stacks blockchain that enables educational institutions to issue, manage, and verify digital credentials and certificates.

## Overview

This smart contract provides a complete system for:
- Registering and verifying educational institutions
- Managing different types of credentials
- Issuing digital credentials to recipients
- Verifying the validity and authenticity of credentials
- Revoking credentials when necessary

## Key Features

- Institution registration and verification
- Multiple credential type support
- Time-based credential validity
- Credential revocation system
- Document hash verification
- Public verification interface

## Contract Administration

### Contract Owner Functions

1. `transfer-contract-ownership`
   - Transfers contract administration rights to a new address
   - Only callable by current administrator

2. `verify-institution-status`
   - Verifies an educational institution
   - Only callable by contract administrator

3. `add-credential-type`
   - Adds new credential types to the system
   - Defines validity periods for different credentials

## Institution Management

### Registration

Institutions can register using `register-new-institution`:
```clarity
(register-new-institution 
    "University Name"
    "https://university-website.com"
)
```

Required parameters:
- `institution-name`: String (max 50 chars)
- `institution-website`: String (max 100 chars)

### Credential Management

1. Issuing Credentials:
```clarity
(issue-new-credential
    "CREDENTIAL-UUID"
    recipient-principal
    "CREDENTIAL-TYPE"
    credential-hash
    "Additional metadata"
)
```

2. Revoking Credentials:
```clarity
(revoke-issued-credential
    "CREDENTIAL-UUID"
    recipient-principal
)
```

## Data Structures

### Institution Records
```clarity
{
    institution-name: (string-ascii 50),
    institution-website: (string-ascii 100),
    institution-is-verified: bool
}
```

### Credential Records
```clarity
{
    issuing-institution-address: principal,
    issuance-timestamp-block: uint,
    expiration-timestamp-block: uint,
    credential-type: (string-ascii 50),
    credential-content-hash: (buff 32),
    credential-metadata: (string-ascii 256),
    is-revoked: bool
}
```

## Public Interfaces

### Read-Only Functions

1. `get-credential-details`
   - Retrieves full credential information
   - Parameters: credential-id, recipient-address

2. `check-credential-validity`
   - Checks if a credential is valid, expired, or revoked
   - Parameters: credential-id, recipient-address

3. `get-institution-details`
   - Retrieves institution information
   - Parameters: institution-address

4. `get-credential-type-info`
   - Retrieves credential type specifications
   - Parameters: type-id

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR_UNAUTHORIZED_ACCESS | Unauthorized access |
| u101 | ERR_INSTITUTION_ALREADY_EXISTS | Institution already exists |
| u102 | ERR_INSTITUTION_OR_CREDENTIAL_NOT_FOUND | Institution or credential not found |
| u103 | ERR_CREDENTIAL_TYPE_NOT_SUPPORTED | Credential type not supported |
| u104 | ERR_CREDENTIAL_REVOKED | Credential revoked |
| u105 | ERR_CREDENTIAL_EXPIRED | Credential expired |
| u106 | ERR_INVALID_INPUT_PARAMETERS | Invalid input parameters |
| u107 | ERR_INVALID_ZERO_ADDRESS | Invalid zero address |
| u108 | ERR_INVALID_VALIDITY_PERIOD | Invalid validity period |
| u109 | ERR_CREDENTIAL_ALREADY_EXISTS | Credential already exists |
| u110 | ERR_INVALID_DOCUMENT_HASH | Invalid document hash |

## Security Features

1. Address validation
   - Checks for zero addresses
   - Validates contract addresses

2. Input validation
   - Text input validation
   - Duration period validation
   - Document hash validation

3. Access control
   - Administrator-only functions
   - Institution verification requirements
   - Credential management restrictions

## Best Practices for Integration

1. Always verify institution status before accepting credentials
2. Use unique credential IDs
3. Store credential hashes securely
4. Implement proper error handling
5. Check credential validity before accepting them

## Limitations

1. Maximum string lengths:
   - Institution name: 50 characters
   - Institution website: 100 characters
   - Credential metadata: 256 characters
   
2. Document hashes must be exactly 32 bytes

3. Validity periods must be greater than 0 blocks