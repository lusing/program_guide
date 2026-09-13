-module(e07_records_maps).
-export([new_person/2, birthday/1, person_to_map/1]).

-record(person, {name, age = 0}).

new_person(Name, Age) when is_list(Name), is_integer(Age), Age >= 0 ->
    #person{name = Name, age = Age}.

birthday(P = #person{age = Age}) ->
    P#person{age = Age + 1}.

person_to_map(#person{name = Name, age = Age}) ->
    #{name => Name, age => Age}.

