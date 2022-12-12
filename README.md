# Financial Management Application (demo)
I developed this application to serve as an alternative to Quicken for recording and analyzing my personal finances. The application was never meant to be distributed for others to use, but I wanted to create this demo to convey its overall functionality. All records and personal information have been replaced with dummy records for preview purposes only.

The dashboard is hosted live at https://dennisarnold.shinyapps.io/Financial_Management_Application_Demo/

There are three primary components of the application: [record storage](#sqlite-database), [record importing](#import-transactions), and the [dashboard](#dashboard) where records can be summarized and edited.




## SQLite Database
Transactions from bank and brokerage accounts are stored in `SQLite Database/Sample Finance Records.db`. Tables exist for both active accounts and old accounts that have been closed.


### Bank Accounts
Each bank account has its own table with the following columns:

Field | Description | Required
--- | --- | ---
transID | Unique ID for each transaction | Required
transDate | Date the transaction took place | Required
transDescription | Description of the transaction as provided from the bank (editable) | Recommended
transMemo | Itemization or additional details of the transaction as provided by the user | Optional
transCategory | Category that the transaction falls under, selected from a pre-defined list | Recommended
transAmount | USD amount the transaction is for | Required
transReconciled | Boolean value indicating that the user has reviewed and confirmed the transaction to be valid and complete | Optional
transOriginalDescription | Description of the transaction as provided from the bank (not editable) | Recommended


### Brokerage Accounts
Each brokerage account has it's own table with the following columns:

Field | Description | Required
--- | --- | ---
transID | Unique ID for each transaction | Required
transDate | Date the transaction took place | Required
transDescription | Description of the transaction as provided from the brokerage | Not Required
securitySymbol | Ticker symbol of the security | Not Required
securityDescription | Full name of the security | Not Required
transQuantity | Number of shares involved in the transaction | Not Required
securityPrice | Price per share the security was traded at | Not Required
transAmount | USD amount the transaction is for | Not Required


### Cryptocurrency
The `Cryptocurrency` table serves as a rudimentary means for recording the monthly balance of a diversified cryptocurrency portfolio. This table is only used for plotting purposes and is not meant to serve as a store of record like the bank and brokerage tables.

Field | Description
--- | ---
plotMonth | The first day of the month, stored as a data value
value | USD equivalent portfolio balance at the end of the month

To represent a non-diversified portfolio consisting of only Bitcoin, the demo is currently hard-configured to pull and calculate the USD value of a set quantity of Bitcoin after the most recent entry in this table.


### Other
The `Categories` table contains a single column where the banking transCategory options are defined. Subcategories can be defined with the use of colons (e.g. Shopping:Food:Groceries)


The `All_Banking` view combines all the bank accounts to simplify report querying. Various sample queries can be found in `MyReports.sql`.




## Import Transactions
The process of importing transactions from bank and brokerage accounts is handled in `Import Transactions/`.


### Bank Transactions
*NOTE: In the production version there are two methods for importing bank transactions: reading CSV files that are downloaded from a bank, and connecting to a bank using Plaid to read transactions directly. For this demo, only the first method is demonstrated.*

To import bank transactions, the transactions are first downloaded in CSV format from a bank. There should be one CSV file for each account; in this demo there are three accounts: checking, savings, and visa. The downloaded CSV files are then renamed appropriately (for this demo, "checking", "savings", "visa") and placed in `Import Transactions/Bank Transactions`.

At this point, `Import Bank Transactions (csv).py` is run. Each account is processed entirely separately, one after another. First, the script compares the transactions in the CSV file to those in the database and determines which transactions are new. It is ideal to have some overlap between the transactions in the CSV files and those in the database in order to ensure that there are no gaps. If there is no overlap, the script will alert the user via the terminal. The script will then display the new transactions and prompt the user to proceed with the import.

Rules can be set up in `Description rules.csv` and `Category rules.csv` to automatically rename the transaction description and assign a category during the import process for recurring transactions. For example, it may be desirable to rename transactions that the bank calls "FOOD LION (STORE 123)" to simply "Food Lion" and assign it the "Shopping:Food:Groceries" category.


### Investment Transactions
Investment transactions are imported similarly to the bank CSV method via the `Import Investment Transactions.py` script. A key difference is instead of being split up into separate CSV files for each account, all investment accounts are exported together in a single CSV file from a brokerage firm. This file is then renamed "investment_transactions.csv" and placed in `Import Transactions/Investment Transactions`.

## Dashboard
The dashboard is run as a Shiny App in `Dashboard.R`. Helper files in `Dashboard/` are used to process and prepare the information for the dashboard.

The dashboard is comprised of two tabs: Summary and Records. The Summary tab provides an overview of account balances, trends, and overall net worth. The Records tab is where bank transactions from active accounts can be easily viewed, tweaked, and reconciled.