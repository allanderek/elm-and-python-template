module Helpers.Classes exposing
    ( active
    , boolean
    , optional
    , required
    )

import Html exposing (Attribute)
import Html.Attributes as Attributes


boolean : String -> String -> Bool -> Attribute msg
boolean left right isLeft =
    case isLeft of
        True ->
            Attributes.class left

        False ->
            Attributes.class right


active : Bool -> Attribute msg
active =
    boolean "active" "inactive"


required : Bool -> Attribute msg
required =
    boolean "required" "optional"


optional : Bool -> Attribute msg
optional =
    required << not
