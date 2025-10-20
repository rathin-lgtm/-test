## Local set up (Windows)

1) Create .env file in the root directory with the following data:
```
SNOWFLAKE_USER=your username (email address)
SNOWFLAKE_ACCOUNT=HVPLP-ACCTKURTOSYSNP
SNOWFLAKE_WH=KRTSYSNP_WAREHOUSE
SNOWFLAKE_ROLE=_OKTA-SF_JAMLABS_DEV
ENVIRONMENT=personal_dev
DAGSTER_HOME=full path to the root directory (i.e.  C:\Users\panisova\Source\repo\Hvp.Dna.EntRpt.Snowflake), used to store Dagster run information.
```
2) Install Python 3.12 from Software Center
3) Open a command prompt and navigate to code directory (make sure, that the code directory is located in ThreatLocker Thrusted path).
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

## Local runs

### Running Dagster

```dagster dev```

Dagster will run locally on http://127.0.0.1:3000/

### Configuring personal development environment

1) Run Dagster
2) Open Dagster UI
3) Trigger Provision infra job (Jobs -> provision_infra -> Materialize all). A database HV_EDP_{username}_DEV will be created in Snowflake, together with resources, required by the Bronze layer (schema, landing stage, tables, file format).

Job settings:
- **Use shared stage**: true/false (true by default. If set to false, personal dev landing stage will be used for source files template instead of shared dev landing stage).

Note: bronze tables creation requires raw data file to be uploaded to the file landing stage, to be used as a template. The file should be uploaded in a folder {source_name}/{table_name}/YYYY/MM/DD (i.e. HARBOURVIEW_EDW/DIM_FUND/2025/10/15/edw_dim_fund.csv). For the personal dev environments, the shared dev's landing stage will be used by default, unless Use shared stage is set to True.

### Running ETL jobs on the personal development environment

ETL jobs have different running modes:
- **Full reload**: true/false (false by default - only new fresh files data is loaded. If set to true, will clean up bronze data, load all files from landing stage, and re-create silver and gold tables).
- **Use shared stage**: true/false (true by default. If set to false, personal dev landing stage will be used for source files instead of shared dev landing stage).

To change these settings, click on an arrow to the right from Materialize all, select Open Launchpad and change the job_config options.

### Destroying personal development environment
1) Run Dagster
2) Open Dagster UI
3) Trigger Destroy infra job (Jobs -> destroy_infra -> Materialize all). The database HV_EDP_{username}_DEV will be dropped. 

