module Components.Page exposing
    ( Page
    , view
    )

import Html exposing (Html)
import Html.Attributes


type alias Page msg =
    { title : String
    , body : List (Html msg)
    }


view : Page msg -> Html msg
view page =
    let
        header : Html msg
        header =
            Html.header
                [ Html.Attributes.class "page-header" ]
                [ Html.h1 [] [ Html.text page.title ] ]
    in
    Html.main_
        [ Html.Attributes.class "page" ]
        (header :: page.body)
