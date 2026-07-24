# Finance/HR Mobile Features — Backend Handoff

> **STATUS: implemented.** The backend shipped these endpoints (see
> `MOBILE_MODULE_API.md`), and the app has been realigned to the **actual**
> contracts. The proposal below is kept for history; the app now uses the real
> shapes (`POST /mobile/expenses` with `totalAmount`/`createDate`;
> `POST /mobile/finance/debtor-payment` with no date field;
> `POST /mobile/hr/salary` and `POST /mobile/hr/advance` — two endpoints).
>
> **Two gaps still open on the backend:**
> 1. **No employee-list endpoint** is documented. The salary/advance screen
>    needs `GET /mobile/hr/employees` (id, name, position) to populate the payee
>    picker — the app calls it optimistically; if it 404s the picker shows an
>    error. Please add it (or point us at the HR-module path).
> 2. **No GET/list for expenses** — fine for now (create-only), noted for later.

The proposed contracts below (pre-implementation):

Conventions (match the rest of the mobile module):
- Base path `/api/v1/mobile`. All authenticated (Bearer); derive tenant/user
  from the token.
- Success envelope `{ "success": true, "data": ... }`; error
  `{ "success": false, "error": { "code", "message", "details" } }`.
- Money is a decimal (BigDecimal); dates are `yyyy-MM-dd`.

If any field name or path differs from the proposal, tell the app team — only
the repository/model layer changes (`*_repository.dart`, `*_models.dart`).

---

## 1. Expenses

### Create expense
```
POST /api/v1/mobile/finance/expenses
{
  "amount": 150000.00,           // required, > 0
  "categoryId": 3,               // optional (if categories are used)
  "category": "Rent",            // optional free-text fallback
  "description": "October rent", // required
  "expenseDate": "2026-07-24",   // required
  "paymentSource": "CASH",       // "CASH" | "BANK", required
  "notes": "..."                 // optional
}
→ 200 { "success": true, "data": {
    "id": 987, "amount": 150000.00, "category": "Rent",
    "description": "October rent", "expenseDate": "2026-07-24",
    "paymentSource": "CASH", "createdAt": "2026-07-24T10:00:00Z" } }
```

### (Optional) expense categories — for a dropdown
```
GET /api/v1/mobile/finance/expense-categories
→ 200 { "success": true, "data": [ { "id": 1, "name": "Rent" }, … ] }
```
If omitted, the app uses a free-text category field.

**Permission:** e.g. `FINANCE_EXPENSE_CREATE`.

---

## 2. Debtor (AR) payments — receive payment from a customer

The app lists a customer's unpaid invoices already
(`GET /finance/ar-invoices/customer/{id}/unpaid`). This adds recording a
payment against that customer's balance.

```
POST /api/v1/mobile/finance/ar-payments
{
  "customerId": 42,             // required
  "amount": 500000.00,          // required, > 0
  "paymentMethod": "CASH",      // "CASH" | "CARD" | "BANK", required
  "paymentDate": "2026-07-24",  // required
  "invoiceId": 555,             // optional — allocate to one invoice;
                                //   omit to auto-allocate oldest-first
  "notes": "..."                // optional
}
→ 200 { "success": true, "data": {
    "id": 321, "customerId": 42, "amount": 500000.00,
    "newBalance": 1000000.00,          // customer AR balance after payment
    "allocations": [ { "invoiceId": 555, "applied": 500000.00 } ],
    "createdAt": "2026-07-24T10:05:00Z" } }
```

Behaviour: reduce the customer's AR balance; if `invoiceId` is given apply to
that invoice, else auto-allocate oldest-first; reject if `amount` exceeds the
outstanding balance (or allow overpayment/credit — please confirm which).

**Permission:** e.g. `FINANCE_AR_PAYMENT_CREATE`.

---

## 3. Employee salary / advance

### List employees (for the picker)
```
GET /api/v1/mobile/hr/employees
→ 200 { "success": true, "data": [
    { "id": 7, "name": "Ali Valiyev", "position": "Cashier" }, … ] }
```

### Record a salary or advance payment
```
POST /api/v1/mobile/hr/salary-payments
{
  "employeeId": 7,              // required
  "amount": 3000000.00,         // required, > 0
  "paymentType": "SALARY",      // "SALARY" | "ADVANCE", required
  "paymentDate": "2026-07-24",  // required
  "paymentSource": "CASH",      // "CASH" | "BANK", required
  "notes": "..."                // optional
}
→ 200 { "success": true, "data": {
    "id": 654, "employeeId": 7, "amount": 3000000.00,
    "paymentType": "SALARY", "paymentDate": "2026-07-24",
    "createdAt": "2026-07-24T10:10:00Z" } }
```
Both salary and advance are cash/bank outflows (like an expense); an advance may
also be tracked as recoverable against the employee — please confirm if so.

**Permission:** e.g. `HR_SALARY_PAYMENT_CREATE`.

---

## Definition of done
The backend can persist an expense, an AR payment (reducing customer balance),
and a salary/advance payment, each returning the documented `data` object. Until
these are live, the app's pages submit and surface the backend error — no data
is fabricated client-side.
