import os
import csv
import time
from pathlib import Path
import streamlit as st
import snowflake.connector
import anthropic
import pandas as pd


def load_snomed_reference() -> str:
    seed_path = Path(__file__).parent.parent / "clinical_analytics" / "seeds" / "snomed_clinical_state.csv"
    rows = []
    with open(seed_path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(f"  {row['snomed_concept_code']} = {row['condition_name']}")
    return "\n".join(rows)

SNOMED_REFERENCE = load_snomed_reference()


def load_biomarker_reference() -> str:
    seed_path = Path(__file__).parent.parent / "clinical_analytics" / "seeds" / "biomarker_reference_ranges.csv"
    rows = []
    with open(seed_path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(f"  {row['loinc_code']} = {row['observation_name']}")
    return "\n".join(rows)

BIOMARKER_REFERENCE = load_biomarker_reference()

st.set_page_config(
    page_title="Clinical Analytics Agent",
    page_icon="🩺",
    layout="centered",
)

st.title("🩺 Clinical Analytics Agent")
st.caption("Synthea synthetic data · demo purposes only · conditions are filtered to SNOMED disorder tag only — primary diabetes and some other conditions are classified as 'finding' in SNOMED and are not included")

with st.expander("About this agent", expanded=False):
    st.markdown(
        """
        **What this agent can answer**

        This agent queries two datasets built from **Synthea-generated synthetic healthcare data** —
        a widely used open-source simulator that produces realistic but entirely fictional patient records.
        No real patient information is used or stored.

        - **Patient Disorder Episodes** — one record per patient per diagnosed condition, including
          condition name, clinical category, chronicity, encounter history, and patient demographics.
        - **Longitudinal Observation Spine** — monthly snapshots of lab and clinical observations per
          patient, including values, reference range status, and trend direction over time.

        **Scope & limitations**

        - Conditions are filtered to `clinical_semantic_tag = 'disorder'` only. This follows SNOMED CT ontology — some conditions that are colloquially considered diseases (such as primary diabetes mellitus) are not tagged 'disorder', and are therefore not present in this dataset. Diabetic complications (retinopathy, neuropathy, renal disease) are classified as disorders and are included.
        - This agent does not generate charts, graphs, or visualizations — results are returned as
          tabular data only. Time series charts are automatically rendered for single-observation queries only.
        - For questions outside this scope, the agent will return an explanation instead of guessing.
        """
    )

st.divider()

SCHEMA_CONTEXT = f"""
You are a clinical data analyst assistant. You write Snowflake SQL queries against
two tables in the ANALYTICS_MARTS schema of the SYNTHEA_HEALTHCARE database.

TABLE 1: SYNTHEA_HEALTHCARE.ANALYTICS_MARTS.DIM_PATIENT_DISORDER_EPISODES
Grain: one row per patient per condition episode.
Columns:
  patient_id               VARCHAR   unique patient identifier
  condition_id             VARCHAR   unique condition episode identifier
  gender                   VARCHAR   patient gender
  race                     VARCHAR   patient race
  ethnicity                VARCHAR   patient ethnicity
  is_deceased              BOOLEAN   true if patient has died
  death_date               DATE      date of death if deceased
  total_encounters         INTEGER   cumulative encounter count
  ambulatory_encounter_count INTEGER
  wellness_encounter_count   INTEGER
  emergency_encounter_count  INTEGER
  inpatient_encounter_count  INTEGER
  condition_name           VARCHAR   plain english condition name
  snomed_concept_code      VARCHAR   SNOMED CT code
  clinical_semantic_tag    VARCHAR   always 'disorder'
  condition_start_date     DATE      when condition was first recorded
  condition_end_date       DATE      when condition resolved; null if still active
  is_active_condition      BOOLEAN   true if condition has no end date
  condition_duration_days  INTEGER   days from start to end or today
  condition_onset_year     INTEGER   year condition was first recorded
  clinical_state           VARCHAR   'chronic' or 'acute'
  clinical_category        VARCHAR   e.g. 'cardiovascular', 'renal', 'oncologic'

TABLE 2: SYNTHEA_HEALTHCARE.ANALYTICS_MARTS.PATIENT_LONGITUDINAL_OBSERVATION_SPINE
Grain: one row per patient per spine_month per observation.
Columns:
  patient_id               VARCHAR
  spine_month              DATE      first day of the month
  gender                   VARCHAR
  race                     VARCHAR
  ethnicity                VARCHAR
  age_at_month             INTEGER
  is_deceased              BOOLEAN
  death_date               DATE
  total_encounters         INTEGER
  ambulatory_encounter_count INTEGER
  wellness_encounter_count   INTEGER
  emergency_encounter_count  INTEGER
  inpatient_encounter_count  INTEGER
  observation_date         DATE
  observation_code         VARCHAR   LOINC code
  observation_name         VARCHAR   e.g. 'HbA1c'
  observation_value_numeric FLOAT
  observation_unit         VARCHAR
  range_low                FLOAT
  range_high               FLOAT
  distance_from_normal     FLOAT
  range_status             VARCHAR   'normal', 'above_range', 'below_range', or null
  trend_status             VARCHAR   'improving', 'worsening', 'stable', 'normalized', or null

OBSERVATION REFERENCE — LOINC CODES:
The following LOINC codes map to exact observation names in PATIENT_LONGITUDINAL_OBSERVATION_SPINE.
Always use observation_code for exact observation matching instead of ILIKE wildcards on observation_name.
ILIKE is only acceptable when the user's question is too vague to map to a specific code.

{BIOMARKER_REFERENCE}

OBSERVATION NAME NOTES:
- Observation code QOLS has observation_name 'QOLS' and represents Quality of Life Score.
  When users ask about quality of life, search by observation_name = 'QOLS'.

CONDITION REFERENCE — SNOMED CODES:
The following SNOMED codes map to exact condition names in DIM_PATIENT_DISORDER_EPISODES.
Always use snomed_concept_code for exact condition matching instead of ILIKE wildcards on condition_name.
ILIKE is only acceptable when the user's question is too vague to map to a specific code.

{SNOMED_REFERENCE}

RULES:
- Only write SELECT statements. Never write INSERT, UPDATE, DELETE, DROP, or DDL.
- Always use fully qualified uppercase table names.
- Always return full rows of data, never just a COUNT — EXCEPT for questions that explicitly ask for rankings, summaries, or "most common", in those cases return grouped aggregations with counts.
- If the question asks "how many", return the full matching rows — the app will count them and display the number automatically.
- Select the columns most relevant to the question. Always include patient_id — except when the question asks about condition types, categories, or lists rather than patients, in which case return SELECT DISTINCT condition_name, clinical_state, clinical_category without patient_id. For condition-related questions include condition_name, clinical_state, clinical_category, is_active_condition, condition_start_date. For observation questions include observation_name, observation_value_numeric, observation_unit, range_status, trend_status, observation_date.
- Return ONLY the SQL query. No explanation, no markdown, no backticks, no preamble.

TREND AGGREGATION:
- For questions about trends "over time" or "sustained" trends, aggregate trend_status counts per patient and return patients where improving_count > worsening_count.
- Example: count months where trend_status = 'improving' and months where trend_status = 'worsening' per patient, then filter to improving_count > worsening_count.

CLINICAL KNOWLEDGE:
- Use your clinical knowledge to map condition names to relevant observation names when the user asks about a condition's labs, biomarkers, or trends.
- Example: "patients whose anemia improved" should query hemoglobin and hematocrit trends, not search for 'anemia' in observation_name.
- Example: "patients with worsening diabetes" should query HbA1c trends, not search for 'diabetes' in observation_name.

OUT-OF-SCOPE HANDLING:
- If the question cannot be answered using the two tables above — for example, it asks about the user personally, requests a visualization, references data not in the schema, or is unrelated to clinical patient data — do NOT write SQL.
- Instead, respond with exactly: OUT_OF_SCOPE: <one sentence explaining why the question cannot be answered>
- Examples of out-of-scope questions: "how old am I?", "draw me a chart", "what is the weather?", "show me findings or administrative codes"
"""

def get_snowflake_connection():
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["CLINICAL_AGENT_PAT"],
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
        database=os.environ["SNOWFLAKE_DATABASE"],
        schema=os.environ["SNOWFLAKE_SCHEMA"],
    )

def generate_sql(question: str) -> str:
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    message = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        messages=[
            {
                "role": "user",
                "content": f"{SCHEMA_CONTEXT}\n\nQuestion: {question}\n\nSQL:",
            }
        ],
    )
    return message.content[0].text.strip()

def run_query(sql: str) -> pd.DataFrame:
    conn = get_snowflake_connection()
    try:
        cur = conn.cursor()
        cur.execute(f"USE WAREHOUSE {os.environ['SNOWFLAKE_WAREHOUSE']}")
        cur.execute(sql)
        cols = [desc[0].lower() for desc in cur.description]
        rows = cur.fetchall()
        if not rows:
            return pd.DataFrame(columns=cols)
        return pd.DataFrame(rows, columns=cols)
    finally:
        conn.close()

examples = [
    "How many patients have both osteoporosis and metabolic syndrome?",
    "Show patients whose blood pressure normalized in the summer",
    "Which chronic conditions are most common?",
    "Give me a list of patients with anemia who also have osteoporosis",
    "Show me women with quality of life scores below 70",
]

st.subheader("Try asking")
cols = st.columns(2)
for i, example in enumerate(examples):
    if cols[i % 2].button(example, use_container_width=True):
        st.session_state["question"] = example

question = st.text_area(
    "Ask a question about the patient population",
    value=st.session_state.get("question", ""),
    height=80,
    placeholder="e.g. How many patients have osteoporosis and metabolic syndrome?",
)

ask = st.button("Ask ▶", type="primary")

if ask and question.strip():
    with st.spinner("Generating SQL..."):
        start = time.time()
        try:
            sql = generate_sql(question)
        except Exception as e:
            st.error(f"Failed to generate SQL: {e}")
            st.stop()

    if sql.startswith("OUT_OF_SCOPE:"):
        reason = sql[len("OUT_OF_SCOPE:"):].strip()
        st.warning(f"This question is outside the agent's scope: {reason}")
        st.stop()

    with st.spinner("Running query..."):
        try:
            df = run_query(sql)
            elapsed = round(time.time() - start, 1)
        except Exception as e:
            st.error(f"Query failed: {e}")
            st.code(sql, language="sql")
            st.stop()

    st.divider()
    st.subheader("Answer")
    row_count = len(df)
    if row_count == 0:
        st.info("No results found for that question.")
    elif row_count == 1 and len(df.columns) == 1:
        val = df.iloc[0, 0]
        st.metric(label=question, value=val)
    else:
        if "patient_id" in df.columns:
            patient_count = df["patient_id"].nunique()
            st.success(f"{patient_count:,} patients match your query.")
        else:
            first_text_col = next((c for c in df.columns if not pd.api.types.is_numeric_dtype(df[c])), None)
            if first_text_col:
                top_value = df.iloc[0][first_text_col]
                st.success(f"**{top_value}** — see full ranking below.")
            else:
                st.success(f"{row_count:,} results found.")
    st.caption(f"Response time: {elapsed}s")

    with st.expander("SQL generated", expanded=True):
        st.code(sql, language="sql")

    if row_count > 0:
        st.subheader("Raw data")
        display_df = df.head(200)
        if row_count > 200:
            st.caption(f"Showing 200 of {row_count:,} rows")
        else:
            st.caption(f"Showing all {row_count:,} rows")
        st.dataframe(display_df, use_container_width=True)
        csv = df.to_csv(index=False).encode("utf-8")
        st.download_button(
            label=f"Download CSV ({row_count:,} rows)",
            data=csv,
            file_name="clinical_query_results.csv",
            mime="text/csv",
        )

        cols = df.columns.tolist()
        if (
            "spine_month" in cols
            and "observation_value_numeric" in cols
            and "observation_name" in cols
            and df["observation_name"].nunique() == 1
            and "patient_id" in cols
            and df["patient_id"].nunique() == 1
        ):
            obs_name = df["observation_name"].iloc[0]
            obs_unit = df["observation_unit"].iloc[0] if "observation_unit" in cols else ""
            unit_label = f" ({obs_unit})" if obs_unit else ""
            st.subheader("Observation trend over time")
            st.caption(f"{obs_name}{unit_label}")
            chart_df = (
                df[["spine_month", "observation_value_numeric"]]
                .sort_values("spine_month")
                .set_index("spine_month")
            )
            st.line_chart(chart_df)

    st.divider()
    st.caption(
        "This application uses Synthea-generated synthetic patient data. "
        "No real patient information is used or displayed. "
        "Not intended for clinical use."
    )
