;; multi-beneficiary-safe.clar
;; Time-Release Safe with multiple beneficiaries + penalty for early withdrawal
;; ASCII-only, list-based beneficiaries, no recursion
;; ----------------------------
;; Error constants
(define-constant err-owner-only (err u100))
(define-constant err-invalid-unlock (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-already-locked (err u103))
(define-constant err-invalid-share (err u111))
(define-constant err-no-funds (err u202))
(define-constant err-no-shares (err u203))
;; ----------------------------
;; State
(define-data-var owner principal tx-sender)
(define-data-var unlock-block uint u0)
(define-data-var locked-amount uint u0)
(define-data-var penalty-rate uint u10) ;; 10% default
(define-data-var total-shares uint u0)
;; beneficiaries is a bounded list of tuples: (addr principal, share uint)
(define-data-var beneficiaries (list 200 {addr: principal, share: uint}) (list))
;; ----------------------------
;; Public: lock funds (owner only)
(define-public (lock (unlock-at uint) (amount uint))
  (begin
    (asserts! (is-eq (var-get owner) tx-sender) err-owner-only)
    (asserts! (> unlock-at block-height) err-invalid-unlock)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (is-eq (var-get locked-amount) u0) err-already-locked)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set unlock-block unlock-at)
    (var-set locked-amount amount)
    (ok amount)
  )
)
;; ----------------------------
;; Public: add a beneficiary (owner only)
(define-public (add-beneficiary (addr principal) (share uint))
  (begin
    (asserts! (is-eq (var-get owner) tx-sender) err-owner-only)
    (asserts! (> share u0) err-invalid-share)
    (var-set beneficiaries (unwrap-panic (as-max-len? (append (var-get beneficiaries) {addr: addr, share: share}) u200)))
    (var-set total-shares (+ (var-get total-shares) share))
    (ok (len (var-get beneficiaries)))
  )
)
;; ----------------------------
;; Helper function for distributing funds
(define-private (distribute-share (beneficiary {addr: principal, share: uint}) (context {amt: uint, total: uint}))
  (let (
        (portion (/ (* (get amt context) (get share beneficiary)) (get total context)))
       )
    (begin
      (unwrap-panic (as-contract (stx-transfer? portion tx-sender (get addr beneficiary))))
      context
    )
  )
)
;; ----------------------------
;; Public: withdraw
;; - If before unlock block: owner may withdraw but pays penalty
;; - If at/after unlock block: distribute to beneficiaries according to shares
(define-public (withdraw)
  (let ((amt (var-get locked-amount)))
    (begin
      (asserts! (> amt u0) err-no-funds)
      (if (< block-height (var-get unlock-block))
          ;; Early withdrawal with penalty (owner only)
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
              ;; Transfer each beneficiary their share using fold
              (fold distribute-share (var-get beneficiaries) {amt: amt, total: total})
              (ok amt)
            )
          )
      )
    )
  )
)
;; ----------------------------
;; Read-only helpers
(define-read-only (get-owner) (ok (var-get owner)))
(define-read-only (get-unlock-block) (ok (var-get unlock-block)))
(define-read-only (get-penalty-rate) (ok (var-get penalty-rate)))
(define-read-only (get-locked-amount) (ok (var-get locked-amount)))
(define-read-only (get-total-shares) (ok (var-get total-shares)))
(define-read-only (get-beneficiaries) (ok (var-get beneficiaries)))
