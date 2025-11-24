;; ------------------------------------------------------------
;;  AGROSHARE TOKENIZATION PROTOCOL (ATP)
;;  Tokenizing agricultural produce into tradeable digital shares
;;  Version: 1.0
;; ------------------------------------------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CONSTANTS & ERROR CODES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-constant ERR-NOT-FARMER u100)
(define-constant ERR-NOT-INVESTOR u101)
(define-constant ERR-NOT-ENOUGH u102)
(define-constant ERR-NOT-HARVESTED u103)
(define-constant ERR-ALREADY-HARVESTED u104)
(define-constant ERR-SALES-CLOSED u105)
(define-constant ERR-NO-TOKENS u106)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Address of the farmer (contract owner)
(define-data-var farmer principal tx-sender)

;; Total number of tokens representing the produce
(define-data-var total-supply uint u0)

;; Tokens remaining for sale
(define-data-var remaining-supply uint u0)

;; Price per token (in microSTX)
(define-data-var price-per-token uint u0)

;; Harvest status
(define-data-var harvest-completed bool false)

;; Sales open/closed
(define-data-var sales-open bool false)

;; Token ledger
(define-map balances
  { owner: principal }
  { amount: uint })


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; EVENTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-private (emit-event (name (string-ascii 32)) (data uint))
  (print { event: name, value: data })
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PUBLIC FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; ------------------------------------------------------------
;; REGISTER PRODUCE & INITIALIZE TOKEN ECONOMY
;; ------------------------------------------------------------

(define-public (register-produce (supply uint) (price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get farmer)) (err ERR-NOT-FARMER))

    (var-set total-supply supply)
    (var-set remaining-supply supply)
    (var-set price-per-token price)
    (var-set sales-open true)

    (emit-event "produce-registered" supply)
    (ok true)
  )
)


;; ------------------------------------------------------------
;; INVESTORS BUY TOKEN SHARES
;; ------------------------------------------------------------

(define-public (buy-tokens (quantity uint))
  (begin
    (asserts! (var-get sales-open) (err ERR-SALES-CLOSED))
    (asserts! (<= quantity (var-get remaining-supply)) (err ERR-NOT-ENOUGH))

    (let
        (
          (cost (* quantity (var-get price-per-token)))
          (current-balance (default-to u0 (get amount (map-get? balances { owner: tx-sender }))))
        )

      ;; payment transferred to farmer
      (try! (stx-transfer? cost tx-sender (var-get farmer)))

      ;; update ledger
      (map-set balances
        { owner: tx-sender }
        { amount: (+ current-balance quantity) })

      ;; update remaining supply
      (var-set remaining-supply (- (var-get remaining-supply) quantity))

      (emit-event "tokens-purchased" quantity)
      (ok quantity)
    )
  )
)


;; ------------------------------------------------------------
;; FARMER MARKS HARVEST COMPLETION
;; ------------------------------------------------------------

(define-public (mark-harvest-complete)
  (begin
    (asserts! (is-eq tx-sender (var-get farmer)) (err ERR-NOT-FARMER))
    (asserts! (not (var-get harvest-completed)) (err ERR-ALREADY-HARVESTED))

    (var-set harvest-completed true)
    (var-set sales-open false)

    (emit-event "harvest-completed" u1)
    (ok true)
  )
)


;; ------------------------------------------------------------
;; INVESTORS REDEEM TOKENS AFTER HARVEST
;; (Off-chain produce distribution or payout is handled manually)
;; ------------------------------------------------------------

(define-public (redeem-tokens)
  (let
      (
        (my-balance (default-to u0 (get amount (map-get? balances { owner: tx-sender }))))
      )

    (asserts! (var-get harvest-completed) (err ERR-NOT-HARVESTED))
    (asserts! (> my-balance u0) (err ERR-NO-TOKENS))

    ;; burn tokens after redemption
    (map-set balances { owner: tx-sender } { amount: u0 })

    (emit-event "tokens-redeemed" my-balance)
    (ok my-balance)
  )
)


;; ------------------------------------------------------------
;; REFUND IF FARMER CANCELS OR FAILS TO HARVEST
;; ------------------------------------------------------------

(define-public (refund)
  (let
      (
        (my-bal (default-to u0 (get amount (map-get? balances { owner: tx-sender }))))
        (token-price (var-get price-per-token))
      )

    (asserts! (not (var-get harvest-completed)) (err ERR-NOT-HARVESTED))
    (asserts! (> my-bal u0) (err ERR-NO-TOKENS))

    (let ((refund-amount (* my-bal token-price)))

      ;; transfer refund from farmer to investor
      (try! (stx-transfer? refund-amount (var-get farmer) tx-sender))

      ;; burn tokens
      (map-set balances { owner: tx-sender } { amount: u0 })

      (emit-event "refund-issued" refund-amount)
      (ok refund-amount)
    )
  )
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; READ-ONLY FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-read-only (get-balance (user principal))
  (ok (default-to u0 (get amount (map-get? balances { owner: user }))))
)

(define-read-only (get-details)
  (ok {
        farmer: (var-get farmer),
        total-supply: (var-get total-supply),
        remaining-supply: (var-get remaining-supply),
        price-per-token: (var-get price-per-token),
        sales-open: (var-get sales-open),
        harvest-completed: (var-get harvest-completed)
      })
)
