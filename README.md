 **AgroShare Tokenization Protocol (ATP)**

 **Tokenizing Agricultural Produce into Digital Shares (v1.0)**

A Clarity smart contract enabling farmers to convert their real-world agricultural produce into tradable on-chain token units. Investors can buy shares, redeem them after harvest, or request refunds if a harvest fails.

---

 **Overview**

AgroShare Tokenization Protocol (ATP) allows farmers to register produce and create a fixed supply of digital tokens representing ownership in the expected harvest. These tokens can be purchased by investors during an open sale window. After harvest, the farmer closes sales and investors redeem tokens for produce or off-chain payout.

This protocol enhances transparency, trust, and liquidity within agricultural financing.

---

 **Key Features**

* **Produce Tokenization:** Farmer converts produce into a fixed number of digital token shares.
* **Investor Participation:** Anyone can buy tokenized shares at a predefined price.
* **Harvest Workflow:** Farmer marks harvest completion, automatically closing sales.
* **Redemption Logic:** Investors redeem their tokens after harvest.
* **Refund Guarantee:** If no harvest occurs, buyers can claim a refund.
* **Event Logging:** Provides traceability via structured events.
* **Immutable Ledger:** Token balances are managed with a secure map-based ledger.

---

 **Contract Functions**

### ### **1. Farmer Actions**

| Function                | Description                                 |
| ----------------------- | ------------------------------------------- |
| `register-produce`      | Initializes supply, price, and opens sales. |
| `mark-harvest-complete` | Closes sales and marks harvest completion.  |

### **2. Investor Actions**

| Function        | Description                             |
| --------------- | --------------------------------------- |
| `buy-tokens`    | Buy tokenized produce shares.           |
| `redeem-tokens` | Redeem shares after harvest.            |
| `refund`        | Get refund if harvest is not completed. |

### **3. Query Functions**

| Read-only     | Description                     |
| ------------- | ------------------------------- |
| `get-balance` | Returns investor token balance. |
| `get-details` | Returns full protocol state.    |

---

 **Contract Flow**

1. **Farmer registers produce**
   → Sets total supply + price
   → Opens token sales
2. **Investors purchase tokens**
   → STX transfers to farmer
   → Token balances update
3. **Farmer marks harvest complete**
   → Sales close
   → Redemption becomes possible
4. **Investors redeem tokens**
   → Tokens burned
   → Off-chain settlement handled manually
5. **If harvest fails**
   → Investors call refund
   → STX returns from farmer
   → Tokens burned

---

 **State Variables**

| Variable            | Type      | Purpose                              |
| ------------------- | --------- | ------------------------------------ |
| `farmer`            | principal | Owner of produce tokenization.       |
| `total-supply`      | uint      | Total tokenized units.               |
| `remaining-supply`  | uint      | Tokens still available for purchase. |
| `price-per-token`   | uint      | Price in microSTX.                   |
| `harvest-completed` | bool      | Whether farmer has harvested.        |
| `sales-open`        | bool      | Whether token purchases are allowed. |

---

 **Events**

Events provide transparency during contract operation.

* `produce-registered`
* `tokens-purchased`
* `harvest-completed`
* `tokens-redeemed`
* `refund-issued`

---

 **Testing Recommendations**

To properly test ATP:

* Ensure only the farmer can register produce and mark harvest completion.
* Attempt buys > remaining supply to validate failure.
* Test harvest complete → token redemption.
* Test harvest NOT complete → refund flow.
* Validate event logs for correctness.

I can generate **unit tests in Clarinet** if needed.

---

 **License**

This project is licensed under the **MIT License** (or your preferred license — specify if needed).
