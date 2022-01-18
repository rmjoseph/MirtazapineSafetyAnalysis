# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)


## [1.2.0] - 2022-01-18
### Added
- Complete case and complete variable analyses for mortality and self-harm
- Self-harm sensitivity analysis with broader eligibility criteria
### Changed
- Added the new analysis files to the analysis master file
### Fixed


## [1.1.0] - 2021-07-30
### Added
- Power calculations for self-harm(30)
- File counting people in the cohort for self-harm(30)
- Sensitivity analysis using SSRI as reference rather than mirtazapine for self-harm(30) analysis
- Summary of median ad doses over follow-up for self-harm(30) analysis

### Changed
- Updated self-harm(30) survival curves to include a risk table, and formated legend.
- Updated master analysis file to include the newly-added self-harm(30) analysis scripts

### Fixed
- Fixed error (specified wrong variables) when extracting self-harm data from HES
- Fixed error in self-harm(30) baseline characteristics script (fix uses enddate30 not enddate6 to define the outcome)


## [1.0.0] - 2021-05-21
- First release
