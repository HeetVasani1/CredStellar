# CredStellar 🚀

CredStellar is a next-generation fintech application that enables users to unlock credit lines backed by their Fixed Deposits (FDs). By leveraging the Stellar blockchain, CredStellar provides near-instant cross-border payment settlements and low transaction fees, bridging the gap between traditional finance (TradFi) and decentralized finance (DeFi).

## 🛠 Tech Stack

### Frontend
- **Framework**: [Flutter](https://flutter.dev/)
  - *Why*: Allows for a single codebase to target both Android and iOS with a premium, high-performance UI.
- **State Management**: [Riverpod](https://riverpod.dev/)
  - *Why*: Provides a robust, compile-safe, and testable way to manage application state and dependency injection.
- **Networking**: [Dio](https://pub.dev/packages/dio)
  - *Why*: Advanced HTTP client with support for interceptors and global configuration, essential for handling backend cold-starts and auth tokens.

### Backend
- **Runtime**: [Node.js](https://nodejs.org/) with [Express](https://expressjs.com/)
  - *Why*: Lightweight, fast, and highly scalable. Perfect for handling the middleware logic between the app, database, and blockchain.
- **Database**: [Supabase](https://supabase.com/) (PostgreSQL)
  - *Why*: Offers a powerful relational database with built-in authentication and real-time capabilities, reducing infrastructure overhead.

### Blockchain & Payments
- **Network**: [Stellar](https://stellar.org/)
  - *Why*: Optimized for payments. Stellar offers sub-5 second finality and negligible transaction fees (fixed at 0.00001 XLM), making it ideal for micro-payments and global remittances.
- **Currency**: XLM (Lumen) / Asset Simulation
  - *Why*: Used as the bridge currency for lightning-fast settlement between users and merchants.

---

## ✨ Key Features
- **FD-Backed Credit**: Create Fixed Deposits and instantly unlock a credit line up to 100% of the principal amount.
- **Scan to Pay**: Seamless QR code scanning (UPI & CredStellar protocol) for instant merchant payments.
- **Utilization Health**: Real-time tracking of credit usage with smart health tips to maintain excellent standing.
- **Global Settlements**: Automated FX conversion from local currency (INR) to USD/XLM for borderless transactions.
- **Security**: Secure storage of session tokens and biometric-ready authentication flows.

## 🚀 Getting Started

1.  **Clone the Repo**:
    ```bash
    git clone https://github.com/HeetVasani1/CredStellar.git
    ```
2.  **App Setup**:
    ```bash
    cd credstellar_app
    flutter pub get
    flutter run
    ```
3.  **Backend Setup**:
    ```bash
    cd credstellar_backend
    npm install
    npm run dev
    ```

---

*Built with ❤️ for the future of decentralized finance.*
