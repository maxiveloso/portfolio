# Maximiliano Veloso: Portfolio
Data science, data analytics and business intelligence portfolio.

[### WWI Retail Analytics Foundation — End-to-end SQL analysis to build reusable insights]([[https://github.com/maxiveloso/portfolio/blob/e510883b7e7c98a4699c2a3bdb8ed6d4e9ebec8e/data-analytics/SQL/WIWO-store/WIWO%20Case%20Study.sql](https://github.com/maxiveloso/portfolio/tree/dc06999e6c7f7132a98e8eadcd09f05bf765eed8/data-analytics/SQL/WIWO-store)]) 

#### TL;DR
In the context of the Wide World Importers (WWI) retail warehouse, I authored a comprehensive SQL analysis suite to establish an analytics foundation spanning data quality checks, exploratory profiling, time intelligence, contribution analysis, RFM segmentation, clustering, and basket analysis. The goal was to enable future dashboards and decision support for product, customer, seller, territory, and time-based insights. The work covers 2013–2016 with 228,225 factSale rows. Built with SQL Server (T-SQL) in VS Code.

#### Key Insights
This portfolio case is code-first; numeric outputs will be added once connected to a WWI DW instance. The analysis is structured to surface the following insights when run:
- Time intelligence pinpoints YoY sales and profit by fiscal period and computes YTD rollups, enabling identification of underperforming months in 2016 relative to 2015.
- Contribution analysis ranks customers, products, and cities by their profit deltas between 2015 and 2016, highlighting the most negative contributors to focus remediation.
- RFM segmentation classifies customers into 125 micro-segments (R, F, M = 1–5) and a combined RFM code for targeting high-frequency, high-monetary segments.
- Basket analysis returns top product pairs with high lift to inform cross-sell placements and promotions.
- Seller and territory cuts expose top-performing salesperson–product combinations and territory-level opportunity via population and city coverage.

#### Impact & Outcomes
The SQL suite creates an audit-friendly, modular foundation that can plug directly into dashboards for Sales, Marketing, and Merchandising. It standardizes core KPIs (sales ex-tax, profit, quantity), enables diagnostic drilling from time to entities, and provides ready-made segmentation and association features for activation. Once connected to a live instance, the outputs can be quantified (e.g., top-N deltas covering X% of variance; lift values for recommended bundles) and translated into actions.
