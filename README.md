## Local set up (Windows)

1) Create .env file in the root directory with the following data:
```
SNOWFLAKE_USER=your username (email address)
SNOWFLAKE_ACCOUNT=HVPLP-ACCTCDPNP
SNOWFLAKE_WH=KRTSYSNP_WAREHOUSE
SNOWFLAKE_ROLE=_OKTA-SF_JAMLABS_DEV
ENVIRONMENT=personal_dev
DAGSTER_HOME=full path to the root directory (i.e.  C:\Users\panisova\Source\repo\Hvp.Dna.EntRpt.Snowflake), used to store Dagster run information.
FILTERED_FUND_IDS=fund ids list to filter for (local runs only, i.e. 28885567,2216520,27078919,2216606,50688556)
FILTERED_INVESTOR_IDS=investor (name) ids list to filter for (local runs only, i.e. 58256296,2215327,28473846,27612261)
```
2) Install Python 3.12 from Software Center
3) Open a Powershell and navigate to code directory (make sure, that the code directory is located in ThreatLocker Thrusted path).
4) Create a virtual environment:
```
py -3.12 -m venv venv
```
5) Add this line to the bottom of the file .\venv\Scripts\activate.ps1 (to avoid pre-commit hook being blocked by ThreatLocker):

```$env:PRE_COMMIT_HOME = "$env:VIRTUAL_ENV\pre-commit"```

6) Activate venv:
```
.\venv\Scripts\activate.ps1
```
7) Install requirements:

```pip install -r .\requirements.txt```

8) Install pre-commit hooks: 

```
pre-commit install
```

9) Install dbt deps:

```
dbt deps --project-dir hv_edp_dbt
```


## Local runs

### Running Dagster
In the root directory, run: 

```dagster dev```

Dagster will run locally on http://127.0.0.1:3000/

### Configuring personal development environment

1) Run Dagster
2) Open Dagster UI
3) Trigger Provision infra job (Jobs -> provision_infra -> Materialize all). A database HV_EDP_{username}_DEV will be created in Snowflake, together with resources, required by the Bronze layer (schema, landing stage, tables, file format).

### Running ETL jobs on the personal development environment

ETL jobs have different running modes:
- **Full reload**: true/false (false by default - only new fresh files data is loaded. If set to true, will clean up bronze data, load all files from landing stage, and re-create silver and gold tables).
- **Stage location**: String ("@HV_EDP_DEV.DEV_RAW.STG_EXT_DMZ_KRTSYSNP_EDP" by default. Determines a stage where the data is read from).
- **Filtered fund ids**: For the local runs, a list of fund ids to filter for (makes job runs faster, as it only gets fund ids selected from the raw table). Can be set in .env. 

To change these settings, click on an arrow to the right from Materialize all, select Open Launchpad and change the job_config options.

### Destroying personal development environment
1) Run Dagster
2) Open Dagster UI
3) Trigger Destroy infra job (Jobs -> destroy_infra -> Materialize all). The database HV_EDP_{username}_DEV will be dropped. 

