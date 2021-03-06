# qty_strings.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# Copyright (c) 2017-2020 Charlie Whitfield
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *****************************************************************************
# All functions assume sim-standard units defined in UnitDefs.

class_name QtyStrings

const unit_defs := preload("res://ivoyager/static/unit_defs.gd")

enum { # case_type
	CASE_MIXED, # "1.00 Million", "1.00 kHz", "1.00 kilohertz", "1.00 Megahertz"
	CASE_LOWER, # does not modify exp_str
	CASE_UPPER, # does not modify exp_str
}

enum { # option_type for number_option()
	NAMED_NUMBER, # "99999", then "1.00 Million", etc.
	SCIENTIFIC,
	UNIT,
	PREFIXED_UNIT,
	# length
	LENGTH_M_KM, # m if x < 1.0 km
	LENGTH_KM_AU, # au if x > 0.1 au
	LENGTH_M_KM_AU,
	LENGTH_M_KM_AU_LY, # ly if x > 0.1 ly
	LENGTH_M_KM_AU_PREFIXED_PARSEC, # if > 0.1 pc, pc, kpc, Mpc, Gpc, etc.
	# mass
	MASS_G_KG, # g if < 1.0 kg
	MASS_G_KG_T, # g if < 1.0 kg; t if x >= 1000.0 kg 
	MASS_G_KG_PREFIXED_T, # g, kg, t, kt, Mt, Gt, Tt, Pt etc.
	# velocity
	VELOCITY_MPS_KMPS, # km/s if >= 1.0 km/s
	VELOCITY_MPS_KMPS_C, # km/s if >= 1.0 km/s; c if >= 0.1 c
}


const LOG_OF_10 := log(10)

# project vars
var multipliers := unit_defs.MULTIPLIERS
var functions := unit_defs.FUNCTIONS
var exp_str := "x10^" # or "e", "E"
var prefix_names := [
	"yocto", "zepto", "atto", "femto", "pico", "nano", "micro", "milli",
	"", "kilo", "Mega", "Giga", "Tera", "Peta", "Exa", "Zetta", "Yotta"
] # e3, e6, ... e24
var prefix_symbols := [
	"y", "z", "a", "f", "p", "n", char(181), "m",
	"", "k", "M", "G", "T", "P", "E", "Z", "Y"
] # same indexing as above

var large_numbers := ["TXT_MILLION", "TXT_BILLION", "TXT_TRILLION", "TXT_QUADRILLION",
	"TXT_QUINTILLION", "TXT_SEXTILLION", "TXT_SEPTILLION", "TXT_OCTILLION",
	 "TXT_NONILLION", "TXT_DECILLION"] # e6, e9, e12, ... e33; localized in project_init()

# Unit symbols in the next two dictionaries must also be present in multipliers
# or functions dictionaries (by default, these are obtained from UnitDefs). The
# converse is not true.

var short_forms := {
	# If missing here, we fallback to the unit string itself (which is usually
	# the desired short form).
	"century" : "TXT_CENTURIES",
	"deg" : "TXT_DEG",
	"degC" : "TXT_DEG_C",
	"degF" : "TXT_DEG_F",
	"deg/d" : "TXT_DEG_PER_DAY",
	"deg/a" : "TXT_DEG_PER_YEAR",
	"deg/century" : "DEG_PER_CENTURY",
}

var long_forms := {
	# If missing here, we fallback to short_forms, then the unit string itself.
	# Note that you can dynamically prefix any "base" unit (m, g, Hz, Wh, etc.)
	# using number_prefixed_unit(). We have commonly used already-prefixed here
	# because it is common to want to display quantities such as: "3.00e9 km".
	# time
	"s" : "TXT_SECONDS",
	"min" : "TXT_MINUTES",
	"h" : "TXT_HOURS",
	"d" : "TXT_DAYS",
	"a" : "TXT_YEARS",
	"y" : "TXT_YEARS",
	"yr" : "TXT_YEARS",
	"century" : "TXT_CENTURIES",
	# length
	"mm" : "TXT_MILIMETERS",
	"cm" : "TXT_CENTIMETERS",
	"m" : "TXT_METERS",
	"km" : "TXT_KILOMETER",
	"au" : "TXT_ASTRONOMICAL_UNITS",
	"ly" : "TXT_LIGHT_YEARS",
	"pc" : "TXT_PARSECS",
	"Mpc" : "TXT_MEGAPARSECS",
	# mass
	"g" : "TXT_GRAMS",
	"kg" : "TXT_KILOGRAMS",
	"t" : "TXT_TONNES",
	# angle
	"rad" : "TXT_RADIANS",
	"deg" : "TXT_DEGREES",
	# temperature
	"K" : "TXT_KELVIN",
	"degC" : "TXT_CENTIGRADE",
	"degF" : "TXT_FAHRENHEIT",
	# frequency
	"Hz" : "TXT_HERTZ",
	"d^-1" : "TXT_PER_DAY",
	"a^-1" : "TXT_PER_YEAR",
	"y^-1" : "TXT_PER_YEAR",
	"yr^-1" : "TXT_PER_YEAR",
	# area
	"m^2" : "TXT_SQUARE_METERS",
	"km^2" : "TXT_SQUARE_KILOMETERS",
	"ha" : "TXT_HECTARES",
	# volume
	"l" : "TXT_LITER",
	"L" : "TXT_LITER",
	"m^3" : "TXT_CUBIC_METERS",
	"km^3" : "TXT_CUBIC_KILOMETERS",
	# velocity
	"m/s" : "TXT_METERS_PER_SECOND",
	"km/s" : "TXT_KILOMETERS_PER_SECOND",
	"km/h" : "TXT_KILOMETERS_PER_HOUR",
	"c" : "TXT_SPEED_OF_LIGHT",
	# angular velocity
	"deg/d" : "TXT_DEGREES_PER_DAY",
	"deg/a" : "TXT_DEGREES_PER_YEAR",
	"deg/century" : "DEGREES_PER_CENTURY",
	# particle density
	"m^-3" : "TXT_PER_CUBIC_METER",
	# mass density
	"g/cm^3" : "TXT_GRAMS_PER_CUBIC_CENTIMETER",
	# mass rate
	"kg/d" : "TXT_KILOGRAMS_PER_DAY",
	"t/d" : "TXT_TONNES_PER_DAY",
	# force
	"N" : "TXT_NEWTONS",
	# pressure
	"Pa" : "TXT_PASCALS",
	"atm" : "TXT_ATMOSPHERES",
	# energy
	"J" : "TXT_JOULES",
	"Wh" : "TXT_WATT_HOURS",
	"kWh" : "TXT_KILOWATT_HOURS",
	"MWh" : "TXT_MEGAWATT_HOURS",
	"eV" : "TXT_ELECTRONVOLTS",
	# power
	"W" : "TXT_WATTS",
	"kW" : "TXT_KILOWATTS",
	"MW" : "TXT_MEGAWATTS",
	# luminous intensity / luminous flux
	"cd" : "TXT_CANDELAS",
	"lm" : "TXT_LUMENS",
	# luminance
	"cd/m^2" : "TXT_CANDELAS_PER_SQUARE_METER",
	# electric potential
	"V" : "TXT_VOLTS",
	# electric charge
	"C" :  "TXT_COULOMBS",
	# magnetic flux
	"Wb" : "TXT_WEBERS",
	# magnetic flux density
	"T" : "TXT_TESLAS",
}

# private
var _n_prefixes: int
var _prefix_offset: int
var _n_lg_numbers: int


func project_init():
	_n_prefixes = prefix_symbols.size()
	assert(_n_prefixes == prefix_names.size())
	_prefix_offset = prefix_symbols.find("")
	assert(_prefix_offset == prefix_names.find(""))
	_n_lg_numbers = large_numbers.size()
	for i in range(_n_lg_numbers):
		large_numbers[i] = tr(large_numbers[i])

func number_option(x: float, option_type: int, unit := "", long_form := false,
		case_type := CASE_MIXED, use_scientific := true, force_scientific := false) -> String:
	# wrapper function for functions below
	match option_type:
		NAMED_NUMBER:
			return named_number(x, case_type)
		SCIENTIFIC:
			return scientific(x, force_scientific)
		UNIT:
			return number_unit(x, unit, long_form, case_type, use_scientific, force_scientific)
		PREFIXED_UNIT:
			return number_prefixed_unit(x, unit, long_form, case_type, use_scientific, force_scientific)
		LENGTH_M_KM: # m if x < 1.0 km
			if x < unit_defs.KM:
				return number_unit(x, "m", long_form, case_type, use_scientific, force_scientific)
			return number_unit(x, "km", long_form, case_type, use_scientific, force_scientific)
		LENGTH_KM_AU: # au if x > 0.1 au
			if x < 0.1 * unit_defs.AU:
				return number_unit(x, "km", long_form, case_type, use_scientific, force_scientific)
			return number_unit(x, "au", long_form, case_type, use_scientific, force_scientific)
		LENGTH_M_KM_AU:
			if x < unit_defs.KM:
				return number_unit(x, "m", long_form, case_type, use_scientific, force_scientific)
			elif x < 0.1 * unit_defs.AU:
				return number_unit(x, "km", long_form, case_type, use_scientific, force_scientific)
			return number_unit(x, "au", long_form, case_type, use_scientific, force_scientific)
		LENGTH_M_KM_AU_LY:
			if x < unit_defs.KM:
				return number_unit(x, "m", long_form, case_type, use_scientific, force_scientific)
			elif x < 0.1 * unit_defs.AU:
				return number_unit(x, "km", long_form, case_type, use_scientific, force_scientific)
			elif x < 0.1 * unit_defs.LIGHT_YEAR:
				return number_unit(x, "au", long_form, case_type, use_scientific, force_scientific)
			return number_unit(x, "ly", long_form, case_type, use_scientific, force_scientific)
		LENGTH_M_KM_AU_PREFIXED_PARSEC:
			if x < unit_defs.KM:
				return number_unit(x, "m", long_form, case_type, use_scientific, force_scientific)
			elif x < 0.1 * unit_defs.AU:
				return number_unit(x, "km", long_form, case_type, use_scientific, force_scientific)
			elif x < 0.1 * unit_defs.PARSEC:
				return number_unit(x, "au", long_form, case_type, use_scientific, force_scientific)
			return number_prefixed_unit(x, "pc", long_form, case_type, use_scientific, force_scientific)
		MASS_G_KG: # g if < 1.0 kg
			if x < unit_defs.KG:
				return number_unit(x, "g", long_form, case_type, use_scientific, force_scientific)
			return number_unit(x, "kg", long_form, case_type, use_scientific, force_scientific)
		MASS_G_KG_T: # g if < 1.0 kg; t if x >= 1000.0 kg 
			if x < unit_defs.KG:
				return number_unit(x, "g", long_form, case_type, use_scientific, force_scientific)
			elif x < unit_defs.TONNE:
				return number_unit(x, "kg", long_form, case_type, use_scientific, force_scientific)
			return number_unit(x, "t", long_form, case_type, use_scientific, force_scientific)
		MASS_G_KG_PREFIXED_T: # g, kg, t, kt, Mt, Gt, Tt, etc.
			if x < unit_defs.KG:
				return number_unit(x, "g", long_form, case_type, use_scientific, force_scientific)
			elif x < unit_defs.TONNE:
				return number_unit(x, "kg", long_form, case_type, use_scientific, force_scientific)
			return number_prefixed_unit(x, "t", long_form, case_type, use_scientific, force_scientific)
		VELOCITY_MPS_KMPS: # km/s if >= 1.0 km/s
			if x < unit_defs.KM / unit_defs.SECOND:
				return number_unit(x, "m/s", long_form, case_type, use_scientific, force_scientific)
			return number_unit(x, "km/s", long_form, case_type, use_scientific, force_scientific)
		VELOCITY_MPS_KMPS_C: # c if >= 0.1 c
			if x < unit_defs.KM / unit_defs.SECOND:
				return number_unit(x, "m/s", long_form, case_type, use_scientific, force_scientific)
			elif x < 0.1 * unit_defs.SPEED_OF_LIGHT:
				return number_unit(x, "c", long_form, case_type, use_scientific, force_scientific)
			return number_unit(x, "km/s", long_form, case_type, use_scientific, force_scientific)
	assert(false, "Unkknown option_type: " + option_type)
	return String(x)

func scientific(x: float, force_scientific := false) -> String:
	# returns "0.0100" to "99999" as non-scientific unless force_scientific
	# TODO: significant_digets (now = 3)
	if x == 0.0:
		return "0.00" + exp_str + "0" if force_scientific else "0"
	var exponent := int(floor(log(abs(x)) / LOG_OF_10))
	if force_scientific or exponent > 4 or exponent < -2:
		var divisor := pow(10.0, exponent)
		x = x / divisor if !is_zero_approx(divisor) else 1.0
		return "%.2f%s%s" % [x, exp_str, exponent] # e.g., 5.55e5
	elif exponent > 1.0:
		return "%.f" % x # 55555, 5555, or 555
	elif exponent == 1.0:
		return "%.1f" % x # 55.5
	elif exponent == 0.0:
		return "%.2f" % x # 5.55
	elif exponent == -1.0:
		return "%.3f" % x # 0.555
	else: # -2.0
		return "%.4f" % x # 0.0555

func named_number(x: float, case_type := CASE_MIXED) -> String:
	# returns integer string up to "999999", then "1.00 Million", etc.;
	# you won't see scientific unless > 99999 Decillion.
	if abs(x) < 1e6:
		return "%.f" % x
	var exp_div_3 := int(floor(log(abs(x)) / (LOG_OF_10 * 3.0)))
	var lg_num_index := exp_div_3 - 2
	if lg_num_index < 0: # shouldn't happen but just in case
		return "%.f" % x
	if lg_num_index >= _n_lg_numbers:
		lg_num_index = _n_lg_numbers - 1
		exp_div_3 = lg_num_index + 2
	x /= pow(10.0, exp_div_3 * 3)
	var lg_number_str: String = large_numbers[lg_num_index]
	if case_type == CASE_LOWER:
		lg_number_str = lg_number_str.to_lower()
	elif case_type == CASE_UPPER:
		lg_number_str = lg_number_str.to_upper()
	return scientific(x) + " " + lg_number_str

func number_unit(x: float, unit: String, long_form := false, case_type := CASE_MIXED,
		use_scientific := true, force_scientific := false) -> String:
	# unit must be in multipliers or functions dicts (by default these are
	# MULTIPLIERS and FUNCTIONS in ivoyager/static/unit_defs.gd)
	x = unit_defs.conv(x, unit, true, false, multipliers, functions)
	var number_str: String
	if use_scientific:
		number_str = scientific(x, force_scientific)
	else:
		number_str = String(x)
	if long_form and long_forms.has(unit):
		unit = tr(long_forms[unit])
	elif short_forms.has(unit):
		unit = tr(short_forms[unit])
	if case_type == CASE_LOWER:
		unit = unit.to_lower()
	elif case_type == CASE_UPPER:
		unit = unit.to_upper()
	return number_str + " " + unit

func number_prefixed_unit(x: float, unit: String, long_form := false,
		case_type := CASE_MIXED, use_scientific := true, force_scientific := false) -> String:
	# Example results: "1.00 Gt" or "1.00 Gigatonnes" (w/ unit = "t" and
	# long_form = false or true, repspectively). You won't see scientific
	# notation unless the internal value falls outside of the prefixes range.
	# WARNING: Don't try to prefix an already-prefixed unit (eg, km) or any
	# composite unit where the first unit has a power other than 1 (eg, m^3).
	# The result will look weird and/or be wrong (eg, 1000 m^3 -> 1.00 km^3).
	# unit = "" ok; otherwise, unit must be in multipliers or functions dicts.
	if unit:
		x = unit_defs.conv(x, unit, true, false, multipliers, functions)
	var exp_div_3 := int(floor(log(abs(x)) / (LOG_OF_10 * 3.0)))
	var si_index := exp_div_3 + _prefix_offset
	if si_index < 0:
		si_index = 0
		exp_div_3 = -_prefix_offset
	elif si_index >= _n_prefixes:
		si_index = _n_prefixes - 1
		exp_div_3 = si_index - _prefix_offset
	x /= pow(10.0, exp_div_3 * 3)
	var number_str: String
	if use_scientific:
		number_str = scientific(x, force_scientific)
	else:
		number_str = String(x)
	if long_form and long_forms.has(unit):
		unit = tr(long_forms[unit])
	elif short_forms.has(unit):
		unit = tr(short_forms[unit])
	if long_form:
		unit = prefix_names[si_index] + unit
	else:
		unit = prefix_symbols[si_index] + unit
	if case_type == CASE_LOWER:
		unit = unit.to_lower()
	elif case_type == CASE_UPPER:
		unit = unit.to_upper()
	return number_str + " " + unit
