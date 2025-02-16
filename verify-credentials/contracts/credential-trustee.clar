;; Credential Verification Smart Contract

;; Error codes
(define-constant ERROR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERROR-INSTITUTION-ALREADY-EXISTS (err u101))
(define-constant ERROR-INSTITUTION-OR-CREDENTIAL-NOT-FOUND (err u102))
(define-constant ERROR-CREDENTIAL-TYPE-NOT-SUPPORTED (err u103))
(define-constant ERROR-CREDENTIAL-REVOKED (err u104))
(define-constant ERROR-CREDENTIAL-EXPIRED (err u105))
(define-constant ERROR-INVALID-INPUT-PARAMETERS (err u106))
(define-constant ERROR-INVALID-ZERO-ADDRESS (err u107))
(define-constant ERROR-INVALID-VALIDITY-PERIOD (err u108))
(define-constant ERROR-CREDENTIAL-ALREADY-EXISTS (err u109))
(define-constant ERROR-INVALID-DOCUMENT-HASH (err u110))

;; Data maps
(define-map registered-education-institutions 
    principal 
    {
        institution-name: (string-ascii 50),
        institution-website: (string-ascii 100),
        institution-is-verified: bool
    }
)

(define-map issued-credentials 
    {credential-id: (string-ascii 50), recipient-address: principal}
    {
        issuing-institution-address: principal,
        issuance-timestamp-block: uint,
        expiration-timestamp-block: uint,
        credential-type: (string-ascii 50),
        credential-content-hash: (buff 32),
        credential-metadata: (string-ascii 256),
        is-revoked: bool
    }
)

(define-map valid-credential-types
    (string-ascii 50)
    {
        type-description: (string-ascii 100),
        validity-duration-blocks: uint
    }
)

;; Administrative functions
(define-data-var contract-administrator principal tx-sender)

;; Validation functions
(define-private (is-valid-blockchain-address (blockchain-address principal))
    (and 
        (not (is-eq blockchain-address (as-contract tx-sender)))
        (not (is-eq blockchain-address 'SP000000000000000000002Q6VF78)))
)

(define-private (is-valid-duration-period (duration-blocks uint))
    (> duration-blocks u0)
)

(define-private (is-valid-text-input (text-input (string-ascii 256)))
    (not (is-eq text-input ""))
)

(define-private (is-valid-document-hash (document-hash (buff 32)))
    (and 
        (not (is-eq document-hash 0x))
        (is-eq (len document-hash) u32)
    )
)

;; Public functions
(define-public (transfer-contract-ownership (new-administrator-address principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-administrator)) ERROR-UNAUTHORIZED-ACCESS)
        (asserts! (is-valid-blockchain-address new-administrator-address) ERROR-INVALID-ZERO-ADDRESS)
        (ok (var-set contract-administrator new-administrator-address))
    )
)

(define-public (register-new-institution 
    (institution-name (string-ascii 50)) 
    (institution-website (string-ascii 100))
)
    (let (
        (institution-details {
            institution-name: institution-name, 
            institution-website: institution-website, 
            institution-is-verified: false
        })
    )
        (asserts! (is-valid-text-input institution-name) ERROR-INVALID-INPUT-PARAMETERS)
        (asserts! (is-valid-text-input institution-website) ERROR-INVALID-INPUT-PARAMETERS)
        (asserts! (is-none (map-get? registered-education-institutions tx-sender)) ERROR-INSTITUTION-ALREADY-EXISTS)
        (ok (map-set registered-education-institutions tx-sender institution-details))
    )
)

(define-public (verify-institution-status (institution-address principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-administrator)) ERROR-UNAUTHORIZED-ACCESS)
        (asserts! (is-valid-blockchain-address institution-address) ERROR-INVALID-ZERO-ADDRESS)
        (asserts! (is-some (map-get? registered-education-institutions institution-address)) ERROR-INSTITUTION-OR-CREDENTIAL-NOT-FOUND)
        (ok (map-set registered-education-institutions 
            institution-address 
            (merge (unwrap-panic (map-get? registered-education-institutions institution-address)) 
                {institution-is-verified: true}
            )
        ))
    )
)

(define-public (add-credential-type 
    (type-id (string-ascii 50)) 
    (type-description (string-ascii 100)) 
    (validity-duration-blocks uint)
)
    (begin
        (asserts! (is-eq tx-sender (var-get contract-administrator)) ERROR-UNAUTHORIZED-ACCESS)
        (asserts! (is-valid-text-input type-id) ERROR-INVALID-INPUT-PARAMETERS)
        (asserts! (is-valid-text-input type-description) ERROR-INVALID-INPUT-PARAMETERS)
        (asserts! (is-valid-duration-period validity-duration-blocks) ERROR-INVALID-VALIDITY-PERIOD)
        (ok (map-set valid-credential-types type-id {
            type-description: type-description,
            validity-duration-blocks: validity-duration-blocks
        }))
    )
)

(define-public (issue-new-credential
    (credential-id (string-ascii 50))
    (recipient-address principal)
    (credential-type (string-ascii 50))
    (credential-content-hash (buff 32))
    (credential-metadata (string-ascii 256))
)
    (let (
        (institution-details (unwrap! (map-get? registered-education-institutions tx-sender) ERROR-INSTITUTION-OR-CREDENTIAL-NOT-FOUND))
        (credential-type-details (unwrap! (map-get? valid-credential-types credential-type) ERROR-CREDENTIAL-TYPE-NOT-SUPPORTED))
        (current-block-timestamp block-height)
        (expiration-timestamp (+ current-block-timestamp (get validity-duration-blocks credential-type-details)))
    )
        (asserts! (is-valid-text-input credential-id) ERROR-INVALID-INPUT-PARAMETERS)
        (asserts! (is-valid-blockchain-address recipient-address) ERROR-INVALID-ZERO-ADDRESS)
        (asserts! (is-valid-text-input credential-type) ERROR-INVALID-INPUT-PARAMETERS)
        (asserts! (is-valid-text-input credential-metadata) ERROR-INVALID-INPUT-PARAMETERS)
        (asserts! (is-valid-document-hash credential-content-hash) ERROR-INVALID-DOCUMENT-HASH)
        (asserts! (get institution-is-verified institution-details) ERROR-UNAUTHORIZED-ACCESS)
        (asserts! (is-none (map-get? issued-credentials {
            credential-id: credential-id, 
            recipient-address: recipient-address
        })) ERROR-CREDENTIAL-ALREADY-EXISTS)
        
        (ok (map-set issued-credentials 
            {credential-id: credential-id, recipient-address: recipient-address}
            {
                issuing-institution-address: tx-sender,
                issuance-timestamp-block: current-block-timestamp,
                expiration-timestamp-block: expiration-timestamp,
                credential-type: credential-type,
                credential-content-hash: credential-content-hash,
                credential-metadata: credential-metadata,
                is-revoked: false
            }
        ))
    )
)

(define-public (revoke-issued-credential 
    (credential-id (string-ascii 50)) 
    (recipient-address principal)
)
    (let (
        (credential-details (unwrap! 
            (map-get? issued-credentials 
                {credential-id: credential-id, recipient-address: recipient-address}
            ) 
            ERROR-INSTITUTION-OR-CREDENTIAL-NOT-FOUND
        ))
    )
        (asserts! (is-valid-text-input credential-id) ERROR-INVALID-INPUT-PARAMETERS)
        (asserts! (is-valid-blockchain-address recipient-address) ERROR-INVALID-ZERO-ADDRESS)
        (asserts! (is-eq tx-sender (get issuing-institution-address credential-details)) ERROR-UNAUTHORIZED-ACCESS)
        (ok (map-set issued-credentials 
            {credential-id: credential-id, recipient-address: recipient-address}
            (merge credential-details {is-revoked: true})
        ))
    )
)

;; Read-only functions
(define-read-only (get-credential-details
    (credential-id (string-ascii 50))
    (recipient-address principal)
)
    (map-get? issued-credentials 
        {credential-id: credential-id, recipient-address: recipient-address}
    )
)

(define-read-only (check-credential-validity
    (credential-id (string-ascii 50))
    (recipient-address principal)
)
    (match (map-get? issued-credentials 
        {credential-id: credential-id, recipient-address: recipient-address}
    )
        credential-details (let (
            (current-block-timestamp block-height)
            (is-expired (> current-block-timestamp (get expiration-timestamp-block credential-details)))
        )
            (if (get is-revoked credential-details)
                ERROR-CREDENTIAL-REVOKED
                (if is-expired
                    ERROR-CREDENTIAL-EXPIRED
                    (ok true)
                )
            ))
        ERROR-INSTITUTION-OR-CREDENTIAL-NOT-FOUND
    )
)

(define-read-only (get-institution-details (institution-address principal))
    (map-get? registered-education-institutions institution-address)
)

(define-read-only (get-credential-type-info (type-id (string-ascii 50)))
    (map-get? valid-credential-types type-id)
)