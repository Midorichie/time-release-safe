;; time-release-safe.clar
;; A decentralized safe that locks STX until a future block height

(define-data-var owner principal tx-sender)
(define-data-var unlock-block uint u0)
(define-data-var locked-amount uint u0)

;; Lock funds and set unlock time
(define-public (lock (unlock-at uint) (amount uint))
    (begin
        (asserts! (is-eq (var-get owner) tx-sender) (err u100)) ;; only owner
        (asserts! (> unlock-at block-height) (err u101)) ;; must be future block
        (asserts! (> amount u0) (err u102)) ;; amount must be > 0

        ;; transfer funds from sender to contract
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

        ;; store details
        (var-set unlock-block unlock-at)
        (var-set locked-amount amount)
        (ok amount)
    )
)

;; Withdraw funds after unlock time
(define-public (withdraw)
    (begin
        (asserts! (is-eq (var-get owner) tx-sender) (err u200)) ;; only owner
        (asserts! (>= block-height (var-get unlock-block)) (err u201)) ;; must reach unlock time
        (let ((amount (var-get locked-amount)))
            (asserts! (> amount u0) (err u202)) ;; ensure funds available
            (var-set locked-amount u0)
            (stx-transfer? amount (as-contract tx-sender) tx-sender)
        )
    )
)

;; Read-only functions
(define-read-only (get-owner) (ok (var-get owner)))
(define-read-only (get-unlock-block) (ok (var-get unlock-block)))
(define-read-only (get-locked-amount) (ok (var-get locked-amount)))
