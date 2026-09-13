-module(e29_maps_advanced).
-export([inc_counter/2, deep_put_city/2]).

inc_counter(Key, Map) when is_map(Map) ->
    maps:update_with(Key, fun(V) -> V + 1 end, 1, Map).

deep_put_city(City, UserMap) when is_map(UserMap) ->
    Profile0 = maps:get(profile, UserMap, #{}),
    Profile1 = maps:put(city, City, Profile0),
    maps:put(profile, Profile1, UserMap).

