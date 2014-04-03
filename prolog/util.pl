% ---------------- %
%  EXECUTION TIME  %
% ---------------- %
measure_time(Time) :- statistics(walltime, [_ | [Time]]), !.
measure_time(_).
measure_time :- measure_time(_), !.
measure_time.

:- dynamic timer_time/2.

/**
 * Start a new timer with a given name.
 * If another timer with the given name exists, an error is raised.
 * 
 * @param Name 		The name of the timer.
 */
timer_start(Name) :-
	timer_exists(Name),
	statistics(real_time,[Time|_]),
	assertz(timer_time(Name, Time)).

/**
 * Get the time from a given timer.
 * 
 * @param Name 		The name of the timer.
 * @param Elapsed The number of elapsed seconds since the timer was started.
 */
timer_get(Name, Elapsed) :-
	timer_not_exists(Name),
	timer_time(Name, Time),
	statistics(real_time,[NowTime|_]),
	Elapsed is NowTime - Time.

/**
 * Stop and destroy a given timer.
 * 
 * @param Name 		The name of the timer to be stopped.
 * @param Elapsed The number of elapsed seconds since the timer was started.
 */
timer_stop(Name, Elapsed) :-
	timer_not_exists(Name),
	timer_get(Name, Elapsed),
	retractall(timer_time(Name, _)).

/**
 * Check if a timer exists and logs an error if it does not.
 *
 * @param Name 		The name of the timer to check for.
 */
timer_exists(Name) :-
	( timer_time(Name, _) -> log_e('timer', ['A timer with the name ', Name, ' already exists.']), fail; true ).

/**
 * Check if a timer doesn't exists and logs an error if it does.
 *
 * @param Name 		The name of the timer to check for.
 */
timer_not_exists(Name) :-
	( not(timer_time(Name, _)) -> log_e('timer', ['A timer with the name ', Name, ' does not exists.']), fail; true ).

% ---------------- %
%   TIME CONVERT   %
% ---------------- %
format_ms(Time, Minutes, Seconds, Milliseconds) :-
	% calculate the minutes
	MinutesFloat is (Time / (1000*60)),
	Minutes is floor(MinutesFloat),
	% calculate the seconds
	SecondsFloat is (Time mod (1000*60) / 1000),
	Seconds is floor(SecondsFloat),
	% calculate the milliseconds
	Milliseconds is (Time mod 1000)
	.

format_s(Time, String) :-
	Ms is (Time * 1000),
	format_ms(Ms, String).

format_ms(Time, String) :-
	format_ms(Time, Minutes, Seconds, Milliseconds),
	TimeList = [Minutes, 'm ', Seconds, 's ', Milliseconds, 'ms'],
	atomic_list_concat(TimeList, String)
	.

% ---------------- %
%    PRINT LIST    %
% ---------------- %
println([], _) :- nl.
println([Head|Tail], Separator) :- write(Head), write(Separator), println(Tail, Separator), !.
println(Element, Separator) :- not(Element = [_|_]), println([Element], Separator).
println(Element) :- println(Element, '').

% ---------------- %
%     LIST MIN     %
% ---------------- %
% start condition, Min is a variable, start with Min = Head
list_min([Head|Tail], Min) :- number(Head), CurMin = Head, list_min(Tail, CurMin, Min), !.
list_min([_Head|Tail], Min) :- list_min(Tail, Min), !.
% end condition, return the CurMin
list_min([], CurMin, Min) :- Min = CurMin.
% loop condition with a min update
list_min([Head|Tail], CurMin, FinalMin) :- number(Head), <(Head, CurMin), list_min(Tail, Head, FinalMin), !.
% loop condition without a min update (Head >= CurMax OR Head NaN)
list_min([_Head|Tail], CurMin, FinalMin) :- list_min(Tail, CurMin, FinalMin), !.

% ---------------- %
%     LIST MAX     %
% ---------------- %
% start condition, Max is a variable, start with Max = Head
list_max([Head|Tail], Max) :- number(Head), CurMax = Head, list_max(Tail, CurMax, Max), !.
list_max([_Head|Tail], Max) :- list_max(Tail, Max), !.
% end condition, return the CurMax
list_max([], CurMax, Max) :- Max = CurMax.
% loop condition with a max update
list_max([Head|Tail], CurMax, FinalMax) :- number(Head), >(Head, CurMax), list_max(Tail, Head, FinalMax), !.
% loop condition without a max update (Head < CurMax OR Head NaN)
list_max([_Head|Tail], CurMax, FinalMax) :- list_max(Tail, CurMax, FinalMax), !.

% ---------------- %
%    LIST COMMON   %
% ---------------- %
list_most_common(List, Element, Count) :-
	% remove duplicates
	setof(X, member(X,List), Set),
	% make a list of count(Element, Count)
	findall(
		count(TempElement, TempCount),
		(member(TempElement, Set), aggregate_all(count, member(TempElement, List), TempCount)),
		AllCounts),
	aggregate_all(max(MaxCount, MaxElement), member(count(MaxElement, MaxCount), AllCounts), Result),
	Result = max(Count, Element).

% ---------------- %
%    LIST INDEX    %
% ---------------- %
index_of([Element|_], Element, 0):- !.
index_of([_|Tail], Element, Index):-
  index_of(Tail, Element, OtherIndex), !,
  Index is OtherIndex + 1.

% ---------------- %
%     LIST PUSH    %
% ---------------- %
/**
 * list_push/3
 * 
 * @param A list to append the element to
 * @param The element to be appended
 * @param The resulting list
 */
% appending an element to an empty list results in a list with that only element
list_push([], Element, [Element]).
% appending an Element to a list made by Head|Tail results in a list with:
%  - the same Head
%  - its NewTail made by appending Tail and Element
list_push([Head|Tail], Element, [Head|NewTail]) :- list_push(Tail, Element, NewTail).

/**
 * Add an element to the top of the list.
 * 
 * @param List 			the original list
 * @param Element 	the element to add
 * @param NewList		the list to return
 */
list_unshift(List, Element, NewList) :-
	NewList = [Element|List].

% ---------------- %
%    LIST CONCAT   %
% ---------------- %
%* concat two generic elements in one list
list_append(A, B, List) :-
    (not(is_list(A)) -> NewA = [A]; NewA = A),
    (not(is_list(B)) -> NewB = [B]; NewB = B),
    append([NewA, NewB], List).

% ---------------- %
%    LIST REMOVE   %
% ---------------- %
/*
 * remove/3
 * @param A list to remove the element from
 * @param The element to be removed
 * @param The resulting list
 */
% removing an Element from an empty List returns an empty list
list_remove([], _, []).
% if the Element is the Head of the list, return NewTail, which is the Tail after calling remove on it again
list_remove([Element|Tail], Element, NewTail) :- list_remove(Tail, Element, NewTail), !.
% if the Element is not the Head of the list, return the original Head and a NewTail, which is the Tail after calling remove on it again
list_remove([Head|Tail], Element, [Head|NewTail]) :- list_remove(Tail, Element, NewTail).

% ---------------- %
%  STRING CONCAT   %
% ---------------- %
% concat_string_list/2 is used to begin the string concatenation
concat_string_list([Head|Tail], Result) :- concat_string_list([Head|Tail], '', Result).
% concat_string_list/3 is used to recurse the string concatenation
concat_string_list([Head|Tail], Temp, Result) :-
	string_concat(Temp, Head, NewString),
	concat_string_list(Tail, NewString, Result).
concat_string_list([], Temp, Result) :- Result = Temp.

% ---------------- %
%    MATHEMATICS   %
% ---------------- %
/**
 * Base-2 logarithm.
 *
 * @param Expr the expression to calculate the log2 for.
 * @return R the result of the calculation.
 */
log2(Expr, R) :- R is log10(Expr) / log10(2).