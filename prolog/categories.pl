% ------------------------------------ %
%              data_type               %
% ------------------------------------ %
% define the type of data              %
% number: to be divided in ranges      %
% category: already divided in ranges  %
% ------------------------------------ %
data_type('PatientSex', category).
data_type('PatientRace', category).
data_type('PatientAge', number).
data_type('KTV', number).
data_type('QB', number).
data_type('ProgWeightLoss', number).
data_type('RealWeightLoss', number).
data_type('DeltaWeight', number).
data_type('ProgDuration', number).
data_type('RealDuration', number).
data_type('DeltaDuration', number).
data_type('SAPStart', number).
data_type('SAPEnd', number).
data_type('SAPAverage', number).
data_type('DAPStart', number).
data_type('DAPEnd', number).
data_type('DAPAverage', number).
data_type('BloodVolume', number).
data_type('DeltaBloodFlow', number).
data_type('DeltaUF', number).
data_type('SymptomID', category).


% ------------------- %
%        class        %
% ------------------- %
% 1st arg: Attr name  %
% 2nd arg: Range list %
% ------------------- %
:- dynamic class/2.

/**
 * Classify all of the available parameters in ranges.
 * For a category: every possible value is both the start and end of the class 
 * For a number: use ranges that span (|max-min|/10) values
 */
update_categories :-
	data_type(Attribute, Type),																% for each data
	make_class(Attribute, Type),   														% make a class
	fail																											% and iterate
	.
update_categories.																								% always succeed

% classify a generic attribute
make_class(Attribute, _) :-
	retractall(class(Attribute, _)),													% delete old ranges, if any
	assertz(class(Attribute, []))															% init the list of ranges
	.

% classify a category attribute
make_class(Attribute, category) :-
	positive(_, Attribute, Value),														% add all of the ranges from the positives
	add_to_class(Attribute, Value, Value),	
	fail 																											% and iterate
	.

% classify a number attribute
make_class(Attribute, number) :-
	findall(Value, positive(_, Attribute, Value), ValueList), % get the list of values
	list_max(ValueList, Max), list_min(ValueList, Min),				% get the maximum and minimum value
	Difference is abs(Max - Min),															% calculate the class dimension
	get_range_span(Difference, Span),													% get the range span
	generate_range(Attribute, Min, Max, Span)									% start generating ranges with the given span
	.
make_class(_,_).																						% always succeed
% calculate Difference/10 as the range span
get_range_span(Difference, Span) :-
	Span is /(Difference,10).
% generate a range for the given class with the given CurrentMax until the Max is reached
generate_range(Attribute, Min, Max, Span) :-
	RangeMin = Min, RangeMax is Min + Span,
	>=(Max, RangeMin),																				% RangeMin must be less or equal than Max
	add_to_class(Attribute, RangeMin, RangeMax),							% add the new range to the class
	NewMin = RangeMax,																				% the NewMin is the old RangeMax
	generate_range(Attribute, NewMin, Max, Span).							% generate the next range, until RangeMax passes Max

make_number_class_span(_, _).

% class(Attribute, [range(top, bottom), ...])
add_to_class(Attribute, Bottom, Top) :-
	class(Attribute, RangeList),															% get the class
	not(member(range(Bottom, Top), RangeList)),								% if the current range doesn't already exist
	append(RangeList, [range(Bottom, Top)], NewRangeList),		% add it
	retractall(class(Attribute, RangeList)),									% replace the list
	assertz(class(Attribute, NewRangeList))
	.