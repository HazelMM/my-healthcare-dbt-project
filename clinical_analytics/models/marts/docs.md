{% docs spine_month %}
The first day of the calendar month in the patient's longitudinal observation spine, derived from `date_trunc('month', ...)`. The spine begins at the month of the patient's first recorded disorder onset and ends at the month of death or the current date, whichever is earlier.
{% enddocs %}

{% docs age_at_month %}
Patient age in full years at the start of the spine month, computed as `datediff('year', birth_date, spine_month)`. NULL if `birth_date` is not recorded.
{% enddocs %}
