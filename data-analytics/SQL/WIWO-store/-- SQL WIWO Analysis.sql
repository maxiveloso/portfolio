-- 00_data_quality_checks
    -- Fact rows without a matching customer
    SELECT COUNT(*) AS OrphanCustomerKeys
        FROM factSale s
        LEFT JOIN dimCustomer c ON s.[Customer Key] = c.[Customer Key]
        WHERE c.[Customer Key] IS NULL;

    -- Unknowns by dimension
    SELECT 
            'dimStockItem' AS dim, COUNT(*) AS UnknownCnt FROM dimStockItem WHERE [Stock Item] = 'Unknown'
        UNION ALL
        SELECT 'dimCustomer', COUNT(*) FROM dimCustomer WHERE [Customer] = 'Unknown'
        UNION ALL
        SELECT 'dimEmployee', COUNT(*) FROM dimEmployee WHERE [Employee] = 'Unknown';

-- 01_exploratory_analysis

    -- Basic Exploratory Queries
    --- Lowest price item
        SELECT 
                [Stock Item], [Unit Price]
            FROM 
                [dbo].[dimStockItem]
            WHERE 
                [Unit Price] = (SELECT MIN([Unit Price])
                        FROM [dbo].[dimStockItem]
                        WHERE [Stock Item] <> 'Unknown')
                AND [Stock Item] <> 'Unknown';

    --- Exclude all items that contain the word box, bag, or carton in their names.
        SELECT 
                [Stock Item], [Unit Price]
            FROM 
                [dbo].[dimStockItem]
            WHERE 
                [Unit Price] = (SELECT MIN([Unit Price])
                            FROM [dbo].[dimStockItem]
                            WHERE [Stock Item] <> 'Unknown'
                                AND [Stock Item] NOT LIKE '%box%'
                                AND [Stock Item] NOT LIKE '%bag%'
                                AND [Stock Item] NOT LIKE '%carton%')
            AND [Stock Item] <> 'Unknown'
            AND [Stock Item] NOT LIKE '%box%'
            AND [Stock Item] NOT LIKE '%bag%'
            AND [Stock Item] NOT LIKE '%carton%';

    --- list of products that contain mug or shirt in their name
        SELECT 
            COUNT([Stock Item]) 
            FROM 
            [dbo].[dimStockItem]
            WHERE 
            [Stock Item] <> 'Unknown'
                AND ([Stock Item] LIKE '%shirt%' OR [Stock Item] LIKE '%mug%');

    --- products that also meet that description 'black'
        SELECT 
                COUNT ([Stock Item]) 
            FROM 
                [dbo].[dimStockItem]
            WHERE 
                [Stock Item] <> 'Unknown' 
                AND ([Stock Item] LIKE '%shirt%' OR [Stock Item] LIKE '%mug%')
                AND [Color] LIKE '%black%';

    ---  WWI Stock Item ID of the cheapest product 
        SELECT 
            TOP 1 [Stock Item], [Unit Price], [WWI Stock Item ID]
                FROM 
                    [dbo].[dimStockItem]
                WHERE 
                    [Stock Item] <> 'Unknown'
                    AND [Stock Item] NOT LIKE '%box%'
                    AND [Stock Item] NOT LIKE '%bag%'
                    AND [Stock Item] NOT LIKE '%carton%'
                    AND ([Stock Item] LIKE '%shirt%' OR [Stock Item] LIKE '%mug%')
                ORDER BY 
                    [Unit Price] ASC;

    --- Markup of WWI Stock Item ID 29?
        SELECT 
                [Stock Item], 
                [Unit Price], 
                [WWI Stock Item ID],
                cast(([Recommended Retail Price]-[Unit Price])/[Unit Price] as decimal(8,4)) as  Markup
            FROM 
                [dbo].[dimStockItem]
            WHERE 
                [Stock Item] <> 'Unknown'
                    AND [Stock Item] NOT LIKE '%box%'
                    AND [Stock Item] NOT LIKE '%bag%'
                    AND [Stock Item] NOT LIKE '%carton%'
                    AND ([Stock Item] LIKE '%shirt%' OR [Stock Item] LIKE '%mug%')
                    and [WWI Stock Item ID]=29
            ORDER BY 
                [Unit Price] ASC;

    --- Number of custormers in each buying group
        SELECT
                [Buying Group],
                COUNT([Customer Key]) AS NumberOfCustomers
            FROM
                [dbo].[DimCustomer]
            GROUP BY
                [Buying Group]
            ORDER BY
                [Buying Group];

    --- Total number of employees (excluding 'Unknown')
        SELECT
            COUNT(Employee) as EmployeeCnt
            FROM 
                dimemployee
            WHERE 
                employee <> 'Unknown'

    --- Proportion of workforce that works in sales
        select 
            CAST(cast(COUNT([Employee]) as decimal(8,2))/ 
                (select 
                    COUNT([Employee])
                    from 
                        dimEmployee
                    WHERE 
                        Employee <> 'Unknown') AS DECIMAL(8,4)) AS SalesPplPctOfTot
            FROM 
                dimEmployee
            WHERE 
                Employee <> 'Unknown' AND [Is Salesperson]=1

    --- Sales territory with the highest population
        SELECT
                [Sales Territory],
                SUM([Latest Recorded Population]) AS TotalPopulation
            FROM
                dbo.dimCity
            GROUP BY
                [Sales Territory]
            HAVING
                SUM([Latest Recorded Population]) = (
                    SELECT
                        MAX(TerritoryTotalPopulation)
                    FROM (
                        SELECT
                            SUM([Latest Recorded Population]) AS TerritoryTotalPopulation
                        FROM
                            dbo.dimCity
                        GROUP BY
                            [Sales Territory]
                    ) AS SubqueryTerritoryPopulations
                );

    --- Number of cities are in the above territory
        SELECT
                COUNT([City Key]) AS NumberOfCitiesInTopTerritory
            FROM
                dbo.dimCity
            WHERE [Sales Territory] IN (
                    SELECT
                        [Sales Territory]
                    FROM
                        dbo.dimCity
                    GROUP BY
                        [Sales Territory]
                    HAVING
                        SUM([Latest Recorded Population]) = (
                            SELECT
                                MAX(TerritoryTotalPopulation)
                            FROM (
                                SELECT
                                    SUM([Latest Recorded Population]) AS TerritoryTotalPopulation
                                FROM
                                    dbo.dimCity
                                GROUP BY
                                    [Sales Territory]
                            ) AS SubqueryTerritoryPopulations
                        )
                );

    --- Population of the biggest city in that territory
        WITH 
            TopSalesTerritories AS (
                -- Territories with highest population
                SELECT
                    [Sales Territory]
                FROM
                    dbo.dimCity
                GROUP BY
                    [Sales Territory]
                HAVING
                    SUM([Latest Recorded Population]) = (
                        SELECT
                            MAX(TerritoryTotalPopulation)
                        FROM (
                            SELECT
                                SUM([Latest Recorded Population]) AS TerritoryTotalPopulation
                            FROM
                                dbo.dimCity
                            GROUP BY
                                [Sales Territory]
                        ) AS SubqueryTerritoryPopulations
                    )
            ),
            CitiesInTopTerritories AS (
                -- Cities from those territories
                SELECT
                    C.[City],
                    C.[Sales Territory],
                    C.[Latest Recorded Population]
                FROM
                    dbo.dimCity AS C
                JOIN
                    TopSalesTerritories AS T
                    ON C.[Sales Territory] = T.[Sales Territory]
            ),
            RankedCities AS (
                -- population per city within each main territory
                SELECT
                    [City],
                    [Sales Territory],
                    [Latest Recorded Population],
                    ROW_NUMBER() OVER (PARTITION BY [Sales Territory] ORDER BY [Latest Recorded Population] DESC) AS rn
                FROM
                    CitiesInTopTerritories
            )
            -- Biggest city from each main territory
                SELECT
                        [City],
                        [Sales Territory],
                        [Latest Recorded Population] AS BiggestCityPopulation
                    FROM
                        RankedCities
                    WHERE
                        rn = 1;

    --- Total population across all sales territories
        SELECT
            SUM([Latest Recorded Population]) AS TotalPopulationAcrossAllTerritories
            FROM
                dbo.dimCity;

    --- Total population, count of cities, max city population for each sales territory. Also adds a total row.
        SELECT
                isnull([Sales Territory],'Total') as SalesTerritory,
                SUM([Latest Recorded Population]) AS TotalPopulation,
                COUNT([WWI City ID]) AS NumberOfCities,
                MAX([Latest Recorded Population]) AS PopulationInBiggestCity
            FROM 
                dimCity
            WHERE 
                City !='Unknown'
            GROUP BY 
                ROLLUP ([Sales Territory])
            ORDER BY 
                TotalPopulation DESC

        -- Cluster analysis for Wingtip Toys shops 
   
-- 02_clusters
    --- Wingtip Toys clustering (postcode/geo)
    --- Postcodes with more than 3 Wingtip Toys shops
        SELECT
                [Postal Code], 
                COUNT(*) AS NumberOfWingtipToysShops
            FROM
                [dbo].[DimCustomer] 
            WHERE
                [Buying Group] LIKE '%Wingtip Toys%'
            GROUP BY
                [Postal Code]
            HAVING
                COUNT([Buying Group]) > 3;

    -- Stores to include in an efficency trial
        SELECT
                [Postal Code],
                Customer
            FROM
                dimCustomer
            WHERE
            [Buying Group] = 'Wingtip Toys'
            AND [Postal Code] IN (
                SELECT
                    [Postal Code]
                FROM
                    dimCustomer
                WHERE
                    [Buying Group] = 'Wingtip Toys'
                GROUP BY
                    [Postal Code]
                HAVING
                    COUNT([Customer Key]) > 3
            )


        --- or, using JOIN
                    WITH PostcodesWithManyWingtipToys AS (
                    SELECT
                        [Postal Code]
                    FROM
                        [dbo].[DimCustomer]
                    WHERE
                        [Buying Group] LIKE '%Wingtip Toys%' 
                    GROUP BY
                        [Postal Code]
                    HAVING
                        COUNT([Customer Key]) > 3
                )
                SELECT
                    C.[Buying Group],
                    C.[Postal Code],
                    C.[Customer Key]
                FROM
                    [dbo].[DimCustomer] AS C
                JOIN
                    PostcodesWithManyWingtipToys AS P
                    ON C.[Postal Code] = P.[Postal Code]
                WHERE
                    C.[Buying Group] LIKE '%Wingtip Toys%';

-- 03_time_intelligence_analysis
    --- Time intelligence with window functions (YoY/MoM/YTD)
        WITH monthly AS (
            SELECT d.[Fiscal Year] AS FiscalYear,
                    d.[Fiscal Month Number] AS FiscalMonth,
                    SUM(s.[Total Excluding Tax]) AS SalesExTax,
                    SUM(s.[Profit]) AS Profit
            FROM factSale s
            JOIN dimDate d ON s.[Invoice Date Key] = d.[Date]
            GROUP BY d.[Fiscal Year], d.[Fiscal Month Number]
            )
            SELECT m.*,
                LAG(m.SalesExTax)  OVER (PARTITION BY m.FiscalMonth ORDER BY m.FiscalYear) AS LY_Sales,
                LAG(m.Profit)      OVER (PARTITION BY m.FiscalMonth ORDER BY m.FiscalYear) AS LY_Profit,
                (m.SalesExTax - LAG(m.SalesExTax) OVER (PARTITION BY m.FiscalMonth ORDER BY m.FiscalYear))
                    / NULLIF(LAG(m.SalesExTax) OVER (PARTITION BY m.FiscalMonth ORDER BY m.FiscalYear), 0.0) AS YoY_Sales,
                SUM(m.SalesExTax) OVER (PARTITION BY m.FiscalYear ORDER BY m.FiscalMonth
                                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS YTD_Sales
            FROM monthly m
            ORDER BY m.FiscalYear DESC, m.FiscalMonth DESC;

    ---- Sales Excluding Tax per year
        SELECT 
                d.[fiscal year] as FiscalYear,
                sum(s.[total excluding tax]) as TotalSalesExclTax
            from 
                dbo.factsale as s 
            inner join 
                dimdate as d on s.[invoice date key] = d.[date]
            group by 
                d.[Fiscal Year]
            order by 
                d.[Fiscal Year]

    ---- Fiscal year with highest profit
        SELECT 
                d.[fiscal year] as FiscalYear,
                sum(s.[profit]) as Profit
            from 
                dbo.factsale as s 
            inner join 
                dimdate as d on s.[invoice date key] = d.[date]
            group by 
                d.[Fiscal Year]
            order by 
                sum(s.[profit]) desc

        ---- Aggregated table
        SELECT 
            d.[fiscal year] as FiscalYear,
            sum(s.[profit]) as Profit,
            sum(s.[total excluding tax]) as TotalSalesExclTax,
            sum(s.[quantity]) as QuantitySold
        from 
            dbo.factsale as s 
        inner join 
            dimdate as d on s.[invoice date key] = d.[date]
        group by 
            d.[Fiscal Year]
        order by 
            d.[Fiscal Year] desc
    
-- 04_drivers
    --- profit analysis:
        -----  why profit from 2016 is significantly lower than 2015?
        --let's explore sales by month first
        SELECT
                d.[Fiscal Year] AS FiscalYear,
                d.[Fiscal Month Label] AS FiscalYearMonth,
                d.[Fiscal Month Number] AS FiscalMonthNumber,
                SUM(s.[Total Excluding Tax]) AS TotalSalesExcludingTax,
                SUM(s.[Quantity]) AS QuantitySold,
                SUM(s.[Profit]) AS Profit
            FROM 
                factSale AS s
            INNER JOIN 
                dimDate AS d ON s.[Invoice Date Key] = d.[Date]
            GROUP BY 
                d.[Fiscal Year], d.[Fiscal Month Label], d.[Fiscal Month Number]
            ORDER BY 
                FiscalMonthNumber

        ----- other possible scenarios we could have ran were lower quantity sold, or pricing problems, higher tax, higher cost
        ---- total profit, total sales and average profit per sale:
            SELECT
                    d.[Fiscal Year] AS FiscalYear,
                    d.[Fiscal Month Label] AS FiscalYearMonth,
                    d.[Fiscal Month Number] AS FiscalMonthNumber,
                    SUM(s.profit) AS TotalProfit,
                    COUNT(s.[sale key]) AS TotalSales,
                    SUM(s.profit) / COUNT(s.[sale key]) AS AverageProfitPerSale
                FROM
                    factSale AS s
                INNER JOIN 
                    dimDate AS d ON s.[invoice date key] = d.Date
                WHERE
                    d.[fiscal year] IN (2015, 2016)
                GROUP BY
                    d.[Fiscal Year], d.[Fiscal Month Label], d.[Fiscal Month Number]
                ORDER BY
                    d.[fiscal year];

    --- contribution analysis 
        --(which customers/products/cities drove the delta)
            WITH by_dim AS (
            SELECT d.[Fiscal Year] AS FY,
                    c.[Customer] AS DimVal,      -- swap for si.[Stock Item] or sc.[City] to pivot view
                    SUM(s.[Profit]) AS Profit
            FROM factSale s
            JOIN dimDate d ON s.[Invoice Date Key] = d.[Date]
            JOIN dimCustomer c ON s.[Customer Key] = c.[Customer Key]
            GROUP BY d.[Fiscal Year], c.[Customer]
            ),
            delta AS (
            SELECT DimVal,
                    SUM(CASE WHEN FY = 2016 THEN Profit ELSE 0 END) -
                    SUM(CASE WHEN FY = 2015 THEN Profit ELSE 0 END) AS Profit_Delta
            FROM by_dim
            WHERE FY IN (2015, 2016)
            GROUP BY DimVal
            )
            SELECT TOP 20 *
            FROM delta
            ORDER BY Profit_Delta ASC; -- most negative contributors first

    --- client analysis:
            SELECT
                    c.[Customer],
                    d.[Fiscal Year] AS FiscalYear,
                    SUM(s.profit) AS TotalProfit
                FROM
                    factSale AS s
                INNER JOIN
                    dimCustomer AS c ON s.[Customer Key] = c.[Customer Key]
                INNER JOIN
                    dimDate AS d ON s.[Invoice Date Key] = d.[Date]
                WHERE
                    d.[Fiscal Year] IN (2015, 2016)
                GROUP BY
                    c.[Customer],
                    d.[Fiscal Year]
                ORDER BY
                    c.[Customer],
                    d.[Fiscal Year];

        ----- Customer RFM segmentation (recency, frequency, monetary)
            DECLARE @as_of_date date = (SELECT MAX([Date]) FROM dimDate);
                WITH cust_sales AS (
                    SELECT s.[Customer Key],
                        MIN(d.[Date]) AS first_purchase,
                        MAX(d.[Date]) AS last_purchase,
                        COUNT(DISTINCT s.[WWI Invoice ID]) AS frequency,
                        SUM(s.[Total Excluding Tax]) AS monetary
                    FROM factSale s
                    JOIN dimDate d ON s.[Invoice Date Key] = d.[Date]
                    INNER JOIN
                        dimCustomer AS c ON s.[Customer Key] = c.[Customer Key]
                    GROUP BY s.[Customer Key]
                ),
                rfm AS (
                    SELECT c.[Customer Key],
                        DATEDIFF(day, last_purchase, @as_of_date) AS recency_days,
                        frequency,
                        monetary,
                        NTILE(5) OVER (ORDER BY DATEDIFF(day, last_purchase, @as_of_date) ASC) AS R,
                        NTILE(5) OVER (ORDER BY frequency DESC) AS F,
                        NTILE(5) OVER (ORDER BY monetary DESC) AS M
                    FROM cust_sales c
                )
                SELECT r.*,
                    c.Customer,
                    CONCAT(R, F, M) AS RFM_Segment
                FROM rfm r
                INNER JOIN dimCustomer AS c ON r.[Customer Key] = c.[Customer Key];

    --- product analysis:
            SELECT
                    si.[Stock Item],
                    d.[Fiscal Year] AS FiscalYear,
                    SUM(s.profit) AS TotalProfit,
                    SUM(s.quantity) AS TotalQuantitySold
                FROM
                    factSale AS s
                INNER JOIN
                    dimStockItem AS si ON s.[Stock Item Key] = si.[Stock Item Key]
                INNER JOIN
                    dimDate AS d ON s.[Invoice Date Key] = d.[date]
                WHERE
                    d.[Fiscal Year] IN (2015, 2016)
                GROUP BY
                    si.[Stock Item],
                    d.[Fiscal Year]
                ORDER BY
                    si.[Stock Item],
                    d.[Fiscal Year];

        ------ Percentiles and outliers (price bands and daily revenue anomalies)
        -- Price deciles and median for stock items
        SELECT [Stock Item], [Unit Price],
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY [Unit Price]) OVER () AS median_price,
            NTILE(10) OVER (ORDER BY [Unit Price]) AS price_decile
            FROM [dbo].[dimStockItem]
            WHERE [Stock Item] <> 'Unknown';

        -- Daily revenue 3-sigma outliers
        WITH daily AS (
            SELECT d.[Date], SUM(s.[Total Excluding Tax]) AS revenue
            FROM factSale s
            JOIN dimDate d ON s.[Invoice Date Key] = d.[Date]
            GROUP BY d.[Date]
            ),
            stats AS (
            SELECT AVG(CAST(revenue AS float)) AS mu, STDEV(CAST(revenue AS float)) AS sigma FROM daily
            )
            SELECT a.[Date], a.revenue,
                (a.revenue - s.mu) / NULLIF(s.sigma, 0.0) AS z_score
            FROM daily a CROSS JOIN stats s
            WHERE ABS((a.revenue - s.mu) / NULLIF(s.sigma, 0.0)) >= 2  -- threshold was be adjusted to 2 because there were no results with 3
            ORDER BY ABS((a.revenue - s.mu) / NULLIF(s.sigma, 0.0)) DESC;

        ------ top selling product in 2016 fiscal year so far
        SELECT
                si.[Stock Item],
                d.[Fiscal Year] AS FiscalYear,
                SUM(s.[total excluding tax]) AS TotalSold,
                SUM(s.quantity) AS TotalQuantitySold
            FROM
                factSale AS s
            INNER JOIN
                dimStockItem AS si ON s.[Stock Item Key] = si.[Stock Item Key]
            INNER JOIN
                dimDate AS d ON s.[Invoice Date Key] = d.[date]
            WHERE
                d.[Fiscal Year] IN (2016)
            GROUP BY
                si.[Stock Item],
                d.[Fiscal Year]
            ORDER BY
                SUM(s.[total excluding tax]) desc,
                si.[Stock Item],
                d.[Fiscal Year];

        ------ top performing product per salesperson in 2016 fiscal year so far
        SELECT
                si.[Stock Item],
                e.[employee],
                d.[Fiscal Year] AS FiscalYear,
                SUM(s.[total excluding tax]) AS TotalSold,
                SUM(s.quantity) AS TotalQuantitySold
            FROM
                factSale AS s
            INNER JOIN
                dimStockItem AS si ON s.[Stock Item Key] = si.[Stock Item Key]
            INNER JOIN
                dimDate AS d ON s.[Invoice Date Key] = d.[date]
            INNER JOIN
                dimEmployee AS e ON s.[salesperson key] = e.[employee key]
            WHERE
                d.[Fiscal Year] IN (2016)
            GROUP BY
                si.[Stock Item],
                e.[employee],
                d.[Fiscal Year]
            ORDER BY
                SUM(s.[total excluding tax]) desc,
                si.[Stock Item],
                d.[Fiscal Year];

    --- seller analysis:
        ------ top performing product per salesperson in 2016 fiscal year so far
            SELECT
                    si.[Stock Item],
                    e.[employee],
                    d.[Fiscal Year] AS FiscalYear,
                    SUM(s.[total excluding tax]) AS TotalSold,
                    SUM(s.quantity) AS TotalQuantitySold
                FROM
                    factSale AS s
                INNER JOIN
                    dimStockItem AS si ON s.[Stock Item Key] = si.[Stock Item Key]
                INNER JOIN
                    dimDate AS d ON s.[Invoice Date Key] = d.[date]
                INNER JOIN
                    dimEmployee AS e ON s.[salesperson key] = e.[employee key]
                WHERE
                    d.[Fiscal Year] IN (2016)
                GROUP BY
                    si.[Stock Item],
                    e.[employee],
                    d.[Fiscal Year]
                ORDER BY
                    SUM(s.[total excluding tax]) desc,
                    si.[Stock Item],
                    d.[Fiscal Year];

        ------ share of total sales per seller in the most recent year with registered sales
        SELECT
                si.[Stock Item],
                e.[employee],
                d.[Fiscal Year] AS FiscalYear,
                SUM(s.[total excluding tax]) AS YTDTotalSold,
                FORMAT(CAST(SUM(s.[Total Excluding Tax]) / 
                                (
                                    SELECT SUM(s.[Total Excluding Tax])
                                    FROM factSale AS s
                                    INNER JOIN dimDate AS d
                                    ON s.[Invoice Date Key] = d.[Date]
                                    WHERE d.[Fiscal Year] = (select MAX ([Fiscal Year])
        from factsale as s 
        inner join dimdate as d on s.[invoice date key] = d.[date]) 
                                ) 
                            AS decimal(8,6)), 
                            'P4'
                        ) AS PercentOfSalesYTD
            
            FROM
                factSale AS s
            INNER JOIN
                dimStockItem AS si ON s.[Stock Item Key] = si.[Stock Item Key]
            INNER JOIN
                dimDate AS d ON s.[Invoice Date Key] = d.[date]
            INNER JOIN
                dimEmployee AS e ON s.[salesperson key] = e.[employee key]
            
            WHERE
                d.[Fiscal Year] IN ((select MAX ([Fiscal Year])
        from factsale as s 
        inner join dimdate as d on s.[invoice date key] = d.[date]) )
            GROUP BY
                si.[Stock Item],
                e.[employee],
                d.[Fiscal Year]
            ORDER BY
                SUM(s.[total excluding tax]) desc,
                si.[Stock Item],
                d.[Fiscal Year];

    --- location analysis:
        SELECT
                sc.[city],
                d.[Fiscal Year] AS FiscalYear,
                SUM(s.profit) AS TotalProfit
            FROM
                factSale AS s
            INNER JOIN
                dimCity AS sc ON s.[city key] = sc.[city key]
            INNER JOIN
                dimDate AS d ON s.[Invoice Date Key] = d.[date]
            WHERE
                d.[Fiscal Year] IN (2015, 2016)
            GROUP BY
                sc.[city],
                d.[Fiscal Year]
            ORDER BY
                sc.[city],
                d.[Fiscal Year];

-- 05_basket
    --- Market-basket analysis (top product pairs with support, confidence, lift)
    WITH lines AS (
        SELECT s.[WWI Invoice ID] AS inv, s.[Stock Item Key] AS item
        FROM factSale s
        WHERE s.[WWI Invoice ID] IS NOT NULL
        ),
        pairs AS (
        SELECT a.item AS A, b.item AS B, COUNT(*) AS pair_txns
        FROM lines a
        JOIN lines b ON a.inv = b.inv AND a.item < b.item
        GROUP BY a.item, b.item
        ),
        item_txns AS (
        SELECT item, COUNT(DISTINCT inv) AS txns
        FROM lines
        GROUP BY item
        ),
        tot AS (SELECT COUNT(DISTINCT inv) AS total_txns FROM lines)
        SELECT p.A, p.B, p.pair_txns,
            CAST(p.pair_txns AS float) / t.total_txns AS support,
            CAST(p.pair_txns AS float) / NULLIF(ta.txns, 0) AS conf_A_to_B,
            (CAST(p.pair_txns AS float) / NULLIF(ta.txns, 0)) / (CAST(tb.txns AS float) / t.total_txns) AS lift
        FROM pairs p
        JOIN item_txns ta ON ta.item = p.A
        JOIN item_txns tb ON tb.item = p.B
        CROSS JOIN tot t
        ORDER BY lift DESC;

