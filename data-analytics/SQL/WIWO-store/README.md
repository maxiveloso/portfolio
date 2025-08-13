### WWI Retail Analytics Foundation — End-to-end SQL analysis to build reusable insights

#### TL;DR
In the context of the Wide World Importers (WWI) retail warehouse, I authored a comprehensive SQL analysis suite to establish an analytics foundation spanning data quality checks, exploratory profiling, time intelligence, contribution analysis, RFM segmentation, clustering, and basket analysis. The goal was to enable future dashboards and decision support for product, customer, seller, territory, and time-based insights. The work covers 2013–2016 with 228,225 factSale rows. Built with SQL Server (T-SQL) in VS Code.

#### Problem & Context
The business problem was to bootstrap a robust analytics foundation for WWI retail so teams can understand sales and profit drivers, customer value, category performance, and cross-sell opportunities. The codebase is organized to answer common business questions out-of-the-box (e.g., YoY trends, top contributors, customer segments, product bundles) while highlighting data quality risks and fiscal calendar nuances. Success criteria were intentionally open-ended for this portfolio project; the deliverable is a structured, extensible SQL analysis suite that can be plugged into BI dashboards.

#### My Role & Scope
I worked as an Analyst owning the SQL design and implementation for all modules: data quality, EDA, time intelligence, contribution and driver analysis, RFM segmentation, clustering, and basket analysis. The intended consumers are hiring managers and analytics leaders evaluating portfolio depth; I will add a companion dashboard case study as a related link. This project targets the WWI DW sample, covered 2013–2016, and was executed in SQL Server via VS Code.

#### Data Overview
The primary dataset is Microsoft’s Wide World Importers data warehouse. The core table factSale contains 228,225 rows across fiscal years 2013–2016. Dimensional tables include dimCustomer, dimStockItem, dimEmployee, dimCity, and dimDate. Important fields include monetary measures (Total Excluding Tax, Profit), quantities, invoice identifiers, and fiscal hierarchies (Fiscal Year, Fiscal Month Number and Label). Notable data quality patterns include explicit “Unknown” members in several dimensions and a fiscal calendar whose month numbering differs from calendar months, which requires care in time-based analysis.

#### Questions & Hypotheses
Key questions addressed include: which products, customers, sellers, and territories drive profit and sales; how performance evolves YoY and YTD given a non-standard fiscal calendar; whether 2016’s profit underperformed 2015 and why; what customer segments emerge from recency, frequency, and monetary value; and which product pairs co-occur with high lift for cross-sell. The working hypothesis is that a concentrated subset of customers and items explain most of the 2015→2016 profit delta and that specific bundles exhibit above-baseline lift suitable for merchandising.

#### Approach & Methods
The pipeline flows from data quality checks to EDA, then time series rollups, contribution analysis, segmentation, clustering, and association rules. Methods include set-based SQL, window functions for lag/YoY/YTD, NTILE-based RFM scoring, CTE-based contribution deltas, and pairwise co-occurrence with support, confidence, and lift. T-SQL was chosen for proximity to the source warehouse and for expressivity of window functions; it keeps logic close to data and ready for BI layer consumption.

#### Key Insights
This portfolio case is code-first; numeric outputs will be added once connected to a WWI DW instance. The analysis is structured to surface the following insights when run:
- Time intelligence pinpoints YoY sales and profit by fiscal period and computes YTD rollups, enabling identification of underperforming months in 2016 relative to 2015.
- Contribution analysis ranks customers, products, and cities by their profit deltas between 2015 and 2016, highlighting the most negative contributors to focus remediation.
- RFM segmentation classifies customers into 125 micro-segments (R, F, M = 1–5) and a combined RFM code for targeting high-frequency, high-monetary segments.
- Basket analysis returns top product pairs with high lift to inform cross-sell placements and promotions.
- Seller and territory cuts expose top-performing salesperson–product combinations and territory-level opportunity via population and city coverage.

#### Impact & Outcomes
The SQL suite creates an audit-friendly, modular foundation that can plug directly into dashboards for Sales, Marketing, and Merchandising. It standardizes core KPIs (sales ex-tax, profit, quantity), enables diagnostic drilling from time to entities, and provides ready-made segmentation and association features for activation. Once connected to a live instance, the outputs can be quantified (e.g., top-N deltas covering X% of variance; lift values for recommended bundles) and translated into actions.

#### Evaluation & Metrics
For this portfolio version, formal validation (e.g., holdouts for basket analysis or sensitivity analyses on z-score anomaly thresholds) is not included. The code includes safe guards like NULLIF and explicit handling of “Unknown” members to avoid misleading denominators and reduce skew.

#### Constraints & Trade-offs
Key constraints include “Unknown” placeholder members and a fiscal calendar whose month numbers differ from Gregorian months. The approach mitigates these by filtering Unknowns in many queries, using fiscal-year partitions for time functions, and including comments for method choices and thresholds (e.g., z-score threshold at 2 due to sparsity of 3-sigma outliers). Remaining risks include reliance on default thresholds and the absence of downstream visual validation, which will be addressed in a related dashboard project.

#### Ethics & Privacy
Not applicable for this public sample dataset. Analyses are aggregate and do not involve sensitive PII beyond standard customer entity names in the sample.

#### Lessons Learned
Building a modular SQL-first foundation makes downstream BI faster: common patterns like lag/YoY/YTD, RFM bucketing, and contribution deltas can be reused across business questions. Clear handling of fiscal calendars and Unknown members avoids common pitfalls. Pairwise association in SQL is practical at moderate scale and yields interpretable lift for merchandising.

#### Next Steps
Next, I plan to wire these queries into a dashboard with drilldowns by time, customer, product, and seller; add numeric benchmarks for YoY attribution; surface RFM cohorts with activation tags; and productionize a top-pairs recommendation widget using the lift table. I will also add snapshot tables or views to stabilize metrics for BI consumption.

#### Tech Stack
Languages and libraries include SQL (T-SQL). The environment is SQL Server, authored and executed via Visual Studio Code using SQL extensions. The architecture is a straightforward read-only analytics layer on top of WWI DW, organized by modules (00_data_quality, 01_exploration, 02_clusters, 03_time_intelligence, 04_drivers, 05_basket).

#### Reproducibility
Repo: [link to be added]. Notebooks: not applicable; all logic is in SQL files. Environment: SQL Server instance accessible from VS Code; load the Wide World Importers DW sample (2013–2016 coverage). Data access: install the WWI DW sample database and ensure schemas and table names match those referenced (factSale, dimDate, dimCustomer, dimStockItem, dimEmployee, dimCity). Run instructions: clone the repo, open in VS Code, connect to SQL Server, and execute the scripts in numerical order from 00_ to 05_. Optional: create views for each section for easier BI integration.

#### Demo & Links
Live dashboard/app: will be added in a related case study focused on visualization and KPI storytelling, referencing this analysis as the data source. Selected visuals: to be added once the dashboard is published.

#### Contact / CTA
Work with me: [https://www.linkedin.com/in/maximiliano-veloso/]. GitHub: [https://maxiveloso.github.io/portfolio/]. See related projects: forthcoming dashboard built on top of this SQL foundation.
