# 🏥 Hospital Readmission Analytics
> **Executive Performance Dashboard & 30-Day Clinical Risk Evaluation**

![Dashboard Overview](dashboard_overview.png)

---

## 📌 Project Overview
Unplanned 30-day hospital readmissions serve as a critical Key Performance Indicator (KPI) evaluating clinical care quality, operational efficiency, and discharge protocols across health systems. High readmission rates reflect potential deficiencies in patient follow-up and lead to severe financial penalties imposed by healthcare regulatory bodies (such as the CMS Hospital Readmissions Reduction Program).

This end-to-end data analytics project analyzes multi-center clinical data across **102,000+ patient encounters** to identify primary drivers of 30-day readmissions, evaluate departmental performance, and pinpoint high-risk patient demographics.

---

## 📑 Data Dictionary
| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `encounter_id` | Integer | Unique identifier for each hospital admission/visit. |
| `patient_nbr` | Integer | Unique identifier assigned to each individual patient. |
| `admission_type_id` | Integer | Category of admission (1=Emergency, 2=Urgent, 3=Elective). |
| `discharge_disposition_id` | Integer | Patient destination after discharge (e.g., Home, SNF, ICF). |
| `medical_specialty` | Varchar | Clinical specialty of the admitting physician (e.g., Nephrology, Cardiology). |
| `time_in_hospital` | Integer | Length of stay measured in total days (1–14 days). |
| `age` | Varchar | Patient age bracket grouped into 10-year intervals (e.g., [20-30), [80-90)). |
| `readmitted` | Varchar | Indicator of 30-day readmission status (`<30`, `>30`, `NO`). |

---

## 📊 Key Metrics & Executive Summary
* **Total Encounters:** 102K
* **Total Patients:** 72K
* **30-Day Readmits:** 11K
* **30-Day Readmit Rate:** 11.16%
* **Avg Length of Stay:** 4.40 Days

---

## 💡 Key Clinical Insights
1. **Departmental Risk Hierarchy:** **Nephrology** registered the highest 30-day readmission rate at **15.10%**, followed by **Family/General Practice (12.20%)** and **General Surgery (11.36%)**.
2. **Admission Channel Vulnerability:** **Emergency Admissions** accounted for the overwhelming majority of encounters (**59.11% / 54K encounters**), correlating heavily with higher readmission risks compared to elective admissions.
3. **Age Group Dynamics:** Patients in the **[20–30) age bracket** demonstrated the highest readmission rate (**14.27%**), while elderly populations in the **[80–90) bracket** maintained a consistently elevated rate of **12.16%**.
4. **Discharge Destinations:** Over **60K patients** were discharged home, while transfers to Skilled Nursing Facilities (SNF) represented 14K encounters, highlighting key operational handoff points for care coordination.

---

## 💻 SQL Query Examples

### 1. Calculating Departmental Readmission Rate (Excluding Low Volume)
```sql
SELECT 
    medical_specialty,
    COUNT(encounter_id) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmits_30_days,
    ROUND(
        CAST(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(encounter_id) * 100, 
        2
    ) AS readmit_rate_pct
FROM hospital_encounters
WHERE medical_specialty IS NOT NULL AND medical_specialty != 'Unspecified'
GROUP BY medical_specialty
HAVING COUNT(encounter_id) >= 100
ORDER BY readmit_rate_pct DESC;

2. Emergency Readmission Percentage Breakdown
SQL
SELECT 
    admission_type_description,
    COUNT(*) AS encounter_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage_share
FROM hospital_encounters
GROUP BY admission_type_description;

🧮 DAX Measures Used

مقتطف الرمز
// 1. Total Encounters
Total Encounters = COUNT(hospital_encounters[encounter_id])

// 2. 30-Day Readmission Count
30-Day Readmits = 
CALCULATE(
    COUNT(hospital_encounters[encounter_id]),
    hospital_encounters[readmitted] = "<30"
)

// 3. 30-Day Readmit Rate %
30-Day Readmit Rate = 
DIVIDE(
    [30-Day Readmits], 
    [Total Encounters], 
    0
)
🛠️ Challenges & Solutions
Challenge 1: Low-Sample Size Distortion (Small Specialties)

Issue: Specialized clinics with 2 encounters and 1 readmission showed a misleading 50% readmission rate.

Solution: Implemented dual-layer visual filtering in Power BI (Total Encounters >= 100 and Top N = 8), isolating high-volume clinical departments for actionable insights.

Challenge 2: Unspecified Category & Cluttered Labels

Issue: Vertical rotated text in vertical bar charts rendered physician specialty names unreadable.

Solution: Transformed the visualization into a horizontal Clustered Bar Chart and filtered out Unspecified entries while preserving the dynamic Top N DAX behavior.

🎨 Dashboard Features & Data Model
Interactive Filtering: Cross-filtering across Age Groups, Admission Types, and Medical Specialties.

Responsive Visual Hierarchy: Dark executive header banner with KPI summary cards and balanced 2x2 grid layout.

Data Model Architecture: Star Schema modeling connecting Fact table hospital_encounters to Dimension tables (Dim_Admission, Dim_Discharge, Dim_Age).

🩺 Strategic Recommendations for Healthcare Leadership
Targeted Outpatient Management: Establish specialized 14-day post-discharge follow-up clinics for Nephrology and Family Practice departments.

High-Risk Cohort Monitoring: Deploy dedicated care coordinators for high-risk age brackets ([20–30) & [80–90)).

Emergency Handoff Optimization: Strengthen care coordination and transition programs for patients admitted via Emergency channels.

🔮 Future Improvements
Predictive ML Modeling: Build a machine learning classification model (e.g., XGBoost / Logistic Regression) to predict 30-day readmission risk scores at the individual patient level.

Financial Impact Modeling: Quantify CMS penalty costs avoided by reducing readmission rates by 1.5%–2.0%.

🚀 How to Run & Explore
Clone this repository: git clone https://github.com/your-username/Hospital_Readmission_Analytics.git

Open hospital_readmission_analytics.pbix using Power BI Desktop.

(Optional) Import raw_hospital_data.csv into SQL Server and execute healthcare_data_cleaning.sql to view the ETL pipeline.

📚 References & Standards
Dataset Source: UCI Machine Learning Repository — Diabetes 130-US Hospitals Dataset (1999–2008).

Clinical Quality Benchmark: CMS Hospital Readmissions Reduction Program (HRRP) Standards.