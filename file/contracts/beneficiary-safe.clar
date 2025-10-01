;; beneficiary-safe.clar
;; Time-release safe with beneficiary support

(define-data-var owner principal tx-sender)
(define-data-var beneficiary (optional principal) none)
(define-data-var unlock-block uint u0)
(define-data-var locked-amount uint u0)

;; Lock funds and set unlock time + beneficiary
(define-public (lock (unlock-at uint) (amount uint) (beneficiary-address principal))
    (begin
        (asserts! (is-eq (var-get owner) tx-sender) (err u100))
        (asserts! (> unlock-at block-height) (err u101))
        (asserts! (> amount u0) (err u102))
        (asserts! (is-eq (var-get locked-amount) u0) (err u103))

        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

        (var-set unlock-block unlock-at)
        (var-set locked-amount amount)
        (var-set beneficiary (some beneficiary-address))
        (ok amount)
    )
)

;; Withdraw: owner OR beneficiary can withdraw after unlock
(define-public (withdraw)
    (let (
        (amt (var-get locked-amount))
        (unlock-at (var-get unlock-block))
        (benef (var-get beneficiary))
    )
        (begin
            (asserts! (>= block-height unlock-at) (err u201))
            (asserts! (> amt u0) (err u202))
            (match benef
                beneficiary-addr
                (begin
                    (asserts!
                        (or (is-eq tx-sender (var-get owner))
                            (is-eq tx-sender beneficiary-addr))
                        (err u200)
                    )
                    (var-set locked-amount u0)
                    (stx-transfer? amt (as-contract tx-sender) tx-sender)
                )
                (err u203) ;; no beneficiary set
            )
        )
    )
)

;; Read-only functions
(define-read-only (get-owner) (ok (var-get owner)))
(define-read-only (get-beneficiary) (ok (var-get beneficiary)))
(define-read-only (get-unlock-block) (ok (var-get unlock-block)))
(define-read-only (get-locked-amount) (ok (var-get locked-amount)))
