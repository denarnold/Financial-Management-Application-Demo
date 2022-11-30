--replace transDescription records
WITH Companies AS (
    SELECT
        transID,
        CASE ABS(RANDOM()) % 10 / 2
            WHEN 0 THEN 'Employer'
            WHEN 1 THEN 'Advance Auto Parts'
            WHEN 2 THEN 'Rite Aid'
            WHEN 3 THEN 'Target'
            ELSE 'Food Lion'
        END AS company            
    FROM Savings_6893
)
UPDATE Savings_6893
SET transDescription = Companies.company
FROM Companies
WHERE Companies.transID = Savings_6893.transID;


--replace transMemo records
UPDATE Savings_6893
SET transMemo = CASE
    WHEN transDescription = 'Employer' THEN 'Paycheck'
    WHEN transDescription = 'Advance Auto Parts' THEN 'Part for car'
    WHEN transDescription = 'Rite Aid' THEN NULL
    WHEN transDescription = 'Target' THEN 'Storage containers'
    WHEN transDescription = 'Food Lion' THEN NULL
    ELSE NULL
    END;
    

--replace transCategory records
UPDATE Savings_6893
SET transCategory = CASE
    WHEN transDescription = 'Employer' THEN 'Income'
    WHEN transDescription = 'Advance Auto Parts' THEN 'Auto:Parts'
    WHEN transDescription = 'Rite Aid' THEN 'Medical'
    WHEN transDescription = 'Target' THEN 'Shopping:Household'
    WHEN transDescription = 'Food Lion' THEN 'Shopping:Food:Groceries'
    ELSE NULL
    END;

    
--replace transAmount records
UPDATE Savings_6893
SET transAmount = ABS(ROUND(RANDOM() / 100000000000000000.00, 2)) * -1;

UPDATE Savings_6893
SET transAmount = 400
WHERE transDescription = 'Employer';


--replace transOriginalDescription
UPDATE Savings_6893
SET transOriginalDescription = transDescription;


--check overall account balance
SELECT SUM(transAmount)
FROM Savings_6893;