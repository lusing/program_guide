:- encoding(utf8).
/* 第 123 章：独立目录对账；有限三轴表不冒充无限定理。 */

axis_rows([
    row(inaccessible, small, borel),
    row(measurable, prikry, analytic),
    row(supercompact, proper, sigma12),
    row(woodin, ideal, universally_baire),
    row(woodin_limit, tower, projective),
    row(measurable_above, iteration, ad_l_r)
]).

chapter_number(Entry, N) :-
    file_name_extension(Base, md, Entry),
    ( sub_atom(Base, 0, 3, _, Prefix),
      sub_atom(Base, 3, 1, _, '-')
    ; sub_atom(Base, 0, 2, _, Prefix),
      sub_atom(Base, 2, 1, _, '-')
    ),
    atom_number(Prefix, N).

must(Goal, Label) :-
    ( call(Goal) -> true
    ; format('FAILED: ~w~n', [Label]), fail
    ).

main :-
    format('==== 123~n'),
    axis_rows(Rows), length(Rows, 6),
    source_file(main, File),
    file_directory_name(File, PrologDir),
    file_directory_name(PrologDir, ExamplesDir),
    file_directory_name(ExamplesDir, Root),
    directory_file_path(Root, docs, Docs),
    directory_files(Docs, Entries),
    findall(N, (member(E, Entries), chapter_number(E, N)), Found),
    sort(Found, Chapters),
    numlist(0, 123, Expected),
    must(Chapters = Expected, continuous_chapters),
    length(Chapters, 124),
    numlist(79, 83, FirstNew),
    numlist(93, 122, HigherNew),
    append(FirstNew, HigherNew, ExpectedNew),
    intersection(Chapters, ExpectedNew, ActualNew),
    must(ActualNew = ExpectedNew, new_chapter_set),
    length(ActualNew, 35),
    FinalUnits is 624 + 35 * 7,
    must(FinalUnits =:= 869, unit_formula),
    must(FinalUnits =:= 124 * 7 + 1, unit_crosscheck),
    format('docs: 124 chapters, continuous 00-123; new=35~n'),
    format('axes: 6 aligned rows; units: 624+35*7=869~n'),
    format('END ====~n').

:- initialization(main).
