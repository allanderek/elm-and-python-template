module Types.Button exposing
    ( Kind(..)
    , Variant(..)
    , kindClass
    , variantClass
    )

import Html exposing (Attribute)
import Html.Attributes as Attributes


kindClass : Kind -> Attribute msg
kindClass kind =
    case kind of
        Form ->
            Attributes.class "form-button"

        Interface ->
            Attributes.class "btn"


variantClass : Variant -> Attribute msg
variantClass variant =
    case variant of
        Primary ->
            Attributes.class "btn btn-primary"

        Secondary ->
            Attributes.class "btn btn-secondary"

        Danger ->
            Attributes.class "btn btn-danger"


type Kind
    = Form
    | Interface


type Variant
    = Primary
    | Secondary
    | Danger
