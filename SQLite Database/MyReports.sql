--category totals over the past 30 days
SELECT transCategory, SUM(ROUND(transAmount)) as Amount
FROM All_Banking
WHERE transDate > date('now', '-30 days')
GROUP BY transCategory
ORDER BY Amount DESC;


--total investments over past 3 years
SELECT SUM(ROUND(transAmount)) as Amount
FROM All_Banking
WHERE transDate BETWEEN '2018-02-02' AND '2021-02-02'
    AND transCategory LIKE '%investing%';


--what was my average electric bill during 2019?
SELECT AVG(transAmount)
FROM All_Banking
WHERE transCategory = 'Utilities:Electric'
    AND transDate BETWEEN '2019-01-01' AND '2020-01-01';


--sum my phone bills by month
SELECT strftime("%Y-%m", transDate) as 'Month', SUM(transAmount) 
FROM All_Banking
WHERE transCategory = 'Utilities:Phone'
GROUP BY strftime("%Y-%m", transDate)
ORDER BY strftime("%Y-%m", transDate);


--sum how many times I went to resturants by year
SELECT strftime("%Y", transDate) as 'Year', COUNT(transAmount) as 'Count', ROUND(SUM(transAmount), 0) as 'Cost', ROUND(SUM(transAmount) / COUNT(transAmount), 2) as 'Avg cost per meal'
FROM All_Banking
WHERE transCategory = 'Shopping:Food:Restaurant'
GROUP BY strftime("%Y", transDate)
ORDER BY strftime("%Y", transDate);


--average monthly cost of groceries, summarized by year
SELECT
    substr(transMonth, 1, 4) as 'Year',  --since subquery converted the date to a string, we now have to use substr to extract the year
    ROUND(AVG(monthlySum), 0) as 'Average Monthly Grocery Cost'
FROM
    (
    SELECT strftime("%Y-%m", transDate) as 'transMonth', SUM(transAmount) as 'monthlySum'
    FROM All_Banking
    WHERE transCategory = 'Shopping:Food:Groceries'
    GROUP BY strftime("%Y-%m", transDate)
    ORDER BY strftime("%Y-%m", transDate)
    )
GROUP BY substr(transMonth, 1, 4)
ORDER BY substr(transMonth, 1, 4);


--how much interest have my accounts gained in 2021?
SELECT  transAccount, SUM(transAmount)
FROM All_Banking
WHERE transCategory = 'Interest'
AND transDate BETWEEN '2021-01-01' AND '2022-01-01'
GROUP BY transAccount;