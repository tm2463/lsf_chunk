# LSF Array Batch Runner

Utility for splitting large LSF job arrays into optimally-sized chunks, enabling efficient batch submission and maximizing cluster throughput.

This repo consists of two scripts:

- **`lsf_array_chunk.sh`** — Chunks and submits jobs to LSF. Is a wrapper for **`template.sh`**
- **`template.sh`** — the "executor" script. This script contains the command to be run on each sample

## How it works

1. You give `lsf_array_chunk.sh` a CSV sample sheet listing
   everything you want to process — one row per item, any number of columns.
2. `lsf_array_chunk.sh` divides the csv into batches
3. It submits a single LSF job array (one job, many indices) where each array index is handed one batch file.
4. Each array task runs the executor script (`template.sh`)

## Step 1: Configure `lsf_array_chunk.sh`

Open the script and fill in (or pass as flags) the variables at the top:

| Field | Flag | Description |
|---|---|---|
| `MAIN_LIST` | `-m`, `--main_list` | Path to your sample sheet. Must be a **CSV**; any number of columns. One row per sample. |
| `OUTDIR` | `-o`, `--outdir` | Directory where batch files, logs, and results will be written. Created automatically if it doesn't exist. |
| `BATCH_SIZE` | `-b`, `--batch_size` | Number of rows per batch (i.e. how many items each array task will handle). |
| `CONCURRENCY` | `-c`, `--concurrency` | Max number of batches (array indices) that run at the same time. |
| `JOB_TITLE` | `-j`, `--job_title` | Name for the LSF job array. |
| `SCRIPT_PATH` | `-s`, `--executor_script` | Path to the executor script (`template.sh`). Defaults to `./template.sh`. |
| `MEMORY` | `-M`, `--memory` | Memory to request per job, in **GB**. |
| `CPUS` | `-C`, `--cpus` | Number of CPUs to request per job. |
| `QUEUE` | `-q`, `--queue` | LSF queue to submit to. |
| `LOG_FILE` | `-l`, `--log_file` | Prefix for the stdout/stderr log files written to `OUTDIR`. |

You can either edit the defaults directly at the top of the script, or pass arguments to the command line, e.g.:

```bash
./lsf_array_chunk.sh \
  -m /path/to/sample_sheet.csv \
  -o /path/to/results \
  -b 50 \
  -c 10 \
  -j my_pipeline \
  -s ./template.sh \
  -M 8 \
  -C 4 \
  -q normal \
  -l my_pipeline
```

## Step 2: Configure `template.sh`

This is where you tell the pipeline what to actually *do* with each row.

Open `template.sh` and edit the `process_item` function. Each row of your sample sheet is split on commas into the `cols` array (`cols[0]`,`cols[1]`, `cols[2]`, ...), so make sure each row contains **all the information needed to run the command successfully** (e.g. sample name, input file paths, etc). The command could either run a single tool (see example below), or could run a wrapper script.

Example:

```bash
process_item() {
    local cols=("$@")
    sylph sketch -1 "${cols[1]}" -2 "${cols[2]}" -d "$OUTDIR" -t "$CPUS"
}
```

Note: `$OUTDIR` (the batch's output directory) and `$CPUS` are already
available inside `process_item` — you don't need to redefine them.

## Step 3: Run it

Once both scripts are configured, just run:

```bash
./lsf_array_chunk.sh
```

(or with flags, as shown above, if you didn't hardcode the values).

This will:
1. Create `OUTDIR` if needed.
2. Split `MAIN_LIST` into batch files under `OUTDIR`.
3. Submit one LSF job array covering all batches, respecting your
   requested `CONCURRENCY`, `MEMORY`, `CPUS`, and `QUEUE`.
4. Write per-task logs to `OUTDIR/<LOG_FILE>.<JobID>.<Index>.out.log` and
   `.err.log`.

## Output

Inside `OUTDIR` you'll find:

- `batch_list.txt` — list of all batch file paths created.
- `batch_1.txt`, `batch_2.txt`, ... — the chunked pieces of your sample sheet.
- `<LOG_FILE>.<JobID>.<Index>.out.log` / `.err.log` — stdout/stderr for each
  array task.
- Whatever output files your `process_item` command produces.

## Before running at scale

- Run on a small test sample sheet first (e.g. only the first 10 rows, `BATCH_SIZE=3`, `CONCURRENCY=2`) to confirm `process_item` works before scaling up.