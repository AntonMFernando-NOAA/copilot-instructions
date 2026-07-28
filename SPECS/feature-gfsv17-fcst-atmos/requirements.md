# Requirements Document

Retain ATM product logs (#5130)

**Branch:** `feature/gfsv17-fcst-atmos`
**Issue:** [NOAA-EMC/global-workflow#5130](https://github.com/NOAA-EMC/global-workflow/issues/5130)
**Spec:** [kiro-spec://feature-gfsv17-fcst-atmos](kiro-spec://feature-gfsv17-fcst-atmos)

## Glossary

- **Per-product ATM log**: a small COM text file marking that one ATM product
  type was copied — `${RUN}.t${cyc}z.log.atm.{atmf,sfcf,grib,flux}.f${FH3}.txt`.
- **Combined per-hour sentinel**: `${RUN}.t${cyc}z.log.f${FH3}.txt`, the single
  per-forecast-hour sentinel downstream jobs poll.
- **ATM barrier**: `ush/forecast_atm_barrier.sh`, the MPMD rank that waits for
  all per-product logs of a forecast hour then writes the combined sentinel.
- **Manager rank**: a `ush/forecast_manager.sh` MPMD task that copies one class
  of product data to COM and writes its per-product log.
- **DOPOST / WRITE_DOPOST**: inline post that additionally produces the `grib`
  and `flux` master products (adds the `log.atm.grib`/`log.atm.flux` deps).

## Introduction

The GFS Forecast Manager copies ATM products to COM and writes per-product log
files (`${RUN}.t${cyc}z.log.atm.{atmf,sfcf,grib,flux}.f${FH3}.txt`) that mark
each product type as copied. The ATM barrier currently deletes these per-product
logs after writing the combined per-hour sentinel
(`${RUN}.t${cyc}z.log.f${FH3}.txt`). Issue #5130 requires the per-product logs
to be retained in COM so downstream jobs and models can verify products were
copied, without regressing restart behavior, and ideally so restarts skip
already-copied products.

## Requirements

### Requirement 1: Retain per-product ATM logs in COM
**User Story:** As a downstream job or model, I want the per-product ATM log
files to remain in COM after a forecast hour completes, so that I can confirm
each ATM product was copied correctly.

#### Acceptance Criteria
1. WHEN the ATM barrier writes the combined per-hour sentinel
   (`${RUN}.t${cyc}z.log.f${FH3}.txt`) THEN the system SHALL retain all
   per-product dependency logs for that hour
   (`log.atm.atmf`, `log.atm.sfcf`, and when `WRITE_DOPOST` is enabled
   `log.atm.grib` and `log.atm.flux`) in COM.
2. WHEN a forecast hour completes normally THEN the system SHALL NOT remove the
   per-product ATM logs from COM.
3. WHERE the ATM barrier reaches its post-history-done WARN-drain path, the
   system SHALL write the combined WARN sentinel AND SHALL retain any per-product
   logs that were produced for the pending hours.

### Requirement 2: Preserve restart capability and the sentinel contract
**User Story:** As a workflow operator, I want the existing restart and
downstream-sentinel behavior to be unchanged, so that retaining logs introduces
no regression.

#### Acceptance Criteria
1. THE system SHALL continue to write the combined per-hour sentinel
   `${RUN}.t${cyc}z.log.f${FH3}.txt` as the single sentinel downstream jobs poll.
2. WHEN a forecast segment is rewound/rerun THEN the system SHALL NOT leave stale
   state that prevents the manager or barrier from completing.
3. THE change SHALL be limited to log retention and SHALL NOT alter the product
   data files copied to COM or their destinations.

### Requirement 3: Skip re-copying already-copied products on restart
**User Story:** As a workflow operator, I want the forecast manager to skip
products it already copied when a segment restarts, so that restarts do not
redundantly re-copy data.

#### Acceptance Criteria
1. WHEN a forecast manager rank restarts AND a per-product COM log already exists
   for a given sentinel THEN the manager SHALL mark that sentinel's rows done and
   SHALL NOT re-copy the associated data files.
2. WHEN the ATM barrier restarts AND the combined per-hour sentinel already
   exists for a forecast hour THEN the barrier SHALL treat that hour as complete
   and SHALL NOT reprocess it.

### Requirement 4: EE2 file-naming compliance for retained COM artifacts
**User Story:** As an NCO/EE2 reviewer, I want the retained log files to follow
COM file-naming standards, so that they are acceptable operational deliverables.

#### Acceptance Criteria
1. THE retained per-product log file names SHALL follow the EE2 convention
   (`${RUN}.t${cyc}z.<type>.f${FH3}.txt`: lowercase, no special characters, no
   embedded date, forecast hour where applicable).
2. THE change SHALL NOT introduce new uppercase, special-character, or
   date-embedded file names into COM.
