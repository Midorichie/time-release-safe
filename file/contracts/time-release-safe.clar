;; ---------------------------------------------------------
;; Time-Release Safe with Multi-Beneficiary + Penalty
;; ---------------------------------------------------------
;; Constants for error codes
(define-constant err-owner-only (err u100))
(define-constant err-future-block (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-no-funds (err u200))
(define-constant err-not-unlocked (err u201))
(define-constant err-no-shares (err u203))
(define-constant err-invalid-share (err u204))

;; State variables
(define-data-var owner principal tx-sender)
(define-data-var unlock-block uint u0)
(define-data-var locked-amount uint u0)
(define-data-var penalty-rate uint u10) ;; 10% penalty by default
(define-data-var total-shares uint u0)

;; Beneficiaries list - max 200 beneficiaries
(define-data-var beneficiaries (list 200 {addr: principal, share: uint}) (list))

;; Lock funds until a future block height
(define-public (lock (unlock-at uint) (amount uint))
    (begin
        (asserts! (is-eq (var-get owner) tx-sender) err-owner-only)
        (asserts! (> unlock-at block-height) err-future-block)
        (asserts! (> amount u0) err-invalid-amount)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set unlock-block unlock-at)
        (var-set locked-amount amount)
        (ok amount)
    )
)

;; Add a beneficiary
(define-public (add-beneficiary (recipient principal) (share uint))
    (begin
        (asserts! (is-eq (var-get owner) tx-sender) err-owner-only)
        (asserts! (> share u0) err-invalid-share)
        (var-set beneficiaries 
            (unwrap-panic 
                (as-max-len? 
                    (append (var-get beneficiaries) {addr: recipient, share: share}) 
                    u200
                )
            )
        )
        (var-set total-shares (+ (var-get total-shares) share))
        (ok true)
    )
)

;; Helper function to distribute share to one beneficiary
(define-private (distribute-to-beneficiary 
    (beneficiary {addr: principal, share: uint}) 
    (context {amt: uint, total: uint})
)
    (let (
        (portion (/ (* (get amt context) (get share beneficiary)) (get total context)))
    )
        (begin
            (unwrap-panic 
                (as-contract (stx-transfer? portion tx-sender (get addr beneficiary)))
            )
            context
        )
    )
)

;; Withdraw funds
;; - If before unlock block: owner can withdraw but a penalty is applied
;; - If after unlock block: funds are distributed to beneficiaries
(define-public (withdraw)
    (let ((amt (var-get locked-amount)))
        (asserts! (> amt u0) err-no-funds)
        (if (< block-height (var-get unlock-block))
            ;; Early withdrawal with penalty
            (begin
                (asserts! (is-eq (var-get owner) tx-sender) err-owner-only)
                (let (
                    (penalty (/ (* amt (var-get penalty-rate)) u100))
                    (after-penalty (- amt penalty))
                )
                    (var-set locked-amount u0)
                    (try! (as-contract (stx-transfer? after-penalty tx-sender (var-get owner))))
                    (ok after-penalty)
                )
            )
            ;; Normal withdrawal: distribute to beneficiaries
            (begin
                (let ((total (var-get total-shares)))
                    (asserts! (> total u0) err-no-shares)
                    (var-set locked-amount u0)
                    ;; Use fold to distribute to all beneficiaries
                    (fold distribute-to-beneficiary 
                        (var-get beneficiaries) 
                        {amt: amt, total: total}
                    )
                    (ok amt)
                )
            )
        )
    )
)

;; ---------------------------------------------------------
;; Read-only functions
;; ---------------------------------------------------------
(define-read-only (get-owner) (ok (var-get owner)))
(define-read-only (get-unlock-block) (ok (var-get unlock-block)))
(define-read-only (get-locked-amount) (ok (var-get locked-amount)))
(define-read-only (get-total-shares) (ok (var-get total-shares)))
(define-read-only (get-beneficiaries) (ok (var-get beneficiaries)))
(define-read-only (get-penalty-rate) (ok (var-get penalty-rate)))
