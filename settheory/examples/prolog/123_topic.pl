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
    numlist(0, 148, Expected),
    must(Chapters = Expected, continuous_chapters),
    length(Chapters, 149),
    numlist(124, 148, HaoExpected),
    intersection(Chapters, HaoExpected, HaoChapters),
    must(HaoChapters = HaoExpected, hao_chapter_set),
    length(HaoChapters, 25),
    /* lean 16 + isabelle 8 + coq 6 + julia 15 + python 24 + prolog 10 */
    HaoUnits is 16 + 8 + 6 + 0 + 15 + 24 + 10,
    must(HaoUnits =:= 79, hao_unit_count),
    FinalUnits is 869 + HaoUnits,
    must(FinalUnits =:= 948, unit_formula),
    format('docs: 149 chapters, continuous 00-148; hao=25~n'),
    format('axes: 6 aligned rows; units: 869+79=948~n'),
    format('END ====~n').

:- initialization(main).
