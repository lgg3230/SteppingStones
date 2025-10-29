********************************************************************************
* PROJECT: STEPPING STONES
* AUTHOR: LUIS GOMES
* PROGRAM: MASTER DO FILE
********************************************************************************

// PRELIMINAIRES

set more off
set varabbrev off
clear all
macro drop _all
version 17.0

// DIRECTORIES

// Main:

global klc "/kellogg/proj/lgg3230"
global luis "/Users/luisg/Library/CloudStorage/OneDrive-NorthwesternUniversity/4 - PhD/02_Research/Org_Econ BR"

if "`c(username)'"=="luisg"{
	global main "$luis"
}

if "`c(username)'"=="lgg3230"{
	global main "$klc"
}

// Subfolders:


global rais_raw_dir "$main/UnionSpillovers/Replication-Mar-2/RAIS/output/data/full"
global interim "$main/SteppingStones/data/interim"
global analysis "$main/SteppingStones/data/analysis"
global ibge "$main/SteppingStones/data/raw/IBGE"

global dataprep "$main/SteppingStones/code/dataprep"
global tables "$main/SteppingStones/results/tables"
global graphs "$main/SteppingStones/results/plots"

// CONTROL WHICH PROGRAMS RUN

local 01_rais_to_firm   = 0
local 02_firm_classes   = 0

// RUN PROGRAMS

// Clean rais dataset, mergen with emploer association and collapse to firm level:

if (`01_rais_to_firm'  ==1) do "$dataprep/01_rais_to_firm.do";


