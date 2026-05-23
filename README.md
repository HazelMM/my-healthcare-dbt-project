# AI-Ready Longitudinal Clinical Analytics Foundation

## Project Overview

This repository contains an end-to-end analytics engineering project focused on transforming raw longitudinal electronic health record (EHR) data into semantically consistent, AI-ready clinical datasets.

Using dbt and Snowflake, the project models patient health trajectories across clinical conditions, biomarker observations, and healthcare encounters to create trusted analytical foundations for downstream analytics, machine learning, and AI-assisted clinical reasoning workflows.

Rather than treating healthcare data as isolated reporting tables, this project emphasizes longitudinal patient state modeling, semantic normalization, and clinically meaningful context generation.

---

## Core Objectives

### Longitudinal Patient Modeling
Build patient-centric analytical models that capture changes in health state over time across diagnoses, biomarkers, and encounters.

### Clinical Semantic Layer
Normalize and organize clinical concepts (SNOMED-CT conditions, biomarker observations, encounter events) into reusable semantic domains and governed analytical entities.

### Biomarker & Observation Standardization
Standardize laboratory observations and vital measurements into consistent, queryable longitudinal structures suitable for analytics and feature engineering.

### AI-Ready Clinical Context
Create semantically structured datasets designed to support:
- downstream machine learning workflows
- retrieval-augmented AI systems
- clinical summarization
- cohort analysis
- patient phenotyping

---

## Technology Stack

| Layer | Technology |
|---|---|
| Cloud Data Warehouse | Snowflake |
| Transformation Framework | dbt Core (`dbt-snowflake`) |
| Development Environment | GitHub Codespaces |
| Source Dataset | Synthea Synthetic Healthcare Data |

---

## Source Tables

### `PATIENTS`
Patient demographic and baseline identity information.

### `CONDITIONS`
Longitudinal diagnosis history and SNOMED-CT clinical condition records.

### `OBSERVATIONS`
Laboratory results, biomarker measurements, and vital sign observations captured over time.

### `ENCOUNTERS`
Clinical interaction events representing healthcare utilization and patient touchpoints.

---

## Biomarker Abnormality Business Rules

The `stg_observations` model flags clinically abnormal biomarker readings via the `has_abnormal_biomarker` column. Thresholds are applied by observation code and are based on standard clinical reference ranges for the chronic disease cohorts tracked in this project.

| Observation | Code | Threshold | Clinical Basis |
|---|---|---|---|
| HbA1c | `4548-4` | > 6.5% | ADA diabetes diagnosis threshold |
| Fasting Glucose | `2339-0` | >= 126 mg/dL | ADA diabetes diagnosis threshold |
| eGFR | `33914-3` | < 60 mL/min/1.73m² | KDIGO CKD staging threshold |
| Systolic Blood Pressure | `8480-6` | >= 130 mmHg | AHA Stage 1 hypertension threshold |

These rules are isolated in the staging layer and should not be re-implemented in intermediate or mart models. Downstream models should reference `has_abnormal_biomarker` directly.

---

## Planned Semantic Models

### Patient Health Profile
Patient-centric longitudinal clinical summary.

### Biomarker Trend Models
Normalized biomarker trajectories across time and clinical states.

### Clinical State Models
Semantic categorization of chronic, acute, and physiological conditions.

### AI-Ready Feature Tables
Structured analytical datasets optimized for downstream AI and machine learning workflows.

---

## Project Direction

This project explores how modern analytics engineering practices can create trustworthy semantic foundations for AI-enabled healthcare systems.

A major focus of the project is evaluating where AI-assisted development accelerates analytics engineering workflows — and where human semantic validation, governance, and clinical context remain essential.
