module Helpers.List exposing
    ( emptyAsNothing
    , filterByFirst
    , findWith
    , firstJust
    )

import List.Extra


filterByFirst : List ( Bool, a ) -> List a
filterByFirst items =
    items
        |> List.filter Tuple.first
        |> List.map Tuple.second


firstJust : List (Maybe a) -> Maybe a
firstJust items =
    case items of
        (Just item) :: _ ->
            Just item

        Nothing :: rest ->
            firstJust rest

        [] ->
            Nothing


emptyAsNothing : List a -> Maybe (List a)
emptyAsNothing items =
    case List.isEmpty items of
        True ->
            Nothing

        False ->
            Just items


findWith : a -> (b -> a) -> List b -> Maybe b
findWith itemToFind getter items =
    List.Extra.find
        (\item -> getter item == itemToFind)
        items
